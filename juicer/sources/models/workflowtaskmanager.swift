import Foundation
import Combine

enum WorkflowTaskKind: String, CaseIterable, Codable, Identifiable {
    case systemHealth
    case diskHealth
    case networkHealth
    case brewHealth
    case logHealth

    var id: String { rawValue }

    var title: String {
        switch self {
        case .systemHealth: return "System health"
        case .diskHealth: return "Disk health"
        case .networkHealth: return "Network health"
        case .brewHealth: return "Homebrew health"
        case .logHealth: return "Recent error scan"
        }
    }

    var icon: String {
        switch self {
        case .systemHealth: return "cpu"
        case .diskHealth: return "internaldrive"
        case .networkHealth: return "network"
        case .brewHealth: return "shippingbox"
        case .logHealth: return "doc.text.magnifyingglass"
        }
    }

    var command: String {
        switch self {
        case .systemHealth:
            return "printf '%s\\n' '--- software ---'; sw_vers; printf '%s\\n' '--- memory ---'; vm_stat; printf '%s\\n' '--- uptime ---'; uptime"
        case .diskHealth:
            return "printf '%s\\n' '--- volumes ---'; df -h; printf '%s\\n' '--- largest home folders ---'; du -sh \"$HOME\"/* 2>/dev/null | sort -hr | head -12"
        case .networkHealth:
            return "printf '%s\\n' '--- interfaces ---'; ifconfig | awk '/^[a-z0-9]+:/{name=$1; sub(\":\", \"\", name)} /status: active/{print name, $0}'; printf '%s\\n' '--- dns ---'; scutil --dns | grep -E 'nameserver\\[[0-9]+\\]' | head -8"
        case .brewHealth:
            return "if command -v brew >/dev/null 2>&1; then printf '%s\\n' '--- brew doctor ---'; brew doctor 2>&1 | head -80; printf '%s\\n' '--- outdated ---'; brew outdated; else printf '%s\\n' 'Homebrew is not installed.'; fi"
        case .logHealth:
            return "log show --last 1h --style compact --predicate 'messageType ==  Fault OR messageType ==  Error' 2>/dev/null | tail -80"
        }
    }
}

enum WorkflowTaskState: String, Codable {
    case queued
    case running
    case paused
    case completed
    case failed
    case cancelled

    var title: String {
        switch self {
        case .queued: return "Queued"
        case .running: return "Running"
        case .paused: return "Paused"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }
}

struct WorkflowTask: Identifiable, Codable, Hashable {
    let id: UUID
    let kind: WorkflowTaskKind
    let createdAt: Date
    var state: WorkflowTaskState
    var output: String
    var finishedAt: Date?
    var commandOverride: String?
    var recipeID: String?
    var recipeTitle: String?
    var recipeIcon: String?

    init(kind: WorkflowTaskKind) {
        id = UUID()
        self.kind = kind
        createdAt = Date()
        state = .queued
        output = ""
        finishedAt = nil
        commandOverride = nil
        recipeID = nil
        recipeTitle = nil
        recipeIcon = nil
    }

    init(recipe: workflowrecipe) {
        id = UUID()
        kind = .systemHealth
        createdAt = Date()
        state = .queued
        output = ""
        finishedAt = nil
        commandOverride = recipe.command
        recipeID = recipe.id
        recipeTitle = recipe.title
        recipeIcon = recipe.icon
    }

    var displayTitle: String { recipeTitle ?? kind.title }
    var displayIcon: String { recipeIcon ?? kind.icon }
}

@MainActor
final class workflowtaskmanager: ObservableObject {
    static let shared = workflowtaskmanager()

    @Published private(set) var tasks: [WorkflowTask] = []
    @Published private(set) var isPaused = false
    @Published private(set) var isRunning = false

    private var process: Process?
    private var currentTaskID: UUID?
    private let tasksKey = "juicer.workflow.tasks"

    private init() {
        load()
    }

    func enqueue(_ kind: WorkflowTaskKind) {
        tasks.append(WorkflowTask(kind: kind))
        persist()
        startNextIfNeeded()
    }

    func enqueue(_ recipe: workflowrecipe) {
        tasks.append(WorkflowTask(recipe: recipe))
        persist()
        startNextIfNeeded()
    }

    func enqueueDiskHealth(paths: [String]) {
        var task = WorkflowTask(kind: .diskHealth)
        let validPaths = paths.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        if !validPaths.isEmpty {
            let quoted = validPaths.map { "\\\"\($0.replacingOccurrences(of: "\\\"", with: "\\\\\\\""))\\\"" }.joined(separator: " ")
            task.commandOverride = "printf '%s\\n' '--- selected paths ---'; du -sh \(quoted) 2>&1 | sort -hr"
        }
        tasks.append(task)
        persist()
        startNextIfNeeded()
    }

    func enqueueAll() {
        for kind in WorkflowTaskKind.allCases {
            tasks.append(WorkflowTask(kind: kind))
        }
        persist()
        startNextIfNeeded()
    }

    func retry(_ task: WorkflowTask) {
        if let recipeID = task.recipeID, let recipe = workflowrecipe.all.first(where: { $0.id == recipeID }) {
            enqueue(recipe)
        } else {
            enqueue(task.kind)
        }
    }

    func togglePause() {
        isPaused.toggle()
        if isPaused {
            process?.terminate()
        } else {
            startNextIfNeeded()
        }
        persist()
    }

    func cancel(_ task: WorkflowTask) {
        if task.id == currentTaskID {
            process?.terminate()
        }
        update(task.id) { $0.state = .cancelled; $0.finishedAt = Date() }
        startNextIfNeeded()
    }

    func remove(_ task: WorkflowTask) {
        guard task.id != currentTaskID else { return }
        tasks.removeAll { $0.id == task.id }
        persist()
    }

    func clearFinished() {
        tasks.removeAll { $0.state != .queued && $0.id != currentTaskID }
        persist()
    }

    func clearAll() {
        process?.terminate()
        tasks.removeAll()
        currentTaskID = nil
        isRunning = false
        persist()
    }

    func reportText() -> String {
        tasks.map { task in
            let date = task.createdAt.formatted(date: .abbreviated, time: .shortened)
            return "[\(date)] \(task.displayTitle) — \(task.state.title)\n\(task.output)"
        }.joined(separator: "\n\n")
    }

    private func startNextIfNeeded() {
        guard !isPaused, !isRunning,
              let index = tasks.firstIndex(where: { $0.state == .queued }) else { return }

        let task = tasks[index]
        currentTaskID = task.id
        tasks[index].state = .running
        isRunning = true
        persist()

        let taskID = task.id
        let command = task.commandOverride ?? task.kind.command
        let pipe = Pipe()
        let newProcess = Process()
        newProcess.executableURL = URL(fileURLWithPath: "/bin/zsh")
        newProcess.arguments = ["-lc", command]
        newProcess.standardOutput = pipe
        newProcess.standardError = pipe
        process = newProcess

        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty, let chunk = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor in
                guard let self, let index = self.tasks.firstIndex(where: { $0.id == taskID }) else { return }
                self.tasks[index].output.append(chunk)
                self.persist()
            }
        }

        newProcess.terminationHandler = { [weak self] process in
            pipe.fileHandleForReading.readabilityHandler = nil
            Task { @MainActor in
                guard let self, let index = self.tasks.firstIndex(where: { $0.id == taskID }) else { return }
                if self.tasks[index].state == .cancelled {
                    self.tasks[index].output.append("\nCancelled by user.")
                } else {
                    self.tasks[index].state = process.terminationStatus == 0 ? .completed : .failed
                }
                self.tasks[index].finishedAt = Date()
                self.currentTaskID = nil
                self.process = nil
                self.isRunning = false
                self.persist()
                if UserDefaults.standard.object(forKey: "juicer.workflow.notifications") as? Bool ?? true {
                    NotificationManager.shared.sendNotification(title: "Workflow complete", body: "\(self.tasks[index].displayTitle) finished with status: \(self.tasks[index].state.title).")
                }
                self.startNextIfNeeded()
            }
        }

        do {
            try newProcess.run()
        } catch {
            update(taskID) { $0.state = .failed; $0.output = error.localizedDescription; $0.finishedAt = Date() }
            isRunning = false
            process = nil
            currentTaskID = nil
            startNextIfNeeded()
        }
    }

    private func update(_ id: UUID, _ change: (inout WorkflowTask) -> Void) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        change(&tasks[index])
        persist()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: tasksKey),
              let stored = try? JSONDecoder().decode([WorkflowTask].self, from: data) else { return }
        tasks = stored
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(Array(tasks.suffix(100))) {
            UserDefaults.standard.set(data, forKey: tasksKey)
        }
    }
}

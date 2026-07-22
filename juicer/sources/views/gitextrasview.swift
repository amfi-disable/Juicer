import SwiftUI
import AppKit

struct gitextrasview: View {
    @StateObject private var manager = GitExtraManager(repoPath: FileManager.default.homeDirectoryForCurrentUser.path + "/Desktop/Projects/Apps/Juicer")
    @State private var activeTab = "Overview"
    @State private var standupDays = "7 days ago"
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            JuicerFeatureHeader(
                title: "Git Analytics & Power Tools",
                subtitle: "Features extracted from top 25 open-source Git tools (OneFetch, Git-Sizer, GitLeaks, Git-Standup, Git-Cliff, Git-Trim).",
                icon: "chart.bar.doc.horizontal.fill",
                refreshing: manager.isAnalyzing,
                action: { manager.analyzeRepo(at: manager.repoPath) }
            )
            .padding()
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            
            Divider()
            
            // Sub-Navigation Tabs
            HStack {
                Picker("", selection: $activeTab) {
                    Text("Overview & OneFetch").tag("Overview")
                    Text("Repo Health & Sizer").tag("Health")
                    Text("Standup & Logs").tag("Standup")
                    Text("Changelog Generator").tag("Changelog")
                    Text("Secret Scanner").tag("Secrets")
                    Text("Branch Trim (\(manager.mergedBranchesToTrim.count))").tag("Trim")
                }
                .pickerStyle(.segmented)
                
                Spacer()
            }
            .padding()
            
            Divider()
            
            // Tab Content
            ScrollView {
                VStack(spacing: 20) {
                    if activeTab == "Overview" {
                        overviewTab()
                    } else if activeTab == "Health" {
                        healthTab()
                    } else if activeTab == "Standup" {
                        standupTab()
                    } else if activeTab == "Changelog" {
                        changelogTab()
                    } else if activeTab == "Secrets" {
                        secretsTab()
                    } else {
                        trimTab()
                    }
                }
                .padding()
            }
        }
        .allowWindowDragAndFit()
    }
    
    // MARK: - 1. Overview Tab (OneFetch + Git-Quick-Stats)
    @ViewBuilder
    private func overviewTab() -> some View {
        if let overview = manager.overview {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                JuicerMetricTile(title: "Repository Name", value: overview.repoName, detail: "Head: \(overview.headBranch)")
                JuicerMetricTile(title: "Total Commits", value: "\(overview.totalCommits)", detail: "Age: \(overview.repoAge)")
                JuicerMetricTile(title: "Contributors", value: "\(overview.totalAuthors)", detail: "Primary: \(overview.primaryLanguage)")
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Author Commit Distribution (Git-Quick-Stats)").font(.headline)
                ForEach(manager.authorStats) { author in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(author.author).bold()
                            Spacer()
                            Text("\(author.commits) commits (\(String(format: "%.1f", author.percentage))%)")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        JuicerUsageBar(value: author.percentage, color: .accentColor)
                    }
                }
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary))
        } else {
            ProgressView("Analyzing repository...")
        }
    }
    
    // MARK: - 2. Health Tab (Git-Sizer)
    @ViewBuilder
    private func healthTab() -> some View {
        if let sizer = manager.sizerMetrics {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Git-Sizer Diagnostics").font(.title3.bold())
                    Spacer()
                    Text(sizer.healthRating)
                        .font(.headline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(sizer.healthRating == "Healthy" ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                        .foregroundStyle(sizer.healthRating == "Healthy" ? Color.green : Color.orange)
                        .cornerRadius(6)
                }
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    JuicerMetricTile(title: "Total Objects", value: "\(sizer.totalObjects)", detail: "Loose + Packfile objects")
                    JuicerMetricTile(title: "Packfile Size", value: "\(sizer.packfileSizeBytes / (1024 * 1024)) MB", detail: "Disk consumption")
                    JuicerMetricTile(title: "Branches Count", value: "\(sizer.totalBranches)", detail: "Local and remotes")
                    JuicerMetricTile(title: "Tags Count", value: "\(sizer.totalTags)", detail: "Annotated & lightweight")
                }
                
                if !sizer.warnings.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Health Warnings").bold().foregroundStyle(.orange)
                        ForEach(sizer.warnings, id: \.self) { warning in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                                Text(warning)
                            }
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - 3. Standup Tab (Git-Standup)
    @ViewBuilder
    private func standupTab() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Git-Standup Generator").font(.headline)
                Spacer()
                Picker("Range:", selection: $standupDays) {
                    Text("Past 3 Days").tag("3 days ago")
                    Text("Past 7 Days").tag("7 days ago")
                    Text("Past 14 Days").tag("14 days ago")
                }
                .frame(width: 160)
                
                Button("Generate Standup") {
                    manager.generateStandup(since: standupDays)
                }
                .buttonStyle(.borderedProminent)
            }
            
            TextEditor(text: .constant(manager.standupLog.isEmpty ? "Click 'Generate Standup' to compile your commit activity log for team standup meetings." : manager.standupLog))
                .font(.system(.body, design: .monospaced))
                .frame(height: 250)
                .cornerRadius(8)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - 4. Changelog Tab (Git-Cliff)
    @ViewBuilder
    private func changelogTab() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Git-Cliff Changelog Generator").font(.headline)
                Spacer()
                Button("Generate Changelog") {
                    manager.generateChangelog()
                }
                .buttonStyle(.borderedProminent)
            }
            
            TextEditor(text: .constant(manager.generatedChangelog.isEmpty ? "Click 'Generate Changelog' to auto-generate release notes from Conventional Commits." : manager.generatedChangelog))
                .font(.system(.body, design: .monospaced))
                .frame(height: 280)
                .cornerRadius(8)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - 5. Secrets Tab (GitLeaks)
    @ViewBuilder
    private func secretsTab() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("GitLeaks & Git-Secrets Scanner").font(.headline)
                Spacer()
                Text("\(manager.secretIssues.count) Issues Found")
                    .bold()
                    .foregroundStyle(manager.secretIssues.isEmpty ? Color.green : Color.red)
            }
            
            if manager.secretIssues.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "shield.checkmark.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.green)
                    Text("No Hardcoded Secrets or API Tokens Detected!")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                List(manager.secretIssues) { issue in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "lock.shield.fill").foregroundStyle(.red)
                            Text(issue.secretType).bold().foregroundStyle(.red)
                            Spacer()
                            Text("\(issue.file):L\(issue.line)").font(.caption.monospaced()).foregroundStyle(.secondary)
                        }
                        Text(issue.snippet)
                            .font(.system(.caption, design: .monospaced))
                            .padding(4)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(4)
                    }
                    .padding(.vertical, 4)
                }
                .frame(height: 250)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - 6. Trim Tab (Git-Trim)
    @ViewBuilder
    private func trimTab() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Git-Trim Merged Branch Purger").font(.headline)
                Spacer()
                Button("Purge All Merged Branches") {
                    manager.trimMergedBranches()
                }
                .buttonStyle(.borderedProminent)
                .disabled(manager.mergedBranchesToTrim.isEmpty)
            }
            
            if manager.mergedBranchesToTrim.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.green)
                    Text("No Stale Merged Branches Found")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                List(manager.mergedBranchesToTrim, id: \.self) { branch in
                    HStack {
                        Image(systemName: "arrow.triangle.branch").foregroundStyle(.orange)
                        Text(branch).font(.system(.body, design: .monospaced))
                        Spacer()
                        Text("Merged").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

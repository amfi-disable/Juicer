import Foundation

struct workflowrecipe: Identifiable, Hashable {
    let id: String
    let title: String
    let category: String
    let icon: String
    let command: String

    static let categories = ["System", "Processes", "Disk", "Network", "Security", "Developer", "Logs", "Files", "Power", "Applications"]

    static let all: [workflowrecipe] = [
        recipe("system-os-version", "Operating system version", "System", "macos.window", "sw_vers"),
        recipe("system-uptime", "System uptime", "System", "clock", "uptime"),
        recipe("system-boot-args", "Boot arguments", "System", "arrow.up.circle", "nvram boot-args 2>/dev/null || true"),
        recipe("system-hardware", "Hardware overview", "System", "desktopcomputer", "system_profiler SPHardwareDataType -detailLevel mini"),
        recipe("system-model", "Model identifier", "System", "macbook", "sysctl -n hw.model"),
        recipe("system-kernel", "Kernel and architecture", "System", "terminal", "uname -a; printf '\\narchitecture: '; uname -m"),
        recipe("system-users", "Active users", "System", "person.2", "who"),
        recipe("system-timezone", "Time zone and clock", "System", "clock.badge.checkmark", "date; systemsetup -gettimezone 2>/dev/null || true"),
        recipe("system-hostname", "Computer identity", "System", "tag", "scutil --get ComputerName; scutil --get LocalHostName; scutil --get HostName 2>/dev/null || true"),
        recipe("system-locale", "Locale configuration", "System", "globe", "locale"),

        recipe("process-top-cpu", "Top CPU processes", "Processes", "chart.bar.xaxis", "ps -Ao pid,pcpu,pmem,comm | sort -k2 -nr | head -16"),
        recipe("process-top-memory", "Top memory processes", "Processes", "memorychip", "ps -Ao pid,pcpu,pmem,comm | sort -k3 -nr | head -16"),
        recipe("process-count", "Running process count", "Processes", "number", "printf 'processes: '; ps -ax | wc -l"),
        recipe("process-user-agents", "User launch agents", "Processes", "person.crop.circle.badge.play", "launchctl list | head -80"),
        recipe("process-system-daemons", "System launch daemons", "Processes", "gearshape.2", "find /Library/LaunchDaemons /System/Library/LaunchDaemons -maxdepth 1 -type f -print 2>/dev/null | sort | head -120"),
        recipe("process-login-items", "Login item database", "Processes", "arrow.right.to.line", "sfltool dumpbtm 2>/dev/null | head -160 || true"),
        recipe("process-foreground", "Frontmost application", "Processes", "macwindow", "osascript -e 'tell application \"System Events\" to get name of first application process whose frontmost is true'"),
        recipe("process-open-files", "Open files summary", "Processes", "doc.on.doc", "lsof -n -P -u \"$USER\" 2>/dev/null | head -120"),
        recipe("process-threads", "Thread and task counts", "Processes", "list.number", "ps -M -p $(pgrep -n Finder) 2>/dev/null | head -40 || true"),
        recipe("process-zombies", "Zombie process scan", "Processes", "exclamationmark.triangle", "ps -axo stat,pid,comm | awk '$1 ~ /Z/ {print}' | head -80"),

        recipe("disk-volumes", "Mounted volumes", "Disk", "externaldrive", "df -h"),
        recipe("disk-home-folders", "Home folder sizes", "Disk", "house", "du -sh \"$HOME\"/* 2>/dev/null | sort -hr | head -20"),
        recipe("disk-cache-size", "User cache size", "Disk", "sparkles", "du -sh \"$HOME/Library/Caches\" 2>/dev/null || true"),
        recipe("disk-log-size", "User log size", "Disk", "doc.text", "du -sh \"$HOME/Library/Logs\" 2>/dev/null || true"),
        recipe("disk-downloads-size", "Downloads size", "Disk", "arrow.down.circle", "du -sh \"$HOME/Downloads\" 2>/dev/null || true"),
        recipe("disk-trash-size", "Trash size", "Disk", "trash", "du -sh \"$HOME/.Trash\" 2>/dev/null || true"),
        recipe("disk-derived-data", "Xcode DerivedData size", "Disk", "hammer", "du -sh \"$HOME/Library/Developer/Xcode/DerivedData\" 2>/dev/null || true"),
        recipe("disk-docker-size", "Docker data size", "Disk", "shippingbox", "du -sh \"$HOME/Library/Containers/com.docker.docker\" 2>/dev/null || true"),
        recipe("disk-apfs-volumes", "APFS volume map", "Disk", "internaldrive", "diskutil apfs list"),
        recipe("disk-snapshot-list", "APFS snapshot list", "Disk", "camera", "diskutil apfs listSnapshots / 2>/dev/null || true"),

        recipe("network-interfaces", "Network interfaces", "Network", "network", "ifconfig"),
        recipe("network-routes", "Routing table", "Network", "arrow.triangle.branch", "netstat -rn"),
        recipe("network-dns", "DNS resolver state", "Network", "server.rack", "scutil --dns"),
        recipe("network-proxy", "Proxy configuration", "Network", "shield.lefthalf.filled", "scutil --proxy"),
        recipe("network-wifi-status", "Wi-Fi status", "Network", "wifi", "networksetup -getairportpower en0 2>/dev/null || true"),
        recipe("network-wifi-details", "Wi-Fi connection details", "Network", "wifi.router", "system_profiler SPAirPortDataType -detailLevel mini"),
        recipe("network-services", "Configured network services", "Network", "list.bullet.rectangle", "networksetup -listallnetworkservices"),
        recipe("network-sockets", "Active network sockets", "Network", "arrow.left.arrow.right", "netstat -anv | head -120"),
        recipe("network-listening", "Listening ports", "Network", "dot.radiowaves.left.and.right", "lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | head -120"),
        recipe("network-hosts", "Hosts file entries", "Network", "list.bullet", "grep -v '^#' /etc/hosts | sed '/^[[:space:]]*$/d'"),

        recipe("security-sip", "System Integrity Protection", "Security", "lock.shield", "csrutil status"),
        recipe("security-gatekeeper", "Gatekeeper status", "Security", "checkmark.shield", "spctl --status"),
        recipe("security-filevault", "FileVault status", "Security", "lock.doc", "fdesetup status"),
        recipe("security-firewall", "Application firewall status", "Security", "flame", "/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate"),
        recipe("security-secure-boot", "Secure boot policy", "Security", "checkmark.seal", "bputil -d 2>/dev/null | head -80 || true"),
        recipe("security-tcc-database", "Privacy database locations", "Security", "person.badge.shield.checkmark", "ls -l \"$HOME/Library/Application Support/com.apple.TCC/TCC.db\" /Library/Application\\ Support/com.apple.TCC/TCC.db 2>/dev/null || true"),
        recipe("security-quarantine-count", "Quarantined file count", "Security", "shield.slash", "find \"$HOME/Downloads\" -type f -xattrname com.apple.quarantine 2>/dev/null | wc -l"),
        recipe("security-ssh", "Remote login state", "Security", "terminal.fill", "launchctl print-disabled system 2>/dev/null | grep -i ssh || true"),
        recipe("security-screen-lock", "Screen lock settings", "Security", "lock", "defaults read com.apple.screensaver askForPassword 2>/dev/null; defaults read com.apple.screensaver askForPasswordDelay 2>/dev/null"),
        recipe("security-auto-login", "Automatic login state", "Security", "person.crop.circle.badge.checkmark", "defaults read /Library/Preferences/com.apple.loginwindow autoLoginUser 2>/dev/null || echo 'automatic login is not configured'"),

        recipe("developer-xcode", "Xcode installation", "Developer", "hammer.fill", "xcode-select -p; xcodebuild -version 2>/dev/null || true"),
        recipe("developer-swift", "Swift toolchain", "Developer", "swift", "swift --version"),
        recipe("developer-git", "Git version", "Developer", "arrow.triangle.branch", "git --version"),
        recipe("developer-brew", "Homebrew version", "Developer", "shippingbox.fill", "brew --version 2>/dev/null || echo 'Homebrew is not installed'"),
        recipe("developer-node", "Node.js version", "Developer", "curlybraces.square", "node --version 2>/dev/null || echo 'Node.js is not installed'"),
        recipe("developer-npm", "npm version", "Developer", "shippingbox", "npm --version 2>/dev/null || echo 'npm is not installed'"),
        recipe("developer-python", "Python version", "Developer", "chevron.left.forwardslash.chevron.right", "python3 --version 2>&1"),
        recipe("developer-cargo", "Rust toolchain", "Developer", "gearshape", "cargo --version 2>/dev/null || echo 'Cargo is not installed'"),
        recipe("developer-ruby", "Ruby version", "Developer", "r.square", "ruby --version 2>/dev/null || echo 'Ruby is not installed'"),
        recipe("developer-sdks", "Installed SDKs", "Developer", "square.stack.3d.up", "xcodebuild -showsdks 2>/dev/null || true"),

        recipe("logs-errors-hour", "Errors in the last hour", "Logs", "exclamationmark.triangle", "log show --last 1h --style compact --predicate 'messageType ==  Fault OR messageType ==  Error' 2>/dev/null | tail -100"),
        recipe("logs-crashes-day", "Crashes in the last day", "Logs", "bolt.horizontal.circle", "find \"$HOME/Library/Logs/DiagnosticReports\" -type f -mtime -1 -print 2>/dev/null | sort | tail -100"),
        recipe("logs-install", "Installer log tail", "Logs", "square.and.arrow.down", "tail -100 /var/log/install.log 2>/dev/null || true"),
        recipe("logs-kernel", "Kernel log tail", "Logs", "cpu", "log show --last 1h --style compact --predicate 'process == \"kernel\"' 2>/dev/null | tail -100"),
        recipe("logs-loginwindow", "Login window events", "Logs", "rectangle.inset.filled.and.person.filled", "log show --last 1h --style compact --predicate 'process == \"loginwindow\"' 2>/dev/null | tail -100"),
        recipe("logs-security", "Security events", "Logs", "lock.shield", "log show --last 1h --style compact --predicate 'subsystem CONTAINS[c] \"security\"' 2>/dev/null | tail -100"),
        recipe("logs-brew", "Homebrew log folders", "Logs", "shippingbox", "du -sh \"$HOME/Library/Logs/Homebrew\" 2>/dev/null; find \"$HOME/Library/Logs/Homebrew\" -type f -mtime -7 -print 2>/dev/null | tail -80"),
        recipe("logs-app-size", "Application log sizes", "Logs", "chart.bar.doc.horizontal", "du -sh \"$HOME/Library/Logs\"/* 2>/dev/null | sort -hr | head -30"),
        recipe("logs-unified-stats", "Unified log statistics", "Logs", "chart.xyaxis.line", "log stats 2>/dev/null | head -100"),
        recipe("logs-last-reboot", "Last reboot records", "Logs", "arrow.clockwise", "last reboot | head -20"),

        recipe("files-hidden-home", "Hidden files in home", "Files", "eye.slash", "find \"$HOME\" -maxdepth 2 -name '.*' -not -path '*/.*/.*' -print 2>/dev/null | head -120"),
        recipe("files-large-downloads", "Large Downloads files", "Files", "doc.badge.ellipsis", "find \"$HOME/Downloads\" -type f -size +100M -print 2>/dev/null | head -100"),
        recipe("files-recent-home", "Recently modified home files", "Files", "clock.arrow.circlepath", "find \"$HOME\" -type f -mtime -1 -not -path '*/Library/*' -print 2>/dev/null | head -100"),
        recipe("files-symlinks", "Symbolic links in home", "Files", "link", "find \"$HOME\" -type l -print 2>/dev/null | head -120"),
        recipe("files-extended-attributes", "Extended attribute sample", "Files", "tag", "find \"$HOME/Downloads\" -type f -maxdepth 2 -exec xattr -l {} \\; 2>/dev/null | head -160"),
        recipe("files-quarantine-sample", "Quarantine attribute sample", "Files", "shield.lefthalf.filled", "find \"$HOME/Downloads\" -type f -xattrname com.apple.quarantine -print 2>/dev/null | head -100"),
        recipe("files-empty-directories", "Empty directories", "Files", "folder.badge.minus", "find \"$HOME/Downloads\" -type d -empty -print 2>/dev/null | head -100"),
        recipe("files-extension-counts", "File extension counts", "Files", "doc.text.magnifyingglass", "find \"$HOME/Downloads\" -type f -maxdepth 2 2>/dev/null | sed -n 's/.*\\.//p' | tr '[:upper:]' '[:lower:]' | sort | uniq -c | sort -nr | head -30"),
        recipe("files-duplicate-names", "Duplicate file names", "Files", "doc.on.doc", "find \"$HOME/Downloads\" -type f -maxdepth 3 -print 2>/dev/null | sed 's#.*/##' | sort | uniq -d | head -100"),
        recipe("files-permission-sample", "Permission sample", "Files", "lock.open", "find \"$HOME/Downloads\" -maxdepth 2 -type f -perm -111 -print 2>/dev/null | head -100"),

        recipe("power-settings", "Power management settings", "Power", "bolt", "pmset -g custom"),
        recipe("power-battery", "Battery status", "Power", "battery.100", "pmset -g batt"),
        recipe("power-battery-health", "Battery health details", "Power", "battery.75percent", "system_profiler SPPowerDataType -detailLevel mini"),
        recipe("power-sleep", "Sleep and wake settings", "Power", "bed.double", "pmset -g | grep -E ' sleep | displaysleep | disksleep | hibernatemode'"),
        recipe("power-scheduled", "Scheduled power events", "Power", "calendar.badge.clock", "pmset -g sched"),
        recipe("power-thermal", "Thermal state", "Power", "thermometer.medium", "pmset -g therm"),
        recipe("power-assertions", "Power assertions", "Power", "bolt.horizontal", "pmset -g assertions"),
        recipe("power-ups", "UPS status", "Power", "shippingbox", "system_profiler SPUPSDataType -detailLevel mini 2>/dev/null || true"),
        recipe("power-charger", "Charger information", "Power", "powerplug", "ioreg -rn AppleSmartBattery 2>/dev/null | grep -E 'ExternalConnected|IsCharging|Voltage|Amperage' | head -40"),
        recipe("power-low-mode", "Low power mode state", "Power", "leaf", "pmset -g | grep lowpowermode || true"),

        recipe("apps-count", "Installed application count", "Applications", "square.grid.2x2", "find /Applications \"$HOME/Applications\" -maxdepth 1 -type d -name '*.app' -print 2>/dev/null | wc -l"),
        recipe("apps-list", "Installed application list", "Applications", "list.bullet.rectangle", "find /Applications \"$HOME/Applications\" -maxdepth 1 -type d -name '*.app' -print 2>/dev/null | sort | head -160"),
        recipe("apps-signed", "Code-signature sample", "Applications", "checkmark.seal", "find /Applications -maxdepth 1 -type d -name '*.app' -print 2>/dev/null | head -15 | while read app; do codesign -dv --verbose=1 \"$app\" 2>&1 | grep -E 'Identifier=|TeamIdentifier='; done"),
        recipe("apps-bundle-identifiers", "Bundle identifier sample", "Applications", "barcode", "find /Applications -maxdepth 1 -type d -name '*.app' -print 2>/dev/null | head -40 | while read app; do defaults read \"$app/Contents/Info\" CFBundleIdentifier 2>/dev/null; done"),
        recipe("apps-recent", "Recently used applications", "Applications", "clock", "defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSRecentApplications 2>/dev/null | head -120"),
        recipe("apps-support-size", "Application Support size", "Applications", "folder", "du -sh \"$HOME/Library/Application Support\" 2>/dev/null || true"),
        recipe("apps-containers-size", "Application containers size", "Applications", "shippingbox", "du -sh \"$HOME/Library/Containers\" 2>/dev/null || true"),
        recipe("apps-launch-services", "Launch Services database", "Applications", "doc.badge.gearshape", "ls -lh \"$HOME/Library/Preferences/com.apple.LaunchServices\"* 2>/dev/null || true"),
        recipe("apps-quicklook-cache", "Quick Look cache size", "Applications", "eye", "du -sh \"$HOME/Library/Containers/com.apple.quicklook.ThumbnailsAgent\" 2>/dev/null || true"),
        recipe("apps-plugins", "Application plugins", "Applications", "puzzlepiece.extension", "find /Applications -path '*/Contents/PlugIns/*' -maxdepth 7 -print 2>/dev/null | head -120")
    ]

    private static func recipe(_ id: String, _ title: String, _ category: String, _ icon: String, _ command: String) -> workflowrecipe {
        workflowrecipe(id: id, title: title, category: category, icon: icon, command: command)
    }
}

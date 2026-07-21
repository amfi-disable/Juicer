# Juicer

<p align="center">
  <img src="juicer/sources/resources/assets.xcassets/appicon.appiconset/icon_128x128.png" width="128" height="128" alt="Juicer App Icon" />
</p>

<p align="center">
  <b>The ultimate all-in-one companion suite and developer utility for macOS!</b>
</p>

<p align="center">
  <a href="https://github.com/amfi-disable/Juicer/releases/tag/V1.0.1"><img src="https://img.shields.io/badge/Version-V1.0.1-blue" alt="Version" /></a>
  <a href="license"><img src="https://img.shields.io/badge/License-MIT-green" alt="License" /></a>
  <a href="https://developer.apple.com/macos"><img src="https://img.shields.io/badge/Platform-macOS%2014.0%2B-lightgrey?logo=apple" alt="Platform" /></a>
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-6.0-orange?logo=swift" alt="Swift" /></a>
</p>

Juicer is the ultimate open-source companion utility for **macOS developers and power users**. It is a 100% free, local-first suite that consolidates package managers, disk analyzers, app uninstallers, launchd editors, developer cache pruners, hosts file editors, and system tweaks into a high-performance native SwiftUI app.

---

## 🧭 Bundled Workspace Companion Suite (V1.0.1)

Juicer organizes its extensive feature set across **9 specialized companion workspaces**:

- 🚀 **Juicer Hub**: Central launcher and interactive launchpad canvas supporting Pan & Zoom gestures, edge-to-edge full screen modes, and launch bypass options.
- 📦 **Juicer Store**: Modern Homebrew Cask (GUI) & Formula (CLI) package manager with background metadata resolution, tap manager, service controller, and Brewfile sync.
- ⚡ **System & Hardware**: Real-time CPU/GPU gauges, memory pressure, battery health, power schedules, and thermal/fan sensors.
- 🌐 **Network & Ports**: Wi-Fi survey tools, speed tester, open port listener, DNS diagnostics, active VPN profiles, and firewall rules.
- 🛡️ **Security & Privacy**: TCC permission audit, privacy cabinet, FileVault inspector, quarantine stripper, anti-keylogger scanner, and app locker.
- 💾 **Disk & Storage**: Space Lens disk visualizer (Treemaps & Sunburst charts), developer cache cleaner, large file locator, duplicate finder, and storage snapshot manager.
- 🛠️ **Developer Suite**: SDK runtime switcher, trusted script plugins runner, local web server, code snippet expander, and environment profiles.
- ⚙️ **System Configs**: App uninstaller, orphan finder, launch daemon editor, hidden macOS tweaks, log rotator, and system optimizer.
- 🧰 **Utilities & Desktop**: Window tiler, clipboard manager, hot corners, color loupe, screen ruler, PDF toolbox, and desktop helper widgets.

---

## 🛠️ Key Capabilities

- **App Store Software Center 🛍️**: Easily manage Homebrew Casks (GUI) and Formulae (CLI) in a modern layout with category and pricing classification.
- **Space Lens (Disk Visualizer) 🔍**: Proportional squarified Treemaps and Canvas-drawn Sunburst charts with path copying and staged batch discard.
- **Deep App Uninstaller 🧹**: Drag and drop any `.app` to remove caches, app support, plists, containers, `ByHost Preferences`, and helper tools.
- **Orphan Directory Sweeper**: Locate and clean up orphaned files left behind by deleted applications.
- **Clipboard History Manager 📋**: Local-first text clipboard cache with pinned items, search filtering, formatting stripping, and hotkeys.
- **Status Menu Bar Monitor 📈**: Live system disk and physical memory utilization widget embedded directly in the macOS menu bar.
- **Trusted Script Plugins 🧩**: Execute custom shell scripts (`.sh`, `.command`, `.zsh`) securely with real-time log output.
- **DNS Profile Manager & Ad-Blocker 🛡️**: Switch local DNS profiles and apply StevenBlack's hosts filter to `/etc/hosts`.

---

## 🍺 Installation

### Method A: Install via Homebrew Tap (Recommended)
Install Juicer using our official Homebrew Tap:

```bash
# Tap the repository
brew tap amfi-disable/juicer

# Install Juicer Cask
brew install --cask juicer
```

### Method B: Direct Release Download 📦
1. Download `juicer.zip` from our latest [V1.0.1 GitHub Release](https://github.com/amfi-disable/Juicer/releases/tag/V1.0.1).
2. Extract the archive and move `Juicer.app` to `/Applications`.
3. If macOS Gatekeeper flags un-notarized ad-hoc binaries, run:
   ```bash
   xattr -cr /Applications/Juicer.app
   ```
4. Launch Juicer!

---

## 🏗️ Technical Architecture & Build Setup

- **Platform**: macOS 14.0+
- **Language**: Swift 6 / SwiftUI
- **Code Signing**: Deep ad-hoc signed (`CODE_SIGN_IDENTITY: "-"`) with Sparkle framework re-signing to eliminate dyld Team ID launch errors.
- **Project Generator**: Uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to build `juicer.xcodeproj` from `project.yml`.

To build locally:
```bash
brew install xcodegen
xcodegen generate
xcodebuild build -project juicer.xcodeproj -scheme juicer -configuration Debug
```

---

## 🤖 Automated Contributors & AI Reviewers

Juicer is continuously audited, linted, and reviewed by automated AI agents and workflow bots:

- 🐰 **[CodeRabbit](https://coderabbit.ai)** (`@coderabbitai`) - Context-aware AI PR reviewer & security auditor.
- 🛡️ **[CodeQL](https://codeql.github.com)** (`github-advanced-security`) - Continuous static application security testing (SAST).
- 📦 **[Dependabot](https://github.com/dependabot)** (`@dependabot[bot]`) - Automated dependency updates.
- 🧹 **[Stale Bot](https://github.com/actions/stale)** (`@actions/stale[bot]`) - Issue triage & PR maintenance.

---

## 📜 License & Code of Conduct

This project is licensed under the [MIT License](license).
All contributors are expected to adhere to the [Code of Conduct](code_of_conduct.md).

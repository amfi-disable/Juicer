# Juicer

<p align="center">
  <img src="juicer/sources/resources/assets.xcassets/appicon.appiconset/icon_128x128.png" width="128" height="128" alt="Juicer App Icon" />
</p>

<p align="center">
  <b>The ultimate all-in-one companion suite and developer utility for macOS!</b>
</p>

<p align="center">
  <a href="https://github.com/amfi-disable/Juicer/releases"><img src="https://img.shields.io/badge/Version-V1.0.1-blue" alt="Version" /></a>
  <a href="license"><img src="https://img.shields.io/badge/License-MIT-green" alt="License" /></a>
  <a href="https://developer.apple.com/macos"><img src="https://img.shields.io/badge/Platform-macOS%2014.0%2B-lightgrey?logo=apple" alt="Platform" /></a>
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-6.0-orange?logo=swift" alt="Swift" /></a>
</p>

Juicer is the ultimate all-in-one companion utility for **macOS developers and power users**. It is a 100% free, open-source, local-first suite that consolidates package managers, disk analyzers, app uninstallers, launchd editors, developer cache pruners, hosts file editors, and hidden system tweaks into a high-performance native SwiftUI desktop app.

---

## Key Features

- **App Store Software Center 🛍️**: Easily manage Homebrew Casks (GUI) and Formulae (CLI) in a modern App Store-like layout. Classifies packages by categories (*Productivity, Utilities, Development, Design, Entertainment, System*) and pricing models (*Free, Freemium, Paid*). Features high-speed, asynchronous list loading with background metadata resolution.
- **Space Lens (Disk Visualizer) 🔍**: Visualize your storage layout using proportional squarified Treemaps or Canvas-drawn hierarchical Sunburst charts. Includes split details panels, path copying, Quick Look integrations, and a staged Discard Pile for batch deletions.
- **App Uninstaller 🧹**: Drag and drop any `.app` to harvest and delete its hidden leftover files (caches, app support, plist, logs, containers, `ByHost Preferences`, and privileged helper tools).
- **Orphan Finder**: Scan `~/Library` and sweep away directories left behind by long-deleted apps.
- **Clipboard History Manager 📋**: Local-first text clipboard history cache supporting pinned items, search filtering, duplicate prevention, formatting stripping, and quick-action paste triggers.
- **BetterCmdTab (App Switcher) 🔄**: Swaps standard app switching behavior with a custom material overlay showing running tasks and live window previews/thumbnails.
- **Status Menu Bar Monitor 📈**: Live system disk and physical memory utilization widget embedded directly in the macOS menu bar.
- **Trusted Script Plugins 🧩**: Extensions interface that watches a user-defined folder, lists executable shell scripts (`.sh`, `.command`, `.zsh`), and runs custom developer automation workflows securely with real-time log output.
- **DNS Profile Manager & Ad-Blocker 🛡️**: Save and switch between local DNS profiles. Instantly download, parse, and apply public ad-blocking/malware hosts filters (like StevenBlack's hosts filter) to your `/etc/hosts` file.
- **Service Manager**: Load, unload, inspect, edit, and create user and system launch daemons/agents.
- **Workflow Center 🧪**: Queue safe system, disk, network, Homebrew, and recent-error diagnostics with pause/resume, retry, cancellation, previews, persistent history, custom scan paths, copy, export, and completion notifications.
- **100 Diagnostic Recipes**: Search and run one hundred local read-only checks across system state, processes, storage, networking, security, developer tools, logs, files, power, and applications. Favorite recipes and queue them as a reusable health workflow.
- **Developer Cache Pruner**: Reclaim space by pruning DerivedData, simulator support, package manager caches (npm, yarn, bun, cargo, homebrew), and unused Docker assets.
- **System Tweaks**: Configure hidden macOS settings for Dock, Finder, Keyboard speed, and screenshot options.
- **Quarantine Stripper**: Strip Gatekeeper quarantine tags from downloaded files and apps recursively.
- **File Association Override**: Batch-assign file types to open with preferred editors or IDEs.

---


## Installation

### Method A: Install via Homebrew Tap (Recommended) 🍺
You can install Juicer instantly using our custom Homebrew Tap:

```bash
# Add our custom tap
brew tap amfi-disable/juicer

# Install Juicer Cask
brew install --cask juicer
```

### Method B: Manual Download 📦
Because Juicer is compiled locally and not signed with an Apple Developer ID, macOS Gatekeeper may show a *"damaged and can't be opened"* warning when downloaded manually.

To open the app:
1. Download `Juicer.zip` from our latest [GitHub Release](https://github.com/amfi-disable/Juicer/releases/tag/V1.0.1).
2. Extract the archive and drag `Juicer.app` to your `/Applications` directory.
3. Open Terminal and strip the quarantine flag:
   ```bash
   xattr -cr /Applications/Juicer.app
   ```
4. Open and launch the app!

---

## Technical Architecture

- **Platform**: macOS 14.0+
- **Language**: Swift 6.0 / SwiftUI
- **Security**: Runs unsandboxed to perform low-level system directory scanning and service operations. Deletions are sent to the system Trash using the native `FileManager` API for safety.
- **Dependencies**: None (100% native).

---

## Development Setup

This project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to define the Xcode project file dynamically from `project.yml`.

1. Install XcodeGen:
   ```bash
   brew install xcodegen
   ```
2. Generate the Xcode project:
   ```bash
   xcodegen generate
   ```
3. Open `juicer.xcodeproj` and build!

---

## License & Code of Conduct

This project is licensed under the [MIT License](license).
All contributors are expected to adhere to the [Code of Conduct](code_of_conduct.md).

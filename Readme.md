# Juicer

<p align="center">
  <img src="juicer/sources/resources/assets.xcassets/AppIcon.appiconset/icon_128x128.png" width="128" height="128" alt="Juicer App Icon" />
</p>

<p align="center">
  <b>The ultimate all-in-one companion suite and developer utility for macOS!</b>
</p>

<p align="center">
  <a href="https://github.com/amfi-disable/Juicer/releases"><img src="https://img.shields.io/badge/Version-V1.0.0-blue" alt="Version" /></a>
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
- **DNS Profile Manager & Ad-Blocker 🛡️**: Save and switch between local DNS profiles. Instantly download, parse, and apply public ad-blocking/malware hosts filters (like StevenBlack's hosts filter) to your `/etc/hosts` file.
- **Service Manager**: Load, unload, inspect, edit, and create user and system launch daemons/agents.
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
1. Download `Juicer.zip` from our latest [GitHub Release](https://github.com/amfi-disable/Juicer/releases/tag/V1.0.0).
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

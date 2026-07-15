# juicer

<p align="center">
  <img src="juicer/sources/resources/assets.xcassets/AppIcon.appiconset/icon_128x128.png" width="128" height="128" alt="Juicer App Icon" />
</p>

<p align="center">
  <b>The ultimate all-in-one companion utility for macOS!</b>
</p>

<p align="center">
  <a href="https://github.com/amfi-disable/Juicer/releases"><img src="https://img.shields.io/badge/Version-1.0.0--alpha-blue" alt="Version" /></a>
  <a href="license"><img src="https://img.shields.io/badge/License-MIT-green" alt="License" /></a>
  <a href="https://developer.apple.com/macos"><img src="https://img.shields.io/badge/Platform-macOS%2014.0%2B-lightgrey?logo=apple" alt="Platform" /></a>
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-6.0-orange?logo=swift" alt="Swift" /></a>
</p>

Juicer is the ultimate all-in-one app for **macOS developers and power users**. It is a 100% free, open-source, local-first utility that consolidates app uninstallers, orphan file cleaners, launchd/service editors, developer cache pruners, hidden system tweakers, Gatekeeper tools, DNS editor, LaunchServices overrides, and a Software Center into a unified, high-performance native SwiftUI desktop system app.

## features

- **app uninstaller**: Drag and drop any `.app` to harvest and delete its hidden leftover files (caches, app support, plist, logs, containers).
- **orphan finder**: Scan `~/Library` and sweep away directories left behind by long-deleted apps.
- **service manager**: Load, unload, inspect, edit, and create user and system launch daemons/agents.
- **developer cache pruners**: Reclaim space by pruning DerivedData, simulator support, package manager caches (npm, yarn, bun, cargo, homebrew), and unused Docker assets.
- **system tweaks**: Configure hidden macOS settings for Dock, Finder, Keyboard speed, and screenshot options.
- **quarantine stripper**: Strip Gatekeeper quarantine tags from downloaded files and apps recursively.
- **local dns editor**: Edit `/etc/hosts` in a structured table, sync new local mappings, and flush DNS.
- **file association override**: Batch-assign file types to open with preferred editors or IDEs.

## technical architecture

- **platform**: macOS 14.0+
- **language**: Swift 6.0 / SwiftUI
- **security**: Runs unsandboxed to perform low-level system directory scanning and service operations. Deletions are sent to the system Trash using the native `FileManager` API for safety.
- **dependencies**: None (100% native).

## development setup

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

## License & Code of Conduct

This project is licensed under the [MIT License](license).
All contributors are expected to adhere to the [Code of Conduct](code_of_conduct.md).

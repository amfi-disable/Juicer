# juicer

[![GitHub Release](https://img.shields.io/github/v/release/amfi-disable/Juicer?style=flat-square&color=blue)](https://github.com/amfi-disable/Juicer/releases)
[![Build Status](https://img.shields.io/github/actions/workflow/status/amfi-disable/Juicer/build.yml?branch=main&style=flat-square)](https://github.com/amfi-disable/Juicer/actions)
[![License](https://img.shields.io/github/license/amfi-disable/Juicer?style=flat-square&color=green)](license)
[![Platform](https://img.shields.io/badge/platform-macOS%2014.0%2B-lightgray?style=flat-square)](https://developer.apple.com/macos)
[![Swift Version](https://img.shields.io/badge/swift-6.0-orange?style=flat-square&logo=swift)](https://swift.org)
[![SwiftLint Check](https://img.shields.io/github/actions/workflow/status/amfi-disable/Juicer/lint.yml?label=swiftlint&branch=main&style=flat-square)](https://github.com/amfi-disable/Juicer/actions)


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

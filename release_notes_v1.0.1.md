Welcome to **Juicer V1.0.1**! This stable release delivers native macOS App Icon integration, Homebrew Cask upgrade compatibility, customizable Menu Bar Extras, and comprehensive compiler compatibility fixes for macOS 14+.

## What's New in V1.0.1

### 1. Native App Icon & Homebrew Cask Integration 🎨
* **Embedded High-Res ICNS Asset**: Built and embedded a multi-resolution `AppIcon.icns` asset directly into `Juicer.app/Contents/Resources/AppIcon.icns`, guaranteeing proper icon rendering across macOS Finder, Dock, and Launchpad.
* **Homebrew Cask Auto-Updates**: Updated Cask SHA-256 checksums and download routes in `amfi-disable/homebrew-juicer` tap to support seamless `brew upgrade --cask juicer` execution.

### 2. Menu Bar Extras & Custom UI Components ⚡
* **Native Menu Bar Controls**: Refactored `MenuBarExtra` components to use the `isInserted` binding pattern for smooth, configurable status bar controls in Settings.
* **Juicer UI Utilities**: Added reusable SwiftUI components including `JuicerUsageBar` (horizontal progress tracking bar) and `JuicerEmptyState` (placeholder view for metrics loading).
* **System Metrics Helpers**: Added static helper utilities (`SystemMetricsSupport.time` and `SystemMetricsSupport.formatBytes`) to ensure clean metric displays.

### 3. Stability & Compiler Compatibility Fixes 🛠️
* **macOS 14+ Symbol Effects**: Replaced macOS 15.0+ `.symbolEffect(.rotate)` with macOS 14.0+ compatible `.symbolEffect(.pulse)` behaviors to maintain broad system backward compatibility.
* **AirDrop Quick-Send**: Resolved compiler type mismatches in the AirDrop Quick-Send view by explicitly casting ternary style options to uniform `Color` instances.
* **Bluetooth Device Manager**: Corrected closure parsing type errors when filtering battery percentage digits.
* **Text Case Converter**: Added explicit `return` statements across all switch statement cases to fix non-single expression switch warnings.
* **Code Snippets Library**: Resolved access scope warnings by matching property visibility keywords.

---

## Installation & Opening Instructions ⚠️

Because Juicer is locally compiled and not notarized, macOS Gatekeeper may show a *"damaged and can't be opened"* warning when downloading the zip file. 

To run Juicer:

1. **Via Homebrew Cask (Recommended)**:
   ```bash
   brew upgrade --cask juicer
   ```
2. **Via Direct Zip Download**:
   - Extract `juicer.zip` directly to `/Applications/Juicer.app`.
   - Clear Gatekeeper quarantine tag:
     ```bash
     xattr -cr /Applications/Juicer.app
     ```
   - Launch `Juicer.app` normally from Applications or Launchpad.

## Useful Links
* **Repository Homepage**: [Juicer on GitHub](https://github.com/amfi-disable/Juicer)
* **Issue Tracker**: [Report Bugs & Request Features](https://github.com/amfi-disable/Juicer/issues)

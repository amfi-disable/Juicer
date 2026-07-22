# changelog

## v1.0.3 — 2026-07-22

### added

- **Environment Variable Profiles & Secret Masker**: Manage `.env` profiles, auto-detect sensitive credentials (API keys, JWTs, DB URLs), mask secrets with custom visibility toggles, and export as `.env` or shell export statements.
- **Per-Process Real-Time Network Bandwidth Monitor**: Live download/upload throughput tracking per running process using native macOS `nettop` monitoring.
- **App Language Asset Stripper**: Scan and strip unused `.lproj` localization directories from installed applications to reclaim gigabytes of disk space.
- **Vision OCR Screen Area Grabber**: Interactive screen region selector using native Apple Vision framework for instant text recognition and auto-copy to clipboard.
- **Real-Time Unified Log Stream Viewer**: Stream and filter live macOS system `os_log` logs with subsystem, process, and severity predicates.
- **Natural Language to Shell Command Converter**: Translate plain English text prompts into validated zsh shell commands with 1-click execution and explanations.
- **Batch Image Compressor & Converter**: Lossless/lossy image conversion (PNG, JPEG, WebP) with custom quality controls.

### improved

- Swift 6 Sendable concurrency safety enforced across all state managers.
- Expanded Developer Cache Pruner targets to over 50+ developer tools (Xcode, Rust, Go, Java, Python, Node, Docker).
- Enhanced Global Command Palette (`Cmd+Shift+K`) search indexing for instant tool launching.

---

## v1.0.1 — 2026-07-20

### fixed

- Removed force unwraps from snapshot storage, undo backups, cache backups, system settings links, and display settings links.
- Made Accessibility API values type-safe so an unavailable or unexpected window value returns safely instead of terminating the app.
- Made disk forecast calculation resilient to an empty or changing history collection.
- Stopped invalid store homepage values from creating a crash path.

### release engineering

- Set the macOS build number to `101` for V1.0.1.
- Renamed tracked files and the app icon resource to lowercase names.
- Made Swift parsing and Release builds fail CI when validation fails.
- Added a reproducible release packaging workflow and checklist.

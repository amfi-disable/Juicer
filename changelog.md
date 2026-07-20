# changelog

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

# open source feature audit

## current juicer inventory

Juicer currently has six workspaces and 200 user-facing capabilities:

- Store: software center, Homebrew explorer, cask/formula updates, services, taps, and Brewfile sync.
- System: dashboard, live status, CPU/memory/GPU/disk I/O/network monitors, battery health, startup/login items, process killer, logs, KEXTs, power, thermal, fans, memory purge, swap, VPN profiles, network locations, Bluetooth, AirDrop, FileVault, firewall, network exposure, USB guard, screen recording, clipboard access, location services, and microphone/camera indicators.
- Disk: app uninstaller, orphan finder, developer caches, large/old files, hidden files, disk explorer/visualizer, deletion history, duplicate files, empty folders, download organizer, archive utility, disk images, file-type conversion, symbolic links, disk verification, storage snapshots, and secure delete.
- Configs: service manager, system tweaks/optimizer, quarantine stripper, DNS editor, file associations, app lipo, SDK switcher, permissions, extended attributes, metadata, privacy scanner, password audit, quarantined files, sandbox inspector, anti-keylogger scanner, and secure notes.
- Utilities: clipboard/snippet tools, menu-bar and desktop controls, hot corners, keyboard/text tools, QR/color/screen tools, battery saver, printer/PDF/Markdown/code tools, local web/network tools, VPN/DNS/hosts/blocklist tools, app/FileVault locks, Kana/emoji/Unicode tools, screenshot annotation, window tiling, display/night-shift/keyboard/trackpad tools, shortcut runner, system/software inventory, update/log/service tools, disk prediction, backups, network limiting, disk images, sound mixer, plus the 100 additional Settings/Finder/clipboard shortcuts in the catalog.

## benchmark repositories

| capability | repository / clone link | useful patterns | license caution |
| --- | --- | --- | --- |
| app uninstall and leftovers | https://github.com/alienator88/Pearcleaner.git | helper daemon, deep leftover search, undo, drag/drop, translation pruning, trash sentinel, export | Commons Clause/source-available; do not copy code into Juicer without a license review |
| system monitoring and sensors | https://github.com/exelban/stats.git | modular readers, popup detail views, widgets, per-module settings, sensor backends | MIT; ideas and compatible implementation patterns are reusable |
| window switching | https://github.com/lwouis/alt-tab-macos.git | window-level state, screen/Space tracking, thumbnail capture, permission gates, event routing, search | verify the repository license before copying code; use independent implementations |
| clipboard history | https://github.com/p0deje/Maccy.git | rich pasteboard types, concealed/transient filtering, pins, persistence, paste/remove-formatting actions, search, tests | MIT; reuse concepts, not wholesale files |
| menu-bar scripting | https://github.com/swiftbar/SwiftBar.git | plugin folder, directory observer, scheduled/streaming plugins, plugin errors/debug output, launch-at-login | MIT |
| menu-bar layout | https://github.com/jordanbaird/Ice.git | Carbon hotkey registry, global/local event monitors, permission UI, navigation state, menu-bar sections | GPL-3.0; do not copy code into a differently licensed product |
| window snapping | https://github.com/rxhanson/Rectangle.git | screen detection, visible-frame correction, halves/quarters/thirds/sixths, drag snap, cooperative resizing, tests | MIT; port behavior with an independent implementation |

## gaps found in juicer

### high priority

1. Clipboard Manager is text-only, session-only, capped at 25 items, and has no pins, ignore rules, rich pasteboard types, persistence, or paste-without-formatting.
2. BetterCmdTab shows application icons rather than individual windows and does not capture window thumbnails or distinguish Spaces/screens.
3. Window Tiler only offers left/right halves on the main display; it lacks quarters, thirds, sixths, maximize, restore, next-display, drag snapping, and display-aware visible-frame calculations.
4. App Uninstaller has good leftover inspection but no dedicated privileged helper lifecycle, trash sentinel, translation-pruning workflow, or exportable removal manifest.
5. System monitoring is primarily in-app; it lacks modular menu-bar widgets, configurable module order, historical charts, sensor readers, and widget-style detail popovers.
6. Utilities do not have a plugin folder, directory observer, plugin scheduling, stream output, or per-plugin error/debug surface.
7. Disk Visualizer has strong treemap/sunburst foundations but should add saved scans, color-by-extension/date/parent, filters, export, and richer Quick Look workflows.

## implementation decisions

- Adopt MIT-compatible ideas from Maccy, Stats, SwiftBar, and Rectangle through independent Juicer code.
- Do not copy Pearcleaner or Ice source because their license terms are not compatible with an unreviewed direct import.
- Keep security boundaries explicit: destructive file work stays behind confirmation/Trash, and privileged work should use a separately reviewed helper target.
- Prefer modular adapters so Stats-like sensors and SwiftBar-like plugins do not increase the core app’s startup cost.

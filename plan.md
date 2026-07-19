# Feature Implementation Plan for Juicer

This document lists 100 additional feature ideas for the Juicer macOS utility app. Each feature should be implemented as a new module (view, model, etc.) and integrated into the sidebar navigation.

## System & Performance
1. [x] CPU & Memory Monitor – Real‑time CPU, RAM, and swap usage graphs with per‑process breakdown.
2. [x] GPU Utilization Monitor – Show GPU utilization, temperature, and memory usage (Metal/Intel/AMD).
3. [x] Disk I/O Monitor – Real‑time read/write throughput per drive and per process.
4. [x] Network Traffic Monitor – Live upload/download speeds, per‑app breakdown, and connection details.
5. [x] Battery Health Dashboard – Cycle count, capacity, temperature, and charging‑rate history.
6. [x] Startup Item Manager – Enable/disable launch agents, launch daemons, login items, and background services.
7. [x] Login Item Delay Configurator – Add custom delays to login items to stagger startup.
8. [x] Process Killer / Force‑Quit Assistant – Search & kill misbehaving processes with safety confirmations.
9. [x] System Log Viewer – Unified viewer for `/var/log/system.log`, `console.log`, and user logs with filtering & search.
10. [x] Kernel Extension (KEXT) Manager – List, enable/disable, and view details of loaded kernel extensions (Intel Macs).
11. [x] Launch Daemon/Agent Editor – GUI plist editor with validation and syntax highlighting.
12. [x] Timer‑Based Power Schedule – Schedule sleep, wake, shutdown, or reboot at specific times/dates.
13. [x] Thermal Throttling Monitor – Show when CPU/GPU is throttling due to temperature and suggest fixes.
14. [x] Fan Speed Controller (where hardware allows) – Manual fan curve presets.
15. [x] RAM Cleaner / Memory Purge – Safe purge of inactive memory to free RAM (`purge` command wrapper).
16. [x] Swap Manager – View swapfile size/viewer and toggle swap on/off (requires admin).
17. [x] VPN Profile Manager – Import, export, enable/disable, and configure built‑in macOS VPN configurations.
18. [x] Network Location Manager – Create, switch, and delete network locations (Wi‑Fi, Ethernet, VPN, proxies).
19. [x] Bluetooth Device Manager – Pair/unpair, view battery levels, and auto‑connect preferred devices.
20. AirDrop Quick‑Send – Drag‑and‑drop files onto a menu‑bar item to instantly AirDrop to nearby devices.

## Storage & Filesystem
21. Duplicate File Finder – Scan for duplicate files by hash, size, name, or content with preview & safe‑delete.
22. Large File Finder – Locate files larger than a user‑defined threshold across selected folders.
23. Empty Folder Cleaner – Locate and delete empty directories recursively.
24. Temporary Files Cleaner – Clean `/tmp`, `~/Library/Caches`, `/Library/Caches`, and app‑specific temp folders.
25. Download Folder Organizer – Auto‑sort downloaded files into subfolders by type/date with rule‑based engine.
26. Archive Extractor/Creator – Zip, tar, gzip, bzip2, xz, 7z extraction & creation with drag‑and‑drop.
27. Disk Image Manager – Create, mount, verify, convert, and encrypt `.dmg`, `.iso`, `.sparsebundle`.
28. File Permissions Repair – Repair permissions on home folder, Applications, Library, or custom paths.
29. Extended Attributes Viewer/Editor – View/edit `com.apple.*`, `com.dropbox.*`, etc., attributes.
30. Hidden File Visibility Toggle – Quick toggle to show/hide hidden files in Finder via a menu‑bar toggle.
31. File Type Converter – Batch convert images, audio, video, documents via built‑in `sips`, `afconvert`, `ffmpeg` (bundled static binary).
32. Metadata Editor – Edit EXIF, IPTC, XMP, ID3, PDF, and Office document metadata in batch.
33. Symbolic Link Manager – Create, list, validate, and delete symlinks & hard links with a UI.
34. Disk Verification & Repair – Run `fsck_hfs`, `fsck_apfs`, `diskutil verify/repair` with progress UI.
35. Storage Snapshot Manager – Create APFS snapshots, list, compare, and rollback (requires admin).

## Privacy & Security
36. FileVault Status & Recovery Key Manager – Show encryption status, and allow backing up or changing the recovery key.
37. Firewall Configuration GUI – Easy toggle for macOS Application Firewall with per‑app allow/deny lists.
38. Privacy Scanner – Scan for microphone, camera, screen‑recording, accessibility, and full‑disk access permissions granted to apps.
39. Password Audit – Scan keychain for weak, reused, or expired passwords and suggest updates.
40. Secure Delete (Secure Erase) – Overwrite file deletion with multiple passes (DoD 5220.22‑M, Gutmann).
41. Quarantined‑file Scanner – Find all files with `com.apple.quarantine` attribute and let user strip or review them.
42. Application Sandbox Inspector – Show which App Sandbox entitlements each installed app has requested/used.
43. Network Exposure Monitor – Show which apps have open listening ports and remote connections.
44. USB Device Guard – Whitelist/blacklist USB devices and get notified when unknown USB is plugged in.
45. Screen Recording Detector – Alert when any app starts a screen‑recording session.
46. Clipboard Access Monitor – Notify when apps read the clipboard and allow blocking.
47. Location Services Auditor – List apps that have requested location access and when they last used it.
48. Microphone/Camera Indicator – Menubar icon that lights up when mic/cam is active (like the mic/camera indicator in Ventura).
49. Anti‑Keylogger Scanner – Scan for known keylogger signatures in `/Library/LaunchAgents`, `~/Library/LaunchAgents`, `/Library/LaunchDaemons`.
50. Secure Notes Vault – Encrypted local notes stored in the keychain with Touch ID / Face ID protection.

## Productivity & Utilities
51. Clipboard Manager – Keep a history of copied text, images, files (with preview) and quick‑paste shortcuts.
52. Snippet Expander – Text expansion with snippet variables (date, time, clipboard, clipboard history).
53. Menu‑Bar Customizer – Rearrange, hide, show, and add custom scripts or SwiftUI views to the menu bar.
54. Desktop Icons Toggle – Show/Hide desktop icons with a single click (like HiddenMe).
55. Hot Corners Configurator – Edit Mission Control Hot Corners with additional actions (scripts, URLs, apps).
56. Keyboard Shortcut Manager – View, search, add, edit, and remove custom keyboard shortcuts for all apps.
57. Text Case Converter – Selected text → Upper, Lower, Title, Sentence, Camel, Snake, Kebab case via menu‑bar or service.
58. Character/Word Counter – Live count for selected text or clipboard content.
59. QR Code Generator/Scanner – Create QR codes from text/URL and scan using the Mac’s camera.
60. Color Picker – System‑wide color picker with history, HEX/RGB/HSB/CMYK values, and copy‑to‑clipboard.
61. Screen Ruler & Protractor – On‑screen measurement tool for pixels, inches, centimeters, and angles.
62. Pixel‑Perfect Screen Loupe – Zoom magnifier with color sampler and crosshair.
63. Battery‑Saver Mode – Automatically reduce visual effects, lower keyboard backlight, put disks to sleep when on battery.
64. Printer Queue Manager – View, pause, resume, cancel print jobs; view printer status and ink/toner levels.
65. PDF Toolbox – Merge, split, rotate, compress, encrypt/decrypt PDFs using built‑in `PDFKit` or `qpdf`.
66. Markdown Previewer – Live preview of Markdown files with syntax highlighting and export to HTML/PDF.
67. Code Snippets Library – Store reusable code blocks with language tagging, search, and one‑click insert.
68. Local Web Server – One‑click start/stop a simple static file server (`python -m http.server` or Swift‑NIO) for testing.
69. Port Scanner – Scan localhost or remote host for open TCP/UDP ports with service guesswork.
70. LAN Device Discovery – Bonjour/mDNS browser showing all services (_http, _ssh, _afpovertcp, _smb, _ipp, etc.).
71. Wi‑Fi Survey Tool – Show SSID, signal strength, channel, security, and recommend least‑crowded channel.
72. Network‑Profile Switcher – Switch between predefined network configurations (static IP, DNS, proxies, proxies‑exceptions).
73. VPN Auto‑Connect – Auto‑connect a preferred VPN on specific Wi‑Fi SSIDs or when launching certain apps.
74. Public IP & Geoloc Lookup – Show your current public IP, ISP, and approximate location.
75. Speed Test Tool – One‑click download/upload/ping test using `speedtest‑cli` or native URLSession to a known endpoint.
76. DNS Resolver Diagnostics – Test custom DNS servers (Cloudflare, Google, Quad9, etc.) for latency and DNSSEC validation.
77. Hosts File Editor – GUI editor for `/etc/hosts` with enable/disable, comment, and import/export lists.
78. Ad‑block / Malware‑block List Updater – Scheduled download and merge of popular hosts lists (StevenBlack, adaway, etc.).
79. App Locker – Password‑ or biometrics‑lock selected applications (requires accessibility permission).
80. File Vault Auto‑Lock – Automatically lock the screen after a period of inactivity when on battery.
81. Japanese/Kana Input Helper – Quick switch to Romaji → Kana/Kanji conversion popup.
82. Emoji Picker – Searchable emoji palette with history and frecency ordering.
83. Unicode Character Inspector – Show code point, UTF‑8/16/32 bytes, glyph, and category for any selected character.
84. Screen‑Shot Annotation Tool – Quick markup (arrows, boxes, text, blur) after a screenshot, with save / copy options.
85. Window‑Snapping/Tiling Manager – Drag windows to screen edges or use keyboard shortcuts to tile, quarter, full‑screen, center.
86. Display Profile Manager – Create, switch, and calibrate color profiles (ICC) for external monitors.
87. Night Shift/True Tone Scheduler – Schedule Night Shift, True Tone, and custom color temperature changes based on time/location.
88. Keyboard Backlight Timer – Automatically turn off keyboard backlight after a period of inactivity.
89. Trackpad Gesture Customizer – Add, remove, or modify multi‑finger gestures via private APIs (if allowed) or via BetterTouchTool‑style scripting.
90. Automator/Shortcut Runner – Run saved Automator workflows, Shortcuts, or Shell scripts from the menu bar with one click.
91. System Info Exporter – Export a comprehensive HTML/JSON report of hardware, software, network, and settings for support tickets.
92. License & Software Inventory – List all installed apps (App Store, brew, manual .pkg) with version, install date, and vendor.
93. Auto‑Update Checker – Poll for updates from brew, mas, npm, composer, cargo, pip, etc., and provide a bulk update button.
94. Log File Rotator – Automatically compress and delete old logs based on rules (e.g., `/var/log/*.log`).
95. System Service Status Dashboard – Wrapper around `launchctl list` showing service state (running/waiting/failed) with color coding.
96. Disk Space Predictor – Predict when disk will be full based on current usage trends and notify.
97. Automatic Backup Trigger – Start rsync‑based backup to local/network volume when specific folders change.
98. Network Speed Limiter (Bandwidth Control) – Limit upload/download speed per app or port via `pfctl` or `ipfw` wrapper.
99. Automatic Disk Image Mounter – Automatically mount `.dmg` or `.iso` files dropped into a folder and notify.
100. Sound Volume Mixer – Per‑app output volume adjustment UI (Core Audio audio session wrapper).

## Implementation Notes
- Each feature should follow the existing architecture: SwiftUI views, ObservableObject models/managers, and integration via `NavigationItem`.
- Add new entries to `NavigationItem.swift` (enum) with appropriate workspace, title, and icon.
- Create a corresponding view file under `Sources/juicer/sources/views/` (e.g., `cpumonitormodels.swift`, `cpumonitorview.swift`).
- Add a case in the `mainsidebarview.swift` detail switch statement to display the new view.
- Optionally add a `NotificationCenter` observer in `juicerapp.swift` for keyboard shortcuts or deep linking.
- Ensure all new files are added to the Xcode project via `project.yml` (or regenerate with `xcodegen`).

## Next Steps
1. Review this plan and assign priorities.
2. For each high‑priority feature, create a task in the task list.
3. Implement features one by one, verifying each build passes.
4. Use the provided subagents to continuously monitor for build errors or lint issues.

---
*Plan generated by Claude Code. Awaiting further instructions from the user.*

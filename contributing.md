# Contributing to Juicer

Thank you for your interest in contributing to Juicer! As an open-source utility, we welcome all developer improvements.

## Development Setup

To build and run the Juicer project locally:

1. **Prerequisites**: Make sure you have Xcode 15+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen) installed:
   ```bash
   brew install xcodegen
   ```
2. **Generate Xcode Project**: Generate the project file from our declarative specification (`project.yml`):
   ```bash
   xcodegen generate
   ```
3. **Open Xcode**: Open the generated project bundle:
   ```bash
   open juicer.xcodeproj
   ```
4. **Compile & Run**: Press `Cmd + R` inside Xcode to build and launch the application locally.

## Guidelines

- **File/Folder Naming**: All files and folders in the repository should be strictly named in **lowercase**.
- **Commits Guideline**: FollowConventional Commits standard prefixes (e.g. `feat: add ...`, `fix: resolve ...`, `style: format ...`).
- **Tests**: Verify your changes build cleanly and run unit tests (`Cmd + U` in Xcode) before opening a Pull Request.

Please make sure to read and follow our [Code of Conduct](code_of_conduct.md) before submitting contributions.

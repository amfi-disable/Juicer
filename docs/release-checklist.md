# v1.0.1 release checklist

## automated checks

Run these commands from the repository root:

```bash
xcodegen generate
swiftc -parse $(find juicer/sources -name '*.swift' -print)
xcodebuild build -project juicer.xcodeproj -scheme juicer -configuration Release -sdk macosx -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO CODE_SIGN_IDENTITY='' CODE_SIGNING_REQUIRED=NO
git diff --check
```

The GitHub workflows run the source parser and a strict Release build. Generated Xcode projects and build products remain local and ignored.

## release artifact

The tag must be `V1.0.1`. The release workflow generates `juicer.zip` containing `Juicer.app`, computes its SHA-256 checksum, and attaches it to the GitHub release.

Before publishing a public download, the maintainer should sign and notarize the app with the production Developer ID credentials, then verify the downloaded archive on a clean macOS 14 or newer system.

## post-publish checks

- Confirm the release asset is named `juicer.zip`.
- Confirm the Homebrew cask automation can download the asset and calculate its checksum.
- Confirm the Sparkle appcast contains the signed release entry before enabling Sparkle updates for the public artifact.
- Test first launch, Full Disk Access onboarding, notification permission, update checking, app uninstallation preview, and undo restore.

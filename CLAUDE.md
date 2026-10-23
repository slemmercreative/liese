# Liese: notes for Claude

Liese is a lightweight native macOS Lottie viewer (SwiftUI app plus Quick Look preview extension), built with XcodeGen and rendered with lottie-ios.

## Ground rules

- **Never edit `Liese.xcodeproj`.** It's generated and git-ignored. Change `project.yml` (targets, packages, sources) or `Config/Liese.xcconfig` (settings) instead.
- Code in `Shared/` compiles into **both** the app and the Quick Look extension. Keep it AppKit/Foundation/Lottie only: no SwiftUI app types and nothing that the sandbox would block.
- The Quick Look extension is sandboxed and can read only the previewed file.
- Decode Lottie and dotLottie files off the main thread (`LottieLoader.load` does this already). `DotLottieFile` synchronous APIs assert when called on the main thread.
- Swift language mode is 5 (`SWIFT_VERSION = 5.0`), and the deployment target is macOS 14. `@Observable`, `ContentUnavailableView`, and so on are fine to use.
- Use American English in code, comments, and UI copy.

## Shipping a change ("feature turn")

At the end of each feature or fix:

1. Add a line under `## Unreleased` in `CHANGELOG.md`.
2. Commit with a descriptive message.
3. Install the new build:
   - **On Paul's Mac** (local Claude Code / terminal): run `make install`. It builds Release, installs to `/Applications/Liese.app`, and reloads Quick Look. If the install fails, fix the build before finishing.
   - **From a cloud session or Linux VM** (no Xcode): you can't build there. Commit, then tell Paul to run `make install`, or rely on the post-commit hook if `make hooks` is enabled on his Mac. The hook doesn't run on Linux.
4. To verify, `make doctor` shows the installed commit, and `make preview FILE=Samples/bounce.json` tests Quick Look.

When a change is user-visible and worth a version, bump it with `make version V=x.y.z` (semver).

## Map

- `App/LieseApp.swift`: `DocumentGroup(viewing:)` scene, About panel, Playback menu
- `App/PlayerController.swift`: playback state around `LottieAnimationView` (60 Hz ticker for the playhead)
- `App/PlayerScreen.swift`: canvas plus control bar; `LottieCanvas` is the `NSViewRepresentable`
- `Shared/LottieLoader.swift`: detects JSON vs dotLottie, decodes, and builds `AnimationInfo`
- `Shared/CanvasView.swift`: background (checkerboard, etc.) that hosts the Lottie view
- `QuickLook/PreviewViewController.swift`: view-based `QLPreviewingController`; non-Lottie JSON falls back to text
- `scripts/install.sh`: build, install, and register (lsregister and pluginkit), then reset Quick Look

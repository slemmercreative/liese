# Liese

A lightweight, native macOS viewer for Lottie animations, with a Quick Look extension so you can hit Space on a `.json` or `.lottie` file in Finder and see it play.

- Opens Lottie JSON (Bodymovin exports) and dotLottie (`.lottie`) files
- Play/pause, frame scrubbing and stepping, loop toggle, playback speed
- Checkerboard, dark, gray, or white canvas
- Info popover: size, fps, frame range, duration, layers, assets, markers, Bodymovin version
- Quick Look preview with a size/fps/duration overlay. JSON that isn't a Lottie animation is shown as formatted text.

Rendering uses Airbnb's [lottie-ios](https://github.com/airbnb/lottie-ios) (native Core Animation, no web view).

## Requirements

- macOS 14 Sonoma or later
- Xcode 16 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen). `make install` installs it with Homebrew if it's missing.

You don't need an Apple developer account. Builds are signed ad hoc ("Sign to Run Locally").

## Quick start

```sh
make install                     # build Release → /Applications/Liese.app, refresh Quick Look
make preview                     # Quick Look the bundled sample
open -a Liese Samples/bounce.json
```

The first build takes a minute or two because Swift Package Manager fetches and compiles Lottie.

## Everyday workflow

| Command | What it does |
| --- | --- |
| `make install` | Release build, install to `/Applications`, re-register the Quick Look extension, and relaunch Liese if it was running |
| `make hooks` | Turn on auto-install after every commit (runs in the background, with a notification when done) |
| `make unhooks` | Turn off auto-install |
| `make open` | Generate `Liese.xcodeproj` and open it in Xcode |
| `make run` | Debug build and launch from `build/` (nothing installed) |
| `make preview FILE=…` | Open a file with Quick Look (`qlmanage -p`) |
| `make doctor` | Show the installed version and commit, plus the Quick Look registration |
| `make version V=0.2.0` | Set the marketing version |
| `make uninstall` | Remove the app and unregister the extension |
| `make clean` | Delete `build/` and the generated project |

To ship a change: commit it and run `make install`. If you've run `make hooks`, committing is enough.

**Build numbers:** `CFBundleVersion` is the git commit count, and the short commit hash appears in **Liese → About Liese** (with `-dirty` when it was built with uncommitted changes). Use them to check which build is installed.

## Project layout

```
project.yml              XcodeGen spec (source of truth; Liese.xcodeproj is generated + ignored)
Config/Liese.xcconfig    versions, bundle ID, signing
Config/Local.xcconfig    optional, git-ignored per-machine overrides (see .example)
App/                     SwiftUI document-based viewer app
QuickLook/               Quick Look preview extension (sandboxed)
Shared/                  code compiled into both targets (loader, metadata, canvas)
Samples/                 test files
scripts/                 install / doctor / uninstall
.githooks/post-commit    optional auto-install hook (make hooks)
```

## Quick Look notes

- The extension registers for **all** `public.json` files. JSON that isn't a Lottie animation is shown as text, but this does replace the system's default JSON preview. If you'd rather keep the default, remove `public.json` from `QLSupportedContentTypes` in `QuickLook/Info.plist`. `.lottie` files will still preview.
- If previews don't appear after installing:
  1. Run `make doctor` to see whether the extension is registered and enabled (`+`).
  2. Check **System Settings → General → Login Items & Extensions → Quick Look** and make sure Liese is enabled.
  3. Launch `/Applications/Liese.app` once, then try again.
  4. Stale copies from Xcode's DerivedData can take priority. `make doctor` lists every copy LaunchServices knows about, and `make install` unregisters the copy in `build/`.
  5. If macOS won't load the ad hoc–signed extension, sign with your team: copy `Config/Local.xcconfig.example` to `Config/Local.xcconfig` and set `DEVELOPMENT_TEAM`.

## Known limits

- lottie-ios doesn't evaluate After Effects expressions, and a few effects aren't supported. See [lottie-ios supported features](https://airbnb.io/lottie/#/supported-features).
- For multi-animation dotLottie files, only the first animation plays.
- External image assets (not embedded) load in the app but not in Quick Look, because the sandbox only grants access to the previewed file.

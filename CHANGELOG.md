# Changelog

## Unreleased

- Launching Liese without a file now opens a blank canvas that says to drop a Lottie file or click to open one, instead of the Open panel. Dropping a file onto it opens the file. The canvas also returns when the last open file is closed.
- New app icon: three short curves stacked in black, red, and gold, with light and dark variants that follow the system appearance on macOS 26 (Icon Composer `App/AppIcon.icon`); dark mode is black with a charcoal top curve. `make install` now refreshes the Dock and Cmd+Tab icon when it changes. `scripts/make-icon.swift` regenerates both icon sets.

## 0.1.0 (2026-10-23)

- First version: a document-based viewer for Lottie JSON and dotLottie files, with play/pause, scrubbing, frame stepping, loop, speed, canvas backgrounds, and an info popover.
- Quick Look preview extension with a size/fps/duration overlay. Non-Lottie JSON is shown as formatted text.
- XcodeGen project, `make install` build-and-install workflow, optional post-commit auto-install hook, and GitHub Actions CI build.

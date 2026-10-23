#!/usr/bin/env bash
# Build Liese (Release), install it, and make Quick Look pick up the new extension.
#
#   scripts/install.sh                     # → /Applications/Liese.app
#   INSTALL_DIR=~/Applications scripts/install.sh
#   CONFIG=Debug scripts/install.sh        # install a debug build
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

APP_NAME="Liese"
APPEX_NAME="LieseQuickLook"
CONFIG="${CONFIG:-Release}"
INSTALL_DIR="${INSTALL_DIR:-/Applications}"
DERIVED="$ROOT/build/DerivedData"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

step() { printf '\033[1;35m▸\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

[[ "$(uname)" == "Darwin" ]] || die "install.sh has to run on macOS."
xcodebuild -version >/dev/null 2>&1 || die "Xcode is required (the full Xcode.app, not just the command line tools)."
if ! command -v xcodegen >/dev/null; then
  command -v brew >/dev/null || die "XcodeGen is required: brew install xcodegen (https://github.com/yonaskolb/XcodeGen)"
  step "Installing XcodeGen with Homebrew"
  brew install xcodegen
fi
[[ -w "$INSTALL_DIR" ]] || die "$INSTALL_DIR isn't writable. Try: INSTALL_DIR=~/Applications make install"

# One install at a time (the post-commit hook can fire in quick succession).
mkdir -p "$ROOT/build"
LOCK="$ROOT/build/.install.lock"
if ! mkdir "$LOCK" 2>/dev/null; then
  other="$(cat "$LOCK/pid" 2>/dev/null || true)"
  if [[ -n "$other" ]] && kill -0 "$other" 2>/dev/null; then
    die "Another install is already running (pid $other)."
  fi
  rm -rf "$LOCK" && mkdir "$LOCK"
fi
echo $$ > "$LOCK/pid"
trap 'rm -rf "$LOCK"' EXIT

BUILD_NUMBER="$(git rev-list --count HEAD 2>/dev/null || echo 1)"
GIT_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo dev)"
if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then GIT_SHA="${GIT_SHA}-dirty"; fi

step "Generating Xcode project"
xcodegen generate --quiet

step "Building $APP_NAME ($CONFIG · build $BUILD_NUMBER · $GIT_SHA)"
xcodebuild \
  -project "$APP_NAME.xcodeproj" \
  -scheme "$APP_NAME" \
  -configuration "$CONFIG" \
  -derivedDataPath "$DERIVED" \
  -destination 'generic/platform=macOS' \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  LIESE_GIT_SHA="$GIT_SHA" \
  -quiet build

BUILT_APP="$DERIVED/Build/Products/$CONFIG/$APP_NAME.app"
[[ -d "$BUILT_APP" ]] || die "Build product not found at $BUILT_APP"
DEST="$INSTALL_DIR/$APP_NAME.app"

was_running=0
if pgrep -xq "$APP_NAME"; then
  was_running=1
  step "Quitting running $APP_NAME"
  osascript -e "quit app \"$APP_NAME\"" >/dev/null 2>&1 || true
  for _ in {1..20}; do pgrep -xq "$APP_NAME" || break; sleep 0.25; done
  pkill -x "$APP_NAME" 2>/dev/null || true
fi

# Fingerprint the icon so we only reset the Dock's icon cache when it changed.
icon_sum() { cat "$1/Contents/Resources/Assets.car" "$1/Contents/Resources/AppIcon.icns" 2>/dev/null | shasum | cut -d' ' -f1; }
old_icon="$(icon_sum "$DEST")"

step "Installing to $DEST"
rm -rf "$DEST"
ditto "$BUILT_APP" "$DEST"

step "Registering app and Quick Look extension"
# Forget the copy in build/ so Quick Look only sees the installed one.
"$LSREGISTER" -u "$BUILT_APP" >/dev/null 2>&1 || true
pluginkit -r "$BUILT_APP/Contents/PlugIns/$APPEX_NAME.appex" >/dev/null 2>&1 || true
"$LSREGISTER" -f -R -trusted "$DEST"
pluginkit -a "$DEST/Contents/PlugIns/$APPEX_NAME.appex"
APPEX_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$DEST/Contents/PlugIns/$APPEX_NAME.appex/Contents/Info.plist")"
pluginkit -e use -i "$APPEX_ID" >/dev/null 2>&1 || true

step "Reloading Quick Look"
qlmanage -r >/dev/null 2>&1 || true
qlmanage -r cache >/dev/null 2>&1 || true
killall QuickLookUIService >/dev/null 2>&1 || true

if [[ "$(icon_sum "$DEST")" != "$old_icon" ]]; then
  # The Dock and Cmd+Tab switcher cache app icons; bump the bundle date and restart the Dock.
  step "Refreshing the Dock icon"
  touch "$DEST"
  killall Dock >/dev/null 2>&1 || true
fi

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$DEST/Contents/Info.plist")"
printf '\033[1;32m✓ Installed %s %s (%s · %s)\033[0m\n' "$APP_NAME" "$VERSION" "$BUILD_NUMBER" "$GIT_SHA"

if [[ "$was_running" == 1 || "${OPEN_AFTER:-0}" == 1 ]]; then
  open "$DEST"
fi

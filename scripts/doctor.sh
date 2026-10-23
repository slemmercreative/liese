#!/usr/bin/env bash
# Show what's installed and which copies of the Quick Look extension macOS knows about.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="${INSTALL_DIR:-/Applications}/Liese.app"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

plist() { /usr/libexec/PlistBuddy -c "Print :$2" "$1/Contents/Info.plist" 2>/dev/null || echo "?"; }

echo "Repo HEAD:      $(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo none) ($(git -C "$ROOT" rev-list --count HEAD 2>/dev/null || echo 0) commits)"
if [[ -d "$APP" ]]; then
  echo "Installed app:  $APP"
  echo "                version $(plist "$APP" CFBundleShortVersionString) · build $(plist "$APP" CFBundleVersion) · commit $(plist "$APP" LieseGitCommit)"
  echo "Signature:      $(codesign -dv "$APP" 2>&1 | grep -E '^(Authority|Signature)=' | head -1)"
else
  echo "Installed app:  none at $APP (run: make install)"
fi

echo
echo "Quick Look extensions registered for Liese (+ = enabled, - = disabled):"
pluginkit -m -A -D -v -p com.apple.quicklook.preview 2>/dev/null | grep -i liese || echo "  none"

echo
echo "Liese copies known to LaunchServices (stale ones can hijack Quick Look):"
"$LSREGISTER" -dump 2>/dev/null | grep -Eo 'path: +[^ ]*/Liese\.app' | sed -E 's/path: +/  /' | sort -u || true

echo
echo "Try a preview:  make preview FILE=Samples/bounce.json"

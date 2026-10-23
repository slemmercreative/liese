#!/usr/bin/env bash
# Remove the installed app and unregister its Quick Look extension.
set -uo pipefail
APP="${INSTALL_DIR:-/Applications}/Liese.app"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

pkill -x Liese 2>/dev/null || true
if [[ -d "$APP" ]]; then
  pluginkit -r "$APP/Contents/PlugIns/LieseQuickLook.appex" >/dev/null 2>&1 || true
  "$LSREGISTER" -u "$APP" >/dev/null 2>&1 || true
  rm -rf "$APP"
  echo "Removed $APP"
else
  echo "Nothing installed at $APP"
fi
qlmanage -r >/dev/null 2>&1 || true
killall QuickLookUIService >/dev/null 2>&1 || true

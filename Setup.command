#!/usr/bin/env bash
# Liese one-click setup. Double-click this file in Finder (or run it in Terminal).
#
# Installs what's missing (Xcode command line setup, Homebrew, XcodeGen), removes
# any older Liese install, then builds and installs the current version to
# /Applications with its Quick Look extension.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

step() { printf '\n\033[1;35m▸\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m✓\033[0m %s\n' "$*"; }
fail() {
  printf '\n\033[1;31m✗ %s\033[0m\n' "$*" >&2
  read -r -p "Press Return to close this window." _ || true
  exit 1
}
trap 'fail "Setup stopped because a step failed (see above)."' ERR

printf '\033[1mLiese setup\033[0m\n'
[[ "$(uname)" == "Darwin" ]] || fail "Liese runs on macOS only."
major="$(sw_vers -productVersion | cut -d. -f1)"
(( major >= 14 )) || fail "Liese needs macOS 14 Sonoma or later (this Mac has $(sw_vers -productVersion))."

# 1. Xcode. It can't be installed from a script, so point the user at the App Store.
step "Checking for Xcode"
if ! xcodebuild -version >/dev/null 2>&1; then
  xcode_app="$(mdfind "kMDItemCFBundleIdentifier == 'com.apple.dt.Xcode'" 2>/dev/null | head -1 || true)"
  if [[ -n "$xcode_app" ]]; then
    step "Selecting $xcode_app (asks for your password)"
    sudo xcode-select -s "$xcode_app/Contents/Developer"
  else
    open "macappstores://apps.apple.com/app/xcode/id497799835" || true
    fail "Xcode is required. Install it from the App Store (just opened), launch it once, then double-click Setup.command again."
  fi
fi
if ! xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1; then
  step "Finishing Xcode first-launch setup and accepting its license (asks for your password)"
  sudo xcodebuild -license accept
  sudo xcodebuild -runFirstLaunch
fi
ok "$(xcodebuild -version | head -1)"

# 2. Homebrew and XcodeGen.
step "Checking for XcodeGen"
for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  [[ -x "$brew_path" ]] && eval "$("$brew_path" shellenv)" && break
done
if ! command -v xcodegen >/dev/null; then
  if ! command -v brew >/dev/null; then
    step "Installing Homebrew"
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew; do
      [[ -x "$brew_path" ]] && eval "$("$brew_path" shellenv)" && break
    done
  fi
  step "Installing XcodeGen"
  brew install xcodegen
fi
ok "XcodeGen $(xcodegen --version 2>/dev/null | awk '{print $NF}')"

# 3. Remove any existing Liese so the new build replaces it cleanly.
new_version="$(sed -nE 's/^MARKETING_VERSION = (.*)/\1/p' Config/Liese.xcconfig)"
for dir in /Applications "$HOME/Applications"; do
  app="$dir/Liese.app"
  [[ -d "$app" ]] || continue
  old_version="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist" 2>/dev/null || echo unknown)"
  step "Removing installed Liese $old_version from $dir (installing $new_version)"
  INSTALL_DIR="$dir" bash scripts/uninstall.sh
done

# 4. Build and install.
step "Building and installing Liese $new_version (the first build takes a few minutes)"
INSTALL_DIR=/Applications bash scripts/install.sh

trap - ERR
printf '\n\033[1;32m✓ Liese %s is installed in /Applications.\033[0m\n' "$new_version"
echo "Open a .json or .lottie file with Liese, or select one in Finder and press Space to preview it."
open -a /Applications/Liese.app || true
read -r -p "Press Return to close this window." _ || true

#!/usr/bin/env bash
# Install the TZExpand Hammerspoon Spoon.
#
# Usage (one-liner):
#   curl -fsSL https://raw.githubusercontent.com/FernieTheDev/homebrew-tzexpand/main/scripts/install-spoon.sh | bash
#
# Or, from a checkout:
#   ./scripts/install-spoon.sh

set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/FernieTheDev/tzexpand/main"
SPOON_DIR="$HOME/.hammerspoon/Spoons/TZExpand.spoon"
INIT_LUA="$HOME/.hammerspoon/init.lua"

say() { printf "\033[1;36m▸\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m!\033[0m %s\n" "$*"; }
err() { printf "\033[1;31m✗\033[0m %s\n" "$*" >&2; }

# 1. Hammerspoon
if [ ! -d "/Applications/Hammerspoon.app" ]; then
  if command -v brew >/dev/null 2>&1; then
    say "Installing Hammerspoon via Homebrew…"
    brew install --cask hammerspoon
  else
    err "Hammerspoon is not installed and Homebrew is unavailable."
    err "Install Hammerspoon from https://www.hammerspoon.org and re-run."
    exit 1
  fi
fi

# 2. Spoon files
mkdir -p "$SPOON_DIR"
if [ -f "$(dirname "$0")/../Spoons/TZExpand.spoon/init.lua" ]; then
  say "Copying spoon from local checkout…"
  cp "$(dirname "$0")/../Spoons/TZExpand.spoon/init.lua" "$SPOON_DIR/init.lua"
else
  say "Downloading spoon…"
  curl -fsSL "$REPO_RAW/Spoons/TZExpand.spoon/init.lua" -o "$SPOON_DIR/init.lua"
fi

# 3. init.lua bootstrap (only if not already present)
mkdir -p "$HOME/.hammerspoon"
if [ ! -f "$INIT_LUA" ] || ! grep -q "spoon.TZExpand" "$INIT_LUA"; then
  say "Adding bootstrap snippet to $INIT_LUA"
  cat >> "$INIT_LUA" <<'LUA'

-- TZExpand: hotkey-driven timezone expander
-- Configure via the 🕘 menu bar item (settings persist across reloads).
hs.loadSpoon("TZExpand")
spoon.TZExpand:start({
    home = "America/Los_Angeles",              -- your home tz (first run only; menubar overrides)
    extras = { "America/New_York", "Europe/London" }, -- defaults
    hotkey = { mods = {"ctrl", "alt"}, key = "t" },
})
LUA
else
  say "init.lua already references TZExpand — leaving it alone."
fi

# 4. Reload if running
if pgrep -x Hammerspoon >/dev/null 2>&1; then
  if command -v hs >/dev/null 2>&1; then
    say "Reloading Hammerspoon config…"
    hs -c "hs.reload()" >/dev/null 2>&1 || true
  else
    warn "Open Hammerspoon's menu bar icon → Reload Config to pick up the spoon."
  fi
else
  say "Launching Hammerspoon…"
  open -a Hammerspoon
fi

cat <<'DONE'

✓ TZExpand spoon installed.

Next steps:
  1. Grant Hammerspoon Accessibility access (one time):
     System Settings → Privacy & Security → Accessibility → enable Hammerspoon
  2. Edit ~/.hammerspoon/init.lua to set your home tz, extras, and hotkey.
  3. Press ⌃⌥T after typing a time like "9pm" or "9 pm PT" in any input.

DONE

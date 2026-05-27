#!/usr/bin/env bash
# Uninstall the TZExpand Hammerspoon Spoon.
#
# Usage (one-liner):
#   curl -fsSL https://raw.githubusercontent.com/FernieTheDev/tzexpand/main/scripts/uninstall-spoon.sh | bash
#
# Or, from a checkout:
#   ./scripts/uninstall-spoon.sh
#
# Flags (for non-interactive use):
#   --spoon-only       remove just the spoon + bootstrap snippet
#   --with-hammerspoon also uninstall Hammerspoon itself
#   --yes              don't ask for confirmation

set -euo pipefail

SPOON_DIR="$HOME/.hammerspoon/Spoons/TZExpand.spoon"
INIT_LUA="$HOME/.hammerspoon/init.lua"
SETTINGS_PLIST="$HOME/Library/Preferences/org.hammerspoon.Hammerspoon.plist"

say()  { printf "\033[1;36m▸\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m!\033[0m %s\n" "$*"; }
ok()   { printf "\033[1;32m✓\033[0m %s\n" "$*"; }

MODE=""
ASSUME_YES=0
for arg in "$@"; do
  case "$arg" in
    --spoon-only)       MODE="spoon" ;;
    --with-hammerspoon) MODE="all"   ;;
    --yes|-y)           ASSUME_YES=1 ;;
    -h|--help)
      sed -n '2,12p' "$0"; exit 0 ;;
    *) warn "unknown arg: $arg" ;;
  esac
done

if [ -z "$MODE" ]; then
  # Determine where to read user input from.
  # When piped from curl, bash reads the script from stdin, so we can't
  # redirect stdin — instead read each prompt directly from /dev/tty.
  if [ -e /dev/tty ]; then
    TTY_IN=/dev/tty
  elif [ -t 0 ]; then
    TTY_IN=/dev/stdin
  else
    echo "TZExpand uninstaller: no TTY available; pass --spoon-only or --with-hammerspoon." >&2
    exit 2
  fi

  echo ""
  echo "What would you like to uninstall?"
  echo "  1) TZExpand only  (remove spoon + bootstrap snippet; keep Hammerspoon)"
  echo "  2) TZExpand AND Hammerspoon"
  echo "  3) Cancel"
  echo ""
  while true; do
    printf "Choose [1/2/3]: "
    read -r choice < "$TTY_IN"
    case "$choice" in
      1) MODE="spoon"; break ;;
      2) MODE="all";   break ;;
      3|q|Q|"") echo "Cancelled."; exit 0 ;;
      *) echo "Please enter 1, 2, or 3." ;;
    esac
  done
fi

# ----- Remove the spoon ------------------------------------------------------
if [ -d "$SPOON_DIR" ]; then
  say "Removing $SPOON_DIR"
  rm -rf "$SPOON_DIR"
  ok "Spoon removed."
else
  warn "Spoon directory not found at $SPOON_DIR (already gone?)."
fi

# ----- Strip bootstrap snippet from init.lua ---------------------------------
if [ -f "$INIT_LUA" ] && grep -q "spoon.TZExpand" "$INIT_LUA"; then
  say "Removing TZExpand bootstrap from $INIT_LUA"
  cp "$INIT_LUA" "$INIT_LUA.bak.$(date +%Y%m%d%H%M%S)"
  # Drop:
  #   - the "-- TZExpand:" comment line
  #   - the hs.loadSpoon("TZExpand") line
  #   - any line referencing spoon.TZExpand (incl. multi-line :start({...}) blocks)
  python3 - "$INIT_LUA" <<'PY'
import sys, pathlib, re
p = pathlib.Path(sys.argv[1])
lines = p.read_text().splitlines(keepends=True)
out = []
i = 0
n = len(lines)
while i < n:
    line = lines[i]
    stripped = line.strip()

    # Skip our header comment if it precedes a loadSpoon("TZExpand").
    if stripped.startswith('--') and 'TZExpand' in stripped:
        j = i + 1
        while j < n and lines[j].strip() == '':
            j += 1
        if j < n and re.search(r'hs\.loadSpoon\(\s*"TZExpand"\s*\)', lines[j]):
            i = j  # fall through to the loadSpoon handler below
            continue
        out.append(line); i += 1; continue

    # hs.loadSpoon("TZExpand") (+ optional comment tail) — drop the line.
    if re.search(r'hs\.loadSpoon\(\s*"TZExpand"\s*\)', line):
        i += 1
        continue

    # spoon.TZExpand:method(...) — single line OR multi-line until matching ).
    if re.search(r'spoon\.TZExpand\b', line):
        # Count net open/close parens from the start of this line.
        opens = line.count('(') - line.count(')')
        i += 1
        while opens > 0 and i < n:
            opens += lines[i].count('(') - lines[i].count(')')
            i += 1
        continue

    out.append(line); i += 1

new = ''.join(out)
new = re.sub(r'\n{3,}', '\n\n', new)
p.write_text(new)
PY
  ok "init.lua cleaned (backup saved alongside)."
else
  warn "No TZExpand bootstrap found in $INIT_LUA."
fi

# ----- Clear persisted spoon settings ---------------------------------------
if [ -f "$SETTINGS_PLIST" ]; then
  if /usr/bin/defaults read org.hammerspoon.Hammerspoon TZExpandSpoonSettings >/dev/null 2>&1; then
    say "Clearing persisted TZExpand settings"
    /usr/bin/defaults delete org.hammerspoon.Hammerspoon TZExpandSpoonSettings >/dev/null 2>&1 || true
    ok "Settings cleared."
  fi
fi

# ----- Reload Hammerspoon so the menubar icon goes away ---------------------
if pgrep -x Hammerspoon >/dev/null 2>&1; then
  if command -v hs >/dev/null 2>&1; then
    say "Reloading Hammerspoon to drop the menu-bar icon"
    hs -c "hs.reload()" >/dev/null 2>&1 || true
  else
    warn "Open Hammerspoon → Reload Config to drop the menu-bar icon."
  fi
fi

# ----- Optionally remove Hammerspoon itself ---------------------------------
if [ "$MODE" = "all" ]; then
  say "Removing Hammerspoon…"

  # Quit Hammerspoon first so brew can uninstall cleanly.
  if pgrep -x Hammerspoon >/dev/null 2>&1; then
    say "Quitting Hammerspoon"
    osascript -e 'tell application "Hammerspoon" to quit' 2>/dev/null || true
    sleep 1
  fi

  if command -v brew >/dev/null 2>&1 && brew list --cask hammerspoon >/dev/null 2>&1; then
    say "Running: brew uninstall --cask hammerspoon"
    brew uninstall --cask hammerspoon
  elif [ -d "/Applications/Hammerspoon.app" ]; then
    say "Removing /Applications/Hammerspoon.app"
    rm -rf "/Applications/Hammerspoon.app"
    ok "Hammerspoon.app removed."
  else
    warn "Hammerspoon.app not found in /Applications (already uninstalled?)."
  fi

  # Remove user-level Hammerspoon data.
  for path in \
    "$HOME/.hammerspoon" \
    "$HOME/Library/Preferences/org.hammerspoon.Hammerspoon.plist" \
    "$HOME/Library/Application Support/org.hammerspoon.Hammerspoon" \
    "$HOME/Library/Saved Application State/org.hammerspoon.Hammerspoon.savedState" \
    "$HOME/Library/Logs/Hammerspoon"
  do
    if [ -e "$path" ]; then
      say "Removing $path"
      rm -rf "$path"
    fi
  done
  ok "Hammerspoon removed."
  echo ""
  echo "Note: macOS may still list Hammerspoon under System Settings → Privacy & Security → Accessibility."
  echo "You can remove that entry manually."
fi

echo ""
ok "TZExpand uninstalled."

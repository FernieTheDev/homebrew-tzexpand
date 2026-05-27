# TZExpand

A tiny macOS menu bar app that turns a time you just typed (anywhere — Slack,
email, Notes, browser) into a multi-timezone expansion with a single hotkey.

> Type `3pm`, hit **⌃⌥T** → `3pm PT (6pm ET / 11pm GMT)`

You can also include a timezone in the input and it'll be used as the source:

> `6pm ET` → `6pm ET (3pm PT / 11pm GMT)`

## Install

There are two ways to install — pick the one you prefer:

### Option A: Hammerspoon spoon (recommended — works reliably in Slack/Electron/web apps)

```sh
curl -fsSL https://raw.githubusercontent.com/FernieTheDev/homebrew-tzexpand/main/scripts/install-spoon.sh | bash
```

This installs [Hammerspoon](https://www.hammerspoon.org) (via brew if available), drops the spoon into `~/.hammerspoon/Spoons/TZExpand.spoon/`, and adds a bootstrap snippet to `~/.hammerspoon/init.lua`. Grant Accessibility to **Hammerspoon** once and you're done — no per-update re-grant.

Edit `~/.hammerspoon/init.lua` to change your home timezone, extras, or hotkey, then `hs.reload()` from the Hammerspoon console.

### Option B: Standalone menu-bar app (Homebrew cask)

```sh
brew install ferniethedev/tzexpand/tzexpand
```

> Heads up: the GitHub repo for this tap is `homebrew-tzexpand` (Homebrew
> requires the `homebrew-` prefix); the install URL drops the prefix.

After the first launch, macOS will prompt for Accessibility access. Open
**System Settings → Privacy & Security → Accessibility** and enable
**TZExpand**. Note: because the app is ad-hoc signed, you'll need to re-grant
Accessibility on every `brew upgrade`. If that bothers you, use Option A.

## Usage

1. Type a time in any text field. Examples that work:
   `3pm`, `3:00pm`, `3 pm`, `3:00 pm`, `3pm PT`, `3:00pm PT`, `3 pm PT`,
   `15:00`, `15:30 CET`, `noon`, `midnight`.
2. Either select the time, or just press the hotkey right after typing it —
   the app will grab the previous word.
3. Press **⌃⌥T**. The text is replaced with the full expansion.

If a timezone is present in your input it overrides the home TZ as the
source, and your home TZ is automatically added to the parenthetical list.

## Configure

Click the menu bar icon → **Settings…** to choose:

- Your **home timezone**.
- **Additional timezones** displayed in the parentheses, in order.
- The **separator** between extra zones (default ` / `).

The hotkey defaults to **⌃⌥T**. A graphical recorder is on the roadmap;
override it for now via UserDefaults:

```sh
defaults write dev.fernie.tzexpand TZExpand.hotkey.keyCode -int 17     # 'T'
defaults write dev.fernie.tzexpand TZExpand.hotkey.modifiers -int 6144 # ⌃⌥
```

## Headless / CLI

The same binary works as a CLI when given arguments:

```sh
swift run TZExpand "3pm PT"
# → 3pm PT (6pm ET / 11pm GMT)
```

## Build from source

```sh
git clone https://github.com/ferniethedev/homebrew-tzexpand.git
cd homebrew-tzexpand
VERSION=0.1.0 bash scripts/build-release.sh
open build/dist/TZExpand.app
```

## How it works

- Hotkey → `Carbon RegisterEventHotKey` (truly global).
- Selection capture → Accessibility API, with a `⌥⇧←` fallback to grab the
  previous word when nothing is selected.
- Parsing → tolerant pure-Swift parser (see `Sources/TZExpandCore/TimeParser.swift`).
- Formatting → `DateFormatter` + `TimeZone` with a curated abbreviation map.
- Paste back → snapshot pasteboard, write expansion, synthesize ⌘V, restore
  pasteboard ~0.4s later.

## Caveat: ad-hoc signing

Until a paid Apple Developer ID is wired up, releases are ad-hoc signed.
The Homebrew cask strips the quarantine xattr post-install. If you download
the zip manually, do the same:

```sh
xattr -dr com.apple.quarantine /Applications/TZExpand.app
```

## License

MIT — see `LICENSE`.

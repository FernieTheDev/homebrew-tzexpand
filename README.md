# TZExpand

A hotkey-driven multi-timezone expander for macOS, distributed as a
[Hammerspoon](https://www.hammerspoon.org) [Spoon](https://www.hammerspoon.org/Spoons/).

Type a time anywhere — Slack, email, Notes, your browser — hit the hotkey, and
the time is replaced with the full multi-timezone expansion.

> `3pm` → ⌃⌥T → `3pm PT (6pm ET / 11pm UK)`
>
> `9 pm ET` → ⌃⌥T → `9pm ET (6pm PT / 2am UK)`

It understands all of these input shapes:

- `9`, `9:00`, `21:30`
- `9pm`, `9 pm`, `9:30 pm`
- `9pm PT`, `9 pm ET`, `3pm BST` (typed tz becomes the source; your home tz is added to the parenthetical)

UK / Europe / US zones respect DST automatically.

## Install

One-liner:

```sh
curl -fsSL https://raw.githubusercontent.com/FernieTheDev/tzexpand/main/scripts/install-spoon.sh | bash
```

The installer will:

1. Install [Hammerspoon](https://www.hammerspoon.org) via Homebrew if it isn't already (`brew install --cask hammerspoon`)
2. Drop the spoon into `~/.hammerspoon/Spoons/TZExpand.spoon/`
3. Append a small bootstrap snippet to `~/.hammerspoon/init.lua`
4. Reload (or launch) Hammerspoon

**One-time manual step:** grant Hammerspoon Accessibility access at
**System Settings → Privacy & Security → Accessibility** (enable
*Hammerspoon*). Because the permission lives on Hammerspoon, future spoon
updates don't require re-granting.

## Use

1. Type a time in any text field. Examples that work:
   `3pm`, `3:00pm`, `3 pm`, `3:00 pm`, `3pm PT`, `3 pm ET`, `15:00`, `15:30 CET`, `21:30`.
2. Either select the time, or just press the hotkey right after typing it —
   the spoon grows the selection backward by up to 4 words until it finds a parseable time.
3. Press **⌃⌥T**. The text is replaced with the full expansion.

## Configure

Click the **🕘** in your menu bar:

- **Change home timezone…** — searchable list of common IANA zones
- **Add / remove / reorder extras** — each extra has a submenu
- **Test expand…** — try an input string in a dialog
- **Edit `~/.hammerspoon/init.lua`** / **Reload Hammerspoon** — for power users

Settings persist via `hs.settings`, so menu-bar edits survive Hammerspoon reloads
and override the defaults in `init.lua`.

To change the hotkey, edit the call in `~/.hammerspoon/init.lua`:

```lua
spoon.TZExpand:start({
    home = "America/Los_Angeles",
    extras = { "America/New_York", "Europe/London" },
    hotkey = { mods = {"ctrl", "alt"}, key = "t" }, -- ← here
})
```

…then run `hs.reload()` from the Hammerspoon console.

## Manual install (no installer script)

```sh
brew install --cask hammerspoon
mkdir -p ~/.hammerspoon/Spoons
curl -fsSL https://raw.githubusercontent.com/FernieTheDev/tzexpand/main/Spoons/TZExpand.spoon/init.lua \
    -o ~/.hammerspoon/Spoons/TZExpand.spoon/init.lua
```

Then add to `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("TZExpand")
spoon.TZExpand:start({
    home = "America/Los_Angeles",
    extras = { "America/New_York", "Europe/London" },
    hotkey = { mods = {"ctrl", "alt"}, key = "t" },
})
```

## Why Hammerspoon?

Earlier versions shipped as a standalone Swift menu-bar app (Homebrew cask).
That worked but had two ongoing pains:

- **TCC revoked Accessibility on every `brew upgrade`** (the binary is ad-hoc
  signed, so the CDHash changes on each release and macOS forgets the grant).
- **Paste was flaky in Electron apps** (Slack, Discord) and inside web inputs
  where AX selection writes are not honored.

Hammerspoon solves both:

- One Accessibility grant on Hammerspoon itself, forever.
- `hs.eventtap` + `hs.pasteboard` work reliably in Electron and the web.
- Iteration is `hs.reload()` (≈1 s) instead of rebuild → sign → upgrade → re-grant.

## License

MIT — see [LICENSE](LICENSE).

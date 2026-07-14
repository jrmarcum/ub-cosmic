# COSMIC desktop layouts

ub-cosmic ships a **switchable COSMIC desktop-layout system**, defaulting to a
**Windows-like** arrangement so a Windows migrant feels at home, with a one-command
switch to other arrangements.

> These run on the **COSMIC session** (the primary desktop). GNOME remains available as
> a backup session but does not carry layouts.

## Honest scope

COSMIC is a young, from-scratch desktop. It **cannot** reproduce Zorin's 12 layouts
faithfully — there's **no start menu with categories**, you **can't ungroup taskbar
windows into labeled buttons**, applets aren't individually configurable, and there's no
upstream layout switcher. What COSMIC *can* do is rearrange its **panel + dock + applets +
theme**, which yields a handful of genuinely distinct arrangements. So expect
**~4–6 solid approximations**, not 12 pixel-perfect clones.

## How it works

A "layout" is a **snapshot of the relevant cosmic-config directories** — the tool copies
those in and out of `~/.config/cosmic`. It never parses RON, so presets are built by
**capturing a hand-tuned live COSMIC session** rather than authored by hand.

```bash
ub-cosmic-layout list            # list layouts + the current one
ub-cosmic-layout set macos       # switch (log out/in to fully apply)
ub-cosmic-layout current
ub-cosmic-layout reset           # remove layout config; COSMIC regenerates defaults
```

## Building / tuning a layout (the required workflow)

Presets start empty — you populate them on a booted COSMIC session:

1. Arrange the COSMIC panel/dock/theme by hand (Settings → Desktop → Panel & Dock).
2. Capture it:
   ```bash
   ub-cosmic-layout capture windows
   # writes ~/.config/ub-cosmic/cosmic-layouts/windows/
   ```
3. Copy that directory into the repo at
   `system_files/usr/share/ub-cosmic/cosmic-layouts/windows/` and commit. The next image
   build ships it — and if it's the `windows` (default) preset, `build.sh` bakes it into
   `/usr/share/cosmic` as the system-wide default.

## Intended layouts

| Preset | Arrangement | Zorin analogue |
| --- | --- | --- |
| `windows` *(default)* | single bottom bar; launcher left, window list center, tray right | Windows 11 / Windows |
| `macos` | top panel + centered auto-hiding bottom dock | macOS-like |
| `ubuntu` | left vertical dock + top panel | Ubuntu-like |
| `classic` | bottom panel, no dock | Windows Classic-ish |
| `compact` | one thin bottom bar | Compact panel |
| `touch` | large bottom dock, big targets | Touch |

## Status

- **Framework:** complete — switcher, `capture`, and default-bake wiring all work.
- **Preset content:** **none yet** — must be captured on a live COSMIC session (see above).
  Until then `ub-cosmic-layout set <name>` reports the layout has no content.
- **Default session:** to actually *land* users in COSMIC (and thus the Windows layout),
  COSMIC should be the default session — open item in [cmem/next-work.md](cmem/next-work.md).

## Files

- Switcher: `usr/bin/ub-cosmic-layout`
- Presets: `usr/share/ub-cosmic/cosmic-layouts/<name>/`
- Baked default: copied into `/usr/share/cosmic/` by `build.sh` when the `windows` preset
  has content.

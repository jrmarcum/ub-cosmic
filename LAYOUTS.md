# Desktop layouts (Zorin-style)

ub-cosmic ships **12 switchable desktop layouts** inspired by Zorin OS, defaulting to
**Windows 11-like** — so a Windows migrant lands on something familiar and can switch to any
of the others in one command.

> **Important:** these layouts run on the **GNOME session**, not COSMIC. Zorin's layouts are built
> on GNOME Shell + extensions (`dash-to-panel`, `ArcMenu`, `dash-to-dock`), which have no COSMIC
> equivalent. COSMIC remains installed and selectable at the login screen; it just doesn't host the
> layout system. (See [cmem/decisions.md](cmem/decisions.md).)

## Status: DRAFT presets — need a VM tuning pass ⚠️

The switcher, the extension install, and the Windows-11 default are **complete and functional**. The
per-layout preset *content* (exact panel sizes, element order, ArcMenu layout, etc.) is a **best-effort
first draft written without a live session** and must be tuned on a booted GNOME VM. The `capture`
workflow below makes that easy and repeatable. Until then, expect approximate — not pixel-perfect —
layouts, and treat this feature as beta.

## The 12 layouts

| Name (`ub-cosmic-layout set …`) | Approximates | Backbone |
| --- | --- | --- |
| `windows-11` *(default)* | Windows 11 — centered grouped taskbar + start menu | dash-to-panel + ArcMenu (Eleven) |
| `windows-classic` | Windows 7/10 — labeled, ungrouped taskbar buttons | dash-to-panel + ArcMenu (Windows) |
| `windows-list` | Windows with a window-list taskbar | dash-to-panel (ungrouped) |
| `windows` | Generic Windows-like | dash-to-panel + ArcMenu (Redmond) |
| `macos` | macOS — top menu bar + centered bottom dock | dash-to-dock |
| `ubuntu` | Ubuntu — left dock, always visible | dash-to-dock (left) |
| `gnome` | Stock GNOME Shell | (extensions off) |
| `cinnamon` | Linux Mint Cinnamon — bottom panel + menu | dash-to-panel + ArcMenu (Mint) |
| `elementary` | elementary OS — top bar + small centered dock | dash-to-dock |
| `chromeos` | ChromeOS — bottom shelf | dash-to-dock (fixed) |
| `compact` | Thin bottom panel | dash-to-panel (small) |
| `touch` | Large touch-friendly dock | dash-to-dock (big icons) |

## Using it

```bash
ub-cosmic-layout list            # show all layouts + the current one
ub-cosmic-layout set macos       # switch layout (log out/in to fully apply)
ub-cosmic-layout current         # show the active layout
ub-cosmic-layout reset           # back to stock GNOME
```

> **Wayland note:** GNOME can't hot-reload extensions on Wayland, so after `set` you must **log out
> and back in** (or reboot) for the new layout to fully take effect.

## Finishing / tuning a layout on a VM (the intended workflow)

1. Boot a ub-cosmic VM into the **GNOME** session.
2. `ub-cosmic-layout set windows-11` (or any layout), log out/in.
3. Hand-tune it with GNOME Tweaks + the Dash-to-Panel / ArcMenu / Dash-to-Dock settings until it
   looks right.
4. Capture it back into a preset:
   ```bash
   ub-cosmic-layout capture windows-11
   # writes ~/.config/ub-cosmic/layouts/windows-11.dconf
   ```
5. Copy that file into the repo at
   `system_files/usr/share/ub-cosmic/layouts/windows-11.dconf` and commit. The next image build
   ships your tuned version to everyone.

## Known caveats

- **ArcMenu isn't in Fedora's repos**, so `build.sh` fetches it from GitHub best-effort and never
  fails the build if that download breaks. If ArcMenu is missing, the Windows layouts fall back to
  dash-to-panel's built-in app grid instead of a start menu. Pin the URL to a GNOME-Shell-compatible
  release.
- **Default *session* vs default *layout*:** Windows-11 is the default *layout within GNOME*. For a
  user to actually *land* in it, GNOME must be the default *session* — that knob is still open (see
  [cmem/next-work.md](cmem/next-work.md)). Today GDM remembers each user's last session choice.
- **Files:** switcher `usr/bin/ub-cosmic-layout`; presets `usr/share/ub-cosmic/layouts/*.dconf`;
  system default `etc/dconf/db/local.d/00-ub-cosmic-windows-11` + profile `etc/dconf/profile/user`.

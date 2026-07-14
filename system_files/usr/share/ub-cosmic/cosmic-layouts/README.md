# COSMIC layout presets

Each subdirectory here is a **layout preset** — a snapshot of the cosmic-config
components (`com.system76.CosmicPanel*`, `CosmicComp*`, `CosmicTheme*`,
`CosmicBackground*`, `CosmicTk*`, `applets`) that define a desktop arrangement.

Presets are **captured from a live COSMIC session**, not hand-written — cosmic-config
RON is versioned and structural, so authoring it blind is unreliable. Build one with:

```bash
# on a booted ub-cosmic COSMIC session:
#   1. arrange the panel/dock/theme by hand
#   2. capture it:
ub-cosmic-layout capture windows
#   3. copy ~/.config/ub-cosmic/cosmic-layouts/windows/ into this directory and commit
```

## Intended layouts (COSMIC approximations of the Zorin set)

COSMIC can't reproduce all 12 Zorin layouts (no start menu, can't ungroup taskbar
windows, applets aren't configurable). These are the ones that are meaningfully
distinct on COSMIC:

| Preset  | Arrangement | Zorin analogue |
| ------- | ----------- | -------------- |
| `windows` *(default)* | single bottom bar: app-launcher left, window list center, tray/clock right | Windows 11 / Windows |
| `macos`   | top panel + centered auto-hiding bottom dock | macOS-like |
| `ubuntu`  | left vertical dock + top panel | Ubuntu-like |
| `classic` | bottom panel, no dock, traditional | Windows Classic-ish |
| `compact` | one thin bottom bar, small applets | Compact panel |
| `touch`   | large bottom dock, big targets | Touch |

Add more if you can make them distinct — the switcher works with any preset dir.
`build.sh` bakes the `windows` preset into `/usr/share/cosmic` as the system default
once it has captured content.

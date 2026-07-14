# Design Decisions — ub-cosmic

Load-bearing decisions that must not be silently reverted. All dated 2026-07-13 unless noted.

## Base image: `bazzite-gnome` (not plain `bazzite`)

Chosen so **GNOME is the reliable backup session** behind COSMIC. `bazzite-gnome` ships GNOME + GDM;
GDM lists every installed session, so COSMIC and GNOME both appear at login. Switching to plain
`bazzite` would give a KDE backup instead — change the `FROM` in `Containerfile` if that's ever
desired.

## COSMIC layered via the `cosmic-desktop` metapackage

COSMIC is installed in `build_files/build.sh` with `dnf5 install -y cosmic-desktop` (plus optional
apps: cosmic-store/terminal/edit/screenshot/wallpapers). COSMIC is in Fedora's repos since F41; the
metapackage pulls the whole DE. Alternative is the group `@cosmic-desktop-environment` — equivalent.

## Keep GDM; do NOT enable cosmic-greeter

We deliberately leave the base image's **GDM** as the display manager and do not
`systemctl enable cosmic-greeter`. This is what makes "COSMIC with a GNOME backup" work — one DM that
offers both sessions. Do not add a competing display manager.

## Default session is user-selected, not forced

We do **not** ship a forced-default-session hint. The mechanism (per-user AccountsService / `/etc/gdm`
templates) is fragile on atomic, so we leave it to GDM's per-user "remember last choice." The live
ISO's GRUB menu defaults to the COSMIC entry, but the installed system's session default is the
user's choice. `build.sh` only *verifies* `cosmic.desktop` exists.

## ISO method: titanoboa (live), with BIB as fallback

Owner chose the **titanoboa** live-ISO path (matches how upstream Bazzite builds ISOs) over
bootc-image-builder. BIB config is kept under `disk_config/` for local builds and as a documented
fallback, but the CI ISO is titanoboa. Titanoboa is experimental — noted in README caveats.

## Portable memory in `cmem/`

Ported from wasmtk 2026-07-13. All project memory lives in `cmem/` (git-tracked, travels with the
repo). `CLAUDE.md` is a **tracked** pointer stub (deliberately NOT gitignored, unlike wasmtk) so the
"memory lives in cmem/" rule is portable to any machine/USB. Do not write memory to machine-local
`~/.claude/...` locations.

## Placeholders resolved

`REPO_ORGANIZATION` and all image refs use `jrmarcum` (the GitHub owner). If the repo is ever forked
or the owner changes, update: `image-template.env`, `disk_config/iso.toml`, and the `ghcr.io/...`
refs in `README.md`.

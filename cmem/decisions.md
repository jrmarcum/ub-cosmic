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

## Automatic upstream updates — floating base tag, do NOT pin (owner decision 2026-07-13)

The owner explicitly wants ub-cosmic to **receive Universal Blue / Bazzite updates automatically**
(especially fixes). The model:

- **`Containerfile` base stays a FLOATING tag** (`bazzite-gnome:stable`) — never pin to `@sha256:…`.
  A pinned digest would freeze the base and require manual bumps, defeating auto-updates.
- **`build.yml` daily `cron` rebuild** re-pulls the newest base + newest Fedora COSMIC packages and
  republishes `ghcr.io/jrmarcum/ub-cosmic:latest` every day (publish/sign runs on `schedule` events).
- **Installed machines auto-update** from *our* image via Bazzite's inherited updater — they never
  pull `bazzite-gnome` directly, so upstream reaches them only after our daily rebuild republishes.
- **Renovate is configured NOT to pin/digest the Containerfile base** (`.github/renovate.json5` has a
  `matchManagers: ["dockerfile"]` rule disabling `pin`/`pinDigest`/`digest`). This is required —
  `config:best-practices` pulls in `docker:pinDigests`, which would otherwise pin + auto-merge the
  base digest and silently freeze updates. Renovate still SHA-pins GitHub Actions (kept).

**Do not "pin the base for reproducibility"** — that tradeoff was explicitly rejected here in favor of
always receiving upstream fixes. If reproducibility is ever needed, it must be re-decided with the
owner, not added silently.

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

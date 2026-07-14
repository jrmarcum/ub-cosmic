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

## greenboot auto-rollback ENABLED by default (owner decision 2026-07-13)

The owner wants the image to **self-heal** for non-technical users: a bad update that boots badly
should roll back automatically, not require manual GRUB/`bootc rollback`. So `build.sh` installs
`greenboot greenboot-default-health-checks` and enables the greenboot/redboot units.

- **Default required checks** come from `greenboot-default-health-checks` (failed systemd units,
  network/DNS, etc.). Plus a **custom required check** at
  `system_files/etc/greenboot/check/required.d/50-graphical-target.sh` that fails if
  `graphical.target` doesn't go active within ~120s (catches a broken-desktop / black-screen update).
- **Mechanism:** greenboot uses the GRUB `boot_counter`; after the default 3 failed boots it triggers
  `rpm-ostree rollback` to the previous deployment. A fully non-booting update (kernel panic) is
  covered by the counter even without health checks.
- **Rollback-loop guard:** the graphical check waits/retries up to ~120s so a slow-but-healthy boot
  never false-triggers. Keep new REQUIRED checks conservative for the same reason; put anything
  speculative in `wanted.d` (advisory, non-fatal).
- Custom check scripts must be **executable** — `build.sh` `chmod +x`es `required.d/*.sh` because git
  checkouts on Windows can drop the +x bit.

This is inherited-base behavior we deliberately turn ON; plain Bazzite ships rollback as *manual*
only. Applies to every ub-cosmic variant (incl. any future nvidia variant).

## Desktop layouts are COSMIC-native (owner decision 2026-07-13, revised same day)

Owner wants Zorin-style desktop layouts, defaulting to **Windows-like**, for non-technical Windows
migrants — **on the COSMIC session** (the primary desktop), NOT GNOME.

- **History:** a first version was built on GNOME (dash-to-panel/ArcMenu/dconf) because that's the only
  way to get all 12 Zorin layouts faithfully. Owner then clarified it must be COSMIC. The **GNOME
  layout machinery was removed** (extension installs, 12 dconf presets, dconf profile/db, dconf-based
  switcher) — see git history around this date if it's ever wanted back.
- **COSMIC reality (verified 2026-07-13):** COSMIC has no extension ecosystem, no start menu, can't
  ungroup taskbar windows, applets aren't configurable, no upstream layout switcher (request #746). So
  layouts are limited to rearranging the COSMIC **panel + dock + applets + theme** → **~4–6 distinct
  approximations, not 12**. Set expectations accordingly; do NOT promise faithful Zorin parity.
- **Design — file-tree switcher (no RON authoring):** a "layout" is a snapshot of the cosmic-config
  dirs (`com.system76.CosmicPanel*`, `CosmicComp*`, `CosmicTheme*`, `CosmicBackground*`, `CosmicTk*`,
  `applets`). `ub-cosmic-layout` (`usr/bin/`) copies these in/out of `~/.config/cosmic` — subcommands
  list/set/current/**capture**/reset. cosmic-config RON is versioned/structural and **cannot be
  authored blind**, so presets are CAPTURED from a hand-tuned live COSMIC session.
- **Presets:** live in `usr/share/ub-cosmic/cosmic-layouts/<name>/`; **content is empty until captured
  on a VM.** `build.sh` bakes the `windows` (default) preset into `/usr/share/cosmic` as the system
  default — but only once it has captured content (guarded no-op otherwise, so builds never ship an
  empty default).
- **OPEN — default session:** COSMIC should be the default session so users land in the Windows
  layout; GDM default-session wiring is still open (see [next-work.md](next-work.md)). Don't flip
  silently.
- **Legal/ethics:** our own presets with open tools; do NOT copy Zorin's proprietary assets/code.

## NVIDIA vs AMD/Intel: two images, one ISO, first-boot auto-rebase (owner decision 2026-07-13)

GPU drivers are baked into the image at build time, so a single image can't serve both GPU
families. Decisions:

- **Build TWO images** via a `build.yml` matrix: `ub-cosmic` (from `bazzite-gnome:stable`, AMD/Intel)
  and `ub-cosmic-nvidia` (from `bazzite-gnome-nvidia-open:stable`, NVIDIA **open** kernel modules —
  covers RTX 20-series / GTX 16-series+). Older GPUs would use `bazzite-gnome-nvidia` (proprietary).
- **Build ONE ISO**, from the AMD/Intel image (titanoboa live ISO). The user flashes one ISO
  regardless of GPU.
- **First-boot auto-rebase:** the AMD/Intel image ships `ub-cosmic-gpu-rebase.service` +
  `/usr/lib/ub-cosmic/gpu-rebase.sh`. On boot it runs `lspci`; if an NVIDIA GPU is present it
  `bootc switch`es to `ub-cosmic-nvidia` and reboots once. The NVIDIA image does NOT ship/enable the
  service (build.sh gates enablement on `IMAGE_VARIANT`).
- **Why first-boot and not install-time:** the owner picked titanoboa for the ISO, and titanoboa is a
  **live-only** ISO builder with **no Anaconda kickstart `%post`** (verified by reading its
  `build_iso.sh`). True install-time GPU detection would require the Anaconda `anaconda-iso` (BIB)
  path; that was explicitly declined in favor of keeping titanoboa + first-boot rebase.
- **Network caveat (inherent):** the rebase must pull the NVIDIA image, so it needs internet.
  Ethernet → applies on first boot; Wi-Fi → applies on the next reboot after the user first connects.
  The service retries each boot until done (stamp: `/var/lib/ub-cosmic/gpu-rebase.done`).

**Parametrization:** `Containerfile` takes `ARG BASE_IMAGE` + `ARG IMAGE_VARIANT`; the Justfile
threads them via `env_var_or_default` (local builds default to the AMD/Intel base); `build.yml`'s
matrix sets them per variant. The image ref inside `gpu-rebase.sh` is hard-coded to
`ghcr.io/jrmarcum/ub-cosmic-nvidia:latest` — update it if the owner/name changes.

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

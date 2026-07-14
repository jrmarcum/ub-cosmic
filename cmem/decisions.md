# Design Decisions — ub-cosmic

Load-bearing decisions that must not be silently reverted. All dated 2026-07-13 unless noted.

## Base image: `bazzite-gnome` (not plain `bazzite`)

Chosen so **GNOME is the reliable backup session** behind COSMIC. `bazzite-gnome` ships GNOME + GDM;
GDM lists every installed session, so COSMIC and GNOME both appear at login. Switching to plain
`bazzite` would give a KDE backup instead — change the `FROM` in `Containerfile` if that's ever
desired.

## COSMIC layered via an explicit session package list (NO metapackage)

COSMIC is installed in `build_files/build.sh` by an **explicit list** (cosmic-session, -comp, -panel,
-applets, -bg, -launcher, -settings(-daemon), -osd, -notifications, -app-library, -files, -randr,
-idle, -wallpapers, -initial-setup, xdg-desktop-portal-cosmic) plus optional apps
(cosmic-store/term/edit/screenshot/player). **There is NO `cosmic-desktop` metapackage** — an earlier
version assumed one and the build failed with "No match for argument: cosmic-desktop" (2026-07-13).
All package names were verified against the **Fedora 44** base (Bazzite's current Fedora) before use;
re-verify names on a major Fedora bump. COSMIC has been in Fedora since F41.

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

## BricsCAD runtime deps baked in; app is user-layered (owner decision 2026-07-13)

Owner wants BricsCAD to have the best chance of running. Facts + decisions:

- **BricsCAD V26 is Qt 6.8-based** (older versions were GTK — verified 2026-07-13). Fedora is an
  officially supported platform (glibc ≥ 2.35, x86-64), so the Bazzite base qualifies.
- **We bake the runtime libraries only, NOT the app** (proprietary + license-gated). `build.sh`
  installs Qt6 (`qt6-qtbase`/`-gui`/`qtsvg`/`qtwayland`), the **Qt xcb platform-plugin stack**
  (`xcb-util*`, `libxkbcommon*`, `libX11-xcb` — the "could not load platform plugin xcb" culprits),
  X11 libs, `mesa-libGLU`, fonts, `openssl-libs`/`libcurl`, and legacy `gtk2`/`libpng12` as a
  belt-and-suspenders for the RPM's older Requires. All package names verified in Fedora repos.
- **Install path (BRICSCAD.md):** user downloads the Fedora RPM and **layers it** with
  `rpm-ostree install BricsCAD*.rpm` (atomic/bootc — not a plain dnf into the running system).
- **GPU caveat (Bricsys):** 3D HW accel is NOT supported on Intel graphics or dual-GPU laptops →
  works on NVIDIA (`ub-cosmic-nvidia`) and AMD; Intel-only = software 3D. This dovetails with the
  NVIDIA auto-rebase.
- **Wayland:** Qt6 runs via `qt6-qtwayland` or XWayland (xcb libs); `QT_QPA_PLATFORM=xcb` is the
  fallback. If the deps list ever needs trimming for size, the xcb-util family + Qt6 base are the
  must-keeps; gtk2/libpng12 are the first to drop.

## Licensing & compliance posture (owner request 2026-07-13)

- **Repo license = Apache-2.0** ([LICENSE](../LICENSE)) — correct, matches upstream `image-template`
  (Apache-2.0) which the scaffolding derives from; also matches the `Apache-2.0` image label in the
  Justfile. Don't change to a copyleft license without checking the derived image-template files.
- **Apache §4 compliance:** added [NOTICE](../NOTICE) (attribution + a statement that the template
  files were modified). Upstream image-template/titanoboa ship **no NOTICE file** and no filled
  copyright holder, so nothing mandatory to carry over.
- **[THIRD_PARTY.md](../THIRD_PARTY.md)** documents: derived source (image-template), build tooling/
  actions (titanoboa, remove-unwanted-software, bootc-image-builder, cosign — all Apache-2.0/MIT),
  the Bazzite (Apache-2.0)/Fedora base whose **bundled packages carry their own licenses inside the
  image at `/usr/share/licenses/`**, COSMIC = **GPL-3.0**, and a **trademark/non-endorsement**
  disclaimer (Universal Blue, Bazzite, Fedora, COSMIC/System76, BricsCAD/Bricsys, NVIDIA, Windows,
  Zorin).
- **BricsCAD is NOT bundled/redistributed** — only its open-source runtime deps are installed; the
  name is used descriptively. Never commit BricsCAD binaries/assets to the repo or bake them into the
  image.
- **Verified facts (2026-07-13):** bazzite/titanoboa/image-template = Apache-2.0 (GitHub API);
  cosmic-comp = GNU GPL. Not legal advice — commercial distribution warrants a real legal review,
  especially trademarks and OS-image redistribution.
- **Logo/brand is RESERVED, dual-licensed (owner, 2026-07-13):** the project logo
  (`UB-COSMIC-Linux.png`) is **© Jon Marcum, all rights reserved + asserted trademark** — NOT under
  Apache-2.0. Repo is dual-licensed: Apache-2.0 code, reserved brand. Goal: **only the owner may sell
  merch with the logo; anyone else needs a written license.** NOTE: MIT/CC do the OPPOSITE (they grant
  reuse) — never "MIT the logo." Protection = reserve rights (no license) + trademark, not a permissive
  license. Reserved in NOTICE, THIRD_PARTY.md §7, README. For real merch sales, trademark registration
  + legal review is the stronger path (ties into the commercial gate below).
- **Distribution intent (owner, 2026-07-13):** **Public open-source distribution of this repo is
  fine and expressly permitted by Apache-2.0** — no legal gate on sharing the source publicly. The
  owner corrected an earlier overcautious note: "public distribution" is NOT a gate. A legal review
  is warranted only before **COMMERCIAL** activity — selling, a commercial product, or distributing
  built OS media under a brand (trademarks, OS-image redistribution, BricsCAD-not-bundled). Not
  commercial at this time; the current attribution + disclaimers suffice for open-source use.

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

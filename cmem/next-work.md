# Next Work — ub-cosmic

Prioritized "what to pick up next" list (2026-07-13). INDEX.md/overview.md are authoritative status;
this is the short next-up list.

## A. Get the first build green (blocking)

1. **Create the Cosign key and add `SIGNING_SECRET`** — image builds fail without it. See
   [build-and-release.md](build-and-release.md) § "Required secret". Commit `cosign.pub` only.
2. **Confirm GitHub Actions are enabled** on the repo (Actions tab → enable workflows).
3. **Run *Build container image*** and confirm `ghcr.io/jrmarcum/ub-cosmic:latest` publishes.
   - First run is slow; COSMIC adds a few hundred MB over Bazzite.
   - Watch for `dnf5 install cosmic-desktop` / `greenboot` failing if a package name drifted for the
     base's Fedora release — adjust in `build_files/build.sh`.
   - Verify the greenboot `systemctl enable` loop didn't error the build; confirm the units are
     enabled in the built image.
4. **Run *Build live ISO (titanoboa)*** and download the ISO artifact; boot-test it in a VM.
   - Sanity-check greenboot: a healthy boot should reach the desktop and clear `boot_counter`.

## A2. NVIDIA handling — DECIDED + IMPLEMENTED 2026-07-13

Resolved: **two images + one ISO + first-boot auto-rebase**, NVIDIA base = `-nvidia-open`. Fully
implemented (Containerfile args, matrix, rebase service, build.sh gating). See
[decisions.md](decisions.md) § "NVIDIA vs AMD/Intel". Remaining verification once builds run:

- Confirm the matrix publishes BOTH `ub-cosmic` and `ub-cosmic-nvidia` to GHCR.
- Test on an actual/VM NVIDIA machine: first boot should detect NVIDIA, `bootc switch`, reboot once,
  and land on `ub-cosmic-nvidia`. Confirm no rebase loop and the `gpu-rebase.done` stamp is written.
- Confirm an AMD/Intel machine stays on `ub-cosmic` (stamp written, no switch).
- If targeting older NVIDIA GPUs, add/switch the matrix entry to `bazzite-gnome-nvidia`.

## A3. Desktop layouts — tune DRAFT presets on a live VM (raised 2026-07-13)

Framework is done (switcher, 12 presets, extension install, Windows-11 dconf default). Remaining,
all needing a booted GNOME VM:

- **Tune each of the 12 presets** via `ub-cosmic-layout set <name>` → adjust → `ub-cosmic-layout
  capture <name>` → copy into `system_files/usr/share/ub-cosmic/layouts/`. Especially verify the
  `windows-11` centered-taskbar `panel-element-positions` JSON and each ArcMenu `menu-layout` name.
- **Pin ArcMenu** to a release matching the base's GNOME Shell version (build.sh currently uses
  `releases/latest`); confirm the GitHub asset name `arcmenu@arcmenu.com.zip` is correct, else the
  guarded fetch silently no-ops and Windows layouts lose the start menu.
- **Confirm the packaged extensions load** on the base's GNOME Shell version (version compatibility).
- **DECIDE default *session*:** to actually land users in the Windows-11 layout, GNOME must be the
  default session (currently user-selected via GDM). Decide + wire, or accept COSMIC-first with the
  layout as GNOME's default. Don't flip silently — see [decisions.md](decisions.md).

## B. Hardening / polish (after first green build)

- **Do NOT pin the base image** — automatic upstream updates are the chosen model (floating
  `:stable` + daily rebuild; Renovate blocked from digest-pinning the Containerfile). See
  [decisions.md](decisions.md) § "Automatic upstream updates".
- Decide whether to **force COSMIC as the default session** (currently user-selected — see
  [decisions.md](decisions.md)).
- Trim or expand the COSMIC app set in `build.sh` to taste.
- If titanoboa ever fails, wire up the BIB `build-disk.yml` path from upstream image-template as the
  fallback ISO builder.

## C. Deferred

- ArtifactHub listing (`artifacthub-repo.yml` has a placeholder `repositoryID`).
- Optional S3 upload of ISOs (secrets `S3_*`) if artifacts aren't enough.

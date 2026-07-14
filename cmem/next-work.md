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

## A2. DECIDE: nvidia vs non-nvidia variant(s) (raised 2026-07-13)

The base image is a **build-time** choice — you cannot detect the user's GPU before selecting it.
Bazzite ships separate images per GPU (`bazzite-gnome` for AMD/Intel; `bazzite-gnome-nvidia` /
`bazzite-gnome-nvidia-open` for NVIDIA). Options for ub-cosmic:

1. **Build two images + two ISOs** — `ub-cosmic` (bazzite-gnome) and `ub-cosmic-nvidia`
   (bazzite-gnome-nvidia-open). User self-selects the matching ISO (what Bazzite does). Simplest,
   robust. **Leading option.**
2. **First-boot GPU auto-detect + rebase** — ship the non-nvidia ISO; a first-boot service runs
   `lspci`, and if NVIDIA is present rebases to `ub-cosmic-nvidia`. Smoothest for the user but adds a
   long first-boot + reboot and a failure mode. Can layer on top of option 1 later.

Sub-decision if NVIDIA is built: `-nvidia-open` (open kernel modules; RTX 20-series / GTX 16-series
and newer — recommended) vs `-nvidia` (proprietary; older GPUs). Needs owner input. Blocks a clean
build-matrix design.

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

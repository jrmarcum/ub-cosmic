# Building & maintaining ub-cosmic

This is the **maintainer / developer** guide. End users want the [README](README.md).

ub-cosmic is a custom [bootc](https://github.com/bootc-dev/bootc) image: a `Containerfile` layers
COSMIC + customizations onto a Bazzite base, GitHub Actions builds and **signs** two images
(AMD/Intel + NVIDIA) and publishes them to GHCR, and a **titanoboa** workflow turns the AMD/Intel
image into a live ISO.

## What CI produces

| Artifact | How | Where |
| --- | --- | --- |
| OCI image `ghcr.io/jrmarcum/ub-cosmic:latest` (AMD/Intel) | `.github/workflows/build.yml` (matrix) | GitHub Container Registry |
| OCI image `ghcr.io/jrmarcum/ub-cosmic-nvidia:latest` (NVIDIA) | `.github/workflows/build.yml` (matrix) | GitHub Container Registry |
| **One** live installer ISO (from the AMD/Intel image) | `.github/workflows/build-iso.yml` (titanoboa) | Workflow run **Artifacts** |

**Bases:** `bazzite-gnome:stable` (AMD/Intel) and `bazzite-gnome-nvidia-open:stable` (NVIDIA open
drivers). GDM stays the display manager, so COSMIC and GNOME are both selectable at login.

## One-time setup

1. **Set identity** in [`image-template.env`](./image-template.env) — `REPO_ORGANIZATION` (already
   `jrmarcum`). `disk_config/iso.toml` points at `ghcr.io/jrmarcum/ub-cosmic:latest` for local ISO builds.
2. **Create a Cosign signing key** (image builds fail without it):
   ```bash
   COSIGN_PASSWORD="" cosign generate-key-pair
   gh secret set SIGNING_SECRET < cosign.key      # add PRIVATE key to repo secrets
   git add cosign.pub                              # commit the PUBLIC key only
   ```
   > ⚠️ Never commit `cosign.key` — it's in `.gitignore`.
3. **Enable Actions** on the repo (Actions tab → enable workflows).

## Build order

1. **Build & push the images.** Push to `main` (or run *Build container image* manually). The matrix
   publishes both `ub-cosmic` and `ub-cosmic-nvidia`. First run is slow (COSMIC + deps + rechunk).
2. **Make the GHCR packages public** so machines can pull without auth
   (`github.com/users/jrmarcum/packages` → each package → Package settings → Change visibility).
3. **Build the ISO.** Run *Build live ISO (titanoboa)* → download the ISO + checksum from the run's
   **Artifacts**.
4. **Flash & boot** with Fedora Media Writer / Etcher / `dd`.

## Two-image matrix & GPU selection

The GPU driver stack is baked in at build time, so there are two images. `Containerfile` takes
`ARG BASE_IMAGE` + `ARG IMAGE_VARIANT`; [build.yml](.github/workflows/build.yml)'s matrix builds:

- `ub-cosmic` ← `bazzite-gnome:stable` (AMD/Intel) — the ISO is built from this one
- `ub-cosmic-nvidia` ← `bazzite-gnome-nvidia-open:stable` (NVIDIA open kernel modules)

**First-boot auto-rebase:** the AMD/Intel image ships `ub-cosmic-gpu-rebase.service` +
[`gpu-rebase.sh`](system_files/usr/lib/ub-cosmic/gpu-rebase.sh). On boot it runs `lspci`; if an NVIDIA
GPU is present it `bootc switch`es to `ub-cosmic-nvidia` and reboots once (retries until it has
network). So one ISO serves both. For older NVIDIA GPUs, switch the matrix entry to
`bazzite-gnome-nvidia` (proprietary).

## Automatic upstream updates (how it's wired)

Deliberate design so users get upstream fixes hands-free:

- **Floating base tag** (`bazzite-gnome:stable`) — every build pulls the latest base. **Do NOT pin to
  a `@sha256` digest** (it would freeze the base).
- **Daily `cron`** in `build.yml` rebuilds + republishes, folding in the newest base and COSMIC packages.
- Installed machines auto-update from *our* image (Bazzite's inherited updater).
- **Renovate** ([renovate.json5](.github/renovate.json5)) SHA-pins GitHub Actions but is **blocked from
  pinning the Containerfile base** — otherwise `config:best-practices` would digest-pin it and freeze updates.

> Reproducibility tradeoff: pinning the base gives byte-for-byte builds but delays upstream fixes —
> intentionally not used. See [cmem/decisions.md](cmem/decisions.md).

## Customizing

- **Packages & tweaks:** [`build_files/build.sh`](./build_files/build.sh) — COSMIC install, greenboot,
  GPU-rebase wiring, BricsCAD deps. Add `dnf5 install -y <pkg>` lines, enable units, etc. (Keep the
  cleanup block last so `bootc container lint` stays clean.)
- **Files onto the image:** drop them under [`system_files/`](./system_files/); the tree is copied to
  `/` during build (this is how `iso.yaml`, the layout switcher, greenboot check, and the GPU-rebase
  unit land).
- **Base image:** change `ARG BASE_IMAGE` / the matrix (e.g. `bazzite:stable` for a KDE backup).
- **COSMIC layouts:** capture presets on a live session and commit them under
  `system_files/usr/share/ub-cosmic/cosmic-layouts/` — see [LAYOUTS.md](LAYOUTS.md).

## Local development

On a bootc host with `just` + `podman`:
```bash
just build              # build the image locally
just build-iso          # local ISO via bootc-image-builder (uses disk_config/iso.toml)
just run-vm-iso         # boot the local ISO in a VM
```
The CI live ISO uses **titanoboa**, not BIB, so `just build-iso` can differ slightly. Titanoboa is
experimental; if it fails, the BIB path (`build-disk.yml` in the upstream
[image-template](https://github.com/ublue-os/image-template)) is a documented fallback.

## Design decisions & project memory

Load-bearing decisions, rationale, and next-work live in [`cmem/`](cmem/INDEX.md) (portable,
git-tracked). Read it before making structural changes.

## References

- Universal Blue: https://universal-blue.org/ · Image template: https://github.com/ublue-os/image-template
- Bazzite custom-image docs: https://docs.bazzite.gg/Advanced/creating_custom_image/
- titanoboa: https://github.com/ublue-os/titanoboa · Fedora COSMIC: https://fedoraproject.org/wiki/Changes/FedoraCOSMIC

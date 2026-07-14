# Overview — ub-cosmic

**ub-cosmic** is a custom [Universal Blue](https://universal-blue.org/) / [bootc](https://github.com/bootc-dev/bootc)
OS image: **Bazzite base + the COSMIC desktop layered on top, with GNOME kept as a backup session**,
packaged as a **live installer ISO** built by [titanoboa](https://github.com/ublue-os/titanoboa).

- **Owner:** Jon Marcum (GitHub `jrmarcum`)
- **Repo:** https://github.com/jrmarcum/ub-cosmic
- **Published images:** `ghcr.io/jrmarcum/ub-cosmic:latest` (AMD/Intel) and
  `ghcr.io/jrmarcum/ub-cosmic-nvidia:latest` (NVIDIA). One ISO (built from the AMD/Intel image)
  first-boot-rebases NVIDIA machines automatically — see [decisions.md](decisions.md).

## How it works (the model, set 2026-07-13)

You do **not** remaster an existing ISO. You write a `Containerfile` that `FROM`s a Bazzite image and
layers changes; GitHub Actions builds and pushes an OCI image to GHCR; a second workflow turns that
image into a live ISO. A **daily scheduled rebuild on a floating base tag** keeps the image current
with upstream Universal Blue / Bazzite automatically. See [build-and-release.md](build-and-release.md)
and [decisions.md](decisions.md) § "Automatic upstream updates".

## Repo layout

| Path | Purpose |
| --- | --- |
| `Containerfile` | Entry point. Parametrized `ARG BASE_IMAGE` / `ARG IMAGE_VARIANT` so CI builds both GPU variants; runs the build script, `bootc container lint`. |
| `build_files/build.sh` | All package installs / customizations. Installs `cosmic-desktop` + COSMIC apps; keeps GDM; installs + enables **greenboot** auto-rollback; enables the **first-boot GPU auto-rebase** service on the AMD/Intel variant only; bakes **BricsCAD V26 (Qt6) runtime deps**. |
| `system_files/` | Tree copied to `/` during build. Holds the titanoboa ISO contract (`usr/lib/bootc-image-builder/iso.yaml`), the greenboot check, the GPU auto-rebase service + script, the **COSMIC layout switcher** (`usr/bin/ub-cosmic-layout`), and **COSMIC layout presets** (`usr/share/ub-cosmic/cosmic-layouts/<name>/`, captured from live sessions). |
| `LAYOUTS.md` | Guide to the COSMIC desktop layouts + the capture workflow. |
| `BRICSCAD.md` | How to run BricsCAD: what deps are baked, layering the RPM, GPU/Wayland caveats. |
| `image-template.env` | Build vars (`IMAGE_NAME=ub-cosmic`, `REPO_ORGANIZATION=jrmarcum`). Sourced by the Justfile. |
| `.github/workflows/build.yml` | Builds, signs (Cosign), and pushes the OCI image to GHCR. |
| `.github/workflows/build-iso.yml` | Builds the live ISO via titanoboa; uploads ISO + checksum as artifacts. |
| `disk_config/` | Local-only BIB configs (`disk.toml`, `iso.toml`) for `just build-*`. Not used by the CI ISO. |
| `.github/renovate.json5` | Keeps GitHub Actions SHA-pinned; **blocked from pinning the Containerfile base** so auto-updates keep flowing. |
| `Justfile` | Local build/run recipes (`just build`, `just build-iso`, `just run-vm-iso`). |
| `cmem/` | This portable project memory. |
| `CLAUDE.md` | Git-tracked pointer stub auto-loaded by Claude Code; redirects all memory work to `cmem/`. |

## Current state (2026-07-13)

- Scaffold complete and pushed to `main` (`main` tip `df4d281`). An early divergence with a README
  edit made on github.com was resolved by merge `a2ff811`.
- All `CHANGE_ME`/`<you>` placeholders filled with `jrmarcum`.
- **Portable memory system in place** (`cmem/` + tracked `CLAUDE.md` pointer, commit `33a7db7`); the
  empty machine-local `~/.claude/.../memory/` dir was removed — all memory now lives in `cmem/`.
- **Automatic upstream updates configured** (commit `f4b927d`): floating base tag + daily rebuild,
  and Renovate blocked from pinning the base. See [decisions.md](decisions.md).
- **greenboot auto-rollback enabled by default** (commit `a4ab810`): build.sh + a custom
  graphical-target health check, so a bad update self-heals. See [decisions.md](decisions.md).
- **NVIDIA handled via two images + one ISO + first-boot auto-rebase** (commit `923ab8e`): a CI matrix
  builds `ub-cosmic` (AMD/Intel) and `ub-cosmic-nvidia` (nvidia-open); the single ISO installs the
  AMD/Intel image, which rebases NVIDIA machines on first boot. See [decisions.md](decisions.md).
- **COSMIC desktop layouts** (Windows-like default) via `ub-cosmic-layout` file-tree switcher
  (commit `4116cc0`). Framework complete but **0 of 6 intended presets have content** — the only file
  under `cosmic-layouts/` is the README; content must be captured on a live COSMIC session. ~4–6
  approximations, not 12 (COSMIC limits). Earlier GNOME-based version was removed. See
  [decisions.md](decisions.md) and LAYOUTS.md.
- **BricsCAD-ready:** build.sh bakes BricsCAD V26 (Qt6) runtime deps; the app is user-layered. See
  [decisions.md](decisions.md) and BRICSCAD.md.
- **Not yet done** (see [next-work.md](next-work.md)): create + add the Cosign `SIGNING_SECRET`,
  confirm Actions are enabled, run the (matrix) image build, then run the titanoboa ISO build. No
  image or ISO has been built/published yet.

## Origin of the memory system

The `cmem/` layout and rules were ported 2026-07-13 from the `wasmtk` project
(`D:\Programs\_ProgramExamples\Example_Programs\wasmExamples\wasmtk`) at the owner's request, to keep
all memory portable inside the project tree. See [decisions.md](decisions.md).

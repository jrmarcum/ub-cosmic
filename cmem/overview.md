# Overview — ub-cosmic

**ub-cosmic** is a custom [Universal Blue](https://universal-blue.org/) / [bootc](https://github.com/bootc-dev/bootc)
OS image: **Bazzite base + the COSMIC desktop layered on top, with GNOME kept as a backup session**,
packaged as a **live installer ISO** built by [titanoboa](https://github.com/ublue-os/titanoboa).

- **Owner:** Jon Marcum (GitHub `jrmarcum`)
- **Repo:** https://github.com/jrmarcum/ub-cosmic
- **Published image:** `ghcr.io/jrmarcum/ub-cosmic:latest`

## How it works (the model, set 2026-07-13)

You do **not** remaster an existing ISO. You write a `Containerfile` that `FROM`s a Bazzite image and
layers changes; GitHub Actions builds and pushes an OCI image to GHCR; a second workflow turns that
image into a live ISO. A **daily scheduled rebuild on a floating base tag** keeps the image current
with upstream Universal Blue / Bazzite automatically. See [build-and-release.md](build-and-release.md)
and [decisions.md](decisions.md) § "Automatic upstream updates".

## Repo layout

| Path | Purpose |
| --- | --- |
| `Containerfile` | Entry point. `FROM ghcr.io/ublue-os/bazzite-gnome:stable`, runs the build script, `bootc container lint`. |
| `build_files/build.sh` | All package installs / customizations. Installs the `cosmic-desktop` metapackage + COSMIC apps; keeps GDM so COSMIC and GNOME are both selectable. |
| `system_files/` | Tree copied to `/` during build. Holds the titanoboa ISO contract at `usr/lib/bootc-image-builder/iso.yaml`. |
| `image-template.env` | Build vars (`IMAGE_NAME=ub-cosmic`, `REPO_ORGANIZATION=jrmarcum`). Sourced by the Justfile. |
| `.github/workflows/build.yml` | Builds, signs (Cosign), and pushes the OCI image to GHCR. |
| `.github/workflows/build-iso.yml` | Builds the live ISO via titanoboa; uploads ISO + checksum as artifacts. |
| `disk_config/` | Local-only BIB configs (`disk.toml`, `iso.toml`) for `just build-*`. Not used by the CI ISO. |
| `.github/renovate.json5` | Keeps GitHub Actions SHA-pinned; **blocked from pinning the Containerfile base** so auto-updates keep flowing. |
| `Justfile` | Local build/run recipes (`just build`, `just build-iso`, `just run-vm-iso`). |
| `cmem/` | This portable project memory. |
| `CLAUDE.md` | Git-tracked pointer stub auto-loaded by Claude Code; redirects all memory work to `cmem/`. |

## Current state (2026-07-13)

- Scaffold complete and pushed to `main` (`main` tip `f4b927d`). An early divergence with a README
  edit made on github.com was resolved by merge `a2ff811`.
- All `CHANGE_ME`/`<you>` placeholders filled with `jrmarcum`.
- **Portable memory system in place** (`cmem/` + tracked `CLAUDE.md` pointer, commit `33a7db7`); the
  empty machine-local `~/.claude/.../memory/` dir was removed — all memory now lives in `cmem/`.
- **Automatic upstream updates configured** (commit `f4b927d`): floating `bazzite-gnome:stable` +
  daily rebuild, and Renovate blocked from pinning the base. See [decisions.md](decisions.md).
- **Not yet done** (see [next-work.md](next-work.md)): create + add the Cosign `SIGNING_SECRET`,
  confirm Actions are enabled, run the image build, then run the titanoboa ISO build. No image or ISO
  has been built/published yet.

## Origin of the memory system

The `cmem/` layout and rules were ported 2026-07-13 from the `wasmtk` project
(`D:\Programs\_ProgramExamples\Example_Programs\wasmExamples\wasmtk`) at the owner's request, to keep
all memory portable inside the project tree. See [decisions.md](decisions.md).

# Build & Release Pipeline — ub-cosmic

## Two stages

1. **Image build** (`.github/workflows/build.yml`) — builds the `Containerfile`, rechunks, tags,
   **signs with Cosign**, and pushes to `ghcr.io/jrmarcum/ub-cosmic`. Triggers: push to `main`,
   daily schedule (10:05 UTC), and manual dispatch. PRs build but do not push/sign.
2. **Live ISO build** (`.github/workflows/build-iso.yml`) — manual dispatch. Consumes the pushed
   image via the `ublue-os/titanoboa@main` action and uploads `ub-cosmic-<tag>.iso` + a
   `-CHECKSUM` file as a workflow artifact (7-day retention).

**Order matters:** the ISO workflow needs the image to already exist in GHCR, so run *Build
container image* successfully at least once before *Build live ISO (titanoboa)*.

## Automatic upstream updates (how new Bazzite/UB reaches users)

This is the intended, owner-chosen model (full rationale in [decisions.md](decisions.md) §
"Automatic upstream updates"):

- The `Containerfile` base is a **floating tag** (`bazzite-gnome:stable`), so each build pulls the
  newest upstream base and the newest Fedora COSMIC packages.
- The **daily `cron` in `build.yml`** rebuilds and republishes `ghcr.io/jrmarcum/ub-cosmic:latest`
  every day — this is the mechanism that folds upstream fixes into our image with no manual step.
- **Installed machines** auto-update from *our* image (Bazzite's inherited updater), not from
  `bazzite-gnome` directly — so upstream reaches them only after the daily rebuild republishes.
- **Renovate must NOT pin the base digest** (`.github/renovate.json5` has a `dockerfile`-manager rule
  disabling `pin`/`pinDigest`/`digest`). `config:best-practices` would otherwise pin + auto-merge a
  `@sha256` digest and silently freeze updates. GitHub Actions stay SHA-pinned.

## Required secret: Cosign signing key

Image builds **fail without it** (Universal Blue signs all images). One-time:

```bash
COSIGN_PASSWORD="" cosign generate-key-pair     # produces cosign.key + cosign.pub
gh secret set SIGNING_SECRET < cosign.key        # add PRIVATE key as repo secret
git add cosign.pub && git commit -m "Add cosign public key"   # commit PUBLIC key only
```

`cosign.key` is in `.gitignore` — **never commit it**.

## The titanoboa ISO contract

Titanoboa builds a live ISO directly from the container, per the
[container-native ISO contract v0.1.0](https://github.com/ondrejbudai/bootc-isos). The image must
carry `/usr/lib/bootc-image-builder/iso.yaml` — we install it from
`system_files/usr/lib/bootc-image-builder/iso.yaml`. **Invariant:** the `CDLABEL=` in each boot
entry's kernel args MUST equal the top-level `label:` (currently `ub-cosmic`). The image must also
provide the kernel (`/usr/lib/modules/*/vmlinuz`), `initramfs.img`, and UEFI EFI binaries — the
Bazzite base supplies these.

## Local builds (optional, on a bootc host with `just` + `podman`)

```bash
just build          # build the image locally
just build-iso      # local ISO via bootc-image-builder (uses disk_config/iso.toml — NOT titanoboa)
just run-vm-iso     # boot the local ISO in a VM
```

The CI live ISO uses titanoboa; `just build-iso` uses BIB, so they can differ slightly. BIB is the
documented **fallback** if a titanoboa ISO build ever fails.

## Rebasing an existing bootc machine (no ISO needed)

```bash
sudo bootc switch ghcr.io/jrmarcum/ub-cosmic:latest
systemctl reboot
```

At the GDM login screen, pick **COSMIC** or **GNOME** (GDM remembers the last choice).

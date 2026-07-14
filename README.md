# ub-cosmic

**Universal Blue COSMIC Desktop Edition** — a custom [bootc](https://github.com/bootc-dev/bootc)
image built on top of **Bazzite** ([`bazzite-gnome`](https://github.com/ublue-os/bazzite)),
with the **COSMIC** desktop layered on top and **GNOME kept as a backup session**.

The image is built and published to GHCR by GitHub Actions, and a **live, bootable
ISO** is produced with [titanoboa](https://github.com/ublue-os/titanoboa).

---

## What this repo produces

| Artifact | How | Where |
| --- | --- | --- |
| OCI image `ghcr.io/jrmarcum/ub-cosmic:latest` (AMD/Intel) | `.github/workflows/build.yml` (matrix) | GitHub Container Registry |
| OCI image `ghcr.io/jrmarcum/ub-cosmic-nvidia:latest` (NVIDIA) | `.github/workflows/build.yml` (matrix) | GitHub Container Registry |
| **One** live installer ISO (from the AMD/Intel image) | `.github/workflows/build-iso.yml` (titanoboa) | Workflow run **Artifacts** |

**Bases:** `bazzite-gnome:stable` (AMD/Intel) and `bazzite-gnome-nvidia-open:stable`
(NVIDIA open drivers). GDM stays the display manager, so at login you can pick
**COSMIC** or **GNOME** (backup); GDM remembers each user's choice.

**One ISO, right drivers automatically:** you flash a single ISO regardless of GPU.
It installs the AMD/Intel image, which on first boot detects an NVIDIA card and
transparently rebases to `ub-cosmic-nvidia` — see
[NVIDIA auto-detection](#gpu-nvidia-vs-amdintel-automatic) below.

---

## One-time setup

1. **Create your repo from these files** and push to GitHub (or `Use this template`
   if you publish it as a template).

2. **Set your identity** in [`image-template.env`](./image-template.env):
   - `REPO_ORGANIZATION` is already set to `jrmarcum` (your GitHub username).
   - Also update the image ref in [`disk_config/iso.toml`](./disk_config/iso.toml)
     `disk_config/iso.toml` already points at `ghcr.io/jrmarcum/ub-cosmic:latest` for local ISO builds.

3. **Create a Cosign signing key** (image builds fail without it):
   ```bash
   COSIGN_PASSWORD="" cosign generate-key-pair
   gh secret set SIGNING_SECRET < cosign.key      # add to repo secrets
   git add cosign.pub                              # commit the PUBLIC key only
   ```
   > ⚠️ Never commit `cosign.key`. It is already in `.gitignore`.

4. **Enable Actions** on the repo (Actions tab → enable workflows).

---

## Build order

1. **Build & push the image.** Push to `main` (or run *Build container image*
   manually). This publishes `ghcr.io/jrmarcum/ub-cosmic:latest`.
   - First run is slow; COSMIC adds a few hundred MB on top of Bazzite.

2. **Build the ISO.** Once the image exists, run the **Build live ISO (titanoboa)**
   workflow (Actions → *Build live ISO (titanoboa)* → *Run workflow*).
   Download the ISO + checksum from the run's **Artifacts**.

3. **Flash & boot.** Write the ISO to a USB stick (e.g. with
   [Fedora Media Writer](https://fedoraproject.org/workstation/download) or
   `dd`) and boot it. The live environment includes the Anaconda installer.

---

## Installing on / rebasing an existing bootc machine

If you already run a bootc system (Bazzite, Bluefin, Fedora Atomic…), you can
switch to this image without the ISO:

```bash
sudo bootc switch ghcr.io/jrmarcum/ub-cosmic:latest
systemctl reboot
```

At the GDM login screen, click the gear/session icon and choose **COSMIC** or **GNOME**.

---

## Customizing the image

- **Packages & tweaks:** [`build_files/build.sh`](./build_files/build.sh) — the COSMIC
  install lives here. Add `dnf5 install -y <pkg>` lines, enable systemd units, etc.
- **Files onto the image:** drop files under [`system_files/`](./system_files/); the
  tree is copied to `/` during build. (This is how the ISO's `iso.yaml` is installed.)
- **Base image:** change the `FROM` line in the [`Containerfile`](./Containerfile)
  (e.g. `bazzite:stable` for a KDE backup instead of GNOME).

### Making GNOME the default instead of COSMIC
Session selection is left to the user — GDM lists both and remembers each user's last
choice. To bias new users toward one session you'd ship a GDM/AccountsService default
(intentionally not done; fragile on atomic).

---

## Local development (optional)

On a bootc host with `just` + `podman`:

```bash
just build              # build the image locally
just build-iso          # build an ISO locally via bootc-image-builder (uses disk_config/iso.toml)
just run-vm-iso         # boot the local ISO in a VM
```

The published live ISO in CI uses **titanoboa**, not BIB, so it can differ slightly
from `just build-iso`.

---

## Staying up to date (automatic)

This image is set up to **track upstream Universal Blue / Bazzite automatically** so you receive
fixes without manual work:

- The `Containerfile` uses a **floating base tag** (`bazzite-gnome:stable`) — every build pulls the
  latest base.
- [build.yml](.github/workflows/build.yml) rebuilds **daily** (`cron`), re-layering COSMIC and the
  newest Fedora COSMIC packages, and republishes `ghcr.io/jrmarcum/ub-cosmic:latest`.
- Your installed machines auto-update from **your** image (Bazzite's inherited updater); upstream
  reaches them after the daily rebuild republishes.
- Renovate keeps GitHub Actions SHA-pinned but is **deliberately blocked from pinning the base
  image** ([renovate.json5](.github/renovate.json5)) — pinning to a `@sha256` digest would freeze
  the base and stop automatic updates.

> **Reproducibility tradeoff:** if you ever need byte-for-byte reproducible builds instead of
> auto-updates, you would pin `FROM …:stable@sha256:<digest>` and let Renovate bump it via PRs — but
> that is intentionally *not* used here, because it delays upstream fixes.

---

## Desktop layouts (COSMIC, Windows-like default)

ub-cosmic ships a **switchable COSMIC desktop-layout system**, defaulting to a **Windows-like**
arrangement so Windows migrants feel at home. Switch anytime:

```bash
ub-cosmic-layout list
ub-cosmic-layout set macos      # then log out/in
```

These run on the **COSMIC session** (the primary desktop). COSMIC can't match Zorin's 12 layouts
faithfully (no start menu, can't ungroup taskbar windows), so expect **~4–6 solid approximations**.
Presets are **captured from a live COSMIC session** (cosmic-config can't be authored blind) — the
framework is complete, but **the preset content still needs to be captured on a booted VM**. See
**[LAYOUTS.md](LAYOUTS.md)** for the list and the capture workflow.

## GPU: NVIDIA vs AMD/Intel (automatic)

The GPU driver stack is baked into the image at build time, so there are **two images**:
`ub-cosmic` (AMD/Intel) and `ub-cosmic-nvidia` (NVIDIA open kernel modules). You cannot
detect a user's GPU before the image is built — but you can at install time, so the end
user still only deals with **one ISO**:

1. The single ISO installs the **AMD/Intel** image.
2. On first boot, `ub-cosmic-gpu-rebase.service` runs
   [`/usr/lib/ub-cosmic/gpu-rebase.sh`](system_files/usr/lib/ub-cosmic/gpu-rebase.sh):
   it checks `lspci` for an NVIDIA GPU.
3. **No NVIDIA** → nothing happens; you stay on the AMD/Intel image.
4. **NVIDIA present** → it `bootc switch`es to `ghcr.io/jrmarcum/ub-cosmic-nvidia:latest`
   and reboots once. The machine ends up on the correct drivers with no user choice.

> **Network note:** the rebase needs internet to pull the NVIDIA image. On Ethernet this
> happens on first boot. On Wi-Fi (not configured until you reach the desktop), it applies
> on the next reboot after you first connect — the service retries each boot until done,
> tracked by `/var/lib/ub-cosmic/gpu-rebase.done`.

NVIDIA driver base is **`bazzite-gnome-nvidia-open`** (open kernel modules — RTX 20-series /
GTX 16-series and newer). For older GPUs, change the matrix in
[build.yml](.github/workflows/build.yml) to `bazzite-gnome-nvidia`.

## BricsCAD-ready

The image bakes in the runtime libraries **BricsCAD V26** (Qt 6.8-based) needs — Qt 6, the Qt xcb
platform-plugin stack, OpenGL/GLU, fonts, and legacy GTK2 compat — so it runs once you layer the
app. BricsCAD itself is proprietary/licensed and isn't bundled; see **[BRICSCAD.md](BRICSCAD.md)**
for the install steps and the GPU caveat (BricsCAD 3D accel needs NVIDIA or AMD — not Intel-only).

## Reliability: automatic rollback (greenboot)

The image ships **[greenboot](https://github.com/fedora-iot/greenboot) enabled by default**, so a bad
update self-heals with no user action:

- After each boot, greenboot runs health checks. If they fail across the default 3 boot attempts, the
  system **automatically rolls back** to the previous working deployment (`rpm-ostree rollback`).
- Checks: the vetted `greenboot-default-health-checks` (failed services, network) plus a custom
  `required.d/50-graphical-target.sh` that rolls back if the **desktop never comes up** (e.g. a
  GPU-driver regression → black screen). It waits ~120s to avoid false-triggering on a slow boot.
- A fully non-booting update (kernel panic) is caught by the GRUB boot counter even before health
  checks run.

Manual rollback (`bootc rollback`, the GRUB previous entry, or Bazzite's `brh`) still works too.

## Caveats

- **COSMIC on atomic is still young.** COSMIC entered Fedora's repos in F41 and is
  under heavy development; expect occasional rough edges. GNOME is your safety net.
- **Titanoboa is experimental.** It builds ISOs directly from the container per the
  [container-native ISO contract](https://github.com/ondrejbudai/bootc-isos). If an
  ISO build fails, the BIB path (`build-disk.yml` in the upstream
  [image-template](https://github.com/ublue-os/image-template)) is a fallback.

## License & attribution

ub-cosmic is licensed under the **Apache License 2.0** ([LICENSE](LICENSE)), matching its upstream
[ublue-os/image-template](https://github.com/ublue-os/image-template). Attribution and the
modification statement are in [NOTICE](NOTICE); full third-party notices — build tooling, the
Bazzite/Fedora base and its bundled-package licenses, COSMIC (GPL-3.0), and **trademark /
non-endorsement** disclaimers — are in [THIRD_PARTY.md](THIRD_PARTY.md).

**BricsCAD is not bundled** — it's proprietary; only its open-source runtime dependencies are
installed. ub-cosmic is an independent, unofficial project and ships no upstream logos or branding.

## References

- Universal Blue: https://universal-blue.org/
- Image template: https://github.com/ublue-os/image-template
- Bazzite custom image docs: https://docs.bazzite.gg/Advanced/creating_custom_image/
- titanoboa: https://github.com/ublue-os/titanoboa
- Fedora COSMIC: https://fedoraproject.org/wiki/Changes/FedoraCOSMIC

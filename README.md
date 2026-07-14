<p align="center">
  <img src="UB-COSMIC-Linux.png" alt="ub-cosmic logo" width="480">
</p>

<!-- Logo © 2026 Jon Marcum — all rights reserved / trademark; NOT under Apache-2.0. See THIRD_PARTY.md. -->

# ub-cosmic

**A modern, reliable Linux desktop that stays out of your way.**

ub-cosmic is a custom Linux desktop OS built on Fedora's atomic (image-based) foundation and the
gaming-ready **Bazzite** project, running System76's next-generation **COSMIC** desktop — with
**GNOME** always available as a fallback. It's designed to be **familiar, hard to break, and always
current**: the whole system updates as one signed image, automatically rolls back if an update
misbehaves, and selects the right GPU drivers for your machine on its own.

> For people who want a clean, fast desktop that just works — gamers, Windows switchers, and CAD
> users alike.

---

## Why ub-cosmic

- 🖥️ **Modern desktop, familiar feel** — the fast, Rust-based **COSMIC** desktop as your daily
  driver, with **GNOME** one click away at the login screen. (Switchable Windows-like layouts are on
  the way — see [LAYOUTS.md](LAYOUTS.md).)
- 🛡️ **It won't break on you** — an **immutable, atomic** base means the OS is a known-good image,
  not a fragile pile of files. If an update ever misbehaves, **it automatically rolls back** to the
  last working version — even a black-screen GPU regression self-heals.
- 🔄 **Always up to date, automatically** — the entire OS updates in the background as a single signed
  image and switches over on reboot. It tracks upstream Bazzite/Fedora fixes **daily**, so you're
  never stranded on a stale base.
- 🎮 **Gaming-ready out of the box** — built on **Bazzite**, so you inherit its tuned gaming stack:
  Steam, Proton, Gamescope, MangoHud, controller support, emulators, and codecs.
- 🟢 **Right GPU drivers, zero fuss** — one install works on any machine. If it detects an **NVIDIA**
  card it automatically moves to the NVIDIA-optimized build on first boot; **AMD/Intel** just work.
- 📐 **CAD-ready** — the runtime libraries for **BricsCAD V26** are pre-installed, so a licensed copy
  runs after a simple install step ([BRICSCAD.md](BRICSCAD.md)).
- 🔐 **Secure by default** — images are **cryptographically signed**, and the atomic model keeps the
  core OS tamper-resistant.

## What it's built on

ub-cosmic stands on proven projects — each layer adds something:

| Layer | What it brings |
| --- | --- |
| **Fedora Atomic / [bootc](https://github.com/bootc-dev/bootc)** | The image-based, immutable foundation — atomic updates, easy rollback, reproducible systems |
| **[Universal Blue](https://universal-blue.org/)** | The custom-image ecosystem and build tooling behind a polished, self-updating OS |
| **[Bazzite](https://bazzite.gg/)** | Gaming optimizations, broad hardware & driver support, codecs, Steam/Proton |
| **[COSMIC](https://github.com/pop-os/cosmic-epoch)** (System76) | The modern, fast, Rust-based desktop environment — ub-cosmic's primary desktop |
| **ub-cosmic** | Ties it together: COSMIC on top, GNOME fallback, automatic GPU selection, auto-rollback, CAD-ready |

In short: **Fedora → Universal Blue → Bazzite → ub-cosmic, with COSMIC on top.**

## Get ub-cosmic

ub-cosmic is installed by **rebasing** an existing atomic base onto our image. That's the standard,
robust way Universal Blue custom images are delivered — and a big plus, it **keeps your files and
settings** and lets you **roll back instantly** if you change your mind.

### Step 1 — Install Bazzite (the base)

ub-cosmic is built on **Bazzite**, so start there:

1. Go to **[bazzite.gg](https://bazzite.gg/)** and download the ISO. Choose the **Desktop** image for
   your hardware — the **GNOME** edition is recommended. (GPU choice isn't critical: ub-cosmic sorts
   out NVIDIA drivers automatically in step 2.)
2. Write the ISO to a USB stick with [Fedora Media Writer](https://fedoraproject.org/workstation/download),
   [Balena Etcher](https://etcher.balena.io/), or `dd`.
3. Boot the USB and complete the installer. Bazzite's own
   [installation guide](https://docs.bazzite.gg/General/Installation_Guide/) walks through it.

### Step 2 — Rebase to ub-cosmic

Once you're on the Bazzite desktop, open a terminal and run:

```bash
sudo bootc switch ghcr.io/jrmarcum/ub-cosmic:latest
systemctl reboot
```

That's it — on reboot you're running **ub-cosmic**: COSMIC with a GNOME fallback, automatic
rollback, and (on NVIDIA machines) an automatic switch to the NVIDIA-optimized build on first boot.
At the login screen, pick **COSMIC** or **GNOME** — your choice is remembered.

- 🔒 **Your data stays put.** Rebasing swaps only the OS image, not your `/home` or apps.
- ↩️ **Easy undo.** `sudo bootc rollback && systemctl reboot` puts you right back on Bazzite.

> **Why not a one-click ISO?** A full ub-cosmic ISO is ~5–8 GB — larger than GitHub's 2 GiB release
> limit — so we publish the image and you rebase onto it. (A hosted ISO for fresh/offline installs may
> come later.) Already on another atomic base — Bluefin, Aurora, Fedora Atomic? You can rebase from
> there too; Bazzite just gives the closest starting point.

## Everyday use

**Update** (usually automatic in the background; to do it now):
```bash
sudo bootc upgrade && systemctl reboot
```

**Roll back** if an update ever causes trouble (also automatic after repeated boot failures):
```bash
sudo bootc rollback && systemctl reboot
```
…or just choose the previous entry in the boot menu.

**Switch desktops** — log out, click the session icon on the login screen, and choose **COSMIC** or
**GNOME**.

**Install apps** — use the app store / **Flatpak** (Flathub) for most software. It's the recommended
way on an atomic system and keeps the base clean and updatable.

**CAD** — see **[BRICSCAD.md](BRICSCAD.md)** to install BricsCAD.

## Good to know

- **COSMIC is young.** It's under active development and improving quickly — expect the occasional
  rough edge. GNOME is always there as a rock-solid fallback.
- **BricsCAD 3D acceleration** needs an NVIDIA or AMD GPU (a BricsCAD limitation, not ub-cosmic's);
  Intel-only machines run 3D in software.
- **Desktop layouts** (Windows-like, macOS-like, etc.) are still being built out — the switcher
  exists, the presets are in progress ([LAYOUTS.md](LAYOUTS.md)).

## License & trademarks

- **Code:** Apache-2.0 — see [LICENSE](LICENSE) and [NOTICE](NOTICE). Build tooling, the Bazzite/
  Fedora base and its bundled-package licenses, and COSMIC (GPL-3.0) are covered in
  [THIRD_PARTY.md](THIRD_PARTY.md).
- **Logo / brand** (`UB-COSMIC-Linux.png`): **© 2026 Jon Marcum, all rights reserved** — a reserved
  trademark, **not** open-licensed and not available for reuse.
- ub-cosmic is an **independent, unofficial** project — not affiliated with or endorsed by Universal
  Blue, Bazzite, Fedora, System76, NVIDIA, or Bricsys. All trademarks belong to their owners.

## Build it yourself / contribute

ub-cosmic's code is open source (Apache-2.0). To build the image, set up CI, or customize it, see
**[BUILDING.md](BUILDING.md)**.

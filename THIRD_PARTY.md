# Third-party notices, attribution & trademarks

> This is a good-faith open-source compliance summary, **not legal advice**. If you
> distribute ub-cosmic (especially commercially, or as installable media), get your own
> legal review — particularly for trademarks and for redistributing an OS image.

## 1. This repository

The **ub-cosmic** repository (the files authored here — `build_files/`, `system_files/`,
docs, etc.) is licensed under the **Apache License, Version 2.0** — see [LICENSE](LICENSE)
and [NOTICE](NOTICE).

## 2. Derived source — Universal Blue image template (Apache-2.0)

The repository scaffolding is derived from
[ublue-os/image-template](https://github.com/ublue-os/image-template) (Apache-2.0):
`Containerfile`, `Justfile`, `.github/workflows/*`, `disk_config/*`,
`.github/dependabot.yml`, `.github/renovate.json5`, `image-template.env`. These were
modified for this project. The upstream ships no `NOTICE` file.

## 3. Build tooling & GitHub Actions

Invoked by the workflows (by reference — their source is **not** vendored here); each is
under its own license:

| Component | Used for | License |
| --- | --- | --- |
| [ublue-os/titanoboa](https://github.com/ublue-os/titanoboa) | live ISO build | Apache-2.0 |
| [ublue-os/remove-unwanted-software](https://github.com/ublue-os/remove-unwanted-software) | free CI disk space | Apache-2.0 |
| [osbuild/bootc-image-builder](https://github.com/osbuild/bootc-image-builder) | local disk/ISO builds | Apache-2.0 |
| [sigstore/cosign](https://github.com/sigstore/cosign) | image signing | Apache-2.0 |
| `actions/*`, `docker/login-action`, `extractions/setup-just` | CI plumbing | MIT / Apache-2.0 |

## 4. Base image & bundled software

ub-cosmic is built **FROM** the Bazzite / Universal Blue images, which are built from
Fedora:

- [ublue-os/bazzite](https://github.com/ublue-os/bazzite) — Apache-2.0
- Fedora Linux — Fedora and its packages are distributed under their respective licenses.

The **built OCI image** bundles thousands of independent packages under many licenses
(GPL-2.0/3.0, LGPL, MPL-2.0, MIT, BSD, and others). This repository does **not** contain
or redistribute that source; the per-package license texts travel **inside the image**
under `/usr/share/licenses/<package>/`, which is how binary redistribution compliance is
satisfied by the upstream packaging. Anyone redistributing the built image should preserve
those files (they are included by default).

## 5. COSMIC desktop

The [COSMIC desktop](https://github.com/pop-os/cosmic-epoch) (System76) is installed into
the image as Fedora packages (`cosmic-desktop`, etc.). COSMIC components are licensed under
the **GNU General Public License (GPL-3.0)**. Their license texts ship with the packages in
the image (`/usr/share/licenses/`). ub-cosmic does not modify or redistribute COSMIC source.

## 6. BricsCAD — NOT bundled

**BricsCAD is proprietary software, © Bricsys NV, and is NOT included, bundled, or
redistributed by this project.** `build_files/build.sh` installs only **open-source runtime
dependencies** (Qt 6, xcb libraries, Mesa, fonts, etc.) from Fedora repositories so that a
user who separately obtains and installs a licensed BricsCAD copy has the libraries it needs.
The name "BricsCAD" is used **descriptively** to indicate compatibility; see
[BRICSCAD.md](BRICSCAD.md). No BricsCAD code or assets are present in this repository or the
built image.

## 7. Trademarks & non-endorsement

ub-cosmic is an **independent, unofficial** project. It is **not affiliated with, endorsed,
sponsored, or approved by** any of the following, whose names are used only descriptively to
indicate compatibility or lineage:

- **Universal Blue**, **Bazzite** — Universal Blue project / contributors
- **Fedora** — Red Hat, Inc.
- **COSMIC**, **Pop!_OS** — System76, Inc.
- **BricsCAD**, **Bricsys** — Bricsys NV / Hexagon
- **NVIDIA** — NVIDIA Corporation
- **Windows** — Microsoft Corporation
- **Zorin OS** — Zorin Group (referenced only as design inspiration for layouts)

All trademarks are the property of their respective owners. This project ships **none** of
their logos or branding. If any trademark holder objects to a descriptive use (including the
project name), it will be changed on request.

### Project brand assets — ALL RIGHTS RESERVED (not open source)

The ub-cosmic logo and brand assets — including **`UB-COSMIC-Linux.png`** — are
**© 2026 Jon Marcum, all rights reserved,** and are asserted as a **trademark** of the
project. They are **NOT** licensed under the Apache License 2.0 that covers the rest of this
repository, and **no license to use them is granted.** You may **not** copy, modify,
redistribute, or use these assets — including in a fork or derivative image, and including
any **commercial use such as merchandise (apparel, stickers, prints, etc.)** — without the
owner's prior written permission. **The owner reserves all rights to commercialize the mark;
any third-party commercial or merchandise use requires a separate written license from the
owner.** (Apache-2.0 §6 grants no trademark rights.)

> Because this is a public repository the image file is technically downloadable, but that
> does **not** grant any right to use it. To make brand assets un-downloadable they would
> have to be kept out of the public repository entirely.

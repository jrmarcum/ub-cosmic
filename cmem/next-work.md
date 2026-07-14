# Next Work — ub-cosmic

Prioritized "what to pick up next" list (2026-07-13). INDEX.md/overview.md are authoritative status;
this is the short next-up list.

## A. First build — DONE ✅ (2026-07-14)

- Cosign `SIGNING_SECRET` set, Actions enabled, **matrix build green**: both
  `ghcr.io/jrmarcum/ub-cosmic:latest` and `…-nvidia:latest` published and **verified PUBLIC**
  (anonymous pull HTTP 200; tags `latest`, `20260714`).
- Build fixes made along the way (all committed): Containerfile global `ARG BASE_IMAGE`; `bash
  /ctx/build.sh` + exec bits; explicit COSMIC package list (no `cosmic-desktop` metapackage); drop
  full `libcurl` (base has `libcurl-minimal`); cleanup of dnf/run + greetd `/var` for a clean lint.
- **Distribution = REBASE (not ISO)** — see [decisions.md](decisions.md). Users install Bazzite then
  `bootc switch` to the published image. The image being green + public is all that's needed.
- ISO build is **optional** (titanoboa `build-iso.yml`); only needed for a future hosted ISO. Not the
  user path — don't gate on it.

## A2. NVIDIA handling — DECIDED + IMPLEMENTED 2026-07-13

Resolved: **two images + one ISO + first-boot auto-rebase**, NVIDIA base = `-nvidia-open`. Fully
implemented (Containerfile args, matrix, rebase service, build.sh gating). See
[decisions.md](decisions.md) § "NVIDIA vs AMD/Intel". Remaining verification once builds run:

- Confirm the matrix publishes BOTH `ub-cosmic` and `ub-cosmic-nvidia` to GHCR.
- Test on an actual/VM NVIDIA machine: first boot should detect NVIDIA, `bootc switch`, reboot once,
  and land on `ub-cosmic-nvidia`. Confirm no rebase loop and the `gpu-rebase.done` stamp is written.
- Confirm an AMD/Intel machine stays on `ub-cosmic` (stamp written, no switch).
- If targeting older NVIDIA GPUs, add/switch the matrix entry to `bazzite-gnome-nvidia`.

## A3. COSMIC desktop layouts — capture preset content on a live session (raised 2026-07-13)

Framework is done (COSMIC file-tree switcher, capture, default-bake wiring). Preset content is
**empty** and must be built on a booted COSMIC session:

- **Capture each intended layout** (`windows` default, `macos`, `ubuntu`, `classic`, `compact`,
  `touch`): arrange the COSMIC panel/dock/theme by hand → `ub-cosmic-layout capture <name>` → copy
  `~/.config/ub-cosmic/cosmic-layouts/<name>/` into `system_files/usr/share/ub-cosmic/cosmic-layouts/`.
- **The `windows` preset feeds the baked default** (`build.sh` copies it into `/usr/share/cosmic`
  once it has content) — capture that one first.
- **Verify the switcher's INCLUDE_GLOBS** cover everything a layout needs on the base's COSMIC
  version (component dir names can drift); confirm apply-on-logout works and nothing unrelated gets
  clobbered.
- **DECIDE default *session*:** to actually land users in COSMIC (and the Windows layout), COSMIC
  should be the default session (currently user-selected via GDM). Decide + wire; don't flip silently.
- The earlier GNOME layout system was removed (COSMIC-only decision) — recoverable from git history
  if ever wanted for the GNOME backup session.

## A4. Verify BricsCAD runs (after first green build)

- Layer the BricsCAD V26 Fedora RPM (`rpm-ostree install`) on a built image and confirm it launches
  and the Qt xcb platform plugin loads (the baked `xcb-util*`/`libxkbcommon*` should cover it).
- Confirm 3D works on NVIDIA (`ub-cosmic-nvidia`) and AMD; expect no HW 3D on Intel-only (BricsCAD
  limitation). Try `QT_QPA_PLATFORM=xcb` if Wayland rendering misbehaves.
- If the RPM's `Requires` fails on anything not baked, add it to the BricsCAD block in build.sh.
  See [decisions.md](decisions.md) and BRICSCAD.md.

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
- **GATE — legal review before COMMERCIAL distribution only.** Public open-source distribution of
  the repo is fine (Apache-2.0 permits it) — NOT a gate. A lawyer review is warranted only before
  commercial activity: selling, a commercial product, or distributing built OS media under a brand
  (trademarks, OS-image redistribution, BricsCAD-not-bundled). See [decisions.md](decisions.md)
  § "Licensing & compliance posture".

#!/bin/bash
#
# ub-cosmic image build script.
# Runs inside the container build (see Containerfile). This is the place to
# install packages and lay down configuration.

set -ouex pipefail

# Which image variant we're building — passed from the Containerfile ARG.
# "base" = AMD/Intel (ub-cosmic); "nvidia" = ub-cosmic-nvidia.
IMAGE_VARIANT="${IMAGE_VARIANT:-base}"

### system_files -----------------------------------------------------------
# Copy anything under system_files/ in the repo onto the image root ("/").
# This is how the titanoboa ISO contract file (iso.yaml) gets installed.
cp -avf "/ctx/system_files"/. /

### COSMIC desktop ----------------------------------------------------------
# COSMIC ships in Fedora's repos (F41+), but there is NO `cosmic-desktop`
# metapackage — install the session components explicitly (all verified present
# in the Fedora 44 base).
#
# We deliberately do NOT install/enable cosmic-greeter — bazzite-gnome's GDM stays
# the display manager and lists both COSMIC and GNOME as sessions (COSMIC-first
# with GNOME as a reliable fallback).
dnf5 install -y \
    cosmic-session \
    cosmic-comp \
    cosmic-panel \
    cosmic-applets \
    cosmic-bg \
    cosmic-launcher \
    cosmic-settings \
    cosmic-settings-daemon \
    cosmic-osd \
    cosmic-notifications \
    cosmic-app-library \
    cosmic-files \
    cosmic-randr \
    cosmic-idle \
    cosmic-wallpapers \
    cosmic-initial-setup \
    xdg-desktop-portal-cosmic

# A few quality-of-life COSMIC apps (guarded so an odd name never fails the build).
dnf5 install -y \
    cosmic-store \
    cosmic-term \
    cosmic-edit \
    cosmic-screenshot \
    cosmic-player || true

### Session selection -------------------------------------------------------
# We keep GDM (from bazzite-gnome) as the display manager. It lists every
# installed session, so COSMIC and GNOME both appear at login and GDM remembers
# each user's last choice. Verify the COSMIC session file landed:
test -f /usr/share/wayland-sessions/cosmic.desktop \
    || echo "WARNING: cosmic.desktop wayland session not found after install"

# To force COSMIC as the default for FRESH users you would ship a
# /etc/gdm defaults / AccountsService template — this is intentionally left out
# because the mechanism is per-user and fragile on atomic. See README.

### greenboot — automatic health-check + rollback --------------------------
# Makes a bad update self-heal: greenboot runs health checks after each boot and,
# if REQUIRED checks fail across the configured number of attempts (default 3),
# automatically rolls back to the previous working deployment. This is the
# non-technical-user "just want a working system" safety net.
#
# `greenboot-default-health-checks` provides the vetted required checks (failed
# systemd units, DNS/network, etc.); our own required.d/50-graphical-target.sh
# (shipped via system_files) additionally rolls back if the desktop never comes up.
dnf5 install -y greenboot greenboot-default-health-checks

# Enable the greenboot + redboot units. Some greenboot units are 'static' (pulled
# in by targets) and cannot be enabled directly — tolerate those; the package also
# applies its own systemd preset at install, so this is belt-and-suspenders for the
# atomic image build.
for unit in \
    greenboot-healthcheck.service \
    greenboot-task-runner.service \
    greenboot-status.service \
    greenboot-grub2-set-counter.service \
    greenboot-grub2-set-success.service \
    greenboot-rpm-ostree-grub2-check-fallback.service \
    redboot-auto-reboot.service \
    redboot-task-runner.service; do
    systemctl enable "$unit" 2>/dev/null \
        || echo "note: '${unit}' not directly enablable (likely static) — skipping"
done

# Our custom health-check scripts must be executable (git checkouts on some hosts
# drop the +x bit).
chmod +x /etc/greenboot/check/required.d/*.sh 2>/dev/null || true

### GPU variant — first-boot auto-rebase (AMD/Intel image only) -------------
# One ISO is built from the AMD/Intel image. That image ships a first-boot
# service that detects an NVIDIA GPU and rebases to ub-cosmic-nvidia, so the
# machine ends up on the right drivers with no user choice. The NVIDIA image is
# already correct, so it must NOT carry the service (would loop / be pointless).
chmod +x /usr/lib/ub-cosmic/gpu-rebase.sh
if [[ "${IMAGE_VARIANT}" == "base" ]]; then
    dnf5 install -y pciutils   # provides lspci for GPU detection
    systemctl enable ub-cosmic-gpu-rebase.service
    echo "ub-cosmic: enabled first-boot GPU auto-rebase (base/AMD-Intel variant)."
else
    systemctl disable ub-cosmic-gpu-rebase.service 2>/dev/null || true
    echo "ub-cosmic: NVIDIA variant — GPU auto-rebase service left disabled."
fi

### COSMIC desktop layouts --------------------------------------------------
# ub-cosmic ships switchable COSMIC desktop-layout presets (see LAYOUTS.md),
# defaulting to a Windows-like arrangement. A "layout" is a snapshot of the
# relevant cosmic-config directories; `ub-cosmic-layout` swaps them per user.
# Preset content is CAPTURED from a live COSMIC session (cosmic-config RON can't
# be authored blind) — see cmem/next-work.md and LAYOUTS.md.
chmod +x /usr/bin/ub-cosmic-layout

# Bake the default layout as a COSMIC system default (/usr/share/cosmic), but only
# once the preset actually has captured content — until then, skip (no-op) so the
# build never ships an empty/broken default.
DEFAULT_LAYOUT="windows"
DEFAULT_SRC="/usr/share/ub-cosmic/cosmic-layouts/${DEFAULT_LAYOUT}"
if [[ -d "${DEFAULT_SRC}" ]] && [[ -n "$(ls -A "${DEFAULT_SRC}" 2>/dev/null)" ]]; then
    mkdir -p /usr/share/cosmic
    cp -a "${DEFAULT_SRC}/." /usr/share/cosmic/
    echo "ub-cosmic: baked default COSMIC layout '${DEFAULT_LAYOUT}' into /usr/share/cosmic."
else
    echo "ub-cosmic: no captured content for default layout '${DEFAULT_LAYOUT}' yet — skipping default bake (capture it on a live COSMIC session)."
fi

### BricsCAD runtime dependencies ------------------------------------------
# Give BricsCAD (V26, Qt 6.8-based) the best chance of running once the user
# layers its Fedora RPM (see BRICSCAD.md — the app itself is proprietary/licensed
# and NOT bundled here). Fedora is officially supported (glibc >= 2.35). We bake
# the runtime libraries so the RPM's deps resolve and the Qt xcb platform plugin
# loads. Applies to both GPU variants.
dnf5 install -y \
    qt6-qtbase \
    qt6-qtbase-gui \
    qt6-qtsvg \
    qt6-qtwayland \
    xcb-util \
    xcb-util-image \
    xcb-util-keysyms \
    xcb-util-renderutil \
    xcb-util-wm \
    xcb-util-cursor \
    libxkbcommon \
    libxkbcommon-x11 \
    libX11-xcb \
    libSM \
    libICE \
    libXi \
    libXtst \
    libXrandr \
    libXmu \
    libXScrnSaver \
    mesa-libGLU \
    libdeflate \
    fontconfig \
    freetype \
    openssl-libs \
    hicolor-icon-theme
# NOTE: do NOT install `libcurl` — the base ships `libcurl-minimal`, which provides
# libcurl.so.4 (with HTTPS). Adding full `libcurl` conflicts (both provide
# libcurl(x86-64)) and fails the build.
# Legacy GTK2 compat — V26 is Qt, but the RPM historically still Requires these;
# harmless belt-and-suspenders so `dnf install BricsCAD*.rpm` never blocks on them.
dnf5 install -y gtk2 libpng12

### Example: extra packages from Fedora / RPMFusion --------------------------
# RPMFusion is available by default on Universal Blue images.
# dnf5 install -y tmux

### Example: enable a systemd unit ------------------------------------------
# systemctl enable podman.socket

### Cleanup — keep the bootc image lint-clean ------------------------------
# Removes dnf metadata + scriptlet crumbs so `bootc container lint` doesn't warn
# (nonempty-run-tmp / var-tmpfiles). Keep this LAST, after all installs.
dnf5 clean all || true
rm -rf \
    /var/lib/dnf/repos \
    /var/lib/dnf/history.sqlite* \
    /var/lib/dnf/system-repo.lock \
    /var/cache/* \
    /var/log/* \
    /tmp/* \
    /run/* \
    2>/dev/null || true

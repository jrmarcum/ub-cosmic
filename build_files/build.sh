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
# The COSMIC desktop environment ships in Fedora's repos (F41+). Installing the
# `cosmic-desktop` metapackage pulls the full DE (cosmic-session, cosmic-comp,
# cosmic-settings, cosmic-files, etc.).
#
# We deliberately do NOT enable cosmic-greeter — bazzite-gnome's GDM stays the
# display manager and will list both COSMIC and GNOME as sessions, giving you a
# COSMIC-first setup with GNOME as a reliable fallback.
dnf5 install -y cosmic-desktop

# A few quality-of-life COSMIC extras (comment out any you don't want):
dnf5 install -y \
    cosmic-store \
    cosmic-terminal \
    cosmic-edit \
    cosmic-screenshot \
    cosmic-wallpapers || true

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

### Example: extra packages from Fedora / RPMFusion --------------------------
# RPMFusion is available by default on Universal Blue images.
# dnf5 install -y tmux

### Example: enable a systemd unit ------------------------------------------
# systemctl enable podman.socket

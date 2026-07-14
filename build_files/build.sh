#!/bin/bash
#
# ub-cosmic image build script.
# Runs inside the container build (see Containerfile). This is the place to
# install packages and lay down configuration.

set -ouex pipefail

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

### Example: extra packages from Fedora / RPMFusion --------------------------
# RPMFusion is available by default on Universal Blue images.
# dnf5 install -y tmux

### Example: enable a systemd unit ------------------------------------------
# systemctl enable podman.socket

#!/usr/bin/bash
# ub-cosmic — first-boot GPU auto-select.
#
# Ships only in the AMD/Intel image (ub-cosmic). If the machine actually has an
# NVIDIA GPU, this rebases to the NVIDIA variant (ub-cosmic-nvidia) so the user
# gets the right drivers automatically — no ISO choice, no manual step.
#
# Runs on each boot until it completes (gated by a stamp file):
#   - no NVIDIA GPU        → record "done", never runs again
#   - NVIDIA but offline   → do nothing, retry next boot (needs network to pull)
#   - NVIDIA and online    → bootc switch to the NVIDIA image, then reboot once
set -uo pipefail

STAMP_DIR="/var/lib/ub-cosmic"
STAMP="${STAMP_DIR}/gpu-rebase.done"
NVIDIA_IMAGE="ghcr.io/jrmarcum/ub-cosmic-nvidia:latest"

mkdir -p "${STAMP_DIR}"
[ -f "${STAMP}" ] && exit 0

# Detect an NVIDIA display controller (VGA / 3D class), ignoring e.g. the GPU's
# HDMI-audio function. Requires pciutils (installed by build.sh).
if ! lspci -nn 2>/dev/null \
        | grep -iE 'vga compatible controller|3d controller|display controller' \
        | grep -qi 'nvidia'; then
    echo "ub-cosmic: no NVIDIA GPU detected — staying on the AMD/Intel image."
    touch "${STAMP}"
    exit 0
fi

# NVIDIA present. We need network to pull the ~multi-GB NVIDIA image; if we're not
# online yet (common right after install, before Wi-Fi is set up), retry next boot.
if ! curl -sfI --max-time 15 "https://ghcr.io/v2/" >/dev/null 2>&1; then
    echo "ub-cosmic: NVIDIA GPU found but no network yet — will retry next boot."
    exit 0
fi

echo "ub-cosmic: NVIDIA GPU detected — rebasing to ${NVIDIA_IMAGE}"
if bootc switch "${NVIDIA_IMAGE}"; then
    touch "${STAMP}"
    echo "ub-cosmic: rebased to the NVIDIA image — rebooting to apply."
    systemctl reboot
else
    echo "ub-cosmic: bootc switch failed — will retry next boot." >&2
    exit 1
fi

#!/usr/bin/bash
# ub-cosmic greenboot health check (REQUIRED — failure triggers rollback).
#
# The graphical session target must come up. If a bad update breaks the desktop
# (e.g. a GPU-driver regression → black screen), graphical.target won't go
# active; this check fails, greenboot marks the boot bad, and after the
# configured number of failed boots the system automatically rolls back to the
# last known-good deployment. This is the "it just works" safety net for
# non-technical users.
#
# We wait up to ~120s so a merely slow — but healthy — boot never false-triggers
# a rollback (a rollback loop would be worse than a slow boot).
set -uo pipefail

for _ in $(seq 1 24); do
    if systemctl is-active --quiet graphical.target; then
        echo "graphical.target active — desktop reached"
        exit 0
    fi
    sleep 5
done

echo "graphical.target did not become active within ~120s — failing health check" >&2
exit 1

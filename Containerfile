# ub-cosmic — Universal Blue COSMIC Desktop Edition
#
# Base: bazzite-gnome (GNOME stays installed as the "backup" session, GDM as the
#       display manager). We layer the COSMIC desktop on top so both COSMIC and
#       GNOME are selectable at the login screen.

# Base image is parametrized as a GLOBAL build arg. It MUST be declared before the
# first FROM so it can be used in a `FROM ${BASE_IMAGE}` line (an ARG declared after
# a FROM is stage-scoped and yields an empty FROM → "no FROM statement found").
# CI builds BOTH variants from this one Containerfile:
#   - ub-cosmic         → ghcr.io/ublue-os/bazzite-gnome:stable             (AMD/Intel)
#   - ub-cosmic-nvidia  → ghcr.io/ublue-os/bazzite-gnome-nvidia-open:stable (NVIDIA)
# Both keep GNOME + GDM; :stable is a FLOATING tag (see cmem/decisions.md — do NOT pin).
ARG BASE_IMAGE="ghcr.io/ublue-os/bazzite-gnome:stable"

# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files

# Base Image
FROM ${BASE_IMAGE}
# Universal Blue images: https://github.com/orgs/ublue-os/packages

# Which variant is being built: "base" (AMD/Intel) or "nvidia". build.sh reads this
# to decide whether to install the first-boot GPU auto-rebase service (base only).
ARG IMAGE_VARIANT="base"

### MODIFICATIONS
## All package installs and customizations live in build_files/build.sh.
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    IMAGE_VARIANT="${IMAGE_VARIANT}" /ctx/build.sh

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint

# ub-cosmic — Universal Blue COSMIC Desktop Edition
#
# Base: bazzite-gnome (GNOME stays installed as the "backup" session, GDM as the
#       display manager). We layer the COSMIC desktop on top so both COSMIC and
#       GNOME are selectable at the login screen.

# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /
COPY system_files /system_files

# Base Image
# bazzite-gnome keeps GNOME + GDM; :stable is the recommended channel.
# Pin to a digest once you have a known-good build (see README "Pinning").
FROM ghcr.io/ublue-os/bazzite-gnome:stable
## Other possible base images include:
# FROM ghcr.io/ublue-os/bazzite:stable          # KDE instead of GNOME backup
# FROM ghcr.io/ublue-os/bazzite-gnome:testing   # bleeding edge
# Universal Blue Images: https://github.com/orgs/ublue-os/packages

### MODIFICATIONS
## All package installs and customizations live in build_files/build.sh.
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint

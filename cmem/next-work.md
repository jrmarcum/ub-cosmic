# Next Work — ub-cosmic

Prioritized "what to pick up next" list (2026-07-13). INDEX.md/overview.md are authoritative status;
this is the short next-up list.

## A. Get the first build green (blocking)

1. **Create the Cosign key and add `SIGNING_SECRET`** — image builds fail without it. See
   [build-and-release.md](build-and-release.md) § "Required secret". Commit `cosign.pub` only.
2. **Confirm GitHub Actions are enabled** on the repo (Actions tab → enable workflows).
3. **Run *Build container image*** and confirm `ghcr.io/jrmarcum/ub-cosmic:latest` publishes.
   - First run is slow; COSMIC adds a few hundred MB over Bazzite.
   - Watch for `dnf5 install cosmic-desktop` failing if a package name drifted for the base's Fedora
     release — adjust in `build_files/build.sh`.
4. **Run *Build live ISO (titanoboa)*** and download the ISO artifact; boot-test it in a VM.

## B. Hardening / polish (after first green build)

- **Pin the base image** to a digest in `Containerfile` for reproducibility (README § "Pinning").
  Renovate can keep it updated.
- Decide whether to **force COSMIC as the default session** (currently user-selected — see
  [decisions.md](decisions.md)).
- Trim or expand the COSMIC app set in `build.sh` to taste.
- If titanoboa ever fails, wire up the BIB `build-disk.yml` path from upstream image-template as the
  fallback ISO builder.

## C. Deferred

- ArtifactHub listing (`artifacthub-repo.yml` has a placeholder `repositoryID`).
- Optional S3 upload of ISOs (secrets `S3_*`) if artifacts aren't enough.

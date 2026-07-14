# cmem — Portable Project Memory for ub-cosmic

This folder is the **authoritative, portable project memory** for `ub-cosmic`. It lives inside the
project tree, so it travels with the project (on a USB drive, a fresh clone, or another machine) and
is committed to git — unlike a machine-local `~/.claude/...` memory store, which does **not** move
with the project.

**Format:** plain Markdown — one focused topic file per domain, so any single concern can be
reviewed and revised without wading through one giant file. Keep files small and single-topic.

## Policy (durable — set by the project owner 2026-07-13)

- **`cmem/` is the single home for ALL project memory.** Do **not** write project memory to any
  machine-local location (e.g. `~/.claude/projects/.../memory/`). When the owner (or anyone) says
  "**update the project memory**," that means: update the matching `cmem/` topic file with the
  latest decisions, changes, and current state — then add/refresh its one-line pointer in the Files
  table below. Convert relative dates to absolute; update existing entries rather than duplicating.
- **`README.md` is NOT project memory.** It is the public, user-facing document shipped to GitHub —
  a concise-but-complete guide to *using* / building ub-cosmic (what it is, setup, build order,
  install). Keep it as descriptive as a user needs; do NOT mix internal decision logs into it.
- **`CLAUDE.md` (repo root) is a small, git-tracked pointer** to this folder. It is auto-loaded by
  Claude Code each session and redirects all memory work here. It is intentionally tracked (not
  gitignored) so the portability rule travels with the repo.

### The "update the project memory" trigger (binding on every agent)

When the owner says **"update the project memory"** (or any clear synonym — "update memory", "record
this", "remember this for the project"), the required action is BOTH of:

1. **Revise all relevant `cmem/` files** — fold the latest decisions, changes, and current state
   into the matching topic file(s); refresh the one-line pointer in the Files table below; convert
   relative dates to absolute; update existing entries instead of duplicating.
2. **Sync `README.md` where, and only where, the change is user-relevant** — update the user-facing
   setup/build/install content so the README *matches* the new reality. Keep README user-facing: do
   NOT copy internal decision logs into it (those live in `cmem/` only).

This is the durable contract for this repo. Any agent reading this file is expected to honor it.

### The "look for issues" trigger (binding on every agent)

When the owner says **"look for issues"** (or a clear synonym — "audit", "audit the repo", "check the
build"), perform a **comprehensive audit** of the image/ISO build surface for things that may break a
build or produce a broken image:

1. **Stale placeholders / wrong refs** — leftover `CHANGE_ME`/`<you>`, image refs that don't match
   the GHCR owner/name, `CDLABEL` vs `label` mismatches between `iso.yaml` and the boot entries.
2. **Shell correctness** — `build_files/build.sh` under `set -euo pipefail`; run `bash -n` and (if
   available) `shellcheck`; verify every `dnf5 install` package/group actually exists for the base's
   Fedora release; beware silent `|| true` masking real failures.
3. **Workflow health** — pinned action SHAs, correct secrets (`SIGNING_SECRET`), registry casing,
   `image-ref` tags that actually exist in GHCR, titanoboa `iso.yaml` contract completeness.
4. **Container hygiene** — `bootc container lint` passes; nothing writes to immutable paths; COSMIC
   packages don't clobber the GNOME/GDM backup session.

Report findings with `file:line` + severity, then fix the safe/clear ones and note the rest here.

## Files

| File | What it holds |
| --- | --- |
| [overview.md](overview.md) | What ub-cosmic is, repo layout, key files, and current state (bazzite-gnome base + COSMIC layered + titanoboa live ISO). |
| [build-and-release.md](build-and-release.md) | The build → publish → ISO pipeline: workflows, the Cosign signing requirement, build order, the titanoboa ISO, and the **automatic upstream-update model** (floating tag + daily rebuild). |
| [decisions.md](decisions.md) | Load-bearing design decisions that must not be silently reverted (base choice, COSMIC layering method, keep-GDM, titanoboa over BIB, automatic updates / do-not-pin the base, greenboot auto-rollback on by default, NVIDIA: two images + one ISO + first-boot auto-rebase, COSMIC-native desktop layouts (Windows-like default, captured from live sessions), **BricsCAD V26/Qt6 runtime deps baked in**). |
| [next-work.md](next-work.md) | Prioritized "what to pick up next" list and open setup steps. |

## Related files outside cmem

- `README.md` — the **public, end-user-facing** doc (what the distro is, features/benefits, basis,
  install & everyday use). NOT project memory, NOT maintainer docs.
- `BUILDING.md` — the **maintainer/developer** guide (CI, Cosign, build order, matrix, customizing).
- `LAYOUTS.md` — user-facing guide to the COSMIC desktop layouts + switcher/capture.
- `BRICSCAD.md` — user-facing guide to running BricsCAD (baked deps, layering the RPM, GPU caveats).
- `LICENSE` / `NOTICE` / `THIRD_PARTY.md` — Apache-2.0 + attribution + third-party/trademark notices.
- `CLAUDE.md` — small git-tracked pointer to this folder; auto-loaded by Claude Code each session.

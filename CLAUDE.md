# CLAUDE.md — ub-cosmic

> **⚠️ ALL PROJECT MEMORY LIVES IN `cmem/` (portable, git-tracked).**
> The authoritative project memory is the **`cmem/`** folder at the repo root — start at
> [`cmem/INDEX.md`](cmem/INDEX.md). It is curated into small single-topic Markdown files and travels
> with the project (fresh clone, another machine, or USB).
>
> **Do NOT write project memory to any machine-local location** (e.g.
> `~/.claude/projects/.../memory/`). When saving new project memory, write it into the matching
> `cmem/` topic file and refresh its one-line pointer in [`cmem/INDEX.md`](cmem/INDEX.md).
>
> This file is intentionally **git-tracked** (not gitignored) so the "memory lives in `cmem/`" rule
> is portable to every machine that checks out the repo.

## Binding triggers (full text in `cmem/INDEX.md`)

- **"update the project memory"** — update the relevant `cmem/` file(s) with the latest
  decisions/changes/state, refresh their INDEX pointers, convert relative dates to absolute; then
  sync `README.md` only where the change is user-relevant. Internal logs stay in `cmem/`, never in
  the README.
- **"look for issues"** — comprehensive audit of the image/ISO build surface (stale placeholders /
  wrong image refs, `build.sh` shell correctness + package existence, workflow/secret health, the
  titanoboa `iso.yaml` contract, `bootc container lint`). Report `file:line` + severity, fix the
  clear ones, record the rest in `cmem/`.

## What this project is

A custom Universal Blue / bootc image: **Bazzite base (`bazzite-gnome`) + COSMIC desktop layered on
top, GNOME as the backup session**, shipped as a **live ISO via titanoboa**. See
[`cmem/overview.md`](cmem/overview.md).

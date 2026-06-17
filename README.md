# project-maintenance-cycle

A Claude Code **conductor skill** that runs a full project-maintenance cycle on a
project or scope:

```
ORIENT → REVIEW → DOCUMENT → PLAN → ORCHESTRATE
```

It does not re-implement anything — it **invokes existing skills** at each phase
boundary, detects where the cycle currently stands, enters at the right phase,
enforces approval gates, and makes cross-session handoffs explicit.

## What it chains

| Phase | Does | Delegates to |
|---|---|---|
| 0 · ORIENT | Detect state, confirm parameters, pick entry point | `AskUserQuestion` |
| 1 · REVIEW | Run a code review, capture findings | `code-review` |
| 2 · DOCUMENT | Turn findings into `AUDIT`/`BACKLOG`/`ROADMAP` + report | `maintaining-project-docs` |
| 3 · PLAN | Design the fixes, write the plan | `brainstorming` → `writing-plans` |
| 4 · ORCHESTRATE | Create a worktree, generate orchestrator session files | `using-git-worktrees` + `orchestrator-driven-development` |

## Install

Run the install script — it symlinks the `skill/` payload into every agent
skills directory that exists (`~/.claude/skills`, `~/.codex/skills`,
`~/.agents/skills`):

```bash
./install.sh                 # install into all existing target dirs
./install.sh --all           # ...and create any that are missing
./install.sh ~/.claude/skills # install into a specific dir only
./install.sh --uninstall     # remove installs that point at this repo
```

Only `skill/` is installed; the repo root (README, lifecycle docs, design trail)
is kept out of the loaded skill. The default is a symlink (live edits, no stale
copies); pass `--copy` for environments that don't follow symlinks. Equivalent
manual install:

```bash
ln -sfn "$PWD/skill" ~/.claude/skills/project-maintenance-cycle
```

It then appears as `/project-maintenance-cycle` in new sessions.

## Usage

```
/project-maintenance-cycle [<scope>] [effort]
```

Examples:

- `/project-maintenance-cycle strategies/grid-trader max` — full cycle on a scope.
- `/project-maintenance-cycle libs/tenet-core` — scope only; defaults to `max` effort.
- Freeform also works: *"run a maintenance cycle on grid-trader, review at max, only review+document."*

Phase 0 detects what already exists and proposes where to start, so you can also
re-enter mid-cycle (e.g. a fresh `AUDIT.md` already present → it proposes jumping
straight to PLAN).

## Gates and breakpoints (the discipline)

- **Gate A** — after docs are written, the cycle stops for your explicit approval.
- **Gate B** — before any plan is written, the design + stakes are explained in
  Traditional Chinese and you approve the direction.
- **Breakpoint 1** — `ultra` review is cloud-billed and user-triggered only; the
  conductor hands off to you, never launches it.
- **Breakpoint 2** — the orchestrator runs in a fresh session; the conductor
  generates the session files and stops, never runs them inline.

## Layout

```
skill/                               # the installed payload (symlink target)
  SKILL.md                           #   the conductor spine
  references/phase-contracts.md      #   exact invocation contract + artifacts per sub-skill
docs/superpowers/specs/              # design spec (rationale)
docs/plans/                          # implementation plan
docs/validation/                     # scenario dry-run results
README.md CLAUDE.md                  # project root: readme + agent instructions
ROADMAP.md BACKLOG.md CHANGELOG.md AUDIT.md   # project root: lifecycle docs
```

## Status

Shipped v0.1.0 (2026-06-17). Validated with three subagent dry-run scenarios
(full cycle / partial entry on existing AUDIT / ultra handoff) and exercised
end-to-end on a real package. See `ROADMAP.md` for direction and `BACKLOG.md`
for open work.

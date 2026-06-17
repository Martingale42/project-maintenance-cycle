# project-maintenance-cycle — Agent Instructions

## What this is

A Claude Code **conductor skill** (Markdown + YAML frontmatter, no runtime code)
that drives a project-maintenance cycle — `ORIENT → REVIEW → DOCUMENT → PLAN →
ORCHESTRATE` — by invoking existing sub-skills at phase boundaries. Shipped
(v0.1.0); validated with 3 subagent dry-run scenarios (no automated test suite —
a skill's "tests" are scenario runs).

## Commands

```bash
# Install / make discoverable (symlink the skill/ payload; loader follows symlinks)
ln -sfn "$PWD/skill" ~/.claude/skills/project-maintenance-cycle

# Validate after editing skill/SKILL.md — re-run the dry-run scenarios (see docs/validation/)
# Dispatch a subagent given ONLY skill/SKILL.md + a scenario; check it enters the right
# phase, honors Gate A/B, and hands off (never inline) on ultra / orchestrator.

# Structural checks the skill must keep passing
wc -l skill/SKILL.md                             # must stay < 500 (writing-skills rule)
grep -c '@\./\|@~/\|superpowers:' skill/SKILL.md skill/references/phase-contracts.md   # must be 0
```

There is no build/lint/bench step — the deliverable is `skill/SKILL.md` +
`skill/references/phase-contracts.md`.

## Architecture

The installed payload lives in `skill/` (the symlink target); the repo root holds
the project's own docs. `skill/SKILL.md` is the conductor spine: operating rules,
the phase state machine, Phase 0 detection decision tree, Phase 1–4 execution,
gates, red flags, and the integration map. `skill/references/phase-contracts.md`
holds the exact invocation contract + artifacts of each sub-skill (loaded on
demand, keeping SKILL.md tight). Design rationale lives in
`docs/superpowers/specs/`; direction in `ROADMAP.md`. The skill **invokes** `code-review`, `maintaining-project-docs`,
`brainstorming`→`writing-plans`, and `using-git-worktrees`+`orchestrator-driven-development`;
it never re-implements them.

## Project-specific conventions

- **SKILL.md must stay under 500 lines** and at conductor altitude — invoke + pass
  artifact + handle the gate; never re-document a sub-skill's internals (that's
  what `references/phase-contracts.md` is for).
- **No `@`-style links** anywhere (they force-load files at skill-load time); use
  plain paths and explicit `**REQUIRED SUB-SKILL:**` markers.
- Sub-skills are referenced by **plain name** (`brainstorming`, not
  `superpowers:brainstorming`) — that is how they resolve in this environment.
- Instruction prose is **English**; Traditional Chinese appears only inside the
  verbatim user-facing messages the conductor speaks.

## Gotchas

- The install is a **symlink**, so editing files here changes the live skill
  immediately — no copy/sync step, but also no staging buffer.
- `.pmc-findings.md` is a **gitignored** runtime scratch file the conductor may
  write during REVIEW; never commit it.
- The freshness check in Phase 0 uses GNU `stat -c %Y` — not portable to BSD/macOS
  `stat` (tracked in `BACKLOG.md`).
- `code-review ultra` is **user-triggered only** (cloud, billed); the conductor
  must hand off, never launch it. Same for the orchestrator (needs a fresh
  session). These two breakpoints are the skill's load-bearing discipline.

## Lifecycle docs

`ROADMAP.md` (map) · `BACKLOG.md` (open work) · `CHANGELOG.md` · `AUDIT.md`
(index → `docs/audits/`). Maintenance SOP: the `maintaining-project-docs` skill.

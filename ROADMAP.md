# project-maintenance-cycle — Roadmap

**Updated**: 2026-06-17 (v0.1.0 shipped — conductor authored, validated 3/3 scenarios, merged @e6034ea)
**Purpose**: the single document recording where this skill is going and why.
Each next step gets its own design/plan before work starts; this file is the
map, not the plans.

## Vision

A single conductor that runs the project-maintenance loop the same way every
time, across the sessions it naturally spans — so step order, scope passing,
artifact contracts, gates, and cross-session handoffs stop being carried in the
operator's head. Binding requirements:

- **Never re-implement a sub-skill** — invoke and delegate (enforced by the
  conductor-altitude convention + the Red Flags table).
- **Gates are non-skippable** — Gate A (doc review) and Gate B (zh-TW design +
  stakes) require explicit in-conversation approval.
- **Cross-session boundaries are explicit handoffs** — `ultra` review and the
  orchestrator are never run inline (enforced by Breakpoint 1 / 2).

## Layer map and status

```
Phase 0  ORIENT       ✅  detection decision tree + AskUserQuestion params
Phase 1  REVIEW       ✅  invokes code-review; ultra → Breakpoint 1 handoff
Phase 2  DOCUMENT     ✅  invokes maintaining-project-docs; Gate A
Phase 3  PLAN         ✅  invokes brainstorming → writing-plans; Gate B (zh-TW)
Phase 4  ORCHESTRATE  ✅  worktree + orchestrator-driven-development; Breakpoint 2
Validation            ✅  3 subagent dry-run scenarios (docs/validation/)
Install               ✅  symlink into ~/.claude/skills/
Portability           ☐  BSD/macOS stat in the Phase 0 freshness check
Ergonomics            ☐  short `pmc` alias; gh-absent handling for --comment
```

## Conductor roadmap

- **Portability** (demand-triggered): make the Phase 0 freshness check work on
  BSD `stat` (macOS), not only GNU `stat -c %Y`. Do it when the skill is used on
  a non-Linux host.
- **Validation breadth**: add dry-run scenarios for the document-only partial
  run and the orchestrator-files-exist resume path.
- **Ergonomics**: optional `pmc` alias symlink; define `--comment` behavior when
  `gh` is unavailable.
- **Upstream signal**: the live test established that `code-review` with a path
  scope and no diff reviews the path's contents — worth confirming/citing in the
  contract if `code-review` documents it.

## Sequencing (recommended, revisit each kickoff)

Portability and validation-breadth are the only items with real pull, and only
when triggered (a macOS run; a partial-cycle bug). Everything else is YAGNI until
usage demands it. No work is currently scheduled — the skill is feature-complete
for its v0.1 scope.

## Development process (the institution, keep it)

This skill was itself built with the loop it encodes a flavor of: **brainstorm →
spec → plan → build (per-task implementer + spec-review + code-quality-review
gates) → final review → merge**. Future changes follow the same: design first,
keep SKILL.md under 500 lines and at conductor altitude, and re-run the dry-run
scenarios before merging any change that touches gate or handoff wording.

## Reference index

| Document | Content |
|---|---|
| `BACKLOG.md` | open work, status rows |
| `AUDIT.md` | audit index → `docs/audits/` |
| `CHANGELOG.md` | shipped changes (Keep a Changelog) |
| `docs/superpowers/specs/` | design spec (rationale) |
| `docs/validation/` | scenario dry-run results |
| `~/.claude/skills/maintaining-project-docs` | SOP for these docs |

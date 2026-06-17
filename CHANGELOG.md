# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project aims to
follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Changed

- Moved the skill payload into a `skill/` subdirectory (`skill/SKILL.md`,
  `skill/references/`); lifecycle docs and the design trail stay at the repo
  root. **Install now symlinks `skill/`**, not the repo root, so the loaded skill
  directory contains only the payload. Re-point existing installs:
  `ln -sfn "$PWD/skill" ~/.claude/skills/project-maintenance-cycle`.

### Fixed

## [0.1.0] — 2026-06-17

First tagged release.

### Added

- `SKILL.md` — the conductor: operating rules, the `ORIENT → REVIEW → DOCUMENT →
  PLAN → ORCHESTRATE` phase state machine, the Phase 0 detection decision tree,
  Phase 1–4 execution with the `ultra` guard, Gate A / Gate B, the two
  cross-session breakpoints, a red-flags table, and the sub-skill integration map.
- `references/phase-contracts.md` — exact invocation contract and artifacts for
  each delegated sub-skill (`code-review`, `maintaining-project-docs`,
  `brainstorming`→`writing-plans`, `using-git-worktrees`+`orchestrator-driven-development`).
- `docs/validation/2026-06-17-scenario-results.md` — three subagent dry-run
  scenarios (full cycle / partial entry on existing AUDIT / ultra handoff), 3/3 pass.
- Design spec and implementation plan under `docs/superpowers/specs/` and `docs/plans/`.

<!-- No remote is configured yet; add the compare/release links here when the
     repo is published, replacing this note (never ship example.invalid). -->

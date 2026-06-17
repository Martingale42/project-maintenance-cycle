# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project aims to
follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] — 2026-06-17

First release.

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
- Project docs: `README.md`, `CLAUDE.md`, and the lifecycle docs (`ROADMAP.md`,
  `BACKLOG.md`, `CHANGELOG.md`, `AUDIT.md`).
- `install.sh` — symlinks the `skill/` payload into every existing agent skills
  directory (`~/.claude/skills`, `~/.codex/skills`, `~/.agents/skills`). Supports
  `--all`, explicit target dirs, `--copy`, `--force`, and `--uninstall`; idempotent.
- `LICENSE` — MIT.

### Notes

- The installed payload lives in the `skill/` subdirectory (the symlink target);
  the repo root holds the project docs. Install with `./install.sh`.

[Unreleased]: https://github.com/Martingale42/project-maintenance-cycle/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Martingale42/project-maintenance-cycle/releases/tag/v0.1.0

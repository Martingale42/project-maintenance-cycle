# Backlog — project-maintenance-cycle

Single source of truth for **open** work. Every item is a table row with a
status. Evidence and measurements live in the audit reports under `docs/audits/`
(linked via the **Source** column), never inline here.

- **Status**: `open` · `closed @<hash>` · `deferred`. Closing an item flips the
  status in place — the row is never deleted.
- **IDs are never renumbered** once published. A future audit namespaces its IDs
  by scope so they cannot collide with the `PMC-*` ids below.
- `Source` is `self` (author review) until a `docs/audits/` report exists to cite.

## project-maintenance-cycle — P0 (pre-merge gate)

_None open._ The skill is shipped and feature-complete for its v0.1 scope.

## project-maintenance-cycle — P1 (correctness / portability)

| ID | Status | Item | Where | Source |
|---|---|---|---|---|
| PMC-1 | open | Phase 0 freshness check uses GNU `stat -c %Y`; make it work on BSD/macOS `stat` too | `skill/SKILL.md` (Phase 0 — Freshness check) | self |

## project-maintenance-cycle — P2 (ergonomics & validation breadth; no behavior change unless noted)

| ID | Status | Item | Where | Source |
|---|---|---|---|---|
| PMC-2 | open | Add a dry-run scenario for the document-only partial run | `docs/validation/` | self |
| PMC-3 | open | Add a dry-run scenario for the orchestrator-files-exist resume path | `docs/validation/` | self |
| PMC-4 | open | Define `--comment` behavior when `gh` is unavailable | `skill/SKILL.md` (Phase 1) · `skill/references/phase-contracts.md` | self |
| PMC-5 | open | Optional short `pmc` alias symlink for quicker invocation | install (`~/.claude/skills/`) | self |

## Open design questions (resolve at design time — not work items)

- **code-review path-scope contract**: the live test showed `code-review` with a
  path argument and no diff reviews the path's *contents* (not a diff). Decide
  whether to assert this in `skill/references/phase-contracts.md` — it depends on
  whether `code-review` itself documents the behavior as stable.

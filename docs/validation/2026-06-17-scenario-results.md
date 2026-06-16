# project-maintenance-cycle — Validation Scenario Results

- **Date:** 2026-06-17
- **Method:** Three independent dry-run subagents, each given ONLY the installed `SKILL.md` (+ `references/phase-contracts.md`) and a scenario (user request + observed project state). Each was asked to narrate, step by step, what it would do as the conductor — without being told the expected outcome (to avoid gaming). The controller judged PASS/FAIL against expected behavior.
- **Why validated:** `writing-skills` mandates validation for discipline-enforcing skills with complex decision trees. This conductor is both.

## Result summary

| # | Scenario | Expected | Observed | Verdict |
|---|---|---|---|---|
| 1 | Full cycle, fresh project (`max` effort, no AUDIT/plan/orchestrator, no PR) | ORIENT→REVIEW; `effort=max` (not ultra); `--fix` OFF; `--comment` OFF; Gate A stop after DOCUMENT; Gate B in zh-TW before plan; terminal handoff (not inline) | Routed to REVIEW; chose `max` (explicitly refused to assume `ultra`); `--fix`/`--comment` OFF; invoked `code-review`→`maintaining-project-docs`→stopped at Gate A; framed Phase 3 as "fix all findings in AUDIT.md" + zh-TW Gate B; Phase 4 worktree + orchestrator, then handoff to a NEW session | **PASS** |
| 2 | Fresh `AUDIT.md` already exists, no plan | ORIENT→PLAN; do NOT re-run review; do NOT overwrite AUDIT; confirm first | Routed to PLAN; cited the no-overwrite rule verbatim; reused `AUDIT.md` as Phase 3 input; confirmed entry with the user before proceeding; did not re-run review or regenerate AUDIT | **PASS** |
| 3 | `ultra` effort requested, PR exists | Do NOT self-launch ultra; instruct user to run `/code-review ultra <scope>` themselves; wait; resume at Phase 2 (Breakpoint 1) | Routed to REVIEW; `--comment` ON (PR detected); at REVIEW refused to invoke the review itself; instructed the user verbatim to run `/code-review ultra strategies/grid-trader --comment` and return; waited; resumed at Phase 2; then Gate A / Gate B / terminal handoff all correct | **PASS** |

## Cross-cutting behaviors confirmed in all runs

- Conductor invokes sub-skills via the Skill tool; never re-implements them.
- Both cross-session breakpoints (ultra review; orchestrator launch) handled as explicit handoffs — never inline.
- Gates A and B treated as mandatory; agents explicitly refused to skip them on a prior in-turn "OK".
- `--fix` defaults OFF in every run; `--comment` only ON when a PR was detected.

## Outcome

3 / 3 PASS. No SKILL.md changes required. The skill correctly steers entry-phase detection, gate enforcement, the no-overwrite rule, the `ultra` handoff, and the terminal orchestrator handoff.

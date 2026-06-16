---
name: project-maintenance-cycle
description: Use when running a project maintenance cycle on a project or scope — code review, then document findings (AUDIT/BACKLOG/ROADMAP), then plan fixes, then orchestrate implementation. Detects current cycle state and enters at the right phase; supports partial runs (review-only, document-only, plan-from-existing-AUDIT). Conductor that invokes code-review, maintaining-project-docs, brainstorming/writing-plans, and orchestrator-driven-development.
---

## Overview

This is a **conductor skill**. It drives a project-maintenance cycle by invoking existing sub-skills at phase boundaries — it does NOT re-implement them. It detects the current cycle state, enters at the right phase, enforces approval gates, and makes cross-session handoffs explicit.

---

## Operating Rules

- You are a conductor. Invoke sub-skills via the Skill tool at phase boundaries; pass each one the right artifact. Never duplicate a sub-skill's internal logic.
- Always run **Phase 0 ORIENT** first, unless the user explicitly names an entry phase.
- Honor every gate. **Gate A** and **Gate B** require explicit user approval in this conversation before the next phase runs; the **terminal handoff** means you stop and hand off to a new session, never continue inline. No exceptions — do not skip a gate for any reason (e.g. "user already said OK", "no changes needed", "saves a round-trip").
- Cross-session boundaries (`ultra` review, orchestrator launch) are **explicit handoffs** — never run them inline/automatically.
- Reply to the user in **Traditional Chinese** (per their global CLAUDE.md).
- Run one phase at a time; after each phase, state what happened and what the next phase is.

---

## Phase State Machine

| Phase | Name | Action | Delegate-to / Tools | Gate |
|---|---|---|---|---|
| 0 | **ORIENT** | Detect current state, confirm parameters, decide entry point | `AskUserQuestion` | — |
| 1 | **REVIEW** | Run code-review, extract findings | `code-review` skill (Skill tool; `ultra` exception: stop and hand off to user) | — |
| 2 | **DOCUMENT** | Write findings into `AUDIT.md`/`BACKLOG.md`/`ROADMAP.md` + update `README.md`/`CLAUDE.md` | `maintaining-project-docs` skill | **Gate A: user reviews docs** |
| 3 | **PLAN** | Start design from "fix all findings in AUDIT.md" → write plan | `brainstorming` → `writing-plans` skills | **Gate B: explain design + stakes in zh-TW, then approve** (brainstorming HARD-GATE) |
| 4 | **ORCHESTRATE** | Create worktree + generate orchestrator session files | `using-git-worktrees` + `orchestrator-driven-development` skills | **Terminal handoff: instruct user to open new session with `` `orchestrator.md` ``** |

### Session Boundary Breakpoints

The cycle has two natural session breakpoints; the conductor MUST handle these as explicit handoffs, never inline:

- **Breakpoint 1 (conditional):** When `effort=ultra`, code-review runs asynchronously in the cloud → conductor stops, instructs user to run `/code-review ultra <scope>` themselves, then resume from Phase 2 with the results.
- **Breakpoint 2 (mandatory):** The orchestrator must start in a fresh session → the conductor's terminal action is a handoff instruction, not an inline launch.

### Control Flow

```dot
digraph pmc {
  "Phase 0: ORIENT" [shape=box];
  "Phase 1: REVIEW" [shape=box];
  "Phase 2: DOCUMENT" [shape=box];
  "Gate A: user reviews docs" [shape=diamond];
  "Phase 3: PLAN (brainstorming->writing-plans)" [shape=box];
  "Gate B: explain design+stakes in zh-TW, approve" [shape=diamond];
  "Phase 4: ORCHESTRATE (worktree + orchestrator-driven-development)" [shape=box];
  "Terminal handoff: open new session with orchestrator.md" [shape=doublecircle];

  "Phase 0: ORIENT" -> "Phase 1: REVIEW" [label="entry=review/full"];
  "Phase 0: ORIENT" -> "Phase 2: DOCUMENT" [label="entry=document"];
  "Phase 0: ORIENT" -> "Phase 3: PLAN (brainstorming->writing-plans)" [label="entry=plan (AUDIT exists)"];
  "Phase 0: ORIENT" -> "Phase 4: ORCHESTRATE (worktree + orchestrator-driven-development)" [label="entry=orchestrate (plan exists)"];
  "Phase 1: REVIEW" -> "Phase 2: DOCUMENT";
  "Phase 2: DOCUMENT" -> "Gate A: user reviews docs";
  "Gate A: user reviews docs" -> "Phase 3: PLAN (brainstorming->writing-plans)" [label="approved"];
  "Phase 3: PLAN (brainstorming->writing-plans)" -> "Gate B: explain design+stakes in zh-TW, approve";
  "Gate B: explain design+stakes in zh-TW, approve" -> "Phase 4: ORCHESTRATE (worktree + orchestrator-driven-development)" [label="approved"];
  "Phase 4: ORCHESTRATE (worktree + orchestrator-driven-development)" -> "Terminal handoff: open new session with orchestrator.md";
}
```

**Skip-entry and gates:** When Phase 0 routes you to a later entry phase, gates for the phases you skipped are treated as already satisfied (e.g. entering at PLAN because a fresh `AUDIT.md` exists means Gate A — doc review — was satisfied in a prior cycle). Gates for phases you DO run still fire normally: entering at PLAN still requires **Gate B** before ORCHESTRATE; entering at ORCHESTRATE assumes Gate B was already passed when the plan was written.

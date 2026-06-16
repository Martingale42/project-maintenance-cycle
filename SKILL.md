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

---

## Phase 0 — ORIENT

### (a) Detection Scan

> `scope` may already be known from the invocation arguments (e.g. `/project-maintenance-cycle strategies/grid-trader`). If so, scan `<scope>/`; otherwise scan project-wide (whole project is the default) and let the entry-phase proposal account for what was found.

Run these commands to snapshot the project state before asking the user anything:

| Signal | Command |
| --- | --- |
| PR / branch | `git branch --show-current` ; `gh pr view --json number,state 2>/dev/null` |
| AUDIT exists | `find . -maxdepth 3 -name AUDIT.md -not -path '*/.*' 2>/dev/null` (if scope is known, also `test -f <scope>/AUDIT.md`) |
| AUDIT fresh | Compare AUDIT.md mtime vs the latest non-doc commit — see freshness check below |
| existing plan | `ls docs/plans/*.md 2>/dev/null` |
| orchestrator setup | `test -f docs/sessions/orchestrator.md` ; `git worktree list` |

**Freshness check** — "fresh" means AUDIT.md's mtime is newer than the latest non-doc commit:

```bash
if [ "$(stat -c %Y AUDIT.md)" -gt "$(git log -1 --format=%ct -- . ':!docs/' ':!*.md' 2>/dev/null)" ]; then echo FRESH; else echo STALE; fi
```

Freshness is a heuristic — the conductor states its FRESH/STALE verdict to the user in the Phase 0 `AskUserQuestion` prompt and lets the user confirm. When in doubt, treat AUDIT.md as authoritative (the no-overwrite rule protects it).

Map results to a proposed entry phase:

- **No AUDIT, no plan** → propose **REVIEW** (full cycle).
- **Fresh AUDIT exists, no plan** → propose **PLAN** (do NOT re-run review; do NOT overwrite AUDIT — confirm first).
- **Plan exists, no orchestrator files** → propose **ORCHESTRATE**.
- **Orchestrator files exist** → tell the user a prior cycle is already set up; instruct them to open a new Claude Code session with `docs/sessions/orchestrator.md` to resume it — then stop.

### (b) Parameter Collection via AskUserQuestion

Collect all parameters in a single `AskUserQuestion` prompt. Entry phase (derived from the detection scan above) is question 1; include the remaining questions only as needed:

| Parameter | Default | Notes |
| --- | --- | --- |
| `scope` | whole project | Path or "whole project" |
| `effort` | `max` | `low` / `medium` / `high` / `max`; `ultra` must be explicitly requested by the user — never assume it as a default. It runs asynchronously in the cloud (billed); the conductor cannot launch it and must hand off (see Phase 1). |
| `--fix` | **OFF** | Apply fixes inline during review |
| `--comment` | **ON if PR detected, else OFF** | Post findings as inline PR comments |
| `phases` | derived from detection | Subset of REVIEW / DOCUMENT / PLAN / ORCHESTRATE. Only override the detection-derived entry when the user wants a specific subset (e.g. DOCUMENT only). Otherwise follow the proposed entry phase. |

> **Never overwrite a fresh `AUDIT.md` silently.** If a fresh `AUDIT.md` exists and the user did not explicitly request re-review, propose entering at **PLAN** (reuse it). AUDIT.md may be regenerated ONLY when the user actively chooses re-review — never as a routine default.

---

## Phase 1 — REVIEW

### Standard effort (`effort ∈ {low, medium, high, max}`)

Invoke the `code-review` skill via the Skill tool, passing the effort level and scope:

```
/code-review <effort> <scope>
```

Include flags collected in Phase 0:

- `--comment` if a PR was detected (or the user requested it)
- `--fix` if the user opted in

Capture the findings output. If the findings are large (more than ~50 lines), stash them to `$CLAUDE_JOB_DIR/tmp/findings.md` (create the `tmp/` directory if needed) and carry the path forward; otherwise keep them in context.

After the review completes, state: what effort level was used, what scope was covered, and how many findings were captured. Then proceed to Phase 2.

### Ultra effort (`effort = ultra`) — Breakpoint 1 (cross-session handoff)

**STOP. Do NOT invoke the review yourself.**

`ultra` runs asynchronously in the cloud, is billed, and is **user-triggered only — you cannot launch it.** Tell the user verbatim:

> 請您自己在終端機執行：
>
> `/code-review ultra <scope>`
>
> 等 ultra review 完成後，將結果複製貼到這個對話，然後繼續 Phase 2 — DOCUMENT。

Do not proceed to Phase 2 until the user returns with the ultra-review output.

---

## Phase 2 — DOCUMENT

Invoke the `maintaining-project-docs` skill via the Skill tool with this instruction (fill in `<scope>`):

> `update README.md/CLAUDE.md for <scope> and create AUDIT.md/BACKLOG.md/ROADMAP.md for the findings.`

Pass the Phase 1 findings (from context or `tmp/findings.md`) as the AUDIT content for the skill to incorporate.

After the skill completes and any changed files are committed:

### Gate A — User reviews docs (mandatory)

Present a summary of every file written or modified (file path + one-line description of change). Then ask the user:

> 以上文件請確認後，回覆「approved」才進行 Phase 3 — PLAN。

**Do not proceed to Phase 3 until the user explicitly approves.** No exception — "no changes needed" or a prior verbal OK in the same turn does not satisfy Gate A.

---

## Phase 3 — PLAN

Invoke the `brainstorming` skill via the Skill tool, framed as:

> **"fix all findings in AUDIT.md"**

### Gate B — Convention injection (mandatory pre-brainstorm instruction)

Before `brainstorming` begins any design work, explicitly require the following convention:

> 先用繁體中文詳細解釋設計決策與 stakes，approve 後才寫 spec/plan。

This means: explain all design decisions and their stakes in Traditional Chinese in detail; only write the spec/plan after the user explicitly approves the direction. `brainstorming`'s built-in HARD-GATE already enforces no-implementation-before-approval; Gate B adds the language and stakes requirement on top of it.

After `brainstorming` completes and the user has approved the design direction, invoke the `writing-plans` skill via the Skill tool. `writing-plans` will produce a plan file at `docs/plans/YYYY-MM-DD-<feature>.md` and offer the user three execution options:

1. Solo implementation (in current session)
2. Subagent-driven development
3. **Orchestrator-driven development** → flows into Phase 4

If the user selects option 3, proceed to Phase 4. Otherwise the cycle ends here.

---

## Phase 4 — ORCHESTRATE

### Step 1 — Create a worktree

**REQUIRED SUB-SKILL:** invoke `using-git-worktrees` via the Skill tool to create an isolated worktree for this implementation cycle. The orchestrator session files must live in this worktree, not on the current branch.

### Step 2 — Generate session files

Invoke `orchestrator-driven-development` via the Skill tool. It will generate:

- `docs/sessions/orchestrator.md` — main orchestrator prompt
- `docs/sessions/` — executor, reviewer, QA, resume, and progress files
- `.claude/agents/` — subagent definitions

These files are committed to the worktree branch before the handoff.

### Terminal handoff — Breakpoint 2 (mandatory cross-session handoff)

**STOP. Do NOT attempt to run the orchestrator inline.**

Instruct the user to open a new session and paste `docs/sessions/orchestrator.md` as the initial prompt. Tell the user:

> Phase 4 完成。請開啟一個全新的 Claude Code session，並將以下檔案的內容貼入作為第一則訊息：
>
> `docs/sessions/orchestrator.md`
>
> 不要在這個 session 繼續執行 orchestrator — 它必須在全新 session 中啟動。

The conductor's work is done. Do not take any further action in this session.

---

For each sub-skill's exact invocation contract, flags, and artifacts, see `references/phase-contracts.md`.

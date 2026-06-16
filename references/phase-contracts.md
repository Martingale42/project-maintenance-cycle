# Phase Contracts — Sub-skill Invocation Reference

This file specifies the exact invocation contracts, artifacts, terminal states, and prerequisites
for every sub-skill that `project-maintenance-cycle` (the conductor) calls. Load this file when
you need the precise details that SKILL.md defers here.

---

## Phase 1 — `code-review`

### Invocation

Invoked via the **Skill tool** (built-in skill, not an external plugin):

```
/code-review [effort] [--fix] [--comment] [<scope>]
```

All parameters are optional; the conductor supplies them from Phase 0 parameter collection.

| Argument | Values | Notes |
|---|---|---|
| `effort` | `low` / `medium` / `high` / `max` / `ultra` | Default the conductor uses: `max`. `ultra` is **user-triggered only** — see constraint below. |
| `--fix` | flag | Applies findings to the working tree. **OFF by default in this cycle** — fixes are planned deliberately in Phase 3, not applied inline. |
| `--comment` | flag | Posts findings as inline PR comments. Enable only when a PR exists (detected in Phase 0) or the user explicitly requests it. |
| `<scope>` | path or omit | A path within the repo (e.g. `strategies/grid-trader`) or omitted for whole-project review. |

**Effort semantics:**

- `low` / `medium` — fewer findings, higher confidence only; faster.
- `high` / `max` — broader coverage; may include uncertain findings.
- `ultra` — cloud multi-agent deep review; see the `ultra` constraint below.

### `ultra` Constraint (Breakpoint 1)

`ultra` runs asynchronously in the cloud, is billed, and is **user-triggered only — the conductor
cannot launch it.** When `effort = ultra`, the conductor MUST stop immediately and hand off:

> 請您自己在終端機執行：
>
> `/code-review ultra <scope>`
>
> 等 ultra review 完成後，將結果複製貼到這個對話，然後繼續 Phase 2 — DOCUMENT。

The conductor does NOT proceed to Phase 2 until the user returns with the ultra-review output.

### Output / Artifacts

Produces a **findings list** — not a file. The conductor:

1. Captures the findings output in context.
2. If the findings exceed ~50 lines, stashes them to `./.pmc-findings.md` (a gitignored scratch
   file; never committed) and carries the path forward.
3. After the review, states: effort level used, scope covered, and number of findings captured.

### Terminal / Handoff State

- **Standard effort:** review complete, findings in context or stashed to `.pmc-findings.md`.
  Conductor proceeds directly to Phase 2 — DOCUMENT.
- **`ultra` effort:** conductor has stopped and given the user the handoff instruction (Breakpoint 1).
  Phase 2 begins only after the user pastes the results back.

### Prerequisites

- Phase 0 ORIENT completed; `scope`, `effort`, `--fix`, and `--comment` parameters collected.
- A PR must exist for `--comment` to be meaningful.

---

## Phase 2 — `maintaining-project-docs`

### Invocation

Invoked via the **Skill tool** with a freeform instruction string (no slash flags):

```
Skill tool → maintaining-project-docs
```

The conductor passes a freeform instruction using this template:

> `update README.md/CLAUDE.md for <scope> and create AUDIT.md/BACKLOG.md/ROADMAP.md for the findings.`

followed by either:
- the findings content inline (if short), or
- a file reference (e.g. `@./.pmc-findings.md`) if the findings were stashed in Phase 1.

### Scope of Management

The `maintaining-project-docs` skill manages:

| Document | Notes |
|---|---|
| `ROADMAP.md` | Project direction and milestones |
| `BACKLOG.md` | Prioritized issue list |
| `CHANGELOG.md` | Release notes |
| `AUDIT.md` | Findings from the current review cycle |
| `docs/audits/YYYY-MM-DD-<scope>.md` | Immutable per-cycle audit snapshot — never overwritten |
| `docs/` (general) | Knowledge docs under `guides/`, `concepts/`, `reference/`, `reports/` |
| `CLAUDE.md` / `AGENTS.md` | Agent instruction file; `AGENTS.md` is a symlink to `CLAUDE.md` |
| `templates/` | Document templates shipped by the skill |
| `scripts/scaffold-docs.sh` | Bootstrap script for new projects |

### Output / Artifacts

- Updated or newly created documents (`AUDIT.md`, `BACKLOG.md`, `ROADMAP.md`, `README.md`,
  `CLAUDE.md`), committed to the repository.
- Never overwrites existing content: the skill appends or merges, and the immutable
  `docs/audits/YYYY-MM-DD-<scope>.md` snapshots are write-once.

### Gate A (mandatory, post-Phase 2)

After the skill completes and files are committed, the conductor:

1. Presents a concise summary of every file written or modified (file path + one-line description).
2. Waits for an **explicit typed affirmative** from the user in this conversation before Phase 3 runs.

Gate A prompt to user:

> 以上文件請確認後，回覆「approved」才進行 Phase 3 — PLAN。

Valid affirmatives: any clear confirmation the user types after seeing the summary (e.g. "approved",
"OK 繼續", "looks good, continue"). A prior verbal OK, "no changes needed", or the conductor's own
judgment that the docs look fine do NOT satisfy Gate A.

### Terminal / Handoff State

Gate A approved. Conductor proceeds to Phase 3 — PLAN.

### Prerequisites

- Phase 1 REVIEW complete (or entered at PLAN with a fresh AUDIT.md from a prior cycle — in that
  case Phase 2 is skipped and Gate A is treated as already satisfied).
- Findings in context or in `.pmc-findings.md`.

---

## Phase 3 — `brainstorming` → `writing-plans`

These two sub-skills run in sequence. Both are invoked via the **Skill tool**.

### Step 3a — `brainstorming`

#### Invocation

```
Skill tool → brainstorming
Idea: "fix all findings in AUDIT.md"
```

The conductor kicks off brainstorming with the idea phrased exactly as above.

#### Gate B — Design + Traditional Chinese stakes explanation (mandatory)

Before `brainstorming` begins any design or spec work, the conductor injects the following
convention (Gate B):

> 先用繁體中文詳細解釋設計決策與 stakes，approve 後才寫 spec/plan。

This means:
- All design decisions and their stakes must be explained in detail in **Traditional Chinese**.
- The user must **explicitly approve** the direction before any spec or plan is written.

`brainstorming` has a built-in HARD-GATE: no implementation starts before approval. Gate B adds
the language and stakes requirement on top of it. The two gates are complementary; neither
satisfies the other.

#### Output / Artifacts

`brainstorming` produces a design direction that the user has approved. No files are committed at
this step; the approved design is carried forward to `writing-plans`.

### Step 3b — `writing-plans`

#### Invocation

Invoked via the **Skill tool** after Gate B approval from `brainstorming`:

```
Skill tool → writing-plans
```

The approved design direction from `brainstorming` is passed as context.

#### Output / Artifacts

- `docs/plans/YYYY-MM-DD-<feature>.md` — the implementation plan document, committed.
- Three execution options presented to the user:
  1. **Subagent-driven** — executes in the current session using parallel subagents.
  2. **Parallel session** — user opens another session to run the plan manually.
  3. **Orchestrator-driven** — generates orchestrator session files for a new dedicated session.

Only the **orchestrator-driven** option flows forward to Phase 4.

### Terminal / Handoff State

- If the user selects orchestrator-driven: conductor proceeds to Phase 4 — ORCHESTRATE.
- If the user selects any other option: the cycle ends at Phase 3; the conductor does not enter Phase 4.

### Prerequisites

- Gate A approved (or skipped as already-satisfied when entering at PLAN with a fresh AUDIT.md).
- `AUDIT.md` exists and contains findings to address.

---

## Phase 4 — `using-git-worktrees` + `orchestrator-driven-development`

These two sub-skills run in sequence. Both are invoked via the **Skill tool**. The worktree MUST
be created and entered before `orchestrator-driven-development` runs.

### Step 4a — `using-git-worktrees`

#### Invocation

```
Skill tool → using-git-worktrees
```

Creates an isolated git worktree for this implementation cycle. After the worktree is created,
the conductor ensures the active working directory is INSIDE the worktree before invoking the
next sub-skill, so all output paths (`docs/sessions/`, `.claude/agents/`) resolve within the
worktree, not the original branch.

#### Output / Artifacts

- A new git worktree on a feature branch, path registered in `git worktree list`.
- Working directory switched into the worktree.

### Step 4b — `orchestrator-driven-development`

#### Invocation

```
Skill tool → orchestrator-driven-development
```

Reads the plan from `docs/plans/YYYY-MM-DD-<feature>.md` (the file produced in Phase 3).

#### Output / Artifacts

Generates and commits the following inside the worktree:

| Path | Description |
|---|---|
| `docs/sessions/orchestrator.md` | Initial prompt for the orchestrator session (paste this to start) |
| `docs/sessions/resume.md` | Resume instructions if the orchestrator session is interrupted |
| `docs/sessions/<role>.md` | One file per executor/reviewer/QA role |
| `docs/sessions/progress.json` | Tracks phase completion state |
| `.claude/agents/<subagent>.md` | Subagent definitions for each implementation agent |

All files are committed inside the worktree before the handoff.

### Terminal Handoff — Breakpoint 2 (mandatory cross-session handoff)

**STOP. Do NOT attempt to run the orchestrator inline — never.**

The conductor's terminal action is a handoff instruction. Tell the user:

> Phase 4 完成。請開啟一個全新的 Claude Code session，並將以下檔案的內容貼入作為第一則訊息：
>
> `docs/sessions/orchestrator.md`
>
> 不要在這個 session 繼續執行 orchestrator — 它必須在全新 session 中啟動。conductor 的工作至此結束，請勿在本 session 繼續任何操作。

### Prerequisites

- Gate B approved.
- `writing-plans` completed and `docs/plans/YYYY-MM-DD-<feature>.md` exists.
- User selected the orchestrator-driven execution option in Phase 3.

---

## Session Boundary Summary

| Breakpoint | Trigger | Conductor action |
|---|---|---|
| **Breakpoint 1** (conditional) | `effort = ultra` in Phase 1 | Stop; give user the `/code-review ultra <scope>` instruction; wait for results before proceeding to Phase 2. |
| **Breakpoint 2** (mandatory) | End of Phase 4 | Stop; instruct user to open a new session with `docs/sessions/orchestrator.md`. Never launch the orchestrator inline. |

---

This file is reference material loaded on demand; SKILL.md is the operating spine.

# `project-maintenance-cycle` Skill — Design Spec

- **Date:** 2026-06-17
- **Status:** Approved (design phase complete; pending implementation plan)
- **Skill type:** Conductor / orchestration skill (discipline-enforcing + complex decision tree)
- **Repo:** `LLMDev/skills/project-maintenance-cycle`
- **Install target:** `~/.claude/skills/project-maintenance-cycle`

---

## 1. 背景與動機

使用者目前用一套**跨 session 的手動專案維護循環**，每輪固定走：

1. 開新 session、`/cd` 進 project root（例：`TENET`）
2. `/code-review [max] [--fix] [--comment] [<scope>]`（例：`/code-review max strategies/grid-trader`）
3. `/maintaining-project-docs` 把 findings 落成 `AUDIT.md` / `BACKLOG.md` / `ROADMAP.md`，並更新 `README.md` / `CLAUDE.md`
4. `/using-superpowers` 以「修復 `AUDIT.md` 全部 findings」啟動設計
5. 要求用**繁體中文**詳細解釋設計決策與 stakes，approve 後才動工
6. 寫 spec 與 design/implementation plan
7. 建新 worktree，`/orchestrator-driven-development` 產生 orchestrator session files
8. 開新 session 跑 orchestrator

**問題**：步驟順序、scope 傳遞、artifact 契約、審核閘門與跨 session 交接全靠人腦記憶與手動重述，容易漏步、錯序、或在錯的時機重跑已存在的 artifact。

**關鍵洞察**：步驟 4–8 其實**已經是現成的自我串接鏈**（`brainstorming → writing-plans → orchestrator-driven-development`）。新 skill 真正要補的膠水主要在**前段（審查 → 把 findings 系統性落檔）**，以及**在 session 邊界做正確交接**。

---

## 2. 目標與非目標

### 目標 (Goals)
- 用**單一 conductor skill** 在一個 session 內驅動 `ORIENT → REVIEW → DOCUMENT → PLAN → ORCHESTRATE`，每階段邊界有明確閘門。
- **智慧偵測**專案現況，支援**從任意階段切入**與**部分循環**（如只 review+document、或 AUDIT 已存在直接 plan）。
- 不重新實作任何子 skill，只在正確時機用 Skill tool 呼叫、傳遞正確 artifact、注入使用者慣例。
- 把容易出錯的約束（`ultra` 為使用者觸發限定、`--fix` 預設關、不盲目覆蓋既有 AUDIT、orchestrator 不可 inline 跑）固化成規則。

### 非目標 (Non-goals)
- **不**自動化跨 session 的「開新 session 跑 orchestrator」這一步（步驟 8 本質上由人開新 session）。
- **不**自己啟動 `/code-review ultra`（雲端、計費、Claude 無法觸發）。
- **不**重述子 skill 的內部邏輯或重複其文件。
- **不**取代 `brainstorming` 的 HARD-GATE；而是委派並注入慣例。

---

## 3. 核心設計決策（已核准）

| 決策 | 結論 | 理由 |
|---|---|---|
| 架構 | 單一 conductor skill | 使用者選定；每 session 只需呼叫一次 |
| 階段切入 | 智慧偵測 + 可部分執行 | 貼合真實使用（AUDIT 常已存在、常只跑半套） |
| 前段 vs 後段 | 前段（0–2）緊密驅動；後段（3–8）委派既有鏈並注入慣例 | `brainstorming→writing-plans→orchestrator` 已自我串接，重寫會與其 HARD-GATE 衝突且違反「不重述子 skill」 |
| 檔案結構 | `SKILL.md` + `references/phase-contracts.md` | progressive disclosure，避免 SKILL.md >500 行 |

---

## 4. 階段狀態機

| Phase | 名稱 | 動作 | 委派 / 工具 | 閘門 |
|---|---|---|---|---|
| 0 | **ORIENT** | 偵測現況、確認參數、決定切入點 | `AskUserQuestion` | — |
| 1 | **REVIEW** | 跑 code-review，擷取 findings | `/code-review`（Skill tool；`ultra` 例外見 §6） | — |
| 2 | **DOCUMENT** | 把 findings 落成 `AUDIT/BACKLOG/ROADMAP` + 更新 `README/CLAUDE` | `maintaining-project-docs` | **Gate A：使用者審文件** |
| 3 | **PLAN** | 以「修復 `AUDIT.md` findings」啟動設計 → 寫 plan | `brainstorming → writing-plans` | **Gate B：繁中解釋設計+stakes 後 approve**（brainstorming HARD-GATE） |
| 4 | **ORCHESTRATE** | 建 worktree + 產生 orchestrator session files | `using-git-worktrees` + `orchestrator-driven-development` | **終點交接**：請使用者開新 session 貼 `orchestrator.md` |

### 階段邊界即 session 邊界
循環天然有兩個 session 斷點，conductor 必須以**顯式交接**處理，而非 inline 強跑：
- **斷點 1（條件性）**：`effort=ultra` 時，code-review 在雲端非同步跑 → conductor 停下等使用者。
- **斷點 2（必然）**：orchestrator 需在全新 session 啟動 → conductor 終點是「交接指示」。

---

## 5. Phase 0 偵測決策樹（智慧切入核心）

conductor 啟動時快掃以下訊號，再用 `AskUserQuestion` 提議切入點：

| 偵測項目 | 偵測方法 | 影響 |
|---|---|---|
| 是否在 PR / branch | `git` 狀態、`gh pr view` | 決定 `--comment` 預設值 |
| `<scope>/AUDIT.md` 或 root `AUDIT.md` 是否存在、是否 stale | 檔案存在 + 最後更新時間 vs 近期 commit | 提議「直接從 PLAN 切入」；fresh 則不覆蓋（先問） |
| `docs/plans/*` 是否已有對應 plan | glob `docs/plans/*.md` | 提議「直接 ORCHESTRATE」 |
| 是否已有 worktree / `docs/sessions/orchestrator.md` | 檔案存在 + `git worktree list` | 提議「已備妥，請開新 session」 |

**Phase 0 一次收齊的參數：**
- `scope`：路徑或整個專案（預設整個專案）
- `effort`：`low` / `medium` / `high` / `max`（預設 `max`）；`ultra` 為使用者觸發限定（見 §6）
- `--fix`：預設 **OFF**
- `--comment`：僅在偵測到 PR 時預設 **ON**
- `phases`：要執行的階段子集（預設依偵測結果提議）

---

## 6. 子 skill 呼叫契約（將細列於 `references/phase-contracts.md`）

### 6.1 `/code-review`（內建 CLI skill，非官方 plugin）
- **介面**：`/code-review [effort] [--fix] [--comment] [<scope>]`
- **effort 語意**：`low`/`medium` 少而高信心；`high`→`max` 廣覆蓋、可能含不確定 findings；`ultra` 雲端多代理深審。
- **`--fix`**：把 findings 套用回工作目錄（維護循環預設 **不用**，留待 Phase 3 審慎規劃）。
- **`--comment`**：把 findings 發為 PR 行內留言（僅在有 PR 時）。
- **`ultra` 約束**：雲端、計費、**使用者觸發限定**。conductor **不得**自行啟動；遇 `effort=ultra` 須**停下、請使用者自跑 `/code-review ultra <scope>`、等結果回來後從 Phase 2 續跑**。
- **產出**：findings 清單（非檔案）。conductor 將其作為 Phase 2 的 `AUDIT.md` 輸入內容（必要時暫存於 `$CLAUDE_JOB_DIR/tmp` 或保留於 context）。

### 6.2 `maintaining-project-docs`
- **介面**：吃 freeform 指令（非 slash flags）。
- **管理範圍**：`ROADMAP/BACKLOG/CHANGELOG/AUDIT` + `docs/`（含 `docs/audits/YYYY-MM-DD-<scope>.md` 不可變報告）+ `CLAUDE.md`/`AGENTS.md`；附 `templates/` 與 `scripts/scaffold-docs.sh`。
- **conductor 注入的指令模板**（對齊使用者步驟 3）：
  > `update README.md/CLAUDE.md for <scope> and create AUDIT.md/BACKLOG.md/ROADMAP.md for the findings.`
- **產出**：更新/新建文件並 commit（不覆蓋既有內容）。
- **Gate A**：完成後請使用者審閱生成文件再繼續。

### 6.3 `brainstorming → writing-plans`（PLAN）
- conductor 以使用者步驟 4 的框架啟動：「**fix all findings in `AUDIT.md`**」。
- **Gate B 慣例注入**：明確要求「**先用繁體中文詳細解釋設計決策與 stakes，approve 後才寫 spec/plan**」（對齊步驟 5）。
- `brainstorming` 內建 HARD-GATE（approve 前不動工）→ terminal 為 `writing-plans`。
- `writing-plans` 產出 `docs/plans/YYYY-MM-DD-<feature>.md`，並提供三種執行選項（其一為 orchestrator）。

### 6.4 `using-git-worktrees` + `orchestrator-driven-development`（ORCHESTRATE）
- 使用者於 `writing-plans` 選 orchestrator 選項後：建 worktree（步驟 7）+ `orchestrator-driven-development` 讀 plan、產生 `docs/sessions/`（`orchestrator.md` / `resume.md` / 角色檔 / `progress.json`）與 `.claude/agents/` subagent 定義並 commit。
- **conductor 終點**：告知使用者**開新 session 並貼上 `docs/sessions/orchestrator.md`** 啟動（步驟 8，超出本 skill 範圍）。**絕不嘗試 inline 跑 orchestrator。**

---

## 7. 關鍵約束（必寫進 SKILL.md）

1. **`ultra` = 使用者觸發限定**：雲端、計費、Claude 不能啟動 → 必須停下交接、等待、續跑。
2. **`--fix` 預設關**：維護循環精神是審慎規劃修復，不自動套用。
3. **`--comment` 僅在有 PR 時**預設開。
4. **不盲目重跑已有 artifact 的階段**：偵測到 fresh `AUDIT.md` 不覆蓋，先問。
5. **跨 session 邊界是顯式交接**：`ultra` 等待、orchestrator 開新 session。
6. **Gate B 慣例注入**：委派 brainstorming 時要求繁中解釋設計與 stakes 後才 approve。
7. **不重述子 skill**：只說「呼叫 X，它會做 Y」，不複製其內部規則。

---

## 8. 閘門 (Gates) 總覽

| 閘門 | 位置 | 要求 |
|---|---|---|
| **Gate A** | Phase 2 之後 | 使用者審閱 `AUDIT/BACKLOG/ROADMAP/README/CLAUDE` 變更後才進 Phase 3 |
| **Gate B** | Phase 3 內（brainstorming HARD-GATE） | 繁中詳細解釋設計決策與 stakes，使用者 approve 後才寫 spec/plan |
| **終點交接** | Phase 4 之後 | conductor 不開新 session；明確指示使用者手動啟動 orchestrator |

---

## 9. Skill 檔案結構（progressive disclosure）

```
~/.claude/skills/project-maintenance-cycle/
  SKILL.md                      # Overview + 階段狀態機 + Phase 0 偵測決策樹 + 閘門 + 終點交接 + red flags
  references/
    phase-contracts.md          # 每個子 skill 的精確呼叫契約與 artifact（含 ultra 限制、
                                # maintaining-project-docs 指令模板、brainstorming/writing-plans/orchestrator handoff）
```

- SKILL.md 控制在 ~500 行內；偵測清單若夠短可 inline。
- 跨 skill 引用一律用顯式標記（`**REQUIRED SUB-SKILL:** ...`），**不用** `@` 連結（會 force-load 燒 context）。

---

## 10. 命名與呼叫介面

- **名稱**：`project-maintenance-cycle`（CSO 清楚）。可另建短 alias 符號連結（如 `pmc`）。
- **呼叫**：`/project-maintenance-cycle [<scope>] [effort] [flags]`
  - 例：`/project-maintenance-cycle strategies/grid-trader max`
  - 亦支援 freeform：「對 grid-trader 跑維護循環，max effort，只 review+document」。
- **description（frontmatter，CSO 導向）**草案：
  > `Use when running a project maintenance cycle on a project or scope — code review → document findings (AUDIT/BACKLOG/ROADMAP) → plan fixes → orchestrate implementation. Detects current cycle state and enters at the right phase; supports partial runs (review-only, document-only, plan-from-existing-AUDIT).`

---

## 11. Red Flags / Anti-patterns（寫進 SKILL.md）

- ❌ 自行啟動 `/code-review ultra`。
- ❌ 跳過 Gate B 的設計審核。
- ❌ 覆蓋既有 fresh `AUDIT.md` 而未先問。
- ❌ 嘗試 inline 跑 orchestrator（需新 session）。
- ❌ 重述/複製子 skill 的內部邏輯。
- ❌ 預設帶 `--fix`。

---

## 12. 驗證計畫

本 skill 屬「紀律強制 + 複雜決策樹」型 → `writing-skills` 要求**必須驗證**。以子代理跑代表情境：
1. **全新專案完整循環**：ORIENT→REVIEW(max)→DOCUMENT→Gate A→PLAN→ORCHESTRATE handoff，確認每閘門生效、終點為交接指示。
2. **AUDIT 已存在的部分切入**：偵測到 fresh `AUDIT.md`，提議直接 PLAN，不覆蓋既有檔。
3. **`effort=ultra` 交接行為**：conductor 停下、給出「請自跑 `/code-review ultra` 並回來」指示，不嘗試自啟動。

**成功判準**：每情境下 conductor 在正確階段切入、守住閘門、正確委派子 skill、遇 `ultra` 與 orchestrator 都做顯式交接而非自動執行。

---

## 13. Out of Scope / YAGNI

- 自動開新 session 跑 orchestrator（步驟 8 由人執行）。
- 自動觸發雲端 `ultra`。
- 多專案批次循環（一次一專案/scope）。
- 任何子 skill 的功能修改（本 skill 只編排，不改動它們）。

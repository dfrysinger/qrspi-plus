---
status: draft
question_ids: [27]
research_type: codebase
---

# Q27: Artifact Sizes Emitted and Dispatched Across Historical QRSPI Runs

## Summary

**TL;DR:** Four QRSPI runs reside under `docs/qrspi/`. The largest single artifact in any run is `2026-05-17-v07-release/plan.md` at 233,758 bytes (1,320 lines), followed by the same run's `design.md` at 130,786 bytes and `research/summary.md` at 75,094 bytes. The `2026-05-30-v072-release` run carries the heaviest `goals.md` (91,131 bytes) and `research/summary.md` (87,113 bytes). The only documented ad-hoc size-adjustment found in commit messages and review artifacts is in the v072 run: reviewer dispatch for `research/summary.md` used `artifact_path` (path-based) rather than the standard inline `artifact_body` wrapping, explicitly because the file was 87 KB — this usage seeded G29 in v072 goals.md.

**Key findings:**
- `2026-04-29-v0.4-bundle` produced only `goals.md` (35,436 B), `questions.md` (6,628 B), and individual `research/q*.md` files (5,930–24,895 B each); no `research/summary.md`, `design.md`, `structure.md`, `plan.md`, or `parallelization.md` exist in that run.
- `2026-05-17-v07-release` holds the largest overall artifacts: `plan.md` 233,758 B / 1,320 lines, `design.md` 130,786 B / 1,240 lines, `structure.md` 43,665 B, `research/summary.md` 75,094 B, `parallelization.md` 21,756 B, `goals.md` 37,318 B.
- `2026-05-27-v071-hardening` is the most compact full-pipeline run: `plan.md` 41,540 B / 288 lines, `design.md` 17,424 B / 183 lines, `structure.md` 17,541 B, `research/summary.md` 37,485 B, `parallelization.md` 7,924 B.
- `2026-05-30-v072-release` (in-progress at measurement time): `goals.md` 91,131 B, `questions.md` 12,701 B, `research/summary.md` 87,113 B / 432 lines; `design.md`, `structure.md`, `plan.md`, and `parallelization.md` are absent (not yet produced).
- In v072, the research reviewer was dispatched via `artifact_path` instead of inline `artifact_body` for the 87 KB `summary.md` — explicitly documented in commit `45625ed` and goals.md G29 / issue #262 (PI-012). This is the only ad-hoc large-artifact handling found in commit messages or review artifacts across all four runs.
- No commit messages or reviewer dispatch notes for the v07 233 KB `plan.md` or 130 KB `design.md` reference size-driven ad-hoc handling; those artifacts went through 18-round (design) and 6-round (plan, plus supplement) review cycles without documented size-specific dispatch adjustments.
- `quality-codex.R2-F01` in v072 goals review flagged "27 goals too large for one run" (advisory intent finding) but this was OVERRULED — it referred to goal count/scope, not file byte size.

**Surprises:** The v07-release `plan.md` at 233 KB is more than 5× the size of the same artifact in the v071-hardening run (41 KB), reflecting the dramatically different task scope (43 tasks vs. 10 tasks). The v072 `goals.md` at 91 KB is nearly 2.5× the largest goals.md from any other run, making it the heaviest goals artifact in the dataset. Despite the v07 plan.md being by far the largest artifact, no ad-hoc dispatcher adjustments for it appear in any commit message — only the much smaller 87 KB v072 `summary.md` triggered a documented path-based dispatch switch.

**Caveats:** The `2026-04-29-v0.4-bundle` and `2026-05-30-v072-release` are incomplete pipelines (v0.4-bundle stopped after research/reviews; v072 is mid-run at time of measurement). The v072 Q27 research file itself is absent from the repository at measurement time (this report is being written now). Byte sizes were measured with `wc -c` from on-disk files; any in-flight edits between measurement and commit may shift values by a few bytes. Git log searches used `--grep` with targeted patterns; commits using workaround prose that doesn't match those patterns would be missed.

---

## Full findings

### Survey of all run directories

Four run directories exist under `docs/qrspi/`:

| Run directory | Date | Type |
|---|---|---|
| `2026-04-29-v0.4-bundle` | 2026-04-29 | v0.4 issues bundle |
| `2026-05-17-v07-release` | 2026-05-17 | v0.7 full release |
| `2026-05-27-v071-hardening` | 2026-05-27 | v0.7.1 hardening |
| `2026-05-30-v072-release` | 2026-05-30 | v0.7.2 release (in-progress) |

---

### Artifact byte sizes — core pipeline files

The seven canonical artifacts surveyed per run. `ABSENT` means the file does not exist in that run.

| Artifact | v0.4-bundle | v07-release | v071-hardening | v072-release |
|---|---|---|---|---|
| `goals.md` | 35,436 B | 37,318 B | 27,548 B | 91,131 B |
| `questions.md` | 6,628 B | 6,268 B | 4,310 B | 12,701 B |
| `research/summary.md` | ABSENT | 75,094 B | 37,485 B | 87,113 B |
| `design.md` | ABSENT | 130,786 B | 17,424 B | ABSENT |
| `structure.md` | ABSENT | 43,665 B | 17,541 B | ABSENT |
| `plan.md` | ABSENT | 233,758 B | 41,540 B | ABSENT |
| `parallelization.md` | ABSENT | 21,756 B | 7,924 B | ABSENT |

Line counts for the largest files (measured with `wc -l`):

| File | Lines |
|---|---|
| `2026-05-17-v07-release/plan.md` | 1,320 |
| `2026-05-17-v07-release/design.md` | 1,240 |
| `2026-05-30-v072-release/research/summary.md` | 432 |
| `2026-05-17-v07-release/research/summary.md` | (not separately measured; ~75 KB) |
| `2026-05-27-v071-hardening/plan.md` | 288 |
| `2026-05-27-v071-hardening/design.md` | 183 |

---

### Individual research file sizes by run

#### 2026-04-29-v0.4-bundle (13 files, grouped q-files, no summary.md)

| File | Bytes |
|---|---|
| `q01-q26-codebase.md` | 20,163 |
| `q02-web.md` | 5,930 |
| `q03-codebase.md` | 14,166 |
| `q04-web.md` | 11,803 |
| `q05-q06-codebase.md` | 18,210 |
| `q07-q08-web.md` | 16,844 |
| `q09-q10-q23-q28-codebase.md` | 24,895 |
| `q11-q12-web.md` | 20,175 |
| `q13-q19-q25-codebase.md` | 21,100 |
| `q14-q20-web.md` | 24,495 |
| `q15-q17-q24-codebase.md` | 19,152 |
| `q16-q18-q22-q27-web.md` | 17,569 |
| `q21-codebase.md` | 15,806 |

Range: 5,930–24,895 B per file. Grouped-question files (up to 4 questions each) reflect the v0.4 multi-question grouping strategy.

#### 2026-05-17-v07-release (21 q-files + summary.md)

| File | Bytes |
|---|---|
| `summary.md` | 75,094 |
| `q04-web.md` | 29,092 |
| `q08-codebase.md` | 31,439 |
| `q03-codebase.md` | 28,552 |
| `q18-codebase.md` | 22,178 |
| `q09-web.md` | 20,175 |
| `q22-web.md` | 17,934 |
| `q31-codebase.md` | 17,331 |
| `q15-codebase.md` | 17,608 |
| `q06-codebase.md` | 18,226 |
| `q02-web.md` | 16,362 |
| `q12-codebase.md` | 18,490 |
| `q01-codebase.md` | 20,987 |
| `q25-web.md` | 15,999 |
| `q10-codebase.md` | 15,218 |
| `q20-codebase.md` | 15,187 |
| `q13-codebase.md` | 15,706 |
| `q11-web.md` | 13,436 |
| `q24-codebase.md` | 13,679 |
| `q23-codebase.md` | 9,853 |
| `q17-codebase.md` | 6,357 |

Range: 6,357–31,439 B per q-file. Summary: 75,094 B.

#### 2026-05-27-v071-hardening (12 q-files + summary.md)

| File | Bytes |
|---|---|
| `summary.md` | 37,485 |
| `q12-web.md` | 18,365 |
| `q02-web.md` | 15,929 |
| `q05-codebase.md` | 15,000 |
| `q11-codebase.md` | 14,175 |
| `q10-codebase.md` | 13,810 |
| `q08-codebase.md` | 13,290 |
| `q09-web.md` | 11,514 |
| `q06-codebase.md` | 11,753 |
| `q07-codebase.md` | 9,659 |
| `q04-codebase.md` | 6,465 |
| `q03-codebase.md` | 6,229 |
| `q01-codebase.md` | 5,787 |

Range: 5,787–18,365 B per q-file. Summary: 37,485 B.

#### 2026-05-30-v072-release (23 q-files + summary.md)

| File | Bytes |
|---|---|
| `summary.md` | 87,113 |
| `q18-web.md` | 25,630 |
| `q10-codebase.md` | 17,189 |
| `q11-codebase.md` | 16,347 |
| `q07-codebase.md` | 16,449 |
| `q19-codebase.md` | 14,602 |
| `q14-codebase.md` | 13,272 |
| `q15-codebase.md` | 12,723 |
| `q17-web.md` | 12,351 |
| `q22-codebase.md` | 13,764 |
| `q23-codebase.md` | 13,749 |
| `q01-codebase.md` | 12,249 |
| `q20-codebase.md` | 11,429 |
| `q16-codebase.md` | 12,018 |
| `q04-codebase.md` | 10,007 |
| `q05-codebase.md` | 9,962 |
| `q21-codebase.md` | 9,063 |
| `q03-codebase.md` | 9,110 |
| `q08-codebase.md` | 9,462 |
| `q13-codebase.md` | 8,311 |
| `q06-codebase.md` | 8,872 |
| `q12-codebase.md` | 6,572 |
| `q09-codebase.md` | 5,996 |
| `q02-codebase.md` | 5,925 |

Range: 5,925–25,630 B per q-file. Summary: 87,113 B / 432 lines.

---

### Reviewer dispatch logs and commit messages referencing size adjustments

#### Ad-hoc path-based dispatch for v072 research/summary.md (87 KB)

The only documented large-artifact dispatch adjustment found is in the v072 run. The standard reviewer dispatch protocol passes artifacts inline as `artifact_body` (wrapped between `<<<UNTRUSTED-ARTIFACT-START>>>` / `<<<UNTRUSTED-ARTIFACT-END>>>` fences). For the v072 `research/summary.md` (87 KB / 432 lines), the research reviewers were instead dispatched using `artifact_path` (a path-based parameter that lets the reviewer subagent Read the file directly).

Evidence:
1. **Commit `45625ed` (2026-05-30)** — `research: approve (R2 clean × 2 reviewers)`: "quality-claude (sonnet-4.6, task tool): zero findings ... quality-codex (gpt-5.3-codex, task-tool model override): NO_FINDINGS sentinel; persisted by orchestrator (PI-002 recurrence — chat-only return). Codex dispatch path used task-tool model override directly because scripts/run-codex-review.sh fails on Copilot CLI host (PI-008 — script claims [transport: task-tool] but delegates to run-third-party-llm.sh which requires providers: block)."
2. **Goals/round-04.diff** — G29 problem statement: "Per-skill reviewer dispatch contracts ... all specify the artifact under review is passed to the reviewer subagent as a wrapped inline body ... This works for small artifacts but breaks down at scale — `research/summary.md` in v0.7.2 self-host was 87 KB / 432 lines, and wrapping it inline in every reviewer dispatch loads the full body into orchestrator tool-call args, bloats every dispatch payload, and re-bills as cache reads on every subsequent orchestrator turn."
3. **Goals/round-04.diff "What we know so far"**: "Source: #262 (PI-012), v0.7.2 self-host commit `45625ed research: approve (R2 clean × 2 reviewers)` — research R1+R2 used artifact_path against 87 KB summary.md"
4. **Commit `1e3f48f` (2026-05-30)** — `goals: amend for PI-010/011/012 (G6 sharpen, +G28, +G29)`: "G29 (new): canonize artifact_path dispatch parameter for >N KB artifacts; rationale rests on R1/R2 research-review use against 87 KB summary.md; 3 candidates for Design."
5. **Goals/round-04/scope-claude.finding-F01.md** cites: "v0.7.2 self-host applied the path-based form for research R1+R2 (87 KB artifact) with no fidelity loss observed."

The `artifact_path` capability itself was shipped in commit **`4b4c34d` (2026-05-14)**: "feat(research): switch Claude reviewer dispatch to path-based companion_qfile_paths (G4)" — this updated `skills/research/SKILL.md` and `agents/qrspi-research-reviewer.md` to use path-based dispatch for the per-q-file companions.

#### quality-codex.R2-F01 in v072 goals review: "27 goals too large for one run"

File: `docs/qrspi/2026-05-30-v072-release/reviews/goals/round-02/quality-codex.finding-F01.md`

Codex flagged the 27-goal artifact as potentially too large for a single downstream pipeline cycle. The disposition (`round-02-dispositions.md`) records: "quality-codex.R2-F01 (27 goals too large) | intent | 30 | KEEP (intent always kept) → OVERRULE". The overrule rationale: "The 27 goals were user-pre-scoped to the v0.7.2 milestone ... Phasing will decompose the 27 goals into multiple phases via `roadmap.md`." This is a scope/count concern, not a byte-size dispatch concern.

#### v07-release large plan.md and design.md: no size-driven dispatch adjustments found

The v07-release `plan.md` (233,758 B, 1,320 lines) went through 6 review rounds (plus a supplement round). The `design.md` (130,786 B, 1,240 lines) went through 18 review rounds plus a supplement. Neither the plan review fix logs (`reviews/plan/round-{01-06}-fixes.md`) nor the design review dispositions (`reviews/design/round-{01-18}-dispositions.md`) contain any reference to byte-size-driven dispatch changes or ad-hoc context handling for those artifacts. The plan round-03-fixes.md notes line counts ("Plan.md line delta: 1304 → 1308") and round-05-fixes.md notes "plan_lines_after: 1320", but these are standard review-loop tracking, not size-mitigation measures.

The v07 implement-summary.md (`docs/qrspi/2026-05-17-v07-release/implement-summary.md`) records operator-directed pragmatic simplifications (no per-task reviewer fanout, no worktrees, no fix-loop), but these were cost/time directives from the user, not responses to artifact file size.

#### v07-release plan.md was imported in bulk, not reviewed line-by-line in-repo

The entire v07 bundle was committed in a single import: **`0ada5cd` (2026-05-28)** — "docs: import v0.7 release QRSPI artifact bundle (#207)". The commit message notes: "Imports the complete v0.7 QRSPI pipeline artifact bundle from agent-bravo's claude-workspace working tree into the repo for historical record." This means the v07 artifacts were produced in a separate workspace; the in-repo commit is a retrospective import, not the live dispatch site.

#### v071-hardening plan.md approval

Commit **`b640802` (2026-05-28)** — "qrspi(v0.7.1-hardening): approve plan.md after 9-round dual-review convergence": "Plan converged at R9 with 14/14 reviewers clean across Claude (sonnet) + Codex (gpt-5.3-codex) panels. Convergence: R3=20 -> R4=11 -> R5=5 -> R6=2 -> R7=1 -> R8=1 -> R9=0." No size-adjustment notes in this commit message.

#### .qrspi/audit-codex-review.jsonl (v0.4-bundle)

The v0.4-bundle contains a `.qrspi/audit-codex-review.jsonl` file (119 bytes) with a single entry: `{"job_id":"task-moq61cqz-txurmz","elapsed_seconds":1,"completion_status":"success","timestamp":"2026-05-03T19:34:01Z"}`. No size-related fields.

---

### Summary of git log searches

Searches performed with `git --no-pager log --all --grep=<pattern>`:

| Pattern | Relevant results |
|---|---|
| `"size"` | No size-adjustment hits; matched unrelated commits |
| `"large"` | Matched `1e3f48f goals: amend for PI-010/011/012 (G6 sharpen, +G28, +G29)` |
| `"truncat"` | No QRSPI-artifact-size hits |
| `"token"` | Matched implementation commits; no dispatch-size hits |
| `"artifact.path"` | Matched `4b4c34d feat(research): switch Claude reviewer dispatch to path-based companion_qfile_paths (G4)` |
| `"PI-012"` | Matched `1e3f48f goals: amend for PI-010/011/012` |
| `"artifact_path"` | Same as above; also `dfe5ed0 goals: apply R4-F01 scope fix` |
| `"plan.md"` | Matched `53f96f4 materialize approved plan tasks`, `b640802 approve plan.md after 9-round`, `0ada5cd docs: import v0.7 release QRSPI artifact bundle` |
| `"design.md"` | Matched `0ada5cd` import, `367de67 approve design.md after 3-round dual review` |

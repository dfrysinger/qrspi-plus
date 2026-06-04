---
reviewer_tag: goal-traceability-claude
round: 4
status: clean
task: 19
goal_ids: [G27]
---

# Goal Traceability Review — Round 4 (Deep-Mode Pass)

## Verdict

**CLEAN.** The T19 delta presents an unbroken traceability chain from G27 through all nine task-19.md DoD items, through tests, through implementation. No DoD item is unimplemented. No test is untethered to a DoD item. No implementation behavior is unanchored to the spec or goal.

---

## 1. Forward Trace: G27 → plan.md → task-19.md → Tests → Implementation

### Goal anchor

`goals.md` ### G27 (lines 774–800): The Goals skill inlines a Claude-only filesystem glob (`~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs`) that silently opts out every Copilot CLI operator from Codex reviews; the host-aware canonical helper (`check_codex_available` in `run-codex-review.sh`) already handles this correctly on all hosts. The goal is to eliminate the inline glob, replace it with a vendor-neutral probe, and sweep the `codex_reviews:` → `second_reviewer:` rename across all consumer surfaces.

### plan.md anchor

`plan.md` Slice 1.4 names Task 19 as "G27 `second-reviewer-available.sh` helper, `_host-detect.sh` primitive, and Goals consumer migration". `task-19.md` frontmatter carries `goal_ids: [G27]`.

### Per-DoD traceability

| DoD Item | Test(s) | Implementation |
|---|---|---|
| 1. `_host-detect.sh` safe to source under `QRSPI_SOURCE_ONLY=1`, env-signal-only detection, returns `copilot-cli`/`claude-code`/`unknown` | `_host-detect: safe to source under QRSPI_SOURCE_ONLY=1`, `_host-detect: COPILOT_CLI=1 returns copilot-cli`, `_host-detect: CLAUDE_PROJECT_DIR set returns claude-code`, `_host-detect: no known signal returns unknown`, `_host-detect: performs no filesystem probes` | `_host-detect.sh` lines 28–38 (env-signal branches), lines 44–46 (QRSPI_SOURCE_ONLY guard) |
| 2. `second-reviewer-available.sh` executable, optional vendor override, delegates to `_host-detect.sh` + `_resolve-lib.sh` (no local table) | `second-reviewer-available: file exists`, `file is executable`, `shared-source-guard: …sources or references _resolve-lib.sh`, `shared-source-guard: …no inline host×vendor case`, `shared-source-guard: …references _host-detect.sh` | `second-reviewer-available.sh` lines 32–37 (sources both libraries), no inline host×vendor case statement |
| 3. Probe exits 0 for Copilot CLI and Claude Code (matrix default = `openai-codex` for both) | `Copilot CLI default path exits 0`, `Claude Code default path exits 0` | `lookup_default_second_reviewer` in `_resolve-lib.sh` lines 201–208; `second_reviewer_vendor_known('openai-codex')` returns 0 |
| 4. Unknown host / missing default / unknown vendor / unavailable vendor → exit non-zero, exactly one `[second-reviewer-unavailable]` stderr line naming host + vendor | `unknown host exits non-zero`, `unknown host emits exactly one [second-reviewer-unavailable] stderr line`, `diagnostic names detected host`, `diagnostic names requested vendor`, `unknown vendor override exits non-zero`, `unknown-host-guard: recognized vendor override exits non-zero`, `empty-default-vendor-guard: empty lookup result exits non-zero` | `second-reviewer-available.sh` lines 55–58 (guard condition + single-line printf to stderr) |
| 5. `skills/goals/SKILL.md` and `skills/using-qrspi/SKILL.md` contain no Claude-only Codex glob; use `bash scripts/second-reviewer-available.sh` | `grep-audit: skills/goals/SKILL.md does not contain Claude-only Codex availability glob`, `grep-audit: skills/goals/SKILL.md references scripts/second-reviewer-available.sh`, `grep-audit: skills/using-qrspi/SKILL.md does not contain Claude-only Codex availability glob`, `grep-audit: skills/using-qrspi/SKILL.md references scripts/second-reviewer-available.sh` | diff: both SKILL files updated (Codex glob removed, `bash scripts/second-reviewer-available.sh` added at detection site) |
| 6. `skills/using-qrspi/SKILL.md` documents `second_reviewer:` as canonical; rejects legacy `codex_reviews:` with rename-naming diagnostic (no silent alias) | `config-field-naming: using-qrspi documents second_reviewer: as the canonical field`, `config-field-naming: config-validation prose rejects legacy codex_reviews: with rename-naming error` | diff: field-definitions table (`second_reviewer:` canonical + `codex_reviews:` hard-error entry), Config Validation section (explicit reject menu), `^codex_reviews:` absent from template |
| 7. `skills/reviewer-protocol/SKILL.md` contains no `codex_reviews`; Expected-Reviewer Matrix uses `second_reviewer: true\|false` | `grep-audit: skills/reviewer-protocol/SKILL.md contains no codex_reviews field references`, `grep-audit: skills/reviewer-protocol/SKILL.md Expected-Reviewer Matrix uses second_reviewer column headers` | diff: single hunk replaces `codex_reviews: true / false` column headers with `second_reviewer: true / false` |
| 8. Routing-matrix coverage: `second_reviewer: true` same-tier dispatch documented; `[second-reviewer-unavailable]` halt fires when no eligible second reviewer | `using-qrspi: second_reviewer: true dispatch uses same tier for primary and second reviewer`, `_resolve-lib.sh [exec]: [second-reviewer-unavailable] halt fires when default vendor is none (unknown host)`, `_resolve-lib.sh [exec]: [second-reviewer-unavailable] halt diagnostic names host and vendor` | `resolve_second_reviewer_vendor` in `_resolve-lib.sh` lines 237–257; diff: using-qrspi prose updated at Second-model-reviewer detection section ("reuses the resolved `tier:` for both") |
| 9. `_resolve-lib.sh` halts loudly with `[second-reviewer-same-vendor]` when primary == second-reviewer vendor; emits zero stdout lines | `_resolve-lib.sh: contains [second-reviewer-same-vendor] halt diagnostic`, `_resolve-lib.sh [exec]: [second-reviewer-same-vendor] halt fires when primary and second vendor are equal`, `[second-reviewer-same-vendor] halt emits no stdout dispatch spec lines`, `[second-reviewer-same-vendor] halt diagnostic names primary and second vendor` | `resolve_second_reviewer_vendor` lines 248–252 (`same-vendor` branch, zero stdout, return 1) |

---

## 2. Backward Trace: Implementation → Test → Spec → Goal

Every public function and behavior introduced in the delta traces cleanly:

- **`detect_host`** (`_host-detect.sh`) → source-safety + host-signal tests → DoD item 1 → G27.
- **`second_reviewer_vendor_known`** (`_resolve-lib.sh`) → probe executability / override-boundary tests → DoD item 2 → G27.
- **`lookup_default_second_reviewer`** (`_resolve-lib.sh`, pre-existing matrix function, no change) → matrix column tests in `test-routing-matrix-application.bats` → DoD items 3, 4 → G27.
- **`resolve_second_reviewer_vendor`** (`_resolve-lib.sh`) → `[second-reviewer-unavailable]` and `[second-reviewer-same-vendor]` halt tests → DoD items 8, 9 → G27.
- **`second-reviewer-available.sh`** (probe entry point) → executability, behavior, override-boundary, shared-source-guard, unknown-host-guard, empty-vendor-guard tests → DoD items 2–4 → G27.
- **Skills prose changes** (goals/SKILL.md, using-qrspi/SKILL.md, reviewer-protocol/SKILL.md) → grep-audit and config-field-naming tests in `test-dispatch-companion-availability.bats` → DoD items 5–7 → G27.

No behavior was found that could not be traced to a DoD item and to G27. No YAGNI signals.

---

## 3. Gap Analysis

All nine DoD items are implemented and covered. All nine test-expectation bullets in task-19.md map to one or more concrete bats tests across the three named test surfaces:

- `tests/unit/test-second-reviewer-available.bats` (new): DoD items 1–4 + override boundary + shared-source guard.
- `tests/unit/test-dispatch-companion-availability.bats` (new): DoD items 5–7 (grep audits, config-field naming).
- `tests/unit/test-routing-matrix-application.bats` (extended): DoD items 8–9 (matrix column values, `[second-reviewer-unavailable]` halt, `[second-reviewer-same-vendor]` halt, same-tier dispatch prose).

No acceptance criterion from task-19.md's DoD or test-expectations block is left uncovered.

---

## 4. Spec-to-Test Fidelity

Each test expectation in task-19.md was cross-checked against its realized test(s):

- **Source-safety and host-signal tests** — tests assert exact return values (`copilot-cli`, `claude-code`, `unknown`), exact stdout (`[ -z "$output" ]`), and exact exit status. Edge case: `CODEX_CLI=1` with no copilot/claude signal is covered by a separate test pinning the v0.7.2 shipped behavior (`unknown`), and the deferred `codex-cli` return is explicitly `skip`-ped with a rationale comment.
- **Executability and behavior tests** — file-presence, `chmod +x`, exit-0 for Copilot CLI and Claude Code defaults, exit-1 for unknown host / unknown vendor, exactly-one-stderr-line checks, diagnostic names `host=` and `vendor=`.
- **Override-boundary tests** — three cases: recognized vendor accepted (`openai-codex`, `anthropic-claude`), `CONFIG_MD` unset has no effect, and probe ignores primary/second distinctness (reachability only).
- **Shared-source guard** — two grep-based assertions: probe references `_resolve-lib.sh` (positive match) and probe carries no inline `claude-code` or `copilot-cli` vendor case statement (negative match).
- **Grep audits** — five `grep -c … = 0` / `grep -q …` assertions pin the absence of the old Codex glob and the presence of the new probe reference in both skills.
- **Config-validation tests** — `grep -qE 'renamed.*second_reviewer|…'` pins the rename-naming reject prose; `grep -cE '^codex_reviews:'` = 0 pins the template clean-up.
- **`test-routing-matrix-application.bats`** additions — behavioral execution via `resolve_second_reviewer_vendor` in a sourced context (not just a grep probe), checking exit status, stderr content, and zero stdout on halt. The same-tier dispatch coverage is prose-pinned per the task spec's stated boundary (actual fan-out dispatch belongs to T20).

All tests assert the right behavior (not just "no error") with precise value checks or line-count assertions. Edge cases named in the spec — empty default vendor, unrecognized host with recognized vendor override, `none` vendor default — all have dedicated test cases.

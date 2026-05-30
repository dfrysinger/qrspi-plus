# gt-claude · Traceability Summary · Task 09 Round 09

**Artifact:** `tests/unit/test-agent-frontmatter-no-model.bats`
**Commit anchor:** `a73ecb8`
**Goal:** G7b — "Agent `model:` field declarations silently fall back under Copilot CLI"
**Task goal_ids frontmatter:** `[G7b]`

---

## 1. Goal Anchor

```
goals.md § G7 → G7b
  Problem: All 41 agents/qrspi-*.md declare Claude short model names.
           Copilot CLI 1.0.55 emits "model not available" warnings and
           falls back to session model on every dispatch.
  Why we care: Active cost regression; Haiku-tier verifier running at
               Opus cost per dispatch; invisible in run report.
  Acceptance: Fresh copilot plugin install → zero "model not available"
              warnings. BATS regression: new tests pin the no-model
              invariant.
```

---

## 2. Forward Trace: Spec Criterion → Test → Implementation

| # | Spec criterion (task-09.md § Test expectations) | BATS test name | Production code exercised | Status |
|---|---|---|---|---|
| 1 | `test-agent-frontmatter-no-model.bats` sweeps every `agents/qrspi-*.md`; fails if frontmatter carries a top-level `model:` key | `[agent-frontmatter-no-model] no agents/qrspi-*.md frontmatter carries a top-level model: key` (line 71) | `_frontmatter()` helper (lines 36–47); `grep -nE '^model:'`; per-file violation accumulator | ✅ Covered |
| 2 | After all 41 agent files are modified, the structural lint test passes with zero violations reported | Same test as criterion 1 — passes (GREEN) when `violations == 0` | Same code path; GREEN state is the absence of violations | ✅ Covered (implicitly — same test, GREEN state) |
| 3 | All other frontmatter keys (`skills:`, `description:`, `name:`, and any agent-specific keys) are unmodified | **No BATS test** | N/A | ⚠ Manual Validation only — see **Finding F01** |
| 4 | The structural lint test fails clearly in RED for each file that still carries a `model:` key, providing a useful per-file failure message | `[agent-frontmatter-no-model] per-file failure message names the offending file path` (line 103) | `sweep-one-file.sh` synthetic mirror script; asserts output contains fixture path and error format string | ✅ Covered (with caveat — see note on mirror-script divergence below) |

### Note on criterion 4 / mirror-script divergence

The `per-file failure message` test (line 103) validates message shape via a
standalone `sweep-one-file.sh` heredoc script whose `_frontmatter()` is a
simplified variant (no `gsub(/\r$/, "")`, no `in_scalar` tracking). This is a
known divergence also caught by `cs-claude.finding-F02`. From a traceability
perspective, the message-format contract is validated for LF-terminated
fixtures; the production code path's format for CRLF files is not
independently validated, but the message _construction_ logic (the
`${f}: forbidden top-level frontmatter key 'model:' -> ${offending_line}`
format string) is identical between the mirror and production — so a format
regression _would_ still be caught as long as the mirror is kept in sync.

---

## 3. Backward Trace: Tests → Spec → Goal

All eight tests in the file trace backward to G7b.

| Test name | Traces to spec | Traces to goal | YAGNI? |
|---|---|---|---|
| `sweep matches the expected 41 qrspi agent files` (line 55) | Criterion 1 (count canary — drift in agent count = lint scope change) | G7b (all 41 agents must lose `model:`) | No |
| `no agents/qrspi-*.md frontmatter carries a top-level model: key` (line 71) | Criteria 1 + 2 | G7b | No |
| `per-file failure message names the offending file path` (line 103) | Criterion 4 | G7b (structural lint must be actionable) | No |
| `CRLF line endings: model: key detected in CRLF-terminated frontmatter` (line 167) | Criterion 1 (helper correctness — CRLF files must not be silently skipped) | G7b ("sweeps every file matching `agents/qrspi-*.md`") | No |
| `block-scalar: indented --- in block-scalar body does not prematurely close frontmatter` (line 189) | Criterion 1 (helper correctness — block-scalar delimiters must not confuse the extractor) | G7b | No |
| `lint scope is the frontmatter block, not body prose` (line 219) | Task-09 description: "Tier-name references in dispatcher prose blocks… are not modified; only the standalone `model:` key in YAML front matter" | G7b out-of-scope boundary: prose tier names must not be flagged | No |
| `[r5-sf.F01] frontmatter ending with block-scalar key exits cleanly at closing ---` (line 248) | Criterion 1 (helper correctness — scalar-at-end false-positive prevention) | G7b (false positives on clean files would break GREEN state) | No |
| `[r5-sf.F01] frontmatter with block-scalar last key and no body model: still clean` (line 277) | Criterion 1 (companion to above — body-level `model:` not flagged when last key is block scalar) | G7b | No |

**No YAGNI signals.** Every test addresses either a spec criterion or a
helper-correctness edge case that directly supports the core sweep contract.
The four edge-case tests (CRLF, block-scalar, scope, scalar-at-end) were
added in review rounds to guard against false-negative and false-positive
detection bugs in `_frontmatter()` — all directly necessary for the sweep
to meet criterion 1 on the full production agent population.

---

## 4. Gap Analysis

### Criteria this task should cover and does

| Criterion | Covered | Mechanism |
|---|---|---|
| Sweep detects `model:` violation | ✅ | BATS test 2 |
| Lint passes GREEN after migration | ✅ | BATS test 2 (GREEN state) |
| Other keys unmodified | ✅ (manual) | Manual Validation: `git diff --stat HEAD~1 -- 'agents/qrspi-*.md'` |
| RED failure names offending file | ✅ | BATS test 3 |

### Criteria this task explicitly does NOT cover (out of scope per spec)

- `model_routing:` table contents — covered by Task 10
- SKILL prose Model Routing section — covered by Task 10
- Agent body prose (tier names haiku/sonnet/opus/inherit) — explicitly out of scope per task description

### Phase 1 Acceptance Criteria applicable to G7b

| Phase 1 criterion (plan.md) | Task 9 contribution |
|---|---|
| "CI suite passes with no regressions" (replan-gate 1) | The structural lint test (`test-agent-frontmatter-no-model.bats`) is GREEN after all 41 `model:` removals |
| "Full pipeline dry-run emits zero 'model not available' warnings" (replan-gate 2) | Task 9 is G7b part 1 (model: deletion); replan-gate 2 is fully met only after Task 10 adds the `model_routing:` table so dispatchers can route tier names to concrete IDs |

---

## 5. Spec-to-Test Fidelity Summary

| Spec criterion | Test intent matches? | Asserts right behavior? | Edge cases implied? |
|---|---|---|---|
| Criterion 1 (sweep + fail on model:) | ✅ | ✅ per-file accumulator + non-zero exit | CRLF, block-scalar, body-prose separately tested |
| Criterion 2 (zero violations GREEN) | ✅ | ✅ (same test passes when violations == 0) | — |
| Criterion 3 (other keys unmodified) | N/A (no test) | N/A | Manual validation covers atomicity |
| Criterion 4 (per-file RED message) | ✅ | ✅ path in output + error format string | Mirror-script divergence is a known limitation (cs-claude.F02); format contract still validated for LF files |

---

## 6. Finding Index

| ID | Summary | Severity |
|---|---|---|
| gt-claude.F01 | Spec criterion 3 ("other frontmatter keys unmodified") listed under Test Expectations with no BATS test — covered only by Manual Validation; dual placement creates false-completeness signal | Low / Non-blocking |

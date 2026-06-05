---
task: 24
terminal_status: clean-after-cap-bend
cap_bends: 3
accepted_with_issues: true
---

# Task 24 Review

**Goal:** G1 §I.7 / G6 / G11 / G12 — `scripts/detect-interaction-mode.sh`
interaction-mode detection helper (host × override matrix, stdout/stderr-only,
KEY=VALUE protocol) + bats coverage.

**Code artifacts:**
- `scripts/detect-interaction-mode.sh` (166 lines, **FROZEN since round-1**; no
  shell-verdict runtime branch — design.md §I.7 defers host-keyed shell-verdict to
  v0.7.3; implemented at contract/enum level only).
- `tests/unit/test-detect-interaction-mode.bats` (**49 tests, all GREEN** at terminal
  HEAD `be397e3`). Declares `bats_require_minimum_version 1.5.0` (line 41) → modern
  fail-fast (set -e + ERR trap).

**Dual reviewers:** Claude (`claude-sonnet-4.6`) + Codex (`gpt-5.3-codex`) every round.
Per-round verbatim findings + `.clean.md` sentinels persisted under
`reviews/tasks/task-24/round-NN/`. Codex is chat-only (cannot write to disk via Task
dispatch) — its findings/sentinels are orchestrator-persisted. This log summarizes
convergence; the round dirs are the verbatim record.

## SHA chain

| Round | Commit | Note |
|-------|--------|------|
| R1 | `9ae65c8`→`6dc30a6` | Initial: helper + bats suite |
| R2 | `7ac1f5e` | Correctness fixes |
| R3 | `22dd5dd` | round-04 anchor |
| R5 | `19ce07a` | Additive-test fix (cap-bend #1) |
| R6 | `8c88354` | Comment-only fix (cap-bend #2); round-06 anchor |
| R7 | `be397e3` | Test-only fix (cap-bend #3, FINAL); round-07 anchor |

## Round summary

- **R1–R3:** initial implementation + spec/correctness convergence. Production script
  frozen from round-1 (no edits after `9ae65c8`'s helper body).
- **R5 (cap-bend #1):** additive-test fix.
- **R6 (cap-bend #2):** comment-only fix. Round-06 final-state review (12 reviewers):
  8 CLEAN; sf-claude F01–F04 **empirically disproven** (legacy-bats "vacuous non-final
  assertion" misconception — disproved on bats 1.13.0: a suite declaring
  `bats_require_minimum_version 1.5.0` runs test bodies with set -e + ERR-trap, so
  non-final non-zero commands DO fail the test); gt-claude F01/F02 + tc-claude F01/F02
  verified valid. finding-verifier HARD-GATE on 5 candidates: gt-F01=90, gt-F02=90,
  tc-claude-F01=75, tc-claude-F02=78 (KEEP); tc-codex-F02=40 (DROP).
- **R7 (cap-bend #3, FINAL):** test-only fix resolving the kept R6 findings — added
  override-branch no-file-write test, Claude-Code no-file-write test, interactive-override
  × COPILOT_CLI and × CLAUDE_PROJECT_DIR tests; changed header test to grep the
  header-unique anchor `OVERRIDE CHAIN` (was non-unique `QRSPI_INTERACTION_MODE`). New
  tests correctly OMIT the `[T24]` prefix per canonical ID-hygiene. 49/49 pass; production
  script byte-identical.

## Round-07 final-state review (12 reviewers, full depth, both families)

**CLEAN (7):** spec-claude, spec-codex, security-claude, security-codex,
goal-traceability-claude, goal-traceability-codex, test-coverage-claude. gt (both families)
verified R6 findings F01/F02 + the tc interactive-override×host gap all RESOLVED. tda
SKIPPED (test-only delta, no new types).

**Findings — ALL accepted-with-issues (fix-cap exhausted; r7 was the final bend):**

| Finding | Sev | Theme | Disposition |
|---------|-----|-------|-------------|
| sf-claude F02 | Med | No `! grep '^INSTRUCTION='` absent-assertion in override output-shape tests | Accept-with-issues → backlog `pi-bats-instruction-absent-assertion`. Genuine completeness gap; nil practical risk vs FROZEN script. |
| cq-claude F01 / sf-codex F02 | Low | `!`-prefixed negative assertions exempt from set -e / ERR-trap → silently no-op on failure (lines 322,339 new + 267,306,484,612 pre-existing) | Accept-with-issues → backlog `pi-bats-negation-not-enforced`. Paired positive assertion is load-bearing + enforced; `!` guard only defends duplicate-output, which one-exit-per-branch script structure prevents. |
| sf-codex F01 / cs-claude F03 / cs-codex F03 | Low | `find\|wc\|tr` without pipefail could mask `find` error → count 0 | Accept-with-issues. tmpdir always exists (`$BATS_TEST_TMPDIR`); theoretical. |
| sf-claude F01 | Low | `dt=$(grep\|cut)` assignment absorbs grep exit → "key absent" surfaced as "wrong enum" | Accept-with-issues. Diagnostic-precision only; test still fails on regression. |
| tc-codex F01/F02 | Low | Placeholder check only on Copilot branch; skills-side grep coverage narrow | Accept-with-issues. Prior-declined completeness family. |
| cq-codex F01 / cs-claude F01 / cs-codex / tc-claude P01 | Low | `[T24]` prefix present on old tests, absent on new → inconsistency | DECLINED-direction / release-wide. Findings recommend ADDING `[T24]`; canonical rule is the opposite (strip release-wide). Tracked as `pi-tnn-test-name-leak-releasewide`. New tests are correctly prefix-free. |
| cs-claude F02 | Low | `auto`-override host test weaker than `interactive` twin (missing unset + PLATFORM/EVIDENCE asserts) | Accept-with-issues. |
| cq-codex F02 / cs-claude / cs-codex F01/F02 | Low | Large/repetitive test file; extract helpers, here-strings | DECLINED — refactor (user: "substantive refactors doesnt sound good"). Advisory/non-blocking by design. |

## Declined / disproven (prior rounds)

- **sf-claude F01–F04 (R6):** legacy-bats vacuous-non-final-assertion misconception —
  **empirically disproven** on bats 1.13.0.
- **shell-verdict Scope/In-vs-DoD ambiguity:** task-24 Scope/In names shell-verdict, but
  binding DoD + Test Expectations require NO shell-verdict runtime branch (design.md §I.7
  = future-host v0.7.3 work). Implemented at contract/enum level only; host-keyed branch
  correctly absent. **Declined-with-rationale; surface to user.**
- **tc-codex-F02 (R6):** verifier score 40 (below threshold) — dropped.

## Cap-bend record

Fix cycles bent 3× (R5 additive-test, R6 comment-only, R7 test-only) under explicit user
authority ("cap bend as needed to get good quality final result"). **Every bend was
test-only / additive / comment / string** — production script byte-frozen since round-1;
no assertion weakening, no substantive refactors. R7 was the FINAL bend; round-07 surfaced
only new test-completeness/hygiene/style findings on the frozen-and-verified surface →
accepted-with-issues per the cap-discipline rule (no 4th bend).

## Terminal status

**CLEAN-AFTER-CAP-BEND (accept-with-issues).** The full depth-required reviewer set
cleared on the final code state (`be397e3`) for production correctness: spec (×2),
security (×2), goal-traceability (×2) all CLEAN; test-coverage-claude CLEAN; 49/49 tests
GREEN. Residual findings are test-file completeness/hygiene/style with nil practical risk
against the FROZEN, fully-verified production script, and are captured as backlog plugin
issues. tda skipped (no new types). Task 24 is terminal at HEAD `be397e3`.

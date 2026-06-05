---
task: 19
goal_ids: [G27]
review_depth: deep
review_mode: loop_until_clean
codex_reviews: true
verifier_enabled: true
terminal_status: clean-after-5-fixes
---

# Task 19 Review — G27 second-reviewer-availability primitives

Deep mode, dual-family (Claude + Codex) reviewers, verifier enabled. Per-round
verbatim finding files and clean sentinels live under
`reviews/tasks/task-19/round-NN/`; per-finding verifier sidecars live alongside
them as `<reviewer_tag>.finding-FNN.score.yml`. This log is the orchestrator's
round-by-round audit trail and decision record; the round directories are the
authoritative verbatim artifact store.

## Commit progression (per-round anchors)

| Round | Fix commit (anchor)                         | Delta reviewed            |
|-------|---------------------------------------------|---------------------------|
| base  | `58dfc98`                                   | initial implement         |
| 1     | `97e1e09` (round-01-commit.txt)             | base..97e1e09             |
| 2     | `296ad11` (round-02-commit.txt)             | 97e1e09..296ad11          |
| 3     | `a312e49` (round-03-commit.txt)             | 296ad11..a312e49          |
| 4     | `5010d5f` (round-04-commit.txt) — cap-bend #1 | a312e49..5010d5f (test-only) |
| 5     | `44605c7` (round-05-commit.txt) — cap-bend #2 | 5010d5f..44605c7 (test-only) |
| 6     | (review-only, terminal CLEAN)               | 5010d5f..44605c7          |

Production scripts (`scripts/second-reviewer-available.sh`, `scripts/_resolve-lib.sh`)
were FROZEN from round 3 (`a312e49`) onward; rounds 4–6 are coverage-hardening of
the test suite only. The single unavailable guard
(`[ -z "$_default_vendor" ] || [ "$_default_vendor" = "none" ] || [ "$_vendor" = "none" ] || ! second_reviewer_vendor_known "$_vendor"`)
emits one `[second-reviewer-unavailable] host=… vendor=…` line and exits non-zero
for every unavailable case.

## Round-cap accounting

`review_mode: loop_until_clean` carries an implicit 3-round fix cap. Rounds 1–3 are
the 3-cap. The round-4 fix (`5010d5f`) is cap-bend #1; the round-5 fix (`44605c7`)
is cap-bend #2. Both cap-bends were explicitly authorized by the user
("cap bend as needed to get good quality final result"), constrained to
additive/test-only changes ("substantive refactors doesnt sound good"). Round 6 is
the terminal review pass and added no fix cycle.

## Rounds 1–4 (summary)

Rounds 1–3 ran the full deep-mode reviewer set and drove production + test
convergence to the frozen guard at `a312e49`. The round-4 fix (`5010d5f`) was a
test-only additive hardening pass. Verbatim findings, sentinels, and verifier
sidecars for each round are under the corresponding `round-0N/` directory.

## Round 5 — review-only convergence over the round-4 test delta

Full deep-mode fan-out (18 reviewer dispatches) over the test-only delta
`a312e49..5010d5f`. Spec gate CLEAN (both families). Correctness + thoroughness
tiers surfaced a cluster of joint-assertion coverage findings, consolidated by the
orchestrator into three gaps and run through the finding-verifier HARD-GATE (8
sidecars on disk):

- **GAP A — unknown-vendor joint assertion** (5-reviewer convergence): the
  single-line unknown-vendor test asserted `host=` but not `vendor=`, and an
  adjacent test used weak OR semantics (`grep -qE 'nonexistent-vendor-xyz|vendor='`)
  that a `vendor=` key-format regression could slip through. Verifier scores:
  test-coverage-codex F01 = 92, test-coverage-claude F02 = 90, silent-failure-codex
  F01 = 80, silent-failure-claude F02 = 72, code-quality-codex F01 = 55. **ACTED.**
- **GAP B — unknown-host default-path fragmentation** (2-reviewer): the unknown-host
  default path (`vendor` defaults to `none`) split the joint contract across three
  separate single-assertion tests; `vendor=none` was never pinned jointly with the
  single-line count on the default path. Verifier scores: test-coverage-claude
  F01 = 82, test-coverage-codex F02 = 62. **ACTED.**
- **GAP C — success-path stderr-empty** (1-reviewer): silent-failure-claude F01 = 30.
  A success-path test discarded stderr without asserting it empty. **DROPPED** by
  orchestrator: lowest verifier score (30), single reviewer, marginal/implausible
  regression on frozen fully-reviewed production, and halt-path tests already cover
  diagnostic emission. Acting on it risked ping-pong without material coverage gain.

Advisory: code-simplifier-codex F01 aligned with the GAP A joint-assertion fix
(non-blocking); code-simplifier-codex F02 proposed a line-count helper extraction —
**REJECTED** as a prohibited structural refactor (user: "substantive refactors
doesnt sound good").

Verbatim round-5 finding files + sidecars: `round-05/`.

## Round 5 fix (`44605c7`, cap-bend #2) — test-only additive

Dispatched a `qrspi-implementer` fix subagent (sonnet), test-only additive scope,
production frozen. Changes (diff `5010d5f..44605c7`, sole file
`tests/unit/test-second-reviewer-available.bats`, +35/-1):

- **GAP A.1** (additive): added `grep -q 'vendor=nonexistent-vendor-xyz'` to the
  single-line unknown-vendor test so one execution jointly asserts non-zero +
  `line_count==1` + tag + `host=` + `vendor=nonexistent-vendor-xyz`.
- **GAP A.2** (one-line assertion-strengthening): tightened the weak-OR grep to the
  precise `grep -q 'vendor=nonexistent-vendor-xyz'`, removing the false-negative
  alternative.
- **GAP B** (new test): added a joint unknown-host default-path test asserting
  non-zero + `line_count==1` + tag + `host=unknown` + `vendor=none` in one execution.

Implementer report: 30 ok / 1 skip / 0 not ok; zero production files changed.
HEAD-advanced verification passed (reported `commit_sha` == `git rev-parse HEAD`
== `44605c7`, distinct from round base `5010d5f`).

## Round 6 — terminal review pass (CLEAN)

Full deep-mode fan-out over the narrowed test-only delta `5010d5f..44605c7`
(`round-06.diff`, HEAD~1 confirmed == round base). type-design-analyzer skipped —
no new types introduced (test-only delta).

| Tier | Reviewer | Claude | Codex |
|------|----------|--------|-------|
| Correctness (gate) | spec | CLEAN | CLEAN |
| Correctness | code-quality | CLEAN | CLEAN |
| Correctness | silent-failure | CLEAN | CLEAN |
| Correctness | security | CLEAN | CLEAN |
| Thoroughness | goal-traceability | CLEAN | CLEAN |
| Thoroughness | test-coverage | CLEAN | CLEAN |
| Thoroughness | type-design | skipped (no new types) | skipped (no new types) |
| Thoroughness | code-simplifier | CLEAN | CLEAN |

14 CLEAN sentinels, zero findings → no fix cycle → verifier HARD-GATE vacuously
satisfied (no kept findings to gate). Verbatim sentinels: `round-06/`.

Both test-coverage reviewers (who raised the original GAP A/B findings) explicitly
confirmed closure. test-coverage-claude mapped every reachable unavailable branch of
the frozen guard and verified each now has exactly one joint single-execution test
(non-zero + exactly-one-line + tag + `host=` + `vendor=`):

- Case A — unknown-host default (`host=unknown vendor=none`): new test ~L289-317 — GAP A closed
- Case B — unknown-vendor override (`host=copilot-cli vendor=nonexistent-vendor-xyz`): ~L321-342 (delta added the `vendor=` assertion) — GAP B closed
- Case C — explicit `none` (`host=copilot-cli vendor=none`): ~L358-382 — covered
- Case D — empty/missing default vendor (fault-injected): ~L524-572 — covered
- Case E — unknown host + recognized vendor override (`host=unknown vendor=openai-codex`): ~L485-513 — covered

## Terminal status

**CLEAN after 5 fix cycles** (3-cap + 2 user-authorized cap-bends). G27 DoD
(every unavailable case exits non-zero with exactly one `[second-reviewer-unavailable]`
line naming both `host=` and `vendor=`) is fully covered by joint single-execution
assertions. Production frozen since `a312e49`; final tip `44605c7`.

Decisions recorded: GAP C dropped (verifier 30, justification above);
code-simplifier-codex F02 helper-extraction rejected (prohibited refactor);
two cap-bends honored per explicit user authorization.

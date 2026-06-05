---
task: 13
terminal_status: clean
cap_bends: 2
---

# Task 13 Review

**Goal:** G9 — per-task review-loop drift prevention. `scripts/round-prepare.sh`
defers the per-round commit-anchor write (`round-NN-commit.txt`) until **after** the
Step-10 prior-artifact presence assertions, so a failed verification leaves no stray
anchor; emits distinct recovery exit codes (10/11/12); fails loud on missing/malformed
prior anchor and missing/empty scope-set (NN≥3 + tagger enabled). Companion SKILL.md
between-round checklist + scripts/-no-Task-dispatch architectural guard.

**Code artifacts:**
- `scripts/round-prepare.sh` (the G9 subsystem under test)
- `skills/implement/SKILL.md` (between-round checklist + per-task convergence prose)
- `tests/unit/test-scope-tagger-dispatch.bats` (the `[T13]` regression block, 67 tests)

**Test posture at terminal HEAD `3b93583`:** full suite GREEN — 1401 unit,
41 acceptance, 16 integration. shellcheck `--severity=error` clean; `bash -n` clean;
bash-3.2 ban-list clean.

**Dual reviewers:** Claude (sonnet/opus) + Codex (gpt-5.3-codex) every round. Per-round
verbatim findings and `.clean.md` sentinels are persisted on disk under
`reviews/tasks/task-13/round-NN/`; per-round diffs at `round-NN.diff`; per-round commit
anchors at `round-NN-commit.txt`. This log summarizes convergence; the sidecars are the
verbatim record. Codex reviewers cannot write to disk via Task dispatch — the orchestrator
persisted every Codex sidecar manually.

> **Note — out-of-band backfill.** T13 was silently skipped during the original Wave 2
> dispatch (process issue `wave-skip-t13-t24-stage-misread`, recorded in the run's
> plugin-issues log). It was backfilled as an isolated per-task flow forked from its
> Branch-Map base `d3114e3`, running the same TDD + dual-review + verifier discipline as
> every other task. Surface this to the user — it is a release-process discovery, not a
> code defect.

## SHA chain

| Round | Commit | Note |
|-------|--------|------|
| R1 | `79986ba` | Initial: anchor-write deferral after Step-10 assertions; exit 10/11/12; fail-closed grep branching + no-stray-anchor test |
| R2 fix | `79d6400` | (round-1 fix-cycle terminal — base for R2 review) |
| R2 fix (G,H) | `42231bc` | Fix G: add malformed-anchor + empty-scope-set bats tests. Fix H: correct SKILL.md L1189 assert-then-write ordering |
| R3 fix (I) | `d17e1e5` | Fix I: tighten 4 prior-artifact failure tests from `-ne 0` to `-eq 1` (pin exit-1 distinctly); RED-verified |
| R5 fix (cap-bend) | `3b93583` | Additive coverage: later-round happy path, scope-set gate branches, no-stray-anchor sweep, missing-newline fixture; + one verified dead-code removal |

Base commit (per parallelization.md Branch Map): `d3114e3`. Every round broadened with
`<ref>=d3114e3` (per-task scope-tagger not run for this backfill).

## Round-by-round convergence

### Round 1 — correctness (fix cycle landed at `79d6400`)
Initial implementation + the first review→fix iteration. Anchor-write relocated after the
Step-10 assertions; SHA checks exit 10/11/12; fail-closed grep branching; no-stray-anchor
regression test. (Thoroughness fan-out was NOT run in round 1 — corrected in round 4; see
note below.)

### Round 2 — spec-gate + fixes G/H → `42231bc`
- spec-claude **CLEAN**.
- spec-codex **2 findings**: F01 (missing bats coverage for malformed-anchor + empty-scope-set
  branches), F02 (SKILL.md L1189 stale write-then-assert ordering contradicting L1205). Both
  independently verified valid; finding-verifier scored F01=76, F02=70.
- **Fix G** (F01): added the two missing bats tests. **Fix H** (F02): corrected L1189 prose to
  assert-then-write. Suite green.

### Round 3 — spec-gate + fix I → `d17e1e5`
- spec-claude **CLEAN**. spec-codex **F01**: the 4 prior-artifact failure tests asserted
  `status -ne 0`, not the specific `-eq 1`, so exit-1 vs 10/11/12 was not pinned
  (diagnostic-substring assertions partially mitigated). finding-verifier scored 45 (moderate).
- **Fix I**: tightened the 4 sibling tests to `-eq 1` (left the no-stray-anchor test at `-ne 0`).
  RED-verified by flipping exit 1→11 (test failed as expected). Suite green (1453 tests).

### Round 4 — FINAL standard review pass (fix-cap of 3 reached)
- **spec-gate:** spec-claude + spec-codex **both CLEAN** → triggered mandatory same-round fan-out.
- **Correctness fan-out:** cq-claude, cq-codex, sec-claude, sec-codex **all CLEAN**.
  silent-failure (sf-claude F01/F02, sf-codex F1/F2) raised findings — **all targeting
  T12-OWNED scaffolding** (L141 `TASK_BASE_SHA … || true`, L363 sidecar `mv`, L378-382
  `git diff … || true` swallowing), confirmed via `round-04.diff` to be OUTSIDE T13's diff.
  task-13.md § Out-of-scope explicitly assigns "canonical round-prepare.sh scaffolding and the
  general G4 diff/ref-selection behavior" to T12. **Declined as out-of-scope** (see § Deferred).
- **Thoroughness fan-out** (had never run in round 1 — deep-mode P0 gap, caught and corrected here):
  gt-claude **CLEAN**, tc-codex **CLEAN**; tda **skipped** (no new types).
  - gt-codex **F01** + tc-claude **F01** (convergent, medium): no later-round (NN≥2) **happy-path**
    test — the deferred-anchor-write success path Fix A reshaped is only exercised on round 1
    where Step 10 is a no-op.
  - tc-claude **F02** (medium): scope-set gate only tests the enabled+fail corner; gate-off,
    round-2 eligibility boundary, and gate-pass sides untested.
  - tc-claude **F03** (low): no-stray-anchor asserted for only 1 of 4 Step-10 exit paths.
  - tc-claude **F04** (low): missing-trailing-newline malformed shape not independently exercised.
  - cs-claude **F01** + cs-codex (advisory): dead `ANCHOR_CONTENT` + `printf|python3` pipe at
    L192-199 (the `< "$PRIOR_ANCHOR_PATH"` redirect already supersedes the pipe — zero-behavior
    removal). finding-verifier scores: tc-F01=60, tc-F02=52, tc-F03=50, tc-F04=48, cs-F01=60.

### Round 5 — cap-bend additive fix → `3b93583`
Authorized cap-bend (user: "cap bend as needed to get good quality final result", caveat
"substantive refactors doesnt sound good"). Scope: **additive tests + one verified dead-code
removal only** — no production-logic refactor.
- **5 new `[T13]` tests:** later-round (round-2) happy path (F01); scope-set gate-off (F2a),
  round-2 eligibility boundary (F2b), gate-pass (F2c); missing-trailing-newline malformed
  fixture (F4).
- **3 tests extended** with the `[ ! -e round-NN-commit.txt ]` no-stray-anchor assertion
  (malformed-anchor, missing-scope-set, empty-scope-set) — closing F3 across all 4 Step-10 exits.
- **1 production change (F5):** removed the dead `ANCHOR_CONTENT="$(cat …)"` + `printf|python3`
  pipe in `scripts/round-prepare.sh` (collapsed to the already-live `< "$PRIOR_ANCHOR_PATH"`
  redirect). Behavior byte-identical; exit-code branching, anchor-write ordering, and scope-set
  gate logic untouched.
- **Round-5 verification fan-out** (final code state):
  - spec-claude **CLEAN**, spec-codex **CLEAN**.
  - cq-claude **CLEAN**; cq-codex confirmed the removal "clean and an improvement" but raised two
    **test-organization** suggestions — F01 (medium): split the ~1000-line test file into a
    dedicated round-prepare suite; F02 (low): extract test bootstrap helpers. **Both declined**
    (test-layout/helper refactor is exactly the substantive-refactor churn the user vetoed, and
    the fix-cap is exhausted) → § Deferred.
  - sf-claude **CLEAN**, sf-codex **CLEAN**; sec-claude **CLEAN**, sec-codex **CLEAN**.

## Fix-cycle ledger

| Fix | Round | Change | Commit |
|-----|-------|--------|--------|
| (R1) | 1 | Initial impl + anchor-deferral + fail-closed test | `79986ba`→`79d6400` |
| G | 2 | Add malformed-anchor + empty-scope-set tests | `42231bc` |
| H | 2 | SKILL.md L1189 assert-then-write ordering | `42231bc` |
| I | 3 | Tighten 4 prior-artifact tests to `-eq 1` | `d17e1e5` |
| (cap-bend) | 5 | Additive coverage (F01–F04) + dead-code removal (F05) | `3b93583` |

Cap bends: **2** beyond the standard 3-round budget — the round-3 fix exhausted the budget;
round 4 was the standard final review pass; round 5 is the user-authorized additive-only cap-bend.

## Declined / deferred findings

### Declined — out of T13 scope (T12-owned)
- **R4 sf-claude F01/F02, sf-codex F1/F2** — all target T12-owned `round-prepare.sh` scaffolding
  (`TASK_BASE_SHA … || true`; unchecked sidecar `mv`; `git diff … || true` error swallowing).
  Not in T13's diff; task-13.md scopes these to T12. Disposition recorded in
  `round-04/silent-failure-codex.findings.md`.

### Declined — out of cap-bend scope (substantive refactor, user-vetoed)
- **R5 cq-codex F01** (medium): split the test file into a dedicated round-prepare suite.
- **R5 cq-codex F02** (low): extract shared test bootstrap helpers.
  Both are reasonable future test-hygiene improvements but require refactoring existing passing
  tests; declined per the additive-only cap-bend constraint. Disposition in
  `round-05/code-quality-codex.finding-F01.md` / `finding-F02.md`.

## Deferred backlog (future tasks)
1. **round-prepare.sh downstream-emission hardening (T12 scope):** `git diff` error swallowing,
   unchecked sidecar `mv`, `TASK_BASE_SHA` silent no-op. Real robustness gaps surfaced by R4 sf
   reviewers; belong to T12/G4, not T13.
2. **Test-file decomposition (test-hygiene):** `tests/unit/test-scope-tagger-dispatch.bats` has
   grown to ~1000+ lines mixing legacy scope-tagger tests with the T13 round-prepare suite;
   consider a dedicated file + shared setup helpers (R5 cq-codex F01/F02).

## Terminal declaration

**Task 13 — terminal CLEAN.** All correctness, security, and silent-failure reviewers CLEAN on
the final code state (round 5); the deep-mode thoroughness gaps surfaced in round 4 are closed by
the round-5 additive coverage; the only open findings are non-blocking, out-of-scope, or declined
test-hygiene refactors recorded above. Terminal HEAD `3b93583`; full suite GREEN.

# Goal-Traceability Review — Task 8 (G7a cache retirement), Round 01

**Reviewer:** trace-claude
**Verdict:** CLEAN — no traceability findings.

## Chain verified

### Forward: G7a → task-08 TE1..TE10 → tests → implementation

G7a (goals.md lines 171, 185–195) enumerates the cache-mechanism retirement as
eight sub-deliverables. Each maps to one or more task-08 Test Expectations
(TE1..TE10), each TE has a passing automated assertion, and each assertion
traces to a concrete implementation change in commit 64375e7:

| Goal sub-bullet | TE | Test (file / @test) | Impl change (diff lines) |
|---|---|---|---|
| Delete `scripts/g4-cache-probe.sh` | TE1 | `test-cache-retirement-invariants.bats` `[T8 / TE1]` | diff 81–86 (file deleted) |
| Delete `.../spikes/g4-cache-probe.md` | TE2 | `test-cache-retirement-invariants.bats` `[T8 / TE2]` | diff 1–6 (file deleted) |
| Delete `test-cache-control-capability-gate.bats` | TE3 | `test-cache-retirement-invariants.bats` `[T8 / TE3]` | diff 955–960 (file deleted) |
| Delete `test-cache-hit-rate.bats` | TE4 | `test-cache-retirement-invariants.bats` `[T8 / TE4]` | diff 1123–1128 (file deleted) |
| Strip `supports_prompt_cache` + `emit_cache_control_markers` from `using-qrspi/SKILL.md` providers block (YAML + bullets) | TE5, TE6 | `test-cache-retirement-invariants.bats` `[T8 / TE5]` ×3 + `test-run-third-party-llm.bats` `[T8 / TE6]` ×3 | diff 678–692 (4 lines removed); verified on-disk SKILL.md lines 420–446 contain no occurrences |
| Remove `cache_control` marker emission branch from `_dispatch_openai_chat` | TE7 | `test-run-third-party-llm.bats` `[T8 / TE7]` ×3 | diff 471–512 (function body), 522–528 (parsing case arms) — verified on-disk run-third-party-llm.sh lines 247–264 (function) and 530–544 (parser) |
| Trim cache-control truth-table assertions only from `test-run-third-party-llm.bats` | TE8 | `test-cache-retirement-invariants.bats` `[T8 / TE8]` | diff 1349–1385 (four `cache_control gate` @test blocks removed) |
| Drop `SPIKE` export + two `run_pin` invocations from `test-phase1-acceptance.bats` | TE9 | `test-cache-retirement-invariants.bats` `[T8 / TE9a]` + `[T8 / TE9b]` ×2 | diff 904 (SPIKE removed), 924–950 (C-1/C-2/C-5 blocks removed) |
| Don't collateral-damage T7's G6 host-detection assertions | TE10 | `test-cache-retirement-invariants.bats` `[T8 / TE10a]` + `[T8 / TE10b]` | n/a — guard test for non-regression |
| CI-green meta-gate | TE11 | external | external |

Total: 18 new test assertions (6 appended to `test-run-third-party-llm.bats`
for TE6/TE7; 12 in the new `test-cache-retirement-invariants.bats` for
TE1..TE5/TE8/TE9/TE10). All 18 trace upstream to a G7a sub-deliverable.

### Backward: implementation → tests → goal

Every byte changed in commit 64375e7 traces back to a G7a sub-deliverable:

- `scripts/g4-cache-probe.sh` deletion — G7a bullet 1
- `docs/.../g4-cache-probe.md` deletion — G7a bullet 2
- `tests/unit/test-cache-control-capability-gate.bats` deletion — G7a bullet 3
- `tests/unit/test-cache-hit-rate.bats` deletion — G7a bullet 4
- `skills/using-qrspi/SKILL.md` 4-line removal (2 YAML + 2 bullets) — G7a bullet 5
- `skills/using-qrspi/SKILL.anchors.json` line-number reflow — mechanical
  consequence of SKILL.md edit (anchors file is auto-tracked)
- `scripts/run-third-party-llm.sh` removals (function comment, dual-flag
  branch in `_dispatch_openai_chat`, two variable inits, two parsing case
  arms) — G7a bullet 6
- `tests/unit/test-run-third-party-llm.bats` removals (4 truth-table tests)
  + appends (6 absence assertions) — G7a bullet 7 + TE6/TE7
- `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` removals
  (SPIKE export, C-1/C-2/C-5 blocks) — G7a bullet 8
- `tests/acceptance/v07-phase1/test-cache-retirement-invariants.bats`
  (new file) — TE1..TE5/TE8/TE9/TE10 external gate

No YAGNI surface. No orphan code.

### Manual-validation criterion

G7a manual-validation says: `git diff --name-only HEAD~1` for the Task 8
commit must not list any path under `docs/qrspi/2026-04-29-v0.4-bundle/` or
`docs/superpowers/`. The diff touches `docs/qrspi/2026-05-17-v07-release/`
only (the May-17 v0.7 release spike). ✓

### Test-expectation fidelity (spec-to-test)

- TE6: three independent `grep -nwE` calls against `$USING_QRSPI_SKILL` for
  the three literal strings — sharp, word-boundaried, file-targeted as spec
  requires. ✓
- TE7: three independent `grep -nwE` calls against `$DISPATCHER` for the
  same three literals — sharp, word-boundaried, file-targeted as spec
  requires. ✓
- TE8: pattern `^@test "cache_control gate` exactly matches the four
  truth-table @test header forms removed by the implementer. ✓
- TE9: greps `SPIKE=.*g4-cache-probe\.md` and `run_pin[[:space:]].*test-...`
  against `$PHASE1_ACCEPTANCE` from outside (eliminates self-reference per
  spec). ✓
- TE10: greps for unique `[T7 / TE5]` and `[T7 / TE6]` test-name tags —
  fails loudly if T7's G6 host-detection assertions are collateral-deleted.
  ✓

## Observations consistent with G7a "only" minimalism (not findings)

The G7a sub-bullet for `test-run-third-party-llm.bats` reads "Trim
cache_control assertions **only**". The "only" qualifier sanctions minimal
touch. Consequently, two stale-but-harmless artifacts remain:

1. The `_write_config_openai` helper (lines 46–62) still emits
   `supports_prompt_cache:` and `emit_cache_control_markers:` keys into
   fixture configs. The dispatcher's `case "$rec_key"` no longer matches
   these keys, so the dispatcher silently ignores them — dead-but-harmless
   config emission.
2. The file-header docstring (lines 7–10) still mentions "the dual-flag
   cache_control emission gate ... all four cells". Stale documentation,
   but covered by the same "only" qualifier.

Neither blocks any test. Both are consistent with the goal's explicit
minimalism. Flagged only as observations; not a traceability gap.

## Verdict

Chain is unbroken. All 10 testable Test Expectations have a backing
assertion that traces upstream to a G7a sub-deliverable, and every
implementation change traces back to one. Clean.

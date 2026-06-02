---
reviewer: claude
role: plan-test-coverage-reviewer
round: 8
status: clean
artifact: plan.md
diff_ref: main (broaden — full file added vs base)
---

# Round-08 Test-Coverage Review — CLEAN

## Summary

No new test-coverage findings against the full broaden-vs-main diff.

## R7 fix verification

Round-07 kept tc-codex.F02 (T25 missing falsifiable signal for the
`docs/prompt-design-guide.md` stale-reference invariant). Round-07 fix E1
landed at plan.md L1408:

> "Repo-wide grep audit asserts zero remaining live references to
> `docs/prompt-design-guide.md` outside historical CHANGELOG entries
> (matches DoD invariant — fails the build on any stale source-of-truth
> reference)."

This sits inside the T25 `**Test expectations**` block and ties directly
to the existing DoD invariant at L1400. The expectation is specific,
observable, deterministic, and falsifiable. Fix accepted.

## Broaden-vs-main sweep

The round-08 diff is `new file mode 100644` from `/dev/null` (the artifact
does not exist on `main`), so the full plan is in scope. I sampled
T01–T08, T11–T17, T19–T21, T24–T25, T34–T40, T44 — representative across
all seven slices, both lightweight and code tasks, both fail-loud and
documentation-only surfaces.

Across every task examined, test expectations satisfy all four quality
gates:

- **Behavioral coverage**: each happy path names a specific observable
  outcome (exit code, file path, diagnostic prefix, frontmatter field).
- **Edge cases**: missing/empty/malformed/symlink-escape inputs are
  explicitly enumerated where the task processes data (T02, T12, T19,
  T21, T24, T34, T39, T44).
- **Error conditions**: every fallible operation names the specific
  exit code or diagnostic the caller receives — examples include T12
  exits 10/11/12, `[second-reviewer-unavailable]` /
  `[second-reviewer-same-vendor]` for T19, `CONTRACT-CONFLICT:` for T35,
  `resolves outside repository` for T21/T39, `HALLUCINATED: ` for T08,
  and verbatim mismatch-diagnostic strings for T34.
- **Expectation quality**: no "handles X appropriately" / "works
  correctly" / "edge cases are handled" patterns observed in any task
  reviewed.

## Design-required scenarios cross-check

The Phase 1 Acceptance Criteria fail-loud-invariant enumeration at L28
maps 1:1 to per-task test expectations:

- Splitter on adversarial Codex stdout → T20 companion/splitter fixture.
- `_resolve-lib.sh` `[second-reviewer-same-vendor]` halt → T19
  `test-routing-matrix-application.bats` assertion.
- `second-reviewer-available.sh` `[second-reviewer-unavailable]` halt →
  T19 probe behavior tests.
- `plan.md` post-approval split block-hash mismatch halt → T34 with
  exact diagnostic verbatim.
- `scripts/verifier-fan-in.sh` halt causes (missing `change_type`,
  out-of-enum, missing/wrong-extension sidecar, unparseable score) →
  T02 malformed fixture rounds.
- `tools/build-plugin.mjs` `resolves outside repository` and
  include-cycle halts → T39 symlink-escape and include-cycle fixtures.
- Path-filter exfil in `scripts/dispatch-agent.sh` → T21 four-path-family
  table-driven coverage.

No scenario named in the phase acceptance block lacks a corresponding
per-task test expectation.

## R7 drops — confirmed not regressed

- tc-codex.F01 (T39 build-twice determinism) — the existing AC #4
  `git diff --exit-code build/` bound at L30 remains intact; no new
  defect introduced by E1.
- sec-codex.F01, scope-codex.F01, sf-codex.F01 — out of test-coverage
  scope; no new test-coverage gap introduced by their disposition.

## Verdict

Clean. The plan's test expectations are complete and verifiable as a
basis for the Test phase's acceptance-test generation.

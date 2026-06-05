# Test-coverage review — plan.md round 7 (broaden vs main)

**Reviewer:** claude (test-coverage)
**Artifact:** `docs/qrspi/2026-05-30-v072-release/plan.md`
**Round:** 7
**Diff ref:** `<base-branch>` (broaden — full plan.md vs main)
**Disposition:** **CLEAN — no new test-coverage findings**

## Round-06 changes reviewed

Two surgical fixes landed in round-06; both stay within the existing test-coverage
envelope:

### 1. T19 dep edge addition (L65 / L974 / L1103)

Added Task 16 as a `Dependencies:` entry for Task 19, and the symmetric
`Blocks: T19` entry on Task 16. Pure sequencing change.

T19's test expectations (L1140–L1148) already cover:
- `_host-detect.sh` source-safety + four host signals
- `second-reviewer-available.sh` exit 0 on Copilot/Claude defaults
- Override-boundary tests for `<vendor>` arg
- Shared-source assertion against parallel hardcoded host tables
- Grep audits for Codex-glob removal across Goals/using-qrspi/reviewer-protocol
- Routing-matrix same-tier fan-out + `[second-reviewer-unavailable]` halt
- `[second-reviewer-same-vendor]` halt at matrix-lookup time

All of the above functionally depend on T16's `_resolve-lib.sh` schema. The
round-06 dep edge merely ensures the schema lands first so T19's tests can
execute against it; it does not change what T19 verifies. No new edge cases,
error conditions, or behavioral coverage gaps introduced. ✓

### 2. AC #2 T39 fail-loud enumeration extension (L28)

Added four `tools/build-plugin.mjs` fail-loud invariants to the cross-task
Phase 1 AC #2 enumeration. Each traces to a specific, falsifiable T39 test
expectation:

| AC #2 invariant | T39 test expectation trace |
|---|---|
| `resolves outside repository` halt (symlink-escape exfil) | L2268 — explicit stderr diagnostic containing `resolves outside repository`, fixture commits a `!cat`-targeted symlink whose canonical target is outside `$REPO_ROOT` |
| Include-cycle halt with full cycle printed | L2261 — "include cycles with full cycle printed" listed as a unit-test resolver failure case |
| Malformed `!cat` directive and missing-target halts with `file:line` diagnostics | L2261 — both failure cases listed; AC #2 itself names `file:line` as the falsifiable signal, so the Test phase generates a phase-level assertion against the diagnostic shape |
| `${CLAUDE_SKILL_DIR}` shipped-file halt | L2261 — "`${CLAUDE_SKILL_DIR}` in shipped files" listed as a resolver failure case; L2262 — grep audit confirms no shipped file contains the token |

The AC #2 enumeration extension actually **improves** test verifiability by
elevating these four invariants from T39-only DoD/test-expectation scope into
the cross-task phase-level acceptance enumeration. The Test phase will now
generate dedicated phase-level acceptance tests for each invariant, in
addition to T39's per-task tests. ✓

## Cross-checking all five criteria against the round-06 surface

1. **Behavioral coverage** — T19 happy path (probe exit 0 for Copilot/Claude
   defaults) and T39 happy path (exit 0 + reproducible `build/` tree) both
   pinned with observable, deterministic expectations.

2. **Edge cases** — T19 covers unknown host, missing default vendor, unknown
   vendor, unavailable vendor, and same-vendor primary/second-reviewer
   collision. T39 covers idempotent re-run, transitive nested includes, CR
   stripping, absolute paths, path traversal, symlink-escape.

3. **Error conditions** — T19 names two specific stderr prefixes
   (`[second-reviewer-unavailable]`, `[second-reviewer-same-vendor]`) plus
   non-zero exit. T39 names specific diagnostic phrases (`resolves outside
   repository`, "full cycle printed", `file:line`) plus non-zero exit. All
   error paths supply the falsifiable signal the Test phase needs.

4. **Test expectation quality** — Every test expectation added or implied by
   the round-06 changes is specific (names exact diagnostic strings, exact
   exit codes, exact field names), observable (stderr, exit code, file
   contents, grep), deterministic, and falsifiable.

5. **Missing scenarios from design** — None introduced. The round-06 AC #2
   enumeration extension closes a prior gap by ensuring design.md ## G32's
   D3 fail-loud conditions are mirrored at the phase-level acceptance layer,
   not just per-task DoD.

## Scope-hint compliance

No `scope_hint` provided this round (broaden); reviewed the full diff against
main. The two round-06 changes are the only surfaces with new test-coverage
implications; everything else in the diff is the existing plan body already
reviewed in rounds 1–6.

## Verdict

CLEAN. The round-06 dep-edge and AC #2 enumeration fixes both land cleanly
against existing test expectations and introduce no new vague, missing, or
unfalsifiable test scenarios. Plan is ready for downstream Test-phase
acceptance-test generation from the test-expectation surface as-is.

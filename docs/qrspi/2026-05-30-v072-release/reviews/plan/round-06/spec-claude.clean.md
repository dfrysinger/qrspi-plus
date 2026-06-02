---
reviewer: claude
role: qrspi-plan-reviewer
round: 6
artifact: plan.md
verdict: clean-with-concurrence
concurs_with:
  - quality-claude.finding-F01.md
  - quality-claude.finding-F02.md
  - quality-claude.finding-F03.md
review_type: broaden-vs-main
---

# Plan reviewer (claude) — Round 6 (broaden-vs-main)

No additional findings beyond the three `quality-claude.finding-F0[1-3].md`
files already present in this round's directory, with which I concur.

## Scope of this review

Round-06 broaden-vs-main review of plan.md (full 2401-line artifact). Per
Round-05 history note, focused on the surfaces edited in Round-05:

- L22 — Phase 1 Acceptance Criteria #2 enumeration extension
- L92 / L110 — Task List + Dependency Graph narrative
- T16 (L966–L1040) — DoD + Test Expectations after `[second-reviewer-same-vendor]`
  halt removal
- T19 (L1095–L1162) — Out, DoD, Test Expectations, References after the halt
  re-ownership to T19
- T39 (L2202–L2280) — deps update + canonicalization-halt alignment

## Concurrence rationale

### quality-claude.finding-F01 (T19 missing `Dependencies: Task 16`)

I identified this same surface during my analysis but held back from raising
it under a "pre-existing condition" framing. The F01 author's "round-05
**deepens**, not severs, the dependency" framing is the correct
characterization and I was wrong to suppress. Specifically:

- Before round-05: T19 extended `_resolve-lib.sh` with host × vendor matrix
  helpers without a T16 dep edge. The halt lived in T16, so the structural
  ordering was at least notionally tracked via T16 owning the halt that uses
  the helpers T19 adds.
- After round-05: the halt was moved to T19 ("`_resolve-lib.sh`'s host ×
  vendor matrix lookup halts loudly with `[second-reviewer-same-vendor]`" at
  L1136). Now T19 owns both the matrix-lookup helpers AND the halt that uses
  them — but still has no dep edge to T16 which **creates** the file these
  helpers extend.
- The same-file edit risk on `tests/unit/test-routing-matrix-application.bats`
  (both T16 L991 and T19 L1147–L1148 modify it) compounds the ordering
  concern.

This is a load-bearing new defect exposed by the round-05 fix, not a
pre-existing condition the fix left untouched. F01's recommended fix
(`Dependencies: Task 16` on T19 L1103 + `Blocks: Task 17, Task 19` on T16
L974) is the minimal correct edit.

### quality-claude.finding-F02 (L110 narrative misattribution)

I missed this in my Round-06 pass. The L110 rewrite said T39 depends on T21
"for the renamed `scripts/dispatch-agent.sh` path under the `build/`
allow-list and `!cat` resolver inspection" — but T20 owns the rename, not
T21 (T20 task header at L1164; T21 only modifies the already-renamed file).
The actual round-05 rationale per T39 DoD L2253 ("mirrors T21's
`assert_path_under_repo_root` shape") and T39 Test L2268 ("Mirrors T21's
symlink-out-of-repo regression... so the two canonicalization surfaces use
the same audit-friendly diagnostic phrase") is the diagnostic-phrase
consistency, not the rename path. The deps field itself is correct; only
the narrative needs to match the actual rationale.

### quality-claude.finding-F03 (T16/T19 carve-out symmetry)

I missed this in my Round-06 pass. T19's Out (L1121–L1124) carves out
downstream surfaces (T20 renames, T27 snippet, v0.7.3+ futures) but not
T16's upstream resolver foundation. T16's Out (L993–L996) carves out T17,
T27, and v0.7.3+ futures but not T19's matrix-lookup territory. The In
phrasing collision between T16 L986 ("host/vendor routing lookup") and T19
L1116 ("host × vendor matrix... lookup helpers") is precisely the kind of
ambiguity round-05's halt-move was supposed to clean up.

## Verification of round-05 edits not flagged by F01-F03

- L22 AC #2 enumeration extension: `tools/build-plugin.mjs` `resolves
  outside repository` clause is byte-aligned with T39 DoD L2253 and Test
  L2268. Diagnostic phrase consistent.
- L92 + L2210 T39 deps: `[Task 21, Task 25]` consistent across task list
  and per-task spec.
- T16 DoD/Test removal of `[second-reviewer-same-vendor]`: clean — no
  vestigial mention in T16's DoD, Test Expectations, or References.
- T19 DoD L1136 + Test L1148 addition: correctly attributes the halt to
  `_resolve-lib.sh` matrix-lookup time with the clarifying parenthetical
  that `second-reviewer-available.sh` checks reachability only.
- T19 Out removal of the bullet that deferred halt enforcement to T16:
  verified absent.
- Halt-vs-task ownership across the full AC #2 list: every enumerated halt
  traces to an owning task's DoD + Test Expectations (T2/T3/T5/T6/T16/T17/T19/T20/T21/T35/T39).

## Surface-area summary

| Round-05 edit surface | F01 | F02 | F03 | My pass | Net verdict |
|---|---|---|---|---|---|
| L22 AC #2 build-plugin halt | – | – | – | clean | clean |
| L92 / L2210 T39 deps field | – | – | – | clean | clean |
| L110 narrative rewrite | – | flagged | – | missed | F02 stands |
| T16 halt removal | – | – | flagged (carve-out stale) | clean (DoD/Test only) | F03 stands |
| T19 halt addition + Out edit | flagged (missing T16 dep) | – | flagged (Out asymmetry) | partially clean | F01 + F03 stand |
| T39 DoD L2253 mirror language | – | flagged (L110 misattribution) | – | clean | F02 stands |

No edit surface is fully clean; F01-F03 collectively cover the gaps the
round-05 fix exposed or left behind on its own touched surfaces.

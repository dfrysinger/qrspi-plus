---
reviewer: spec-claude
round: 7
artifact: plan.md
diff_ref: main
status: clean
---

# Spec reviewer — no findings (round 7, broaden-vs-main)

## What I reviewed

Full plan.md broaden-vs-main diff (whole file, since main has no plan.md).
Focused on round-06's two surgical fixes and their spec-altitude coherence
across the artifact:

1. **T19 dep edge fix** — L65 (task list), L1103 (T19 spec), L974 (T16 Blocks).
2. **AC #2 T39 enumeration extension** — L22 (Phase 1 Acceptance Criteria).

## Verification results

### Fix 1: T19 → T16 dep edge

| Surface | Location | Status |
|---|---|---|
| Task list dep field | L65 | ✓ `deps: [Task 16]` |
| T19 per-task spec Dependencies | L1103 | ✓ `**Dependencies:** Task 16.` |
| T16 per-task spec Blocks | L974 | ✓ Enumerates T17 + T19 with structural reason ("extends `scripts/_resolve-lib.sh` ... matrix-lookup-time `[second-reviewer-same-vendor]` halt") |
| T19 DoD ownership of halt | L1136 | ✓ `_resolve-lib.sh`'s host × vendor matrix lookup halts loudly with `[second-reviewer-same-vendor]` |
| T19 test expectation for halt | L1148 | ✓ `test-routing-matrix-application.bats` proves halt behavior |
| T20 deps preserve chain | L1172 | ✓ `Task 09, Task 11, Task 12, Task 13, Task 19` — T16→T19→T20 chain intact |
| AC #2 still names halt | L22 | ✓ `_resolve-lib.sh` `[second-reviewer-same-vendor]` halt invariant present |

The structural ownership relocation from round-05 (T16→T19) is now backed
by an explicit dep edge. Parallel-execution schedulers cannot land T19
before T16 creates `_resolve-lib.sh`.

### Fix 2: AC #2 T39 halt enumeration extension

All four newly-enumerated T39 halts have matching backing in T39's task
spec:

| AC #2 enumeration item | T39 backing |
|---|---|
| `resolves outside repository` halt (symlink-escape) | Scope L2224 (outside-root); DoD L2253 (realpath canonicalization, `resolves outside repository` diagnostic); test L2268 (symlink-escape regression with matching diagnostic phrase) |
| include-cycle halt with the full cycle printed | Scope L2223-L2224 (cycle detection, full cycle printed); test L2261 (cycle failure case); acceptance fixture L2267 (deliberate include-cycle failure with required diagnostics) |
| malformed `!cat` directive and missing-target halts with `file:line` diagnostics | Scope L2224 (file:line plus reason for malformed lines and missing targets); test L2261 (malformed + missing-target failure cases) |
| `${CLAUDE_SKILL_DIR}` shipped-file halt | Scope L2224; DoD L2247 (shipped-file grep proves zero remaining); test L2262 (grep audit); acceptance fixture L2267 (legacy `${CLAUDE_SKILL_DIR}` directive failure) |

AC #2 is now bill-of-materials complete for T39's documented fail-loud
surface. Test phase can construct seeded regressions for all four halts.

## What I deliberately did not refile

The following surfaces were dropped in round-06 below threshold and the
underlying conditions are unchanged in round-07; re-filing would be noise:

- **L110 narrative description of dep ordering** (round-06 F02, clarity 60).
  Dep graph item 2 still mentions only T16→T17 (G22→G23) and not T16→T19,
  but per the section's own framing ("Three cross-slice dependency clusters
  dominate; everything else within-slice"), within-slice T16→T19 is
  correctly not enumerated. The dep edges themselves (L65/L1103) are the
  authoritative ordering signal.
- **T16/T19 carve-out symmetry stale wording** (round-06 F03, clarity 45).
  T16 scope L986 mentions "host/vendor routing lookup" and T19 scope L1116
  mentions "host × vendor matrix and default-second-reviewer lookup
  helpers". On careful reading these are non-overlapping (T16: tier→vendor
  base routing; T19: second-reviewer slot matrix extension), but the
  vocabulary overlap remains presentationally suboptimal. Below clarity
  threshold and acknowledged in disposition.

## Spec coverage check (random spot-check of 35 goals)

Confirmed goal→task→test-expectation traceability remains intact post-fix
for the surfaces touched by the round-06 edits:

- **G27** (T19) — problem framing (Claude-only Codex glob → silent Copilot
  opt-out) → T19 scope L1117 (Goals/using-qrspi migration) → T19 DoD L1130-L1136
  (probe behavior, halt diagnostics, same-vendor halt) → test expectations
  L1141-L1148 (executability, override boundary, shared-source, halt
  behaviors). Covered.
- **G22** (T16) — T19 dep addition does not change G22 surface coverage.
  T16's blocks line update is structural, not functional. Covered.
- **G32** (T39) — AC #2 extension brings master fail-loud enumeration into
  alignment with T39's own DoD/test expectations. No goal coverage change;
  the gap was that AC #2 omitted halts T39 already specified. Closed.

## Conclusion

Round-06's two surgical fixes are spec-coherent across all touch surfaces
(task list, per-task specs, AC #2, dep graph implications, T20 chain
preservation). No new spec-altitude defects introduced; no prior-round
findings re-surface above threshold. **Clean.**

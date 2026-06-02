---
round: 6
artifact: plan.md
fixes_applied: 2
findings_dropped: 8
findings_kept: 3
clean_sentinels: 6
verifier_enabled: true
---

# Round 6 dispositions — broaden-vs-main

## Summary

Round 6 ran 14 reviewers (7 Claude + 7 Codex) against the full plan.md
broaden-vs-main diff. Eleven findings filed, three kept by the verifier
(78, 75, scope-bypass), eight dropped (5 below correctness threshold of 70,
2 below clarity threshold of 80, 1 dropped at verifier score 22 against
gtx-claude's positive concurrence). Six clean sentinels.

Two surgical fixes applied to plan.md (3 edits total for E1; 1 edit for E2).

## Kept findings and applied fixes

### E1 — T19 missing `Dependencies: Task 16` (correctness)

**Sources (convergent):**
- `quality-claude.finding-F01.md` — verifier 78 KEEP
- `quality-codex.finding-F01.md` — verifier 75 KEEP
- (`silent-failure-codex.finding-F01.md` — verifier 55 DROP, same root)

**Defect:** T19 declares `Dependencies: none` but cannot start independently
of T16. T16 creates `scripts/_resolve-lib.sh`; T19 extends it with the
host × vendor matrix helpers and now (post round-05) owns the
matrix-lookup-time `[second-reviewer-same-vendor]` halt. The halt that
round-05 moved from T16 to T19 lives in T19's helpers on T16's structural
foundation — no dep edge means parallel-execution scheduling permits T19
to land before T16, producing either a stub conflict or a hard fail.

**Edits applied:**
- **L65** (task list): `Task 19 ... deps: none` → `deps: [Task 16]`
- **L1103** (T19 per-task spec): `**Dependencies:** none.` → `**Dependencies:** Task 16.`
- **L974** (T16 per-task spec): `**Blocks:** T17 (...)` → `**Blocks:** T17 (...); T19 (extends scripts/_resolve-lib.sh with the host × vendor matrix and default-second-reviewer lookup helpers and the matrix-lookup-time [second-reviewer-same-vendor] halt).`

### E2 — AC #2 omits T39 build-pipeline halts (scope-bypass)

**Source:** `security-claude.finding-F01.md` — verifier 50 (scope-bypass KEEP)
(Companion: `security-codex.finding-F02.md` — verifier 60 DROP correctness threshold;
both findings flag the same surface, sec-claude's scope-bypass is the canonical keep.)

**Defect:** Round-05 extended AC #2 to enumerate T39's symlink-escape
canonicalization halt, but four other T39-required build-pipeline halts
remain unenumerated in the master fail-loud list: include-cycle, malformed
`!cat` directive, missing `!cat` target, and `${CLAUDE_SKILL_DIR}`
shipped-file halt. AC #2 is the bill-of-materials Test phase reads to
construct seeded-regression coverage; an incomplete enumeration means
Test can mark AC #2 green without ever firing the missing seeds.

**Edit applied:**
- **L22** (Phase 1 AC #2): extended the trailing clause to enumerate the
  four additional T39 halts (`include-cycle ... with the full cycle
  printed`, `malformed !cat directive and missing-target halts with
  file:line diagnostics`, `${CLAUDE_SKILL_DIR}` shipped-file halt). T39's
  Test Expectations already cover all four with regression fixtures — no
  per-task DoD changes needed.

## Dropped findings (8)

| Finding | Score | Threshold | Reason |
|---|---|---|---|
| quality-claude.F02 (L110 narrative misattribution) | 60 | clarity ≥80 | Below clarity threshold; narrative is non-load-bearing prose, the deps field itself (correct) is the authoritative ordering signal |
| quality-claude.F03 (T16/T19 carve-out symmetry stale) | 45 | clarity ≥80 | Below clarity threshold; DoD bullets are correct on careful reading, carve-out polish is presentational |
| security-codex.F01 (T34 missing/malformed-header halts) | 50 | correctness ≥70 | Below correctness threshold; T34's halts are existing in DoD, AC #2 enumeration is the disagreement |
| security-codex.F02 (T39 extras, codex framing) | 60 | correctness ≥70 | Below correctness threshold; same surface as sec-claude.F01 which is the scope-bypass keep — fix applies via E2 |
| silent-failure-codex.F01 (T19 dep, fail-loud framing) | 55 | correctness ≥70 | Below correctness threshold; same root issue as qty-claude.F01 — fix applies via E1 |
| test-coverage-codex.F01 (T19 grep-OR-test disjunct) | 22 | correctness ≥70 | Strong verifier disagreement; disjunct preserves implementation flexibility |
| goal-traceability-codex.F01 (G25/G29 not in matrix) | 20 | correctness ≥70 | Strong verifier disagreement; gtx-claude (clean) confirms absorption disposition at L11 is sufficient — G25→CD-1 mirror-paragraph and G29→T11 relabel are documented absorptions |
| spec-codex.F01 (R1–R7 reviewer-judgment T27/T33/T37/T38) | 35 | correctness ≥70 | Strong verifier disagreement; R1–R7 IS the deterministic framework for content-semantic tasks at the appropriate altitude |

## Convergence-pattern observation (round-05 → round-06)

Round-05's surgical halt-move from T16→T19 highlighted that T19's deps
were structurally inconsistent with the new ownership — T19's matrix-lookup
helpers extend T16's foundation but the deps field said `none`. Round-06
caught this is exactly the system working correctly: each round's fix
surfaces the next layer of related issues; convergence is progressively
narrower scope, not monotonic decrease in finding count.

Round-04 → Round-05 → Round-06 sequence:
- R4 fix to T16 same-vendor halt → R5 qty-claude.F01 (ownership: T16→T19)
- R5 fix to T19 halt move → R6 qty-claude.F01 (deps edge: add Task 16)
- R5 fix to AC #2 (T39 canonicalization halt) → R6 sec-claude.F01 (AC enumeration: add 4 more T39 halts)

Each round's scope contracts to the affected surface, not the artifact as
a whole. Three rounds of 1–3 surgical edits each have collectively
hardened: the same-vendor halt ownership chain, the T19→T16 dependency
graph, and the AC #2 master enumeration completeness.

## Plugin friction filed during round (v0.7.3 candidates)

- Claude reviewer agents (test-coverage, goal-traceability, security)
  write sentinel/finding files using a generic `claude.<finding-id>.md`
  filename instead of the canonical `<reviewer_tag>.<finding-id>.md` per
  reviewer-protocol. Orchestrator had to rename 3 files this round to
  avoid collisions when multiple Claude reviewers wrote `claude.clean.md`
  or `claude.finding-F01.md`. Other Claude reviewers (quality,
  silent-failure) get this right — inconsistent across the suite.
- Claude quality-reviewer used `change_type: required` / `change_type: optional`
  values which are not in the enum (style|clarity|correctness|scope|intent).
  Orchestrator had to normalize 3 files to `correctness`/`clarity`. The
  schema-violation guard at step 2 would have hard-failed these without
  the normalization pass.

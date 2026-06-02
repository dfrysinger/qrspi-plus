---
round: 5
date: 2026-06-02
artifact: plan.md
verifier_enabled: true
total_findings: 5
kept: 3
dropped: 2
clean_sentinels: 9
applied: 3
declined: 0
---

# Round-05 dispositions

## Reviewer fan-in (broaden vs main)

- **Reviewers dispatched:** 14 (7 Claude qrspi-plan-* + 7 Codex code-review/gpt-5.3-codex)
- **Clean sentinels (9):** spec-claude, scope-claude, silent-failure-claude, goal-traceability-claude, test-coverage-claude, spec-codex, silent-failure-codex, scope-codex, goal-traceability-codex
- **Findings (5):** quality-claude.F01, quality-codex.F01, security-claude.F01, security-codex.F01, test-coverage-codex.F01

## Verifier filter

All 5 findings verified (Haiku 4.5, 0 flakes — 30-50s each).

| Finding | change_type | Score | Threshold | Decision |
|---|---|---|---|---|
| quality-claude.F01 | correctness | 70 | 70 | KEEP (at floor) |
| quality-codex.F01 | correctness | 80 | 70 | KEEP |
| security-claude.F01 | scope | 62 | bypass | KEEP (scope-bypass) |
| security-codex.F01 | correctness | 22 | 70 | DROP |
| test-coverage-codex.F01 | correctness | 35 | 70 | DROP |

## Applied (3)

### A1 — qty-claude.F01: T16 same-vendor halt re-ownership to T19

**Finding:** Round-04 added the `[second-reviewer-same-vendor]` halt as a T16 DoD bullet + test expectation. T16's `In` only carves primary-slot routing; the host × vendor matrix and default-second-reviewer lookup helpers are owned by T19 (T19 In bullet at L1118). Both tasks modify `_resolve-lib.sh` with no T16↔T19 dep edge, violating Plan SKILL's task-self-containment HARD-GATE.

**Edits:**
- Removed `_resolve-lib.sh halts loudly with [second-reviewer-same-vendor]` DoD bullet from T16 (was L1002).
- Removed corresponding test expectation from T16 (was L1016).
- Added DoD bullet to T19 attributing the halt to T19's matrix lookup (L1136), with a parenthetical noting `second-reviewer-available.sh` checks reachability only.
- Added test expectation to T19 (L1148) wired to `tests/unit/test-routing-matrix-application.bats` (which T19 already owns).
- Removed T19 Out bullet that deferred halt enforcement to T16 (was L1127) — T19 now owns the halt directly.
- Re-attributed AC #2's `_resolve-lib.sh [second-reviewer-same-vendor] halt` enumeration item (no per-task attribution needed; the script is created by T16 and extended by T19; AC enumerates surfaces, not owners).

This reverses round-04's over-fix and lands the halt at its correct altitude (matrix lookup, T19).

### A2 — qty-codex.F01: T39 dep edge correction

**Finding:** T39's `deps:` field on the task list (L92) and per-task spec (L2211) said `[Task 25]` only, but Dependency Graph item 3 (L104) says `G3 → G16 → G32` (T20 → T21 → T39); T39's own DoD at L2254 explicitly mirrors T21's path guard; T39's regression test at L2269 references T21. L110 also contradicted L104. Implement schedules by `deps:`, so the gap was materially actionable.

**Edits:**
- T39 task list (L92): `deps: [Task 25]` → `deps: [Task 21, Task 25]`.
- T39 per-task spec (L2210): `Dependencies: Task 25` → `Dependencies: Task 21, Task 25`.
- Within-slice narrative (L110): rewrote "Slice 1.7 is otherwise independent of Slices 1.1–1.6 (only T39 depends on T25...)" → "...except that T39 depends on T25 for the defensive-copy site and on T21 for the renamed `scripts/dispatch-agent.sh` path under the `build/` allow-list and `!cat` resolver inspection."

### A3 — sec-claude.F01: AC #2 build-pipeline canonicalization halt

**Finding:** AC #2 enumerates T21's path-canonicalization guard but omits T39's structurally-identical guard at `tools/build-plugin.mjs` that the plan itself (L2254) says "mirrors T21." Without the AC enumeration, the symlink-escape exfiltration surface lacks a Phase 1 cross-task observable check.

**Edits:**
- AC #2 (L22): extended the fail-loud enumeration with "`tools/build-plugin.mjs` `resolves outside repository` halt when a `!cat` target canonicalizes outside `$REPO_ROOT/` (symlink-escape exfiltration surface)".

## Dropped (2 — sub-threshold)

### D1 — sec-codex.F01: probe-failure silent downgrade (correctness, 22)

**Finding:** Per skill `second-reviewer-available.sh` probe-failure → `second_reviewer: false` is fail-open.

**Verifier reasoning:** Altitude mismatch — design.md D3 explicitly says "skip silently" with stderr `[second-reviewer-unavailable]` diagnostic (already required by plan L1134). Design's D4 enforces a loud halt at dispatch time if a `true` value is hand-edited in. The proposed "fix (b)" is substantively already met; "fix (a)" contradicts a recorded design posture.

**Disposition:** Drop. Would require a backward loop to Design to re-litigate D3. No new evidence forcing that loop; design intent is explicit and the stderr diagnostic is already enumerated. Note: filing as v0.7.3 plugin issue candidate — the verifier correctly caught a "Plan reviewer flagging a documented Design D3 decision" anti-pattern.

### D2 — tc-codex.F01: T16 dispatch-order test expectation (correctness, 35)

**Finding:** T16 scope L990 requires preserving TDD dispatch order; Test Expectations include no ordering assertion.

**Verifier reasoning:** T16 is a routing-schema migration that does not touch dispatch sequencing (governed by Implement/Test skills with existing tests); co-escalation (the routing-relevant half of the contract) is already covered at L1022. Explicit ordering test is a nice-to-have non-regression net rather than a load-bearing omission.

**Disposition:** Drop. Per F-5 fix-altitude rule — dispatch sequencing is implementation-altitude infrastructure that lives in Implement/Test SKILL constraints, not in this routing-migration task spec.

## Round-04 ↔ round-05 convergence pattern

Round-04's T16 same-vendor halt fix introduced round-05's quality-claude.F01 by assigning the contract to the wrong owner. Cross-task contract drift is exactly what "till clean" broaden rounds are designed to surface — round-NN's fix becomes round-(NN+1)'s finding. Convergence is not monotonic decrease in finding count but rather progressively-smaller surface area on the kept-findings set.

## Loop decision

Round-05 applied 3 surgical edits across T16/T19/T39 + AC #2. Round-04 also touched AC #2 and T16/T19. A round-06 will broaden to base-branch and verify the latest edits don't introduce new stragglers, particularly:
- T16 DoD/test removals didn't break any cross-references.
- T19 DoD/test additions are coherent with T19's existing matrix-lookup scope.
- T39 dep edge addition didn't break the dep-graph narrative.
- AC #2 enumeration addition is consistent with T39 DoD wording.

Recommend round-06.

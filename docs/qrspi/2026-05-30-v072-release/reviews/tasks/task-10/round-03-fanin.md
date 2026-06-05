# Task 10 — Round 3 Fan-in

**HEAD before fix:** `0b29faa…` (R2 fix commit)
**Round-03 diff:** `round-03.diff` (469 lines from base `7aa0ecc`)
**Reviewers run:** spec (claude + codex). Spec gate is GATING — fan-out not yet dispatched.

## Spec gate result: **NOT CLEAN — 4 scope/spec findings**

The R3 spec gate caught **major scope drift introduced by R2 fix**. This is an orchestrator failure: my R2 fan-in disposed reviewer findings as "KEEP/fix in R2" without re-validating each finding against the task-10 spec In/Out-of-scope clauses.

## Convergence map

| # | Finding | spec-claude | spec-codex | Combined | Disposition |
|---|---|---|---|---|---|
| A | `scripts/verifier-fan-in.sh` modified despite explicit spec L31/L44/L57 prohibition | MED scope | HIGH scope | **HIGH (max)** | REVERT |
| B | On-error branch + new test file outside target list = scope-creep | LOW info | MED scope | **MED (max)** | REVERT (file PI-V072-T10-001 for v0.7.3) |
| C | Success template `defect_class:` not LAST — violates Fix E's own invariant | MED correctness | — | **MED** | REORDER (move `reason:` before `defect_class:`) |
| D | `representative_score:` rename — spec L42/L54 says "each score" plural | (clean ✅) | HIGH correctness | **AMBIGUOUS** | KEEP `representative_score:` + file PI-V072-T10-005 to disambiguate spec text in v0.7.3 |

## Decision rationale for D

Spec language is genuinely ambiguous:
- L42: "each finding's defect class, **each score**, and the threshold that dropped it"
- L54: "defect_class tags, **scores**, and threshold"

Reading A (literal/per-finding): `contributing_findings:` list with per-entry scores
Reading B (cluster summary): single `representative_score:` with per-finding precision linked via `finding_paths[]` sidecar files

spec-codex defends Reading A. spec-claude defends Reading B as G28-intent-satisfied. Both readings are defensible.

**Choosing Reading B** because:
1. Implementation history shows flip-flop churn (R1 had Reading A → R1 fix flipped to single scalar → R2 fix renamed to `representative_score:`). Restoring per-finding structure would extend the churn without a clear convergent reading.
2. The implementer documented Reading B clearly with sidecar-file-link reasoning.
3. The design intent (informational observations, not data structure for tooling — per spec L43 "explicitly informational and not consumed by scripts in this release") favors a clean cluster-level summary.
4. Reading A reintroduces the verbosity that R2 reviewers (cq-claude, sf-claude) flagged as ambiguous in the first place.
5. The spec ambiguity itself is the real bug, filed as PI-V072-T10-005 for v0.7.3.

## R3 fix instructions (cycle 3 of 3 — last budget)

This is a **revert-heavy** cycle. Most edits are subtractions of out-of-scope R2 additions.

### Fix R3-1 — REVERT `scripts/verifier-fan-in.sh` header changes
Remove the 12-line field-ordering invariant documentation block added in R2 to the script header. The agent body invariant prose is sufficient and in-scope.

### Fix R3-2 — REVERT the test that pins fan-in header content
Delete the `@test "sidecar field-order: verifier-fan-in.sh header documents the invariant"` test added in R2.

### Fix R3-3 — REVERT on-error branch (Fix I)
Remove the "On any unrecoverable error during steps 1–5 … Never return without writing a sidecar." paragraph added before step 1 of the verifier procedure in `agents/qrspi-finding-verifier.md`. Out-of-scope. PI-V072-T10-001 tracks this for v0.7.3.

### Fix R3-4 — REVERT on-error branch unit test
Delete the @test that pins the on-error paragraph (corresponds to Fix I).

### Fix R3-5 — REVERT `unspecified` tightening (Fix H)
Restore original prose at agent L96 and L119: "literal `unspecified` is also valid when failure produced no defect signal". Remove the closed taxonomy list (`verifier-crash`, `infrastructure-failure`, `tool-error`, `file-missing`, `rate-limited`, `parse-error`) and the "best-effort classification" prose. Out-of-scope — spec L39 just says "`defect_class: unspecified` rather than omitting the field" with no taxonomy requirement.

### Fix R3-6 — REVERT unspecified taxonomy unit test
Delete the @test pinning the closed-taxonomy prose.

### Fix R3-7 — REVERT summary-quoting prose (Fix G)
Remove the "summary: MUST be enclosed in double quotes; any `\"` characters in the value MUST be escaped as `\\\"`. Orchestrators MUST NOT copy reviewer finding text verbatim..." prose from `skills/using-qrspi/SKILL.md`. Out-of-scope — spec L42 just says "observation summary" with no shape constraint.

### Fix R3-8 — REVERT summary-quoting AC5 sub-assertion
Remove the AC5 sub-assertion that checks summary-quoting prose.

### Fix R3-9 — REORDER success template (spec-claude F01)
In `agents/qrspi-finding-verifier.md`, move `reason:` to BEFORE `defect_class:` in the SUCCESS template so `defect_class:` is unconditionally last. Update the corresponding unit test to assert `defect_class:` is the last field on the success path (currently the success-template test only asserts score < defect_class line numbers).

### Fix R3-10 — CONSOLIDATE remaining tests into in-scope file + DELETE new test file
After applying Fix R3-2, R3-4, R3-6: review what tests remain in `tests/unit/test-verifier-agent-file.bats`. Tests that should be retained (path-traversal pins, success-template field-order pin, defect_class-last pin on success template) should MOVE into `tests/unit/test-verified-file-shape.bats` (which IS in the spec target-files list). Then DELETE `tests/unit/test-verifier-agent-file.bats`.

### KEEP (do NOT revert) — Fix F path-traversal
Path-traversal constraint on `finding_paths[]` in `skills/using-qrspi/SKILL.md` HAS a spec hook (L42 "relative to the artifact directory"). Keep the prose constraint and the AC5 sub-assertion that checks `! grep -qE '(\.\./|^\s*-\s*/)'`.

### KEEP — `representative_score:` (Reading B)
Per the decision rationale above. Add a comment in the SKILL.md prose noting the spec ambiguity will be clarified in v0.7.3 (PI-V072-T10-005).

## Acceptance for this fix-cycle

1. All R3-1 through R3-10 fixes land.
2. Diff stays within the 4 spec-target files: `agents/qrspi-finding-verifier.md`, `skills/using-qrspi/SKILL.md`, `tests/unit/test-verified-file-shape.bats`, `tests/acceptance/v07-phase1/test-phase1-acceptance.bats`. **NO changes to `scripts/verifier-fan-in.sh`**. **`tests/unit/test-verifier-agent-file.bats` deleted** (net negative diff for that file).
3. All R3 KEEP items remain (representative_score, path-traversal constraint, field-order invariant prose in agent body, success template ordering fix).
4. Bats test count adjusts but all GREEN. The acceptance count should land at 84 (acceptance) and `test-verified-file-shape.bats` grows by ~5 tests (the retained moved ones).
5. Repo-wide test count adjusts — net should drop from 1566 because we're removing tests added with the reverted prose, but with the moved tests it should land near baseline.

## Budget status

This is **fix-cycle 3 of 3** — last available. If R4 spec/correctness reviews don't come back CLEAN, escalate to user (no more fix budget without escalation).

## Plugin-issue backlog adds

- PI-V072-T10-004: orchestrator fan-in does not re-validate findings against task spec scope (process gap; filed)
- PI-V072-T10-005: task-10 spec text "each score" ambiguous between Reading A/B (filed)

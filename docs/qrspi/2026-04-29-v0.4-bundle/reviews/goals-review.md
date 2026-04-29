# Goals review

## Round 1 — Claude

### MAJOR
- **R1-F01** (correctness): Constraints bullets 8 and 9 (empirical-evidence-basis + four-hypotheses) are not environmental constraints. → Move to Purpose / Cross-Cutting Notes.
- **R1-F02** (scope): G7 "Carry residuals from R5 (M5-1, M5-2, M5-3, L5-1, L5-2, L5-3)" reads as commitments, not candidates. → Reframe as problem-state question for Design.

### MINOR
- **R1-F03** (clarity): G6 Problem leads with narrow F-35 defect; broader removability question surfaces only in Why we care. → Lead Problem with the broader claim.
- **R1-F04** (clarity/scope): G8 type `known-fix` is debatable; Candidate C explicitly says "research needed before commitment." → Downgrade type to `exploratory` with a note.
- **R1-F05** (correctness, borderline NIT): G3 + G6 both carry "Process candidate" doctor-lint suggestions; could fold into a 13th goal. → Declined, not over-fragmenting.

### NIT
- **R1-F06** (style): Bullet convention inconsistency. → Declined.
- **R1-F07** (style): Issue numbers in goal headings vs G8's own thesis. → Declined; goals.md lives in `docs/qrspi/` so G8's strictest candidate carves it out.

**Verdict:** APPROVE-WITH-MINOR-FIXES.

## Round 1 — Scope-Reviewer

### Boundary-drift
- **R1-F01** (medium scope): G2 test-debt sentence has assertion shape (N+1 invocations). → Reframe as candidate.
- **R1-F02** (low scope): G3 test-debt sentence is acceptance-criteria-shaped. → Reframe as candidate.
- **R1-F03** (medium scope): G3 "fix shape is mechanical: update X across Y, Z, A" prescribes file-mapping. → Reframe as problem-state.
- **R1-F04** (high scope): G4 six-part numbered fix list is detailed solution definition (specific JSON paths, line numbers, test thresholds). → Reframe as problem-state observations.
- **R1-F05** (high scope): G11 "Edit sites identified" prescribes specific files + exact reviewer-prompt text. → Reframe as candidates.
- **R1-F06** (low scope): G7 R5 residuals enumeration reads as task list. → Same as Claude R1-F02.
- **R1-F07** (low scope): G4 "(covered by G5)" is dependency-tracking. → Drop parenthetical.

### Scope-compliance
None — all OWNS entries satisfied (purpose, constraints, per-goal type + 3 subsections, optional Cross-Cutting Notes).

**Verdict:** MINOR-DRIFT.

## Round 1 — Codex

### MAJOR
- **R1-F01** (scope): G6 broadens #56 from "dedupe one helper" to "is state.sh justified at all" — exceeds source issue scope.
  → **Declined.** User explicitly directed this scope expansion in-session (project memory: `v0.4 bundle hypotheses to test before codifying`). The broader hypothesis is intentional, not drift.
- **R1-F02** (scope): G7 broadens #91 from Bash-containment to "all hook enforcement" — exceeds source.
  → **Declined.** Same rationale: user-directed in-session hypothesis test.
- **R1-F03** (scope): G8 not faithful to #93 + mis-typed as known-fix; widens to external-tracker-IDs and comment/test policy.
  → **Partially accepted.** User-directed expansion stands, but type downgrade applies (per Claude R1-F04). G8 reframed as `exploratory` with bounded-vs-unbounded-split note.
- **R1-F04** (clarity/scope): G3, G4, G11 written at Design/Structure/Plan altitude.
  → **Accepted.** Same content as Scope-Reviewer R1-F03/F04/F05. Reframing all three.

### MINOR
- **R1-F05** (correctness): Purpose overstates provenance (some issues are follow-on methodology hardening, not pure 2026-04-26 run findings).
  → **Accepted.** Soften Purpose claim.

**Verdict:** NEEDS-FIXES.

## Post-review fixes (round 1)

Applied to goals.md:

1. Moved 2 non-constraint bullets out of Constraints (empirical-basis bullet folded into Purpose; four-hypotheses bullet moved into Cross-Cutting Notes).
2. G2 test-debt sentence → reframed as candidate.
3. G3 "fix shape mechanical: update X across Y" → reframed as problem-state.
4. G3 test-debt sentence → reframed as candidate.
5. G4 six-part numbered fix list → reframed as problem-state observations.
6. G4 "(covered by G5)" → dropped parenthetical.
7. G6 Problem reordered → lead with broader removability claim.
8. G7 R5 residuals → reframed as problem-state question Design must answer.
9. G8 type → downgraded to `exploratory`; note added on bounded-vs-unbounded split.
10. G11 "Edit sites identified" → reframed as candidates.
11. Purpose softened on provenance per Codex R1-F05.

Declined: Codex R1-F01/F02 (and the source-faithfulness slice of R1-F03) — user-directed scope expansions per project memory.

## Round 2 — Claude

**Verdict:** APPROVE-CLEAN. All 11 round 1 fixes verified resolved. No new findings. Pass A confirmed each fix bullet; Pass B re-ran the contract sweep end-to-end and surfaced no fresh contract violations.

## Round 2 — Scope-Reviewer

**Verdict:** IN-SCOPE-CLEAN. All 7 round 1 boundary-drift fixes landed cleanly with no over-correction. Pass B re-ran the OWNS/DEFERS sweep and cleared all candidate-framed concrete content (G7 sandbox config keys, G8 grep regexes, G6 named-function refactor) as appropriately specific candidate detail (comparable to the SKILL's Rate Limiter worked example).

## Round 2 — Codex

**Verdict:** APPROVED-WITH-MINOR-FIXES. Two findings:

- **R2-F01** (correctness): G2 "Note for Design" said "if G1 lands fix-path (a) — i.e., 3-level dispatch is confirmed feasible and kept", contradicting the new four-hypotheses bullet's "G1 — the 3-level Implement hierarchy may collapse to 2-level via fix-path (a)." Per issue #51, fix-path (a) IS the flatten-to-2-level path.
  → **Accepted.** G2 Note rewritten to match issue #51 semantics: fix-path (a) = flatten to 2-level (Candidate B); fix-path (a) + Candidate C structurally enforce separation; Candidate A (keep 3-level) leaves the directive load-bearing.
- **R2-F02** (contract): "G10 in-session validation" Cross-Cutting bullet was goal-local and redundant with G10's own "What we know so far" + the four-hypotheses bullet.
  → **Accepted.** Removed from Cross-Cutting Notes.

Pass A: all round 1 fixes verified including the user-directed G6/G7/G8 expansions internally coherent.

## Post-review fixes (round 2)

Applied to goals.md:

1. G2 Note for Design rewritten to align with issue #51's fix-path (a) semantics (flatten = (a) = Candidate B).
2. G10 in-session-validation bullet removed from Cross-Cutting Notes (redundant with the four-hypotheses bullet and G10's own "What we know so far").


---
round: 3
artifact: phasing
status: fixing
---

# Phasing Round 3 dispositions

## Findings inventory

- quality-claude: 2 (medium=2)
- scope-claude: 1 (medium=1)
- quality-codex: 2 (high=1, medium=1)
- scope-codex: 0 (clean — 1st consecutive)

Total: 5 findings, 1 HIGH. All accept.

Convergence trend: round 1 (9 → 4 distinct), round 2 (6 → 4 distinct), round 3 (5 distinct). Tightening. scope-codex first clean.

**Slice 5 tension:** Round 2 stripped Slice 5 to outcomes-only (boundary drift fix). Round 3 says now it's too thin (under-specifies G10 reference-gate semantics; layer enumeration missing; sibling-awareness criterion not checkable). The right balance: phase-level OUTCOMES that name what must be observable (gate pauses, approval recorded, reviewer output references siblings) WITHOUT specifying mechanism (wave numbers, approval implementation, specific data structures).

## ACCEPT (5 distinct)

### R3-F02 quality-codex (HIGH, correctness) — Slice 5 under-specifies G10 reference-gate semantics

The approved design (G10) says a reference-gated task pauses downstream dispatches until approval, and the approval is recorded. Round 2 stripped these from Slice 5 as boundary drift. Result: Phase 1 could pass with only a "render reference inline" check, missing the load-bearing gate behavior.

**Fix:** Add outcome-level (NOT mechanism-level) blocking + recording criteria to Slice 5 description and replan-gate criterion:
- Description addition: "Reference-gated tasks pause downstream dispatches at the human gate until explicit approval is recorded."
- Gate criterion addition: "A reference-gated UI task can be observed pausing dependents from dispatching until approval is recorded; the approval record persists so subsequent re-runs and audits can verify the gate fired and was cleared."

Do NOT reintroduce wave-numbering, task-spec field names, or implementation procedures — those remain Plan/Parallelize/Implement-owned.

### R3-F01 quality-claude (medium, clarity) — Slice 5 missing layer enumeration

Every slice except Slice 5 names the layers it spans (e.g., "skill layer," "agent layer," "orchestrator layer"). Reader cannot confirm verticality.

**Fix:** Add layer enumeration to Slice 5: "Layers touched: skill layer (human-gate path), reviewer agent layer (visual-fidelity reviewer), and orchestrator layer (gate sequencing across dependents)."

### R3-F02 quality-claude (medium, correctness) — Slice 5 sibling-awareness criterion not checkable

"Demonstrates awareness of sibling reviews" / "referencing sibling findings rather than re-proposing the same change" is not concretely observable; requires inferring intent.

**Fix:** Rewrite the sibling-awareness criterion to a concrete observable: "The visual-fidelity reviewer's output for a UI task dispatched alongside sibling UI tasks contains either (a) at least one explicit reference to a sibling task's findings, or (b) an explicit statement that no relevant sibling visual context was found — observable in the reviewer's emitted finding files."

### R3-F01 quality-codex (medium, correctness) — Goal-ID Consistency G16 pointer incomplete

The G16 pointer names only `future-goals.md` and `future-design.md`, but the deferred bundle also touches `future-questions.md` and `future-research-summary.md` (with the documented Q21-in-current-summary exception).

**Fix:** Expand the Goal-ID Consistency G16 pointer to: "G16 carries `phase: future` and is deferred to a later release; its full context spans `future-goals.md`, `future-questions.md`, `future-research-summary.md`, and `future-design.md`. The Q21 research-summary entry stays in current `research/summary.md` (research/q*.md files are not split per the Phasing skill contract); `future-research-summary.md` carries pointers to the in-place Q21 finding. No orphan IDs."

### R3-F01 scope-claude (medium, scope) — phasing.md missing Pruning Summary section

Phasing OWNS current-phase pruning + future-* maintenance, but phasing.md has no section documenting what was pruned. Reader cannot audit the pruning boundary from phasing.md alone.

**Fix:** Add a new `## Pruning Summary` section between `## Goal-ID Consistency` and `## Orphan IDs`. Format: per-artifact, one line each:
- `goals.md` — current-phase: G1–G15, G17, G18. Deferred to `future-goals.md`: G16.
- `questions.md` — current-phase: Q1–Q20, Q22. Deferred to `future-questions.md`: Q21.
- `research/summary.md` — kept intact as full corpus (research/q*.md files are not split per Phasing skill contract); `future-research-summary.md` carries pointers to the Q21/G16 finding location.
- `design.md` — current-phase: G1–G15, G17, G18 + Decisions 1–10. Deferred to `future-design.md`: G16 + FD-01..FD-04 (round-18 design deferrals).

## Fix dispatch plan

Single fix subagent. 5 distinct accepts. All in phasing.md.

## Status

draft → fixing → re-review round 4.

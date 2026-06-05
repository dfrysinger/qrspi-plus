---
finding_id: R2-F01
severity: medium
change_type: correctness
artifact: design
round: 2
reviewer: quality-claude
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/design.md
---

## Test Strategy § Cross-cutting invariants — CD-2 clause assigns T2 to SKILL.md consumer lint, outside T2's `scripts/` coverage boundary

**Location:** `design.md` L732 (Test Strategy § Cross-cutting invariants)

**Problem.** The CD-2 cross-cutting invariant reads:

> "CD-2 evergreen-output rule (T2 lint on `_shared/evergreen-output-rule.md` consumers + T5 contract check)."

T2's coverage boundary is explicitly defined at L720:

> "Coverage boundary: one bats file **per script under `scripts/`**; covers happy path + every named exit code..."

The consumers of `_shared/evergreen-output-rule.md` are artifact-producing SKILL.md files (e.g., `skills/goals/SKILL.md`, `skills/research/SKILL.md`) — not scripts under `scripts/`. A check that every consumer SKILL.md carries a `!cat skills/_shared/evergreen-output-rule.md` line is a grep-based content assertion over markdown prose files. That is T1 (static-analysis lint) territory — or, at most, a G21-style lint gate (a bats test in `tests/lint/`, not a per-script T2 test). T2 as defined cannot own this check without broadening its stated boundary.

**Impact.** Plan authors following the Test Strategy taxonomy would try to author a T2 bats test covering SKILL.md consumer files — a task that contradicts T2's own coverage boundary definition. This either: (a) forces Plan to silently extend T2's boundary, creating ambiguity in the release taxonomy, or (b) results in no test being written for the CD-2 invariant at all.

**Suggested fix.** Change the invariant assignment from "T2 lint" to either:
- "T1 lint" (a `grep -L '!cat skills/_shared/evergreen-output-rule.md'` check run as part of CI static-analysis), or
- "T1 lint (via G21-pattern bats lint gate in `tests/lint/`)" if a bats-based lint pattern is preferred for consistency with G21's BW02 guard.

The T5 portion of this invariant ("T5 contract check") is separately addressed in F02.

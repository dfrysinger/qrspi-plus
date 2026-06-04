---
finding_id: R2-F02
reviewer_tag: spec-codex
severity: medium
change_type: clarity
referenced_files: [skills/implement/SKILL.md, scripts/round-prepare.sh]
---

# SKILL.md checklist L1189 describes pre-Fix-A write-then-assert ordering (contradicts L1205)

**Observed mismatch:**
- `skills/implement/SKILL.md` L1189 (between-rounds checklist step 4): "`round-prepare.sh` ... writes `round-NN+1-commit.txt = <passed-SHA>` on exit 0, **then asserts that prior-round artifacts** (`round-NN-commit.txt`, and `round-NN-scope-set.txt` when narrowing-eligible) exist and are well-formed."
- Actual order after Fix A (`scripts/round-prepare.sh`): Step 10 prior-artifact assertions (L186–219) run FIRST, anchor write (L228–237) runs AFTER.
- L1205 was correctly updated by the round-1 fix cycle: "the Step 10 prior-artifact presence assertions ... also fire **before** the anchor write."

L1189 and L1205 now contradict each other. L1189 still documents the old, vulnerable write-then-assert order that Fix A deliberately reversed.

**Why it matters:** L1189 is the operator-facing checklist step that describes sequencing; leaving it stale misleads operators about when the anchor is written on failure paths and undercuts the fail-closed invariant Fix A established.

**Disposition: ADOPT.** Rewrite L1189's "writes ... then asserts" clause to "asserts that prior-round artifacts ... exist and are well-formed, then writes `round-NN+1-commit.txt`". String-only doc fix — no refactor.

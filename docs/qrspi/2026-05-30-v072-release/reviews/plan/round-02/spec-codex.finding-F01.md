---
reviewer_tag: spec-codex
change_type: correctness
severity: high
artifact: plan.md
location: "Tasks 19 and 20 — G27 second-reviewer migration"
referenced_files:
  - plan.md
  - goals.md
---

# F01 — Plan breaks stated backward-compat + canonical-helper constraints

## Defect

Per goals.md constraints (lines 14–16) and G27 framing (lines 788–793): "do not change established contract"; `run-codex-review.sh` `detect_host()` + `check_codex_available()` are named as canonical helpers Goals should call.

Plan conflicts:

- **Task 20** hard-renames `run-codex-review.sh` away with explicit "no compatibility shim" (plan.md lines 1225–1251, 1260).
- **Task 19** introduces new host-detection primitives (`_host-detect.sh`, `second-reviewer-available.sh`) instead of consuming the stated canonical helpers (lines 1176–1181).

## Impact

Violates explicit goals constraints. Existing call sites (in user repos that already invoke `run-codex-review.sh` directly) will break. Parallel canonical-helper lineages diverge over time.

## Recommended fix

Either (a) keep `run-codex-review.sh` as a backward-compatible entrypoint that sources the new shared code (canonical shim), or (b) make the rename explicit in goals.md by relaxing the constraint AND document an explicit deprecation path with a migration guide. Plan as-written violates the goals contract.

## Counter-argument to consider

The constraint may have been relaxed during the Goals walk-through cycle — verify against the final approved goals.md. If the constraint genuinely IS still in force, this finding is high-severity; if relaxed but the goals text wasn't updated, this is a goals-doc bug, not a plan defect.

---
reviewer: silent-failure-claude
task: 33
round: 3
status: clean
---

# Silent Failure Hunter — Task 33 Round 3: Clean

Reviewed the round-03 diff against `agents/qrspi-plan-reviewer.md` and `skills/plan/SKILL.md`. The diff:

1. Replaces the prefix-based `structural_lint` path check with a strict ERE `^scripts/structural-lints/[A-Za-z0-9_.-]+\.sh$` (rejects whitespace, metacharacters, traversal, absolute paths, and non-token values in one rule).
2. Adds an explicit file existence + readability check (`[ -f "<path>" ] && [ -r "<path>" ]`) with a dedicated `severity: high, change_type: correctness` diagnostic and a "Do NOT proceed to Step 3" gate.
3. Switches script invocation from `bash <path>` to `bash -- <path>`, with prose forbidding `bash -c` interpolation.
4. Updates the SKILL.md defect list from 5 to 6 conditions and the reviewer cross-reference to match.

Silent-failure category sweep against the changed lines:

- **Swallowed errors:** Each new failure mode (regex fail, missing/unreadable script, empty diff, non-zero exit) emits a distinct `severity: high, change_type: correctness` finding. None are quietly absorbed.
- **Silent fallbacks:** Step 4's grant condition is a strict conjunction of four predicates with no default-grant branch. The denial fall-through ("apply the standard LOC ceiling … as if no exception were declared") is conservative (denies the exemption rather than silently granting it).
- **Missing error paths:** The new existence check closes a subtle implicit-handling case where a missing script would previously surface only as `bash` exit 127 under a generic "lint failed" finding. The round-3 path now produces a precise configuration diagnostic before execution. Net improvement, no regression.
- **Inappropriate transformation:** Findings preserve specificity — separate diagnostics for malformed value, missing/unreadable script, empty diff, and non-zero exit.
- **Log-and-continue:** Every defect emits a finding and denies the exemption; no log-only paths.
- **Partial state on failure:** Reviewer logic is read-only validation; no multi-step mutation surface.

The defect-list count update (5 → 6) and the reviewer cross-reference update keep the SKILL.md contract and reviewer rubric in sync, so a future failure mode cannot be silently dropped on one side.

Out-of-scope-but-noted (pre-existing, NOT introduced by this round, NOT raised as findings): the contract still does not specify *how* the structural-lint script obtains "the proposed diff" (no documented ref/env-var convention), and the reviewer's own "verify the proposed diff is non-empty" step does not specify the command/ref it uses. A script that picks the wrong ref and exits 0 could silently produce an undeserved exemption. These ambiguities predate round 3 and are arguably contract-completeness concerns for a follow-up task rather than silent-failure regressions in the diff under review.

Scope-hint surface (`agents/qrspi-plan-reviewer.md`, `skills/plan/SKILL.md`) covers the entire diff; no out-of-hint surface to flag.

No findings.

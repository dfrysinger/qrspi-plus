---
finding_id: F01
severity: low
category: scope
files:
  - skills/using-qrspi/SKILL.md
---

# F01 — Out-of-scope edit to `skills/using-qrspi/SKILL.md` (advisory, target-files deviation)

## What the spec says

`tasks/task-44.md` line 13:

> **Target files:** modify `tests/unit/test-using-qrspi-vocab.bats`; modify `tests/acceptance/v07-phase1/test-phase1-acceptance.bats`

And the Out-of-scope list (line 32):

> Editing the dispatch-routing prose itself — upstream dispatch-routing tasks settle that prose; this task only hardens the pins against the settled wording.

## What the diff does

The round-2 diff modifies a third file outside the Target list: `skills/using-qrspi/SKILL.md`, line 513. One phrase in the `Missing model_routing: block in config.md` H4 body is rewritten:

- before: `does not fire a transient warning and does not silently substitute defaults`
- after:  `does not fire a transient warning and uses no implicit default substitution`

The edit is semantically equivalent (both phrasings assert the same fail-loud behavior) and preserves the surrounding repair/abort guidance.

## Why the implementer made this edit

It resolves the constraint conflict identified in round-1 F01. The conflict was:

- DoD bullet 3 requires the regex to reject `silently substitutes the bundled default` (so the regex must include a `substitut` branch).
- The "stay green against settled prose" DoD bullet (line 40) requires the regex not to false-positive on the existing missing-block H4 body, which contained `does not silently substitute defaults`.
- The Out-of-scope list forbids editing the dispatch-routing prose itself.

These three constraints were unsatisfiable as written. By making a minimal semantically-equivalent prose change, the implementer enabled the broader `(fall|degrad|substitut)` regex without false-positives, satisfying F01's first listed regression phrasing.

## Why this is advisory, not blocking

- The change is one phrase, semantically equivalent, in the same H4 already under the pin's coverage.
- It directly closes the round-1 F01 gap (which the operator's only other documented options were "amend the task spec" or "rework with site-specific regex variants").
- The unit pin and acceptance pin are otherwise fully spec-compliant: all four sites pinned in place, all four `[ -n "$body" ]`-guarded, all three named anti-pattern phrases caught, no new helper or utility, scope otherwise limited to the four pin sites.

## Recommendation

Operator-level decision:

1. **Accept and retroactively amend the task spec** — note that the F01 constraint conflict was resolved by a one-phrase semantically-equivalent edit to the H4 body in `skills/using-qrspi/SKILL.md`, and that this small prose edit is the lowest-cost path to satisfying the DoD's substitut-branch requirement. Update the Target files list and/or the Out-of-scope clause to reflect.

2. **Rework** — back out the SKILL.md edit and instead vary the regex per pin site (broader regex on three sites, narrower on the missing-block site whose body needs to retain the negated phrase). This was option (b) in round-1 F01's recommendation. It keeps the prose untouched but introduces per-site divergence in the deployed regex.

I lean toward path 1: the prose edit is minor, semantically-preserving, and the simplest closure of the round-1 gap. But it is a documented out-of-scope edit, so the operator should be aware before merging.

# Silent-Failure Hunter — Task 35 Round 01 — CLEAN

Reviewer: silent-failure-claude
Scope: T35 anti-fabrication routing — `skills/reviewer-protocol/SKILL.md`
new `### Anti-Fabrication Rule (FAIL-LOUD)` section + `tests/acceptance/test-review-pause.bats`
G10 step.

## Verdict

No silent-failure findings.

## Categories examined

1. **Swallowed errors** — `extract_subsection` awk terminates explicitly on next
   heading, no silent fall-through. `review_round_side_effects` returns 1 with
   `ERROR-unknown-route` on unknown routes (fail-loud). `is_valid_conflict_exit`
   returns non-zero on unrecognized exit kinds.
2. **Silent fallbacks** — `classify_reviewer_chat_output` defaults non-matching
   first lines to `normal-review-round`, which is the documented design behavior
   (fabrication is not a special path; absence-as-rule per design.md G10). Empty
   chat falls to the same default — correct, since empty input is not a conflict
   signal.
3. **Missing error paths** — Stand-ins are pure shell functions over string
   inputs; no I/O, no external calls. No missing error handling.
4. **Inappropriate error transformation** — N/A; no errors are caught/rewrapped.
   The new SKILL section explicitly forbids transforming contract conflicts into
   silent fall-through, fabricated escape hatches, or paraphrased procedures.
5. **Log-and-continue** — None. The SKILL contract requires `End the turn` after
   the `CONTRACT-CONFLICT:` line; there is no log-then-proceed branch.
6. **Partial state on failure** — Operator-intervention route's documented
   side-effect record is `findings_parsed=0 clean_sentinel=0 schema_guard=0
   auto_repair=0 tag_budget=0 round_advance=0` — pinned by the side-effects
   test. The `Do NOT call Write` clause prevents partial finding-file state
   from a conflict response.

## Stand-in coverage assessment (specifically requested)

The bats stand-ins (`classify_reviewer_chat_output`, `review_round_side_effects`,
`operator_intervention_payload`, `is_valid_conflict_exit`) are explicitly
documented as mirroring the documented post-dispatch classifier branch, in the
same style as the existing escalation/pause stand-ins in this file. They pin
the SKILL prose contract and the orchestrator's documented routing semantics,
not the orchestrator's runtime implementation. Two soft observations, neither
rising to a finding:

- `is_valid_conflict_exit` is a literal enumeration of the design's two valid
  exits; the test cases assert the stand-in's own case statement. This is a
  tautology in execution but a documentation-pin in source — it would catch a
  future PR that silently expands the enumerated valid exits without amending
  the SKILL or design.
- The "existing sections remain present and unchanged in shape" test asserts
  heading existence plus the `PHASE-ROUTING-VIOLATION:` token in
  `### Refusal Procedure`. Body prose of the existing sections could drift
  without test failure. T35's DoD scope is "preserve unchanged" by adjacent
  callout, and the broader contradiction-refusal contract is owned by T03's
  surface, so this is acceptable scope partitioning, not a swallowed signal in
  this task.

No escape-hatch paths introduced. No signal-swallowing branches. Clean.

---
reviewer: quality-claude
artifact: design
round: 14
status: clean
---

# quality-claude — clean

No quality findings against the round-14 diff.

## Diff scope reviewed

Two edits inside G6 (Stage-commit parent SHAs validated against named task tips), `design.md` lines 396 and 405:

1. **Step 2 capture procedure rewording.** Replaced the lead-in "Compare the actual parent SHA set against the expected parent SHA set captured at wave-dispatch resolution time." with "Capture the expected parent set at wave-dispatch resolution time." Changed the sidecar representation from "writing the full {integration-base, task-tips...} set" to "writing the integration-base SHA and the task-tip SHA list as separable fields." Dropped the trailing sentence "The validation in step 3 reads from this sidecar and compares the full parent set, with no parent[0]-stripping normalization." in favor of the simpler "The validation in step 3 reads both fields from this sidecar."
2. **Single-task wave edge case rewrite.** Updated to `actual parents = [integration-base, task-tip]; expected captured = {integration_base: <sha>, task_tips: [<task-tip-sha>]}`, then restated the two-invariant validation explicitly.

## Checks applied and outcomes

- **Internal consistency.** Step 3's two invariants reference `captured_integration_base_sha` and `captured_task_tip_shas`; the new step 2 "separable fields" framing matches the invariant names exactly. The Outcome paragraph ("integration-base SHA plus the named task-tip SHAs"), the Dependencies bullet ("capturing both the integration-base SHA … and each task tip SHA"), the Acceptance "Capture step coverage" bullet ("writes the integration-base SHA and each task-tip SHA to the runtime sidecar"), and the rewritten single-task edge case all use the same separable-fields representation. Clean.
- **Removed sentence is genuine cleanup, not lost meaning.** The dropped "no parent[0]-stripping normalization" sentence was a clarification of how a combined-set comparison would behave; with step 3 already using explicit `actual_parents[0]` vs `actual_parents[1:]` checks against the two separable fields, that normalization warning is structurally inapplicable and removing it improves clarity.
- **Diagnostic format still coherent.** The diagnostic in step 3 retains `expected {<expected-set>}` shorthand, but immediately decomposes into `first-parent expected …; task tips missing: …; unexpected parents present: …`. The shorthand can be rendered at display time as the union of the two captured fields; this is appropriate for a human-readable halt diagnostic.
- **Goal coverage / outcome unchanged.** The G6 outcome statement and the named failure mode (v0.7.2 task-21/task-26 silent drop) are not affected by these edits.
- **Test strategy still appropriate.** The five Bats fixtures in Acceptance cover both invariants individually (first-parent-wrong, missing tip, extra parent), the happy path, and the single-task case. The "Capture step coverage" bullet matches the new separable-fields representation.
- **Research grounding (Q11/Q12).** Citations on the symbolic-only branch-map invariant are preserved verbatim in both step 2 and the Dependencies bullet.
- **YAGNI.** Cleanup-only diff; no new surface, no new artifact, no new helper introduced.
- **Trade-offs / "Why this approach" paragraph.** Untouched; the merge-time fence rationale and the only-honest-alternative-considered framing remain intact.

No findings to emit.

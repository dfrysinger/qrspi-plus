---
finding_id: R2-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-06-04-v073-release/goals.md:L55]
artifact: goals
round: 2
reviewer: quality-claude
---

G2's "What we know so far" section opens with "Decision locked during this Goals dialogue: **sweep all `[Tnn]` prefixes** from test names; do NOT bless them." This is commitment language — "decision locked" and "do NOT bless them" frame the direction as resolved and unchallengeable at the Goals layer — which violates the Goals-quality rule that solution mentions in "What we know so far" are framed as candidates Design will weigh, not commitments.

The choice between sweeping and blessing/grandfathering is a design-level question even for a `known-fix` goal. All other "What we know so far" sections in this file use "Candidate X Design should weigh" consistently; G2 line 55 is the sole exception. If Design determines that a selective allow-list for legacy markers, or a phased sweep, is preferable to a full sweep, the "locked" framing actively contradicts Design's authority to make that call.

**Fix:** Remove the "Decision locked during this Goals dialogue" meta-commentary and restate the direction in candidate form, consistent with the file's own convention — e.g., "The direction to sweep all `[Tnn]` prefixes rather than blessing them is the candidate Design should confirm; rationale: T numbers are reused each phase, so a `[T24]` from v0.7.2 collides with a different `[T24]` in v0.7.3 — they are noise, not traceability." This preserves the rationale while leaving the approach open for Design confirmation.

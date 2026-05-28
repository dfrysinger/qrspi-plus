---
finding_id: R2-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/goals.md:L40-L55]
artifact: goals
round: 2
reviewer: quality-claude
---

G2's `type` is `known-fix`, but the goal body presents a genuinely open architectural choice between two materially different mechanism shapes: "a shell shim, in the style of the existing `scripts/run-codex-review.sh` pattern" versus "an in-process wrapper (Node.js or Python)." The text explicitly instructs "Design should weigh whether shell is the right surface or whether an in-process wrapper... is preferable for streaming, error handling, or session-state propagation."

This is not a wording or placement question — it is a load-bearing architectural decision that determines downstream constraints (one of the Constraints in this very file forbids new node/python runtime dependencies unless Design explicitly justifies the boundary, which is precisely the choice G2 punts to Design). Additional open dimensions: API-key management strategy (environment variables, 1Password-style indirection, per-provider config block) and error/fallback semantics.

`known-fix` signals to Design that the shape is settled and only details need wording. G2 instead has a fundamental shape decision pending. Re-tagging as `type: exploratory` would correctly signal that Design should weigh the alternatives rather than execute on a pre-decided shape.

Note: this finding is closely paired with R2-F01 (G1 type misclassification). Together they suggest the `known-fix` tag was applied to the cost-opt trio (G1/G2/G5) by phase rather than by actual openness of the design space — G5 is correctly `exploratory`, but G1 and G2 carry the same level of openness.

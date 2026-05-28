---
finding_id: R9-F04
severity: low
change_type: clarity
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L462-L476, docs/qrspi/2026-05-17-v07-release/design.md:L984-L994]
artifact: design
round: 9
reviewer: quality-claude
---

G10's `reference_artifact:` task-spec field is introduced as a key but its required/optional status when `reference_gate: true` is set is left ambiguous, which conflicts with Decision 10's "all new task-spec fields are additive and have safe defaults" framing.

G10 (line 464):

> A new `reference_artifact:` key names the produced artifact path.

The G10 Implement responsibilities (lines 469–472) describe a workflow that depends on knowing the reference artifact path ("Show the produced reference artifact to the user (Read and display inline if text; show the file path if binary)"). That workflow cannot run without `reference_artifact:` being set.

Decision 10 (lines 984–994) lists `reference_artifact: <path>` among "all new task-spec fields are additive and have safe defaults" — implying the field is optional and absence has a safe default behavior.

These two framings conflict: if `reference_gate: true` is set but `reference_artifact:` is omitted, Implement cannot execute its pause-and-show workflow. The "safe default" of absence cannot mean "no pause" because the gate's whole point is to pause; and it cannot mean "show nothing" because that defeats the human-in-the-loop validation.

The likely intended contract is that `reference_artifact:` is required when `reference_gate: true` is set, and absent (with safe default behavior) otherwise. But the design does not state this conditional-requirement explicitly, and Decision 10's "additive with safe defaults" framing implies unconditional optionality.

Suggested fix: in G10, add a sentence: "`reference_artifact:` is required when `reference_gate: true` is set and is omitted (default) when `reference_gate:` is absent or false. Plan refuses to write a `reference_gate: true` task without `reference_artifact:` populated." And amend Decision 10 to acknowledge that `reference_artifact:` and `reference_gate:` are paired fields with a conditional-required relationship, while still being additive overall (a v0.6 task with neither still behaves as today).

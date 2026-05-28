---
finding_id: R16-F02
severity: medium
change_type: clarity
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L558-L560]
artifact: design
round: 16
reviewer: quality-claude
---

The `wave_context:` companion parameter introduced in G11 lacks a format and schema specification, leaving Plan and Implement to invent the format independently.

The design says (G11, "Wave-aware reviewer brief" paragraph): "When multiple sibling UI tasks ship in the same plan with the same `ui:` + `lift_source:` combination, Implement constructs a per-wave brief from prior-wave reviewer findings on those siblings and passes it as `wave_context:` companion to the reviewers in later waves. This carries forward lessons like 'wave 1 tasks over-copied a source class — wave 2 reviewers, watch for this' without requiring a separate replan."

The design's test strategy for G11 includes: "Wave-context test: when multiple sibling UI tasks ship in the same plan, later-wave reviewers receive a `wave_context:` companion built from earlier-wave findings." This verifies the parameter is passed but says nothing about its shape.

The design does not specify:

- The format of the brief (plain prose? structured YAML? a list of prior-round finding excerpts?).
- Which reviewer findings are included (all per-task reviewer findings from prior waves on UI tasks? only visual-fidelity findings? only high-severity findings?).
- How the visual-fidelity reviewer agent body should interpret or use the `wave_context:` companion — what behavior changes when it is present versus absent.
- Whether the `wave_context:` parameter follows the same `<<<UNTRUSTED-ARTIFACT-START>>>` wrapping convention as other companion parameters per the reviewer dispatch contract.

Without this specification, the design introduces a dispatch-contract extension without sufficient definition for Plan (which authors task specs and dispatch shapes) or Implement (which constructs the brief and wires the dispatch). The parameter is named and motivated but not defined as a contract surface. A downstream Implement task author encountering this for the first time would have to infer the format.

To resolve this, the design should add a brief format specification for `wave_context:` — at minimum: what data is included, in what structure (e.g., a plain-text summary of findings from prior-wave visual-fidelity reviewers on `ui: true` tasks in the same plan), and that it follows the `<<<UNTRUSTED-ARTIFACT-START id=wave_context>>>` wrapping convention. If the format details are intentionally deferred to Plan/Implement, the design should say so explicitly.

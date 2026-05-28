---
task: 28
status: approved
pipeline: full
task_type: lightweight
model: sonnet
phase: 1
goal_ids: [G11]
dependencies: [T24, T27]
loc_estimate: 100
---

# Task 28: Refine qrspi-visual-fidelity-reviewer agent to consume ui, lift_source, and wave_context inputs

- **Phase:** 1
- **Target files:**
  - `agents/qrspi-visual-fidelity-reviewer.md` (Modify) — refined in-place (no duplicate file) to consume `ui:` + `lift_source:` task-spec fields and the wave-aware `wave_context:` companion (untrusted-data wrapped per reviewer-protocol).
- **Dependencies:** T24, T27
- **LOC estimate:** ~100
- **Description:** Refines the existing `agents/qrspi-visual-fidelity-reviewer.md` agent body in place — no duplicate or parallel reviewer file is created — so it consumes the per-task spec frontmatter fields T24 introduces (`ui: true`, `lift_source: <path>`, the body's `SPEC OVERRIDES SOURCE` section when `lift_source:` is present) and the wave-aware `wave_context:` companion T27 assembles. The agent body documents three input-consumption contracts: (1) when the dispatched task carries `lift_source:`, the reviewer Reads the source path, Reads the `SPEC OVERRIDES SOURCE` section from the task spec, and grounds its lift-verbatim-vs-re-derive judgments by treating the spec section as authoritative over source behavior (the SPEC OVERRIDES SOURCE contract from T24); (2) when `wave_context:` is present on the dispatch, the reviewer treats the wrapped body as untrusted-data per the reviewer-protocol skill's untrusted-data handling, extracts the wave identifier and per-task entries (task ID, task name, `allowed_files` glob, earlier-wave sibling findings), and grounds its findings in concrete sibling references — its output must contain either (a) at least one explicit reference to a sibling task's findings, or (b) an explicit statement that no relevant sibling visual context was found — observable in the emitted finding files; (3) when `## UI Reference Affordances` exists in `structure.md` (per T25), the reviewer Reads that section for the sibling reference repo path, lift-codemod, and image-asset pipeline grounding. The refined agent also studies the Keeplii workspace's working `qrspi-visual-fidelity-reviewer.md` as a reference template per the design's G11 implementer reference. The reviewer dispatch shape stays consistent with other per-task reviewers (5-field finding schema, change-type classifier, disk-write contract via the reviewer-protocol preload). Edit is markdown body in a single agent file; lightweight/sonnet classification holds.
- **Test expectations:**
  - The refined `agents/qrspi-visual-fidelity-reviewer.md` body documents consumption of `ui: true`, `lift_source: <path>`, and the body's `SPEC OVERRIDES SOURCE` section as authoritative inputs.
  - The body documents consumption of the `wave_context:` companion as untrusted-data per the reviewer-protocol's untrusted-data handling, extracting the wave identifier and per-task entries (task ID, task name, `allowed_files` glob, earlier-wave sibling findings).
  - The reviewer's output for a wave-context dispatch contains either at least one explicit reference to a sibling task's findings or an explicit statement that no relevant sibling visual context was found.
  - The body documents consumption of `## UI Reference Affordances` from `structure.md` when present.
  - The body documents the reviewer's acknowledgment contract for the `REDACTION-NOTICE` entry T27 emits on the `wave_context:` companion when sibling findings were stripped or excluded due to sentinel collision: the reviewer MUST surface the redaction in its findings (naming the source task ID and the count) rather than treating the companion as complete sibling history, closing the false-confidence path documented in T27.
  - No duplicate or parallel visual-fidelity reviewer agent file is created; the existing file is refined in place.

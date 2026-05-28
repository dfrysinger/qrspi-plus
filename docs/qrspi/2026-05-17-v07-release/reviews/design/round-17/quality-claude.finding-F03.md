---
finding_id: R17-F03
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L563-L568, docs/qrspi/2026-05-17-v07-release/design.md:L366-L383]
artifact: design
round: 17
reviewer: quality-claude
---

The G11 `wave_context:` content definition includes task IDs (e.g., "task ID" in per-task entries) without addressing whether these are exempt from the G7 hygiene contract, creating an unresolved conflict between two design sections.

G11 (design.md lines 563-568) defines the `wave_context:` body to include "per-task entries within the wave, each showing task ID, task name, `allowed_files` glob, and — when available — the post-implementation visual-fidelity reviewer findings from sibling tasks." "Task ID" in QRSPI is a `T<NN>` token — the same family that G7 (lines 366-383) explicitly lists as forbidden in shipped or executable files: "T<NN> — task IDs."

G7's path carve-outs are: `docs/qrspi/**` (the artifact directory) and reviewer agent files. The `wave_context:` parameter is assembled by Implement at runtime and passed as a companion parameter to reviewer dispatches. It is not under `docs/qrspi/**` and is not a reviewer agent file. The design does not state whether `wave_context:` bodies are exempt from the G7 token ban.

This leaves an unresolved conflict: G11 instructs Implement to include T-NN task IDs in `wave_context:`, while G7 instructs implementers to flag any edited line containing T-NN tokens as a hygiene hit. Even though `wave_context:` is an intermediate runtime parameter (not written to a skill or agent file), an implementer writing the assembly code for `wave_context:` would encounter G7's pre-DONE self-check flagging the T-NN references in the assembly code or fixture.

The design should resolve this explicitly in one of two ways: (a) clarify in G11 that wave_context bodies are assembled by Implement using symbolic references (e.g., task numbers used as index keys in the wave_context structure) and that these uses are exempt from G7 because wave_context is a runtime-only dispatch parameter, not a shipped file — and add wave_context assembly to G7's carve-out list; or (b) redefine the wave_context per-task entry to use a non-T-NN identifier (for example, the task file path or a positional index) to avoid the hygiene conflict entirely.

Without this resolution, Plan authors writing G7 and G11 tasks face an unspecified conflict.

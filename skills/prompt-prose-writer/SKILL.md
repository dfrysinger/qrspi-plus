---
description: Apply prompt-design rules when authoring or planning prompt-prose deliverables. Detects whether a deliverable IS prompt prose, and only then Reads the rules and applies every R-rule defined in `skills/_shared/prompt-design-rules.md` before drafting. Preloaded by agent files that may author prompt prose.
---

# Prompt Prose Writer

<!-- INCLUDE-BEGIN: prompt-prose-detection -->
!cat skills/_shared/prompt-prose-detection.md
<!-- INCLUDE-END: prompt-prose-detection -->

<!-- INCLUDE-BEGIN: prompt-prose-writer-addition -->
!cat skills/_shared/prompt-prose-writer-addition.md
<!-- INCLUDE-END: prompt-prose-writer-addition -->

<!-- Guard: if you do not see content between any INCLUDE-BEGIN/INCLUDE-END pair above,
do NOT apply this skill. Surface a load error naming the missing block and stop —
partial context is worse than no skill. -->

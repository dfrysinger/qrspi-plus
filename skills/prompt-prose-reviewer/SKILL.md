---
description: Apply prompt-design rules when reviewing prompt-prose subjects in a diff. Detects which files (or sub-blocks) are prompt prose, applies R1-R7 + cross-cutting principles + finding-type gate, and emits findings with proper change_type tagging. Preloaded by reviewer agents that may encounter prompt prose in their review subject.
---

# Prompt Prose Reviewer

<!-- INCLUDE-BEGIN: prompt-prose-detection -->
!cat skills/_shared/prompt-prose-detection.md
<!-- INCLUDE-END: prompt-prose-detection -->

<!-- INCLUDE-BEGIN: prompt-prose-reviewer-addition -->
!cat skills/_shared/prompt-prose-reviewer-addition.md
<!-- INCLUDE-END: prompt-prose-reviewer-addition -->

<!-- Guard: if you do not see content between any INCLUDE-BEGIN/INCLUDE-END pair above,
do NOT apply this skill. Surface a load error naming the missing block and stop —
partial context is worse than no skill. -->

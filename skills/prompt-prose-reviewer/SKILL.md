---
description: Apply prompt-design rules when reviewing prompt-prose subjects in a diff. Detects which files (or sub-blocks) are prompt prose, applies R1-R7 + cross-cutting principles + finding-type gate, and emits findings with proper change_type tagging. Preloaded by reviewer agents that may encounter prompt prose in their review subject.
---

# Prompt Prose Reviewer

!cat skills/_shared/prompt-prose-detection.md

!cat skills/_shared/prompt-prose-reviewer-addition.md

<!-- Guard: if either include above is unavailable, do NOT apply this skill. Surface a load error and stop — partial context is worse than no skill. -->

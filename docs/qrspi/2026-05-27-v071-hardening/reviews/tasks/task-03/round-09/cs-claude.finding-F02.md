---
finding_id: R9-F02
severity: low
change_type: clarity
referenced_files: [tests/helpers/skill-markdown.bash]
artifact: task-03/tests/helpers/skill-markdown.bash
round: 9
reviewer: cs-claude
non_blocking: true
persistence_note: orchestrator-persisted (chat-only fallback)
---

**Title:** Module header enumerates four public functions but task added a fifth

`skill-markdown.bash` header at lines 8-31 says "Provides four behavioral helpers" but after T3 there are five (the new `extract_section_fence_aware`). Header is the first thing a consumer sees when deciding whether to `load` the file — omission makes the new function invisible at the entry point.

**Fix:** Update count to "five" and add a description entry for `extract_section_fence_aware <file> <anchor-heading>` covering the anchor format, output range, and diagnostic patterns.

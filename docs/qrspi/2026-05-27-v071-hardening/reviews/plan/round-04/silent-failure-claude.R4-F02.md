---
finding_id: R4-F02
severity: low
change_type: correctness
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 4
reviewer: silent-failure-claude
---

SILENT_FALLBACK: Task 8 SKILL.md grep-absence assertion omits cache_control; partial retirement undetected

R4 added SKILL.md absence assertion for supports_prompt_cache and emit_cache_control_markers. Script-side asserts all THREE (cache_control included). SKILL.md assertion omits cache_control.

If SKILL.md prose outside the providers block documents cache_control (transport-dispatch prose), operator configuring cache_control: true gets silent no-op. Documentation survives without backing code.

Fix: Extend SKILL.md grep-absence assertion to cover all three identifiers: supports_prompt_cache, emit_cache_control_markers, AND cache_control. Or expand Task 8 removal spec to delete cache_control from all SKILL.md prose, then assert.

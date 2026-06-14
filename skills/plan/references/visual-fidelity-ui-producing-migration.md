# Visual-Fidelity `ui_producing` Migration

Read this file only when a pre-Slice-5 task spec carries `visual_fidelity_check.ui_producing` and Plan must migrate it to the canonical top-level `ui:` field. New tasks should author `ui:` directly and skip this file.

Pre-Slice-5 task specs may carry a `visual_fidelity_check.ui_producing: true` field. When Plan encounters this field in a task spec during review or post-approval split:

1. Promote the value to a top-level `ui: true` field in the task frontmatter.
2. Remove the `ui_producing` field from inside the `visual_fidelity_check:` block.
3. Preserve all other `visual_fidelity_check:` sub-fields (e.g., `wireframe_refs:`) unchanged.
4. Log the migration in the DONE report as a one-line note per affected task.

This is the one replacement-not-additive field change in Slice 5 per design Decision 10. After migration, the `visual_fidelity_check:` block no longer carries `ui_producing`; the canonical `ui:` top-level field is the single source of truth for whether a task emits UI output.

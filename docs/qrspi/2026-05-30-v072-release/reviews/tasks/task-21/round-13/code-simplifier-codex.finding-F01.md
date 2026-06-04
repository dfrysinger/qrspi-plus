---
finding_id: R13-F01
severity: low
change_type: clarity
reviewer_tag: code-simplifier-codex
referenced_files: [scripts/dispatch-agent.sh]
---

# Unnecessary alias wrapper around reject_if_value_unsafe_for_emission

`reject_if_contains_marker_value()` (around L2503–L2506 in the cumulative
diff) only delegates to `reject_if_value_unsafe_for_emission "$@"`. The
backward-compat alias was introduced in fix-cycle 11 to avoid touching
existing call sites; it can be removed by renaming/inlining the call
sites to the primary function.

Behavior-preserving. Non-blocking.

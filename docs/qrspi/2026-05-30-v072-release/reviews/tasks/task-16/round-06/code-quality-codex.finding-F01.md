---
finding_id: R6-F01
reviewer_tag: code-quality-codex
round: 6
severity: high
change_type: correctness
referenced_files: [scripts/_resolve-lib.sh:88-93, scripts/_resolve-lib.sh:131-135]
---

# code-quality-codex F01 — unreadable-config defenses not self-consistent

Code checks `-f` (exists) but diagnostics claim "unset or not a readable file".
If `CONFIG_MD` exists but is unreadable, `resolve_tier` misclassifies it as
"config present but no default_tier" and `resolve_model` can misroute to
"unconfigured tier" instead of reporting a config-path error. Use readability
checks (`-r`) on the defended path.

**Orchestrator adjudication: KEEP/FIX.** Same root cause as
silent-failure-codex.finding-F03 (cross-reviewer convergence). Change `-f` → `-r`
at L74/L88/L131; additive, makes diagnostics truthful, no refactor.

Chat-only return persisted by orchestrator.

---
finding_id: F02
reviewer: code-simplifier-codex
round: 7
severity: low
change_type: refactor
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
---
Frequent `echo "$output" | grep -q '...'`; here-strings (`grep -q '...' <<<"$output"`)
are equivalent and less noisy. Advisory. (Codex chat-only; orchestrator-persisted.)

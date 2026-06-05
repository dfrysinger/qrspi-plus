---
finding_id: F02
reviewer: code-quality-claude
severity: low
change_type: clarity
referenced_files: [scripts/dispatch-companion.sh:548]
disposition: ACT
---
**Stale L613 line citation.** Comment says allowlist enforced "at launch time (L613)" but L613 is `--model` parsing; actual allowlist is L627. Either correct line or drop cross-reference.

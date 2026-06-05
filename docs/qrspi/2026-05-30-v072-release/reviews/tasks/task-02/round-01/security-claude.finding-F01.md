---
finding_id: R1-F01
reviewer_tag: security-claude
round: 1
task: 02
severity: medium
change_type: correctness
referenced_files:
  - scripts/verifier-fan-in.sh
---

## F01 — Bash octal arithmetic trap on leading-zero scores

Line 219 regex `^-?[0-9]+$` accepts `089`, `099`, `010`, etc. Line 229 `score=$((raw_score))` applies bash octal interpretation:
- `089` / `099`: throws "value too great for base"; under set -e script aborts before record_halt and write_audit
- `010`: silently produces 8 — finding scored 10 is treated as 8

Attack: a verifier sidecar with `score: 089` triggers deterministic crash without audit artifact.

Fix: force decimal via `printf '%d'` or `$((10#$raw_score))` and route printf-failure back through score_unparseable halt path.

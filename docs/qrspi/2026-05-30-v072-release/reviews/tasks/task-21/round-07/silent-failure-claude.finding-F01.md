---
finding_id: R7-F01
severity: high
change_type: correctness
referenced_files: [scripts/dispatch-companion.sh]
status: closed-cycle-7
---
mkdir-before-assert partial-state regression: out-of-repo --round-dir caused
mkdir -p /attacker/.dispatch/.jobs before boundary rejection. Same defect as
sec-codex R7 F03; closed by cdf252d via assert_ancestor_under_repo_root.

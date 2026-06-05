---
finding_id: F01
reviewer: code-quality-claude
severity: low
change_type: hygiene
referenced_files: [scripts/lib/path-guard.sh, scripts/dispatch-agent.sh, scripts/dispatch-companion.sh, tests/unit/test-dispatch-agent.bats]
---
**G16 ID hygiene violations in code comments + test names.** Strip `G16`/`G16:`/`G16 —`/`(G16: …)` prefix from comments and `@test` name strings (path-guard.sh L1/L3; dispatch-agent.sh ~L74/L575/L631; dispatch-companion.sh L45; bats 13+ tests + section comments). Also strip `R2-F01` from batch-section comment. Convergent with cq-codex F01.

---
artifact: design
reviewer_tag: quality-codex
finding_id: quality-codex-F01
change_type: correctness
---

# G6 validates set equality but states parent[0] is load-bearing

## Location

design.md L395-397 (Solution steps 2-3), L405 (single-task edge case), L410-416 (acceptance).

## Finding

G6 says the captured integration-base SHA "will become parent[0]" of the `--no-ff` merge, but the validator compares only the actual vs expected parent set. A set comparison passes a stage commit with the same parents in wrong order — yet first-parent ordering is load-bearing for stage-chain readability and any downstream logic treating the stage chain as the integration spine. The validator cannot detect violations of an invariant the design itself states.

## Expected fix

Specify validator as: `actual_parents[0] == captured_integration_base_sha` AND `set(actual_parents[1:]) == set(captured_task_tip_shas)`. Add acceptance coverage for a fixture with correct set but wrong first parent (must halt with `stage-commit-parent-mismatch`).

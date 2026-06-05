---
finding_id: F01
reviewer: security-claude
severity: low
change_type: correctness
referenced_files: [scripts/dispatch-agent.sh:579, scripts/dispatch-agent.sh:908]
---
**`assert_file_exists` is undefined when called from batch block.** Function defined at L908 but called at L579 (before batch exit 0). With `set +e`, command-not-found returns 127 silently. Boundary guard (`assert_path_under_repo_root`) holds (security primary intact), but existence check no-ops; Linux GNU realpath canonicalizes non-existent in-repo paths → both pass → cat fails silently in prompt assembly → empty artifact_body block.

Fix: move `assert_file_exists` definition above batch block (e.g., near `require_value`), OR inline existence check in batch:
```
if [[ -n "$BATCH_ARTIFACT_ABS" ]]; then
  [[ -f "$BATCH_ARTIFACT_ABS" ]] || { echo "error: --artifact not found: $BATCH_ARTIFACT_ABS" >&2; exit 1; }
  assert_path_under_repo_root "--artifact" "$BATCH_ARTIFACT_ABS"
fi
```

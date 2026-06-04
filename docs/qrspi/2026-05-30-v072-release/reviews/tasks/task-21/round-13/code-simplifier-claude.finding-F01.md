---
finding_id: R13-F01
severity: low
change_type: clarity
reviewer_tag: code-simplifier-claude
referenced_files: [scripts/dispatch-agent.sh]
---

# `--diff-file` block inlines existence check; other path families use the helper

Within the T21 path-guard application surface in `scripts/dispatch-agent.sh`,
the `--diff-file` validation block is the only one of the four path-argument
families that does **not** route its existence check through the
`assert_file_exists` helper that all the other surfaces use:

```sh
# agent-file
AGENT_FILE_ABS="$(resolve_path "$AGENT_FILE")"
assert_file_exists "agent-file" "$AGENT_FILE_ABS"
assert_path_under_repo_root "agent-file" "$AGENT_FILE_ABS"

# subject-code / artifact-body (PRIMARY)
abs="$(resolve_path "$sc")"
assert_file_exists "$PRIMARY_FIELD" "$abs"
assert_path_under_repo_root "$PRIMARY_FIELD" "$abs"

# task-def
TASK_DEF_ABS="$(resolve_path "$TASK_DEF")"
assert_file_exists "task-def" "$TASK_DEF_ABS"
assert_path_under_repo_root "task-def" "$TASK_DEF_ABS"

# companion
abs="$(resolve_path "$cpath")"
assert_file_exists "companion[$cname]" "$abs"
assert_path_under_repo_root "companion[$cname]" "$abs"
```

…but `--diff-file` (lines 1080–1087) inlines the existence check:

```sh
if [[ -n "$DIFF_FILE" ]]; then
  DIFF_FILE="$(resolve_path "$DIFF_FILE")"
  if [[ ! -f "$DIFF_FILE" ]]; then
    echo "error: diff-file not found: $DIFF_FILE" >&2
    exit 1
  fi
  assert_path_under_repo_root "diff-file" "$DIFF_FILE"
fi
```

Replacing the inline `[[ ! -f ... ]] / echo / exit` block with
`assert_file_exists "diff-file" "$DIFF_FILE"` (which emits the identical
diagnostic shape `error: diff-file not found: <path>`) makes all four
T21-guarded path families read identically, removing one of the
"three-statement" patterns in favor of the established two-line pattern.

Behavior-preserving (the helper's diagnostic and exit code match the
inline check). Non-blocking — purely a consistency/clarity simplification
on the T21 surface.

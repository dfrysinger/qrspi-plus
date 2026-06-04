---
finding_id: R5-F02
reviewer: code-quality-claude
round: 5
severity: low
change_type: clarity
referenced_files:
  - tests/unit/test-dispatch-agent.bats
status: accepted-with-issues
---

# Cleanliness: superfluous `[ -f ]` guard on a just-mktemp'd file (line 1262)

```bash
await_stderr_file="$(mktemp "$TMP_DIR/await-stderr-XXXXXX")"
"$REPO_ROOT/scripts/await-round.sh" --round-dir "$round_dir" >/dev/null 2>"$await_stderr_file" || await_rc=$?
local await_stderr_content=""
[ -f "$await_stderr_file" ] && await_stderr_content="$(cat "$await_stderr_file")"
```

The `[ -f ]` guard is unreachable — file was just created by mktemp two lines above; bats runs with `set -e` so a mktemp failure exits before reaching the guard. sf-claude r5 review noted this as "harmless" defensive code. **Accepted with issues** — micro-cleanliness, deferred. Does not block T20 closure.

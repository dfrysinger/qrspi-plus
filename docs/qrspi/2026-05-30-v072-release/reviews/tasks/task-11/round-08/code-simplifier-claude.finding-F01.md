---
reviewer_tag: code-simplifier-claude
round: 8
finding_id: R8-F01
severity: low
change_type: clarity
referenced_files: [scripts/run-codex-review.sh]
status: non-blocking-suggestion
---

# F01 — Unnecessary intermediate `found` variable in `check_codex_available`

## Location

`scripts/run-codex-review.sh`, lines 172–184 (claude-code arm of `check_codex_available`).

## Current pattern

```bash
local found=0
local f
for f in "${HOME}/.claude/plugins/cache/openai-codex/codex"/*/scripts/codex-companion.mjs; do
  if [[ -f "$f" ]]; then
    found=1
    break
  fi
done
if [[ "$found" -eq 1 ]]; then
  return 0
else
  return 1
fi
```

`found` is set in the loop and read exactly once in the post-loop `if/else`. The variable adds no explanatory value — the branching can be expressed directly with `return`.

## Simpler alternative

```bash
local f
for f in "${HOME}/.claude/plugins/cache/openai-codex/codex"/*/scripts/codex-companion.mjs; do
  [[ -f "$f" ]] && return 0
done
return 1
```

- Removes `found` (declared, assigned, then immediately tested: one extra concept to track).
- Collapses the post-loop `if/else return` into a fall-through `return 1`.
- Keeps the same bash-3.2-portable shape (`local f`, no arrays, no `mapfile`).
- Behavior is identical: first matching file returns 0; no match returns 1.

## Note

This is the only caller-visible change in the `claude-code` arm. The `copilot-cli` and `*` arms are unaffected.

Non-blocking suggestion.

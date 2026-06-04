---
reviewer: code-quality-claude
finding_id: F01
severity: minor
change_type: clarity
file: scripts/_resolve-lib.sh
lines: 43-48
---

## `_normalize_tier_value` header comment misdescribes its own whitespace behavior

The header comment claims the helper strips "all **surrounding** whitespace":

```sh
# _normalize_tier_value <raw-value>
# Strips a whitespace-preceded inline `#` comment, then all surrounding
# whitespace, from a routing row's VALUE. Bash 3.2 portable.
_normalize_tier_value() {
  printf '%s' "$1" | sed -E 's/[[:space:]]+#.*$//' | tr -d '[:space:]'
}
```

`tr -d '[:space:]'` deletes **every** whitespace character, not just leading/trailing.
For the routing object `{ vendor: claude, model: claude-haiku-4.5 }` the emitted
value is `{vendor:claude,model:claude-haiku-4.5}` — internal spaces collapsed too.

Per the dispatch this collapse is already adjudicated non-blocking on the
correctness axis (no executable consumer parses the emitted object yet). The
finding here is purely **clarity**: the comment says "surrounding" while the code
deletes internal whitespace as well, so a future maintainer reading the comment
will form a wrong mental model of what the emitted value looks like — exactly the
surprise that bites when the first real consumer of `resolve_model`'s output gets
wired up.

### Suggested fix
Reword to match behavior and flag the consumer caveat, e.g.:

```sh
# Strips a whitespace-preceded inline `# comment`, then ALL whitespace
# (leading, trailing, AND internal) from a routing row's VALUE. Note: internal
# spaces in the { vendor:, model: } object are collapsed; this is safe only while
# the emitted value is consumed as an opaque token, not parsed as YAML.
```

Non-blocking — comment-only.

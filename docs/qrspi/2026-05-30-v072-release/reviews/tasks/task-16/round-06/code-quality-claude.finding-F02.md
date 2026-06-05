---
reviewer: code-quality-claude
finding_id: F02
severity: minor
change_type: dry
file: scripts/_resolve-lib.sh
lines: 143-147, 159-163
---

## Identical none-halt diagnostic duplicated verbatim across two branches in `resolve_model`

`resolve_model` emits the same two-line HALT message from two distinct branches —
the absent-row case and the explicit-`none` case:

```sh
# absent row (lines 143-147)
if [ -z "$row" ]; then
  printf '[routing] HALT: tier "%s" resolves to none (unconfigured tier); ' "$tier" >&2
  printf 'no silent fallback to a neighboring tier — configure model_routing.%s in config.md.\n' "$tier" >&2
  return 1
fi
...
# explicit none value (lines 159-163)
if [ "$value" = "none" ]; then
  printf '[routing] HALT: tier "%s" resolves to none (unconfigured tier); ' "$tier" >&2
  printf 'no silent fallback to a neighboring tier — configure model_routing.%s in config.md.\n' "$tier" >&2
  return 1
fi
```

The two printf pairs are byte-for-byte identical. Conceptually these are the same
operator-facing condition ("the tier is not usably configured"), so the duplication
is real DRY drift: a future copy-edit to the message wording (or to the
`config.md` repair pointer) has to be applied in two places, and a reviewer can no
longer assume the two diagnostics stay in sync.

### Suggested fix
Extract a tiny local helper or collapse the two guards. Since the post-strip
`none` value and an absent row both mean "unconfigured", one option is to treat an
empty row as `value="none"` and fall through to a single halt:

```sh
local value=""
if [ -n "$row" ]; then
  value="$(printf '%s\n' "$row" | sed -E "s/^[[:space:]]+${tier}:[[:space:]]+//")"
  value="$(_normalize_tier_value "$value")"
fi
if [ -z "$value" ] || [ "$value" = "none" ]; then
  _halt_unconfigured_tier "$tier"   # single source of the diagnostic
  return 1
fi
```

Non-blocking — both branches are individually correct today; this is
maintainability hardening against message drift.

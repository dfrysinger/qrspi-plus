---
reviewer: simplify-claude
finding: F01
task: task-10
round: 04
severity: advisory
category: duplication
file: tests/unit/test-agent-frontmatter-no-model.bats
lines: 357-485
status: open
---

# F01 — TE1–TE4 are four near-identical 30-line copies of a single (tier→model, both hosts) assertion

## What

The four BATS blocks `[T10/TE1]` … `[T10/TE4]` (lines 357–485 of
`tests/unit/test-agent-frontmatter-no-model.bats`) are structurally
identical. Each does, modulo three string substitutions
(`<tier>`, `<model-id-regex>`, `TE<n>`):

```bash
local cfg="docs/qrspi/2026-05-27-v071-hardening/config.md"
[ -f "$cfg" ] || { echo "config.md not found at expected path: $cfg"; return 1; }

local cc_block cli_block
cc_block=$(_host_subblock "$cfg" claude-code)
cli_block=$(_host_subblock "$cfg" copilot-cli)

[ -n "$cc_block" ]  || { echo "TEn: claude-code sub-block missing …";  return 1; }
[ -n "$cli_block" ] || { echo "TEn: copilot-cli sub-block missing …"; return 1; }

printf '%s\n' "$cc_block"  | _assert_tier_maps_to <tier> '<model-regex>' || …
printf '%s\n' "$cli_block" | _assert_tier_maps_to <tier> '<model-regex>' || …
```

That is ~128 lines (TE1–TE4) repeating the same six steps with only
the `(tier, model-regex)` pair varying.

## Why it's a simplification candidate

- **Maintenance amplification.** Any change to the
  config-path constant, the sub-block lookup helper signature, or the
  "vacuous-pass guard" pattern (`-z` check on each sub-block) has to
  be applied in four places. The R2 fix already had to make a similar
  per-block schema-replacement edit; the next schema tweak (a fifth
  host, a renamed tier, a config-path move) will repeat the cost.
- **Intent obscured.** The intent — "for every `(tier, expected-model)`
  pair in the four-row table, both host sub-blocks must contain the
  pair" — is what's worth pinning. Four 30-line tests obscure that
  intent behind file-existence boilerplate and per-host
  vacuous-pass diagnostics that are identical in every block.
- **TE1–TE4 already share the *same* failure mode.** If
  `_host_subblock` returns empty for `claude-code` (e.g. someone
  renames the host key in `config.md`), all four tests RED-fail with
  the same diagnostic. The four tests do not partition the failure
  surface in any way that the BATS test name alone couldn't carry.

## Suggested shape (semantics-preserving)

A single table-driven test, or a single fixture-loading helper plus
four one-liner tests. Sketch (Bash 3.2 compatible — positional `set --`
in place of arrays-of-records):

```bash
_assert_tier_in_both_hosts() {
  # Args: <test-tag> <tier> <model-regex>
  local tag="$1" tier="$2" model="$3"
  local cfg="docs/qrspi/2026-05-27-v071-hardening/config.md"
  [ -f "$cfg" ] || { echo "$tag: config.md not found: $cfg"; return 1; }

  local host block
  for host in claude-code copilot-cli; do
    block=$(_host_subblock "$cfg" "$host")
    [ -n "$block" ] || { echo "$tag: $host sub-block missing"; return 1; }
    printf '%s\n' "$block" | _assert_tier_maps_to "$tier" "$model" || {
      echo "$tag: $host/$tier does not map to $model"
      printf '%s sub-block:\n%s\n' "$host" "$block"
      return 1
    }
  done
}

@test "[T10/TE1] haiku   → claude-haiku-4.5      both hosts" { _assert_tier_in_both_hosts TE1 haiku   'claude-haiku-4\.5'; }
@test "[T10/TE2] sonnet  → claude-sonnet-4.6     both hosts" { _assert_tier_in_both_hosts TE2 sonnet  'claude-sonnet-4\.6'; }
@test "[T10/TE3] opus    → claude-opus-4.7-high  both hosts" { _assert_tier_in_both_hosts TE3 opus    'claude-opus-4\.7-high'; }
@test "[T10/TE4] inherit → claude-sonnet-4.6     both hosts" { _assert_tier_in_both_hosts TE4 inherit 'claude-sonnet-4\.6'; }
```

This preserves every existing assertion (file presence, both-host
sub-block presence, per-host tier-maps-to match, loud diagnostic on
miss including the sub-block body) while collapsing ~128 lines to
~16 lines plus a ~15-line helper. The four test names remain distinct,
so BATS reporting and ALL-PASS narration are unchanged.

## Why this is advisory only

The pin contract from `task-10.md` (TE1–TE4) is satisfied either way.
Test-pin clarity and "fragility of fixture vs. intent" are
quality-of-code concerns, not correctness concerns. The verifier may
KEEP the current shape if the team prefers test-per-expectation
visibility over DRY. No blocking signal.

## Pointer

- `tests/unit/test-agent-frontmatter-no-model.bats:357-485` (TE1–TE4)

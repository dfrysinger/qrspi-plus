---
reviewer: simplify-claude
finding: F04
task: task-10
round: 04
severity: advisory
category: duplication
file: tests/unit/test-agent-frontmatter-no-model.bats
lines: 508-516, 603-610
status: open
---

# F04 — bare-tier scan regex appears twice (TE5 and TE7-GREEN)

## What

The same `grep -nE` invocation appears in two test blocks of
`tests/unit/test-agent-frontmatter-no-model.bats`:

TE5 (line 508-516):
```bash
bad_lines=$(printf '%s\n' "$cli_block" \
  | grep -nE '^[[:space:]]+[A-Za-z_][A-Za-z0-9_-]*:[[:space:]]+(haiku|sonnet|opus)[[:space:]]*$' \
  || true)
if [ -n "$bad_lines" ]; then
  echo "TE5: copilot-cli column contains bare tier short-form(s) that trigger 'model not available' warnings:"
  printf '%s\n' "$bad_lines"
  return 1
fi
```

TE7-GREEN (line 603-610):
```bash
bad=$(printf '%s\n' "$cli_block" \
  | grep -nE '^[[:space:]]+[A-Za-z_][A-Za-z0-9_-]*:[[:space:]]+(haiku|sonnet|opus)[[:space:]]*$' \
  || true)
[ -z "$bad" ] || {
  echo "TE7 GREEN: complete fixture wrongly flagged bare-tier short-forms: $bad"
  return 1
}
```

The regex is byte-identical in both places, as is the `|| true` guard
that converts grep's "no match" exit-1 into exit-0.

## Why it's a simplification candidate

- **The pattern is the contract.** The whole point of the bare-tier
  check is that ONE precise regex defines "what counts as a bare
  short-form". When that regex is copy-pasted, a future tightening
  ("also forbid bare `haiku-latest`") has to be applied twice. A
  divergence is silent — TE5 keeps RED-failing while TE7-GREEN
  silently stops policing the helper's negative case.
- **Helpers around this file are already named with the `_` prefix
  convention** (`_model_routing_block`, `_host_subblock`,
  `_assert_tier_maps_to`, `_markdown_section`). The bare-tier scan is
  the only multi-line pattern in TE5/TE7 that didn't get hoisted.

## Suggested shape (semantics-preserving)

Add a sibling helper to the file (mirroring the `_assert_tier_maps_to`
convention — same input on stdin, same exit-code semantics):

```bash
# Helper: scan a host sub-block (on stdin) for bare tier short-forms
# (`haiku` / `sonnet` / `opus` alone, with no version suffix). Prints
# offending lines (with line numbers) to stdout; exits 0 when at least
# one bad line is found, 1 when the block is clean.
_find_bare_tier_lines() {
  grep -nE '^[[:space:]]+[A-Za-z_][A-Za-z0-9_-]*:[[:space:]]+(haiku|sonnet|opus)[[:space:]]*$' \
    || true
  # `|| true` swallows grep's exit-1 on no-match so callers can use
  # [ -z "$(... | _find_bare_tier_lines)" ] / [ -n "..." ] uniformly.
}
```

TE5:
```bash
bad_lines=$(printf '%s\n' "$cli_block" | _find_bare_tier_lines)
if [ -n "$bad_lines" ]; then
  echo "TE5: copilot-cli column contains bare tier short-form(s) …"
  printf '%s\n' "$bad_lines"; return 1
fi
```

TE7-GREEN:
```bash
bad=$(printf '%s\n' "$cli_block" | _find_bare_tier_lines)
[ -z "$bad" ] || { echo "TE7 GREEN: complete fixture wrongly flagged …: $bad"; return 1; }
```

Net change: ~−8 LOC, single source of truth for the bare-tier
detection regex, consistent with the other `_assert_*` / `_*_block`
helpers in the file.

## Why this is advisory only

The duplication is two-call-sites, both clean and clearly named. The
verifier may KEEP if the team prefers in-line regex visibility at
each call site over single-source-of-truth. No correctness signal.

## Pointer

- `tests/unit/test-agent-frontmatter-no-model.bats:508-516` (TE5)
- `tests/unit/test-agent-frontmatter-no-model.bats:603-610` (TE7-GREEN)

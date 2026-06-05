---
finding: F03
reviewer: code-quality-claude
round: 7
severity: medium
area: ID hygiene (criterion 11)
---

## Residual QRSPI-internal task/round IDs in dispatch-agent.sh comments

### Location

`scripts/dispatch-agent.sh`

- Line 14: `# Per T04 of the v0.7 release: this script no longer drives the Codex broker`
- Line 777: `# Allowlist validation (T09 R2 fix): --reviewer-tag is concatenated`
- Line 796: `# Allowlist validation (T09 R2 fix): --model is concatenated into`

### Problem

The round-07 diff correctly removed `G16` prefixes from all comments and test
names throughout the diff. However, three instances of other QRSPI-internal
IDs — `T04`, `T09`, and `R2` — were not cleaned up and remain in code comments.

Grep-lint results (pattern `\b[GRDFTQ]-?[0-9]+[A-Za-z]?\b` against
`scripts/dispatch-agent.sh`):

| Match | Line | Context |
|-------|------|---------|
| `T04` | 14   | "Per T04 of the v0.7 release" |
| `T09` | 777  | "Allowlist validation (T09 R2 fix)" |
| `T09` | 796  | "Allowlist validation (T09 R2 fix)" |
| `R2`  | 777  | same inline ref |
| `R2`  | 796  | same inline ref |

Per criterion 11, QRSPI-internal IDs are forbidden in code comments regardless
of scope. They are run-specific tokens that carry no durable meaning to a
reader unfamiliar with the internal review tracker.

### Fix

Replace with descriptive prose:

```sh
# Line 14 — replace:
# Per T04 of the v0.7 release: this script no longer drives the Codex broker
# with:
# Dispatcher hand-off (v0.7 refactor): this script no longer drives the Codex
# broker directly. …

# Lines 777, 796 — replace:
# Allowlist validation (T09 R2 fix): --reviewer-tag is concatenated …
# with:
# Allowlist validation: --reviewer-tag is concatenated …
```

The motivating context (security properties, grammar choices) is already
explained inline; the task/round references add no information for a reader
who does not have access to the QRSPI tracker.

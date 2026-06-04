---
finding_id: R6-F01
reviewer_tag: silent-failure-codex
round: 6
severity: high
change_type: correctness
referenced_files: [scripts/_resolve-lib.sh:154-167]
---

# silent-failure-codex F01 — empty normalized value → silent success

`resolve_model` can return success with an **empty** resolved value. A row like
`low:   ` (key with trailing whitespace, no value) still matches the
`[[:space:]]`-anchored row grep (L140); after stripping the key prefix and
normalizing (L154-155), `value=""`. The code only halts on exact `"none"`
(L159), so the empty value bypasses the halt and falls through to
`printf '%s\n' "$value"; return 0` (L166-167) — emitting a **blank line with
exit 0**.

**Impact:** caller sees a successful resolution but gets no model mapping — a
silent bad state on malformed config, the exact class this G7b/#204 task exists
to close.

**Fix:** add `[ -z "$value" ]` → loud HALT (distinct malformed-row diagnostic)
before the none-check, plus a pinning behavioral test.

Convergent with silent-failure-claude.finding-F01 (independent dual-family hit).
Chat-only return persisted by orchestrator.

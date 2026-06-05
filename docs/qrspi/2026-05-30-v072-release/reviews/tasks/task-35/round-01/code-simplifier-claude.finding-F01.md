---
finding_id: F01
reviewer: code-simplifier-claude
reviewer_role: code-simplifier
round: 1
task: 35
severity: low
change_type: simplification
file: tests/acceptance/test-review-pause.bats
lines: "168-170"
status: open
---

# F01 — `&& return 1 || true` negation can be expressed more directly

## Pattern

In the first new test (`[G10] reviewer-protocol/SKILL.md contains '### Anti-Fabrication Rule (FAIL-LOUD)' immediately after '### Refusal Procedure'`), the assertion that no headings appear between the two anchors is written as:

```bash
awk -v a="$lineno_refusal" -v b="$lineno_anti" 'NR>a && NR<b' "$BOILERPLATE_FILE" \
  | grep -E '^(### |## )' && return 1 || true
```

The `&& return 1 || true` tail is the standard awkward-bash dance to invert an exit code. It also has the well-known footgun that if the `return 1` branch is ever rewritten to do anything else that itself can fail, `|| true` will silently swallow the new failure.

## Simpler equivalent

bats supports `!` directly on a pipeline:

```bash
! awk -v a="$lineno_refusal" -v b="$lineno_anti" 'NR>a && NR<b' "$BOILERPLATE_FILE" \
  | grep -qE '^(### |## )'
```

(With `-q` so grep doesn't print to stdout when it does find something — the diagnostic in this test is just the failed assertion, same as every other grep assertion in this file.)

This:
- Reads as "no `###`/`## ` heading lines exist in the slice" rather than as control flow.
- Matches the style used by the other negation in this very task — line 259 already uses `! grep -qF ...`.
- Removes the `|| true` swallow.

Behavior-preserving: both forms fail the test iff the inner grep matches; both succeed iff it doesn't.

## Why low severity

It's stylistic — the test passes either way and the pattern is contained to two lines. Worth flipping for consistency with the `! grep -qF` form already used 90 lines below, but not load-bearing.

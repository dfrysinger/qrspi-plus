# cs-claude Finding F02 — Verbose `found` return pattern in `check_codex_available`

**File:** `scripts/run-codex-review.sh`
**Lines:** 179–183 (post-diff, inside `check_codex_available`)
**Category:** Verbose Pattern
**Severity:** Advisory / polish backlog (very minor)
**Security impact:** None — behavior is identical; no security guard is changed.

---

## Current code

```bash
if [[ "$found" -eq 1 ]]; then
  return 0
else
  return 1
fi
```

---

## Problem

The `if/return 0 / else / return 1` idiom is the most verbose way to convert a
boolean variable to a shell exit code.  The condition itself (`[[ … ]]`) already
produces the correct exit status, so the surrounding structure adds four lines
of noise with no benefit.

---

## Proposed simplification

```bash
[[ "$found" -eq 1 ]]
```

In bash, a function's return status is the exit status of its last executed
command.  `[[ "$found" -eq 1 ]]` exits 0 when `found` is 1 (file found → success)
and exits 1 when `found` is 0 (no file → failure), which is exactly the
desired contract.

### Why this is safe

* `found` is initialised to `0` and only ever set to `1` inside the loop.
  The integer comparison is deterministic.
* No security path is affected: the HOME validation case-block and the `/` check
  above the loop are unchanged.
* The function's external contract (`return 0` = Codex available, `return 1` =
  not available) is preserved.
* Compatible with bash ≥ 3.2 (the portability target stated in the comment
  above `check_codex_available`).

---

## Note

This is a one-liner cosmetic change.  If the team prefers the explicit
`return 0` / `return 1` form for readability, it is entirely reasonable to
keep it.  The finding is recorded here for completeness.

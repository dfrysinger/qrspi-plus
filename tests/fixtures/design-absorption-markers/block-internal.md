# Design — block-internal `Explicit non-goal` marker fixture

## G7 — Goal with explicit non-goals enumerated:

Body prose introducing the goal scope.

- Doing the thing this goal does NOT cover. **Explicit non-goal.** The non-goal rationale.
- Another excluded surface. **Explicit non-goal.** A second rationale.

## CD-2 — Some unrelated cross-cutting decision

Body that mentions `**Explicit non-goal.**` outside any `## G\d+` heading; the script ignores it because no enclosing goal-ID is in scope.

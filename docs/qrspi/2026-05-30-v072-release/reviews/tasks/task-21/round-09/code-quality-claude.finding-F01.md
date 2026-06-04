# F01 — Round-number QRSPI-internal token (`R8`) leaked into production code/test comments

**Severity:** must-fix (ID hygiene)

**Locations**

- `scripts/lib/path-guard.sh:96`
  ```
  # materializes a directory tree outside the repo (sf-claude R8 finding).
  ```
- `tests/unit/test-dispatch-agent.bats:1227` (added in this diff)
  ```
  # sf-claude R8 regression: a broken symlink IN the repo whose target lives
  ```

Both are net-new lines in this round-9 diff (path-guard.sh is a new file; the bats comment is in a freshly added test).

**Why it's a problem**

Per the reviewer protocol's ID-hygiene contract, QRSPI-internal IDs matching `\b[GRDFTQ]-?[0-9]+[A-Za-z]?\b` are forbidden in code comments and test-name strings outside `docs/qrspi/`. `R8` is the round-8 token from this very task's review trail.

This is the same class of issue that R7 F02 closed (the dispatch note explicitly calls out "R7 F02 token strip" as cycle-9 follow-through). The just-closed token-strip work introduced two new round-token references while removing the old ones — the policy violation is unchanged, only the round number rolled forward.

The `sf-claude` / `sec-claude` reviewer tags on the same lines are fine (they're reviewer identifiers, not QRSPI internal IDs); only the `R8` token needs to be removed.

**Suggested fix**

Replace each `R8 finding` / `R8 regression` reference with a token-free description of the underlying defect — the comment text already explains what the regression is. For example:

```
# materializes a directory tree outside the repo (broken-symlink boundary regression).
```
```
# Broken-symlink boundary regression: a broken symlink IN the repo whose target lives
```

The rationale is preserved; the run-specific token is dropped.

**Out of scope (per dispatch deferrals)**

- Not flagging `task-20`/`R5 F01` strings on pre-existing context lines (`tests/unit/test-dispatch-sites.bats` around line 274) — those are not part of the R9 additions.
- Not flagging `(sf-claude review)` / `(sec-claude review)` tags — these are reviewer identifiers, not internal IDs.

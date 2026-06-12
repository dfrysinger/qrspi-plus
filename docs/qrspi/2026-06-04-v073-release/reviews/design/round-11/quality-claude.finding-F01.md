---
artifact: design
reviewer_tag: quality-claude
finding_id: quality-claude-F01
change_type: correctness
---

# G6 single-task-wave edge case bullet is stale after round-11's solution-body restructure

## Location

design.md L405 (G6 "Dependencies + edge cases" — single-task wave bullet). Cross-references the round-11 rewrite of G6 step 2 at L396 and the dependencies bullet at L404.

## Finding

Round 11 restructured G6's solution body to lock in a specific shape for the expected-parents set. Solution step 2 (L396, post-diff) now reads:

> the wave-dispatch step captures (a) `git rev-parse HEAD` as the integration-base SHA (will become parent[0] of the `--no-ff` merge), and (b) `git rev-parse refs/heads/<task-NN>` for each task name, writing the **full {integration-base, task-tips...} set** to a runtime sidecar … The validation in step 3 reads from this sidecar and compares the **full parent set, with no parent[0]-stripping normalization**.

The dependencies bullet at L404 was updated to match ("Depends on the wave-dispatch step capturing both the integration-base SHA … and each task tip SHA"). But the single-task-wave edge case bullet at L405 was not updated and now contradicts the locked solution:

> Edge case — single-task wave: actual parents = {integration-base, task-tip}; **expected = {task-tip}**; comparison must include the integration-base parent as expected (it's always parent[0] of `git merge --no-ff`). **Either record the expected-set as "everything except parent[0]" or include the integration base in the expected set. Choose the latter for symmetry** — the validation always compares full parent set vs. full expected set.

Two concrete problems:

1. **`expected = {task-tip}` is now false.** Per the solution body, the wave-dispatch step writes the full `{integration-base, task-tips...}` set to the sidecar. For a single-task wave, that set is `{integration-base, task-tip}`. The bullet asserts `expected = {task-tip}`, which is the *no-integration-base* form the solution body explicitly rejected ("no parent[0]-stripping normalization").

2. **The "Either … or … Choose the latter" deliberation is stale.** This phrasing presents the integration-base-inclusion question as an open design choice being decided in the edge-case bullet. After the round-11 rewrite, the choice is already made and stated in the solution body (and reiterated in the dependencies bullet). The bullet should describe how the single-task case is handled under the now-locked design, not re-deliberate it.

A reader who skims top-to-bottom hits a coherent solution body (full-set capture, full-set comparison), then hits an edge-case bullet that says the expected set is `{task-tip}` and still talks about the choice as live. The reader cannot tell which statement governs.

This is also a small but real correctness hazard for an implementer who reads L405 in isolation: implementing `expected = {task-tip}` would produce a guaranteed mismatch on every single-task wave (actual `{integration-base, task-tip}` vs. expected `{task-tip}`) — exactly the failure the bullet's own next clause ("comparison must include the integration-base parent as expected") tries to head off, but only by way of deliberation rather than directive.

## Expected fix

Rewrite L405 so it states the single-task case under the locked design rather than re-deriving it. Suggested replacement:

> - Edge case — single-task wave: actual parents = {integration-base, task-tip}; expected per the sidecar contract above = {integration-base, task-tip}. The full-set comparison (no parent[0] stripping) handles single-task and multi-task waves symmetrically — the integration-base parent is captured into the expected set at sidecar-write time and is compared as a peer of the task tips, not skipped or normalized away.

That preserves the load-bearing content of the bullet (covering the single-task case explicitly so an implementer doesn't reinvent a parent[0]-stripping shortcut) while removing the stale "expected = {task-tip}" assertion and the now-resolved "Either … or … Choose the latter" deliberation.

Alternatively, if the single-task case is fully covered by the solution body's "writing the full {integration-base, task-tips...} set", drop L405 entirely. The current text adds confusion without adding rule content.

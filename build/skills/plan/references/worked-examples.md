# Plan Worked Examples

Read this file when authoring a task spec and you need a concrete shape for: sweep-task `dependent_tests:` lists, `cross_task_consumers:` lists with dispositions, or a full good-vs-bad task spec contrast. The spine of `skills/plan/SKILL.md` carries the contract; this file carries the worked-example evidence.

## Example A — sweep task with explicit `dependent_tests:` path list

A sweep task that strips `model:` from all 41 agent frontmatter files lists every test that asserts on the previous `model:` values, with a one-sentence disposition per file:

```markdown
- **Test expectations:**
  - All 41 agent files have `model:` removed from frontmatter; no other frontmatter fields change.
  - `dependent_tests:`
    - `tests/unit/test-scope-tagger-dispatch.bats` — currently asserts `model: opus` on line 38; update to assert `model:` is absent post-sweep.
    - `tests/unit/test-verifier-agent-file.bats` — currently asserts `model: sonnet` on line 7; update to assert `model:` is absent post-sweep.
    - `tests/unit/test-visual-fidelity-reviewer-agent.bats` — currently asserts a specific model value on line 35; update to assert `model:` is absent post-sweep.
    - `tests/unit/test-test-writer-dual-mode.bats` — currently asserts `model: opus` on line 52; update to assert `model:` is absent post-sweep.
    - `tests/unit/test-change-type-partition.bats` — currently asserts model-routed dispatch on line 15; passes unchanged once the dispatcher's fallback path is exercised.
    - `tests/unit/test-section-anchor-narrow-read.bats` — currently asserts `model: sonnet` on line 206; update to assert `model:` is absent post-sweep.
```

## Example B — sweep task with `none` plus grep-confirmed zero-match proof

A sweep task that removes a property no test currently asserts on cites a reproducible grep command the reviewer re-runs from the repo root:

```markdown
- **Test expectations:**
  - All 17 CD files have `${VAR}` references replaced with their resolved literals; behavior unchanged.
  - `dependent_tests: none`
    - `grep -rn -- '^model:' tests/` returns zero matches as of plan-authoring time; if a future test introduces an assertion on `model:` before this task lands, the reviewer's re-run will surface the new hit and demand the field be re-shaped to a path list.
```

## Example C — public-symbol rename with three consumers (cross-task-consumer trigger fires)

A task renames the public function `check_codex_available` to `check_second_reviewer_available` across the dispatcher script and one consumer skill, listing three consumer files outside `files_in_scope` with explicit dispositions:

```markdown
- **Test expectations:**
  - `scripts/dispatch-agent.sh` exports the renamed helper; `skills/using-qrspi/SKILL.md` calls the new name.
  - `cross_task_consumers:`
    - `skills/goals/SKILL.md` — references the old helper name in its inline availability probe; `co-edit` to rename the call site inside this task.
    - `skills/implement/SKILL.md` — references the old helper name in the second-reviewer dispatch block; `co-edit` to rename the call site inside this task.
    - `tests/unit/test-codex-host-vendor-matrix.bats` — asserts on the helper-name surface as documentation, not as an executable reference; `no change` because the test was rewritten in T07 to target the host×vendor matrix and no longer pins the helper name.
```

## Example D — body-only bug fix (cross-task-consumer trigger does not fire)

A task fixes an off-by-one error inside the body of an existing function in one file. No public-signature change, no rename, no schema change, no extension-point change. The `cross_task_consumers:` field is NOT required:

```markdown
- **Test expectations:**
  - `lib/pagination.go` `paginate()` returns the correct slice when `offset == len(items)`; existing public signature unchanged.
  - (no `cross_task_consumers:` field — the trigger does not fire because this is a body-only bug fix with no public-signature, schema, or extension-point change.)
```

## Good vs bad full task spec

**Good task spec:**

```markdown
### Task 3: Rate limit middleware

- **Phase:** 1
- **Target files:** create `src/middleware/rate-limiter.ts`, modify `src/app.ts:34-40`
- **Dependencies:** Task 1 (Redis client), Task 2 (rate limit types)
- **LOC estimate:** ~60
- **Description:** Express middleware that checks the client's request count against the rate limit using the Redis client from Task 1. If exceeded, returns 429 with Retry-After header. If under limit, increments the counter and calls next().
- **Test expectations:**
  - Returns 429 when client exceeds 100 requests/minute
  - Returns Retry-After header with seconds until window resets
  - Calls next() when client is under limit
  - Increments Redis counter on each allowed request
  - Extracts client ID from X-Forwarded-For header
  - Returns 429 (not 500) when Redis is unreachable (fail closed)
  - Handles missing X-Forwarded-For gracefully (use IP as fallback)
```

**Bad task spec (vague, placeholders):**

```markdown
### Task 3: Rate limiting

- **Target files:** TBD
- **Dependencies:** none
- **LOC estimate:** ~200
- **Description:** Add rate limiting middleware. Similar to Task 2 but for the middleware layer.
- **Test expectations:**
  - Rate limiting works correctly
  - Edge cases are handled
```

The bad example has TBD files, no dependencies (but clearly needs the Redis client), unrealistic LOC, references "similar to Task 2", and test expectations that can't be verified ("works correctly", "are handled").

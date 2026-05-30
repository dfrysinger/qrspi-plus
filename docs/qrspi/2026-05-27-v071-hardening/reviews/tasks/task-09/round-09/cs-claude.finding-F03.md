# cs-claude · Finding F03 · Two `[r5-sf.F01]` scalar-at-end tests are topologically identical

**File:** `tests/unit/test-agent-frontmatter-no-model.bats`
**Lines:** 242–269 and 271–297 (worktree lines 242–297)
**Severity:** Polish / Non-blocking
**Category:** Redundant Tests / Dead Code

---

## What the two tests do

### Test 1 (lines 242–269): "frontmatter ending with block-scalar key exits cleanly at closing ---"

Fixture:
```yaml
---
name: qrspi-test-scalar-at-end
description: |
  some description text
  more description text
---
body starts here
model: something at body start
```
Assertion: `_frontmatter` must return empty output for `grep -nE '^model:'`
(i.e., body `model:` must NOT be returned).

### Test 2 (lines 271–297): "frontmatter with block-scalar last key and no body model: still clean"

Fixture:
```yaml
---
name: qrspi-test-scalar-at-end-clean
description: |
  some description text
  more description text
---
body starts here
model: this line must not appear in frontmatter output
```
Assertion: identical — `_frontmatter` must return empty output for
`grep -nE '^model:'`.

## The problem

The two fixtures are **topologically identical**:

| Property | Test 1 | Test 2 |
|---|---|---|
| Opening `---` | ✓ | ✓ |
| Non-scalar key | `name:` | `name:` |
| Block-scalar last key | `description: \|` | `description: \|` |
| Indented body lines | 2 lines | 2 lines |
| Closing `---` | ✓ | ✓ |
| Body has `model:` | ✓ (`model: something at body start`) | ✓ (`model: this line must not appear…`) |

Both tests exercise exactly the same code path and pass/fail together.  The
second test's name says "no body model: still clean" but the fixture body
**does** contain a `model:` line — a name/content contradiction that also
suggests the test may have drifted from its original intent during editing.

The comment on Test 2 says it "independently detects the over-reading
regression", but since the topology is identical, it provides zero additional
detection power over Test 1.

## Proposed simplification

Drop Test 2 entirely.  Test 1 already covers the scalar-at-end over-reading
scenario.  If the intent was to have one fixture *with* body `model:` and one
*without* (to distinguish false-positive from false-negative), the second
fixture's body should be rewritten to omit `model:` — but that would then test
a different property (that a clean file produces no output), which is already
covered by the `lint scope is the frontmatter block, not body prose` test (lines
213–240).

Removing Test 2 reduces the test count from 8 to 7 with no coverage loss.

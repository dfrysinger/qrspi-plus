# gt-claude · Finding F01 · Spec criterion 3 ("other frontmatter keys unmodified") is listed under Test Expectations but has no automated test

**Artifact:** `tests/unit/test-agent-frontmatter-no-model.bats`
**Spec source:** `tasks/task-09.md` § Test expectations, bullet 3
**Severity:** Low / Non-blocking
**Category:** Traceability gap — test-expectation bullet without BATS coverage

---

## Traceability chain

```
G7b (goals.md) → task-09 goal_ids: [G7b]
  → task-09.md § Test expectations, bullet 3:
      "All other frontmatter keys (skills:, description:, name:,
       and any agent-specific keys) are unmodified"
  → No BATS test exists for this criterion
  → Manual Validation section instead: "git diff --stat HEAD~1 --
      'agents/qrspi-*.md' shows exactly 41 files changed, each with
      one line removed and zero lines added"
```

## What the spec says

`tasks/task-09.md` § **Test expectations** contains four bullets.
Bullet 3 reads:

> All other frontmatter keys (`skills:`, `description:`, `name:`, and
> any agent-specific keys) are unmodified

This bullet appears inside the `- **Test expectations:**` block — the
same block as the three criteria that _are_ backed by BATS assertions.

## What the test suite covers

The eight tests in `test-agent-frontmatter-no-model.bats` cover:

| Test | Spec criterion covered |
|------|------------------------|
| `sweep matches the expected 41 qrspi agent files` | criterion 1 (count canary) |
| `no agents/qrspi-*.md frontmatter carries a top-level model: key` | criteria 1 + 2 |
| `per-file failure message names the offending file path` | criterion 4 |
| CRLF / block-scalar / scope / scalar-at-end (4 tests) | helper correctness — all back criterion 1 |

**Criterion 3 has no BATS test.** No assertion checks that a key such as
`skills:`, `description:`, or `name:` is still present and unchanged in
any agent file after the task runs.

## The spec's own routing

The `tasks/task-09.md` § **Manual Validation** section explicitly routes
criterion 3 to operator verification:

> `git diff --stat HEAD~1 -- 'agents/qrspi-*.md'` for the Task 9 commit
> shows exactly 41 files changed, each with one line removed and zero lines
> added (verifies that only the `model:` frontmatter line was removed and no
> body prose was collaterally modified). Operator-verified; BATS-level git
> introspection is impractical for this scope.

The manual path is intentional and documented.

## The traceability problem

The spec co-locates criterion 3 in the **Test expectations** block _and_
manually-verifies it in the **Manual Validation** block.  This dual
placement sends conflicting signals:

1. A future reviewer running the BATS suite and seeing all-green has
   no automated signal that criterion 3 was validated.  The BATS run
   cannot distinguish "all keys preserved" from "some other key silently
   removed."

2. Any automated gate that counts spec-criteria-covered-by-tests
   (e.g., a future test-coverage reviewer agent) will see 4 spec bullets
   and only 3 BATS-covered criteria, and will correctly flag a gap — but
   the gap is intentional, which is not discoverable without reading the
   Manual Validation section.

## Suggested resolution (non-blocking)

Either:

**Option A — Move criterion 3 out of Test expectations into Manual Validation.**
Restructure the spec so the Manual Validation section is the canonical
home for "other keys unmodified."  The Test expectations block would then
list only the three BATS-verifiable criteria and accurately represent the
automated coverage boundary.

**Option B — Add a scope-check BATS test.**
A lightweight test can verify that all agent files under
`agents/qrspi-*.md` still contain at least one of the required keys
(e.g., `skills:` present in frontmatter).  This is not "git introspection"
and is fully BATS-portable:

```bash
@test "no required frontmatter key was stripped alongside model:" {
  local f violations=0
  for f in agents/qrspi-*.md; do
    [ -f "$f" ] || continue
    _frontmatter "$f" | grep -qE '^skills:' || {
      violations=$((violations + 1))
      echo "  missing skills: key in $f"
    }
  done
  [ "$violations" -eq 0 ]
}
```

Option A requires only a spec edit (zero code change); Option B closes
the gap with an automated guard.  Either is acceptable; the current state
(criterion in Test expectations with no test) creates an implicit false
completeness signal for future readers.

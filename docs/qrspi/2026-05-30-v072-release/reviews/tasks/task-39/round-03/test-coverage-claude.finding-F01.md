---
reviewer: test-coverage-claude
finding_id: F01
severity: high
change_type: correctness
references:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L3106-L3129
  - docs/qrspi/2026-05-30-v072-release/tasks/task-39.md#L70
---

# F01 — Acceptance fixture tests don't exercise the fixtures (vacuous existence-only assertions)

## Observation

Task 39's `Test expectations` includes (line 70):

> Acceptance fixtures cover a legacy `${CLAUDE_SKILL_DIR}` directive failure
> and a deliberate include-cycle failure **with the required diagnostics**.

The two corresponding acceptance tests in `test-phase1-acceptance.bats`
(lines 3106–3129) only assert that the fixture **directories exist** and
that they contain a literal `${CLAUDE_SKILL_DIR}` token / two `!cat`
directives. They never:

1. Invoke `node tools/build-plugin.mjs --root <fixture>` against the
   fixture.
2. Capture the resolver's exit status (must be non-zero).
3. Assert the diagnostic phrasing required by the spec — namely
   `${CLAUDE_SKILL_DIR}` (legacy-form fixture) and `cycle` plus the
   full `a -> b -> a` chain (cycle fixture).

This is a **vacuous test**: the fixture could exist but contain
syntactically valid `!cat` content that the resolver accepts (or the
resolver could regress and silently emit garbage), and both tests would
still pass.

The corresponding unit-level coverage in `test-build-gate.bats`
(`fail-loud: include cycle exits non-zero with the FULL cycle printed`,
lines 212–223; `fail-loud: ${CLAUDE_SKILL_DIR} occurrence in shipped
file rejected`, lines 244–251) does exercise the resolver, but those
tests use *inline-staged* fixtures, not the shared `tests/fixtures/`
acceptance fixtures. The release-level acceptance gate the task
expectation references is therefore not actually wired to the
production code path.

## Impact

The task's release-level G32 acceptance gate cannot detect:

- A regression where the resolver stops failing on `${CLAUDE_SKILL_DIR}`
  occurrences (e.g., a future allowlist tweak breaks the legacy-form
  guard).
- A regression where the cycle diagnostic drops the full chain or stops
  printing both file paths.
- A fixture-rot scenario where someone edits the fixture content into a
  shape the resolver no longer rejects.

The `with the required diagnostics` half of the test expectation is
unverified.

## Suggested remediation

Replace the existence-only checks with end-to-end runs:

```bats
@test "[T39/G32 acceptance] legacy \${CLAUDE_SKILL_DIR} fixture: build fails non-zero with named diagnostic" {
  local fixroot
  fixroot="$(find "$REPO_ROOT/tests/fixtures" -type d -name 'build-resolver-claude-skill-dir*' -print -quit)"
  [ -n "$fixroot" ]
  run node "$REPO_ROOT/tools/build-plugin.mjs" --root "$fixroot" --out "$BATS_TEST_TMPDIR/out"
  [ "$status" -ne 0 ]
  echo "$output" | grep -F 'CLAUDE_SKILL_DIR'
}

@test "[T39/G32 acceptance] cycle fixture: build fails non-zero with full cycle and both filenames" {
  local fixroot
  fixroot="$(find "$REPO_ROOT/tests/fixtures" -type d -name 'build-resolver-cycle*' -print -quit)"
  [ -n "$fixroot" ]
  run node "$REPO_ROOT/tools/build-plugin.mjs" --root "$fixroot" --out "$BATS_TEST_TMPDIR/out"
  [ "$status" -ne 0 ]
  echo "$output" | grep -E -i 'cycle|circular'
  # Both legs of the cycle must appear in the diagnostic.
  echo "$output" | grep -F 'a.md'
  echo "$output" | grep -F 'b.md'
}
```

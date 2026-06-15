---
finding_id: F01
reviewer: qrspi-spec-reviewer (Test-phase)
reviewer_tag: claude
round: 1
severity: high
change_type: defect
phase: test-phase
artifacts:
  - tests/acceptance/v07-phase1-test-phase/test-g5-orchestration-boundary.bats
  - tests/acceptance/v07-phase1-test-phase/test-regressions-integration-round01.bats
---

# F01 — `printf '%s\n'` assertions over-escape the backslash; search needle never matches the SKILL prose

## Where

- `tests/acceptance/v07-phase1-test-phase/test-g5-orchestration-boundary.bats:66` and `:71`
- `tests/acceptance/v07-phase1-test-phase/test-regressions-integration-round01.bats:62` and `:68`

All four occurrences are of the shape:

```
grep -qF "printf '%s\\\\n'" "$INTEGRATE_SKILL"   # (or $TEST_SKILL)
```

## What's wrong

The double-quoted bash literal `"printf '%s\\\\n'"` collapses `\\` → `\` twice during
string-parse, so the fixed-string argument actually handed to grep is
**`printf '%s\\n'` (TWO backslashes before `n`).** The SKILL prose under review carries
only ONE backslash (this is the bash incantation documented by fix-F01):

`skills/integrate/SKILL.md:94`
```
printf '%s\n' "$(git -C "<repo>" rev-parse HEAD)" \
```

`skills/test/SKILL.md` carries the same single-backslash form per the fix-F01 contract.

With `grep -F`, a two-backslash literal needle cannot match a one-backslash haystack,
so these four positive assertions will **always fail** when executed — they do not
verify the post-fix bare-SHA `printf '%s\n'` contract they claim to verify. The
negated companion lines (e.g. `test-regressions-integration-round01.bats:60`, `:67`,
which assert the pre-fix `'integration_base_sha=%s\\\\n'` shape is ABSENT) vacuously
pass for the same wrong-encoding reason — also masking the bug from cursory file
inspection without actually pinning the pre-fix shape out.

This is a wrong-assertion defect (Test-phase rubric: assertion exercises something
other than the claimed criterion). The plan/design specify ONE backslash; the test
encodes TWO.

## Why it matters

Coverage-report rows directly affected, which lose all signal under this bug:

| Row | Criterion | Status under bug |
|-----|-----------|------------------|
| `test-g5-orchestration-boundary.bats:67` | integrate phase-base.txt bare-SHA write (G5/PA #10) | red — claimed Covered, would red-test |
| `test-g5-orchestration-boundary.bats:71` | test phase-base.txt bare-SHA write (G5/PA #10) | red — claimed Covered, would red-test |
| `test-regressions-integration-round01.bats:62` | fix-F01 integrate-SKILL bare SHA | red — claimed Covered, would red-test |
| `test-regressions-integration-round01.bats:68` | fix-F01 test-SKILL bare SHA | red — claimed Covered, would red-test |

Plan PA #10 SKILL-prose half AND the fix-F01 regression guard both lose their gate.

## Fix direction

Inside double quotes one backslash in source survives as one backslash in the grep
argument:

```
grep -qF "printf '%s\\n'" "$INTEGRATE_SKILL"
```

— or, more legibly, single-quote the entire needle so no double-quote escape parsing
runs at all (each `'` inside is `'"'"'`):

```
grep -qF 'printf '"'"'%s\n'"'"'' "$INTEGRATE_SKILL"
```

Whichever shape lands, the byte-exact needle MUST be `printf '%s\n'` (one backslash)
to match the SKILL prose. Apply the same fix-direction to the negated companion lines
at `:60` and `:67` so they shift from "vacuously pass" to "meaningfully refuse the
key=value form" — otherwise the regression direction silently rots.

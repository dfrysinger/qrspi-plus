---
reviewer: test-coverage-claude
finding_id: F05
severity: low
change_type: correctness
references:
  - tests/unit/test-build-gate.bats#L159-L168
---

# F05 — CR-stripping test relies on `grep -U`, a GNU-only flag absent from BusyBox grep (used in the bash:3.2 CI image)

## Observation

The CR-stripping test asserts:

```bash
@test "[T39/G32] resolver: strips CR (\r) characters from included content" {
  ...
  run grep -U $'\r' "$root/build/skills/sample/SKILL.md"
  [ "$status" -ne 0 ]
}
```

`grep -U` (treat input as binary / disable CRLF→LF auto-stripping) is a
**GNU grep extension**. Both BSD grep (macOS) and BusyBox grep (Alpine
images including the `bash:3.2` Docker image used by `.github/workflows/ci.yml`'s
`bash32` job) reject `-U` as an unknown option, exiting with status 2,
not 1.

The assertion is `[ "$status" -ne 0 ]` — which is satisfied by both:

- (intended) "no `\r` byte present" → grep exits 1
- (unintended) "`-U` not recognized" → grep exits 2

The test therefore **passes vacuously on the bash32 CI image** and
locally on macOS contributor laptops, even if the resolver regresses
and stops stripping CR.

## Impact

The CR-stripping invariant — explicitly listed in the task's
Definition of Done line 48 ("strips CR characters") and Test
Expectations line 63 ("CR stripping") — is unverified on every
shipping CI surface except a GNU-grep host. The unit-level pin gives
false confidence.

## Suggested remediation

Drop `-U` and assert via a portable byte-level check:

```bash
# Portable CR check: read the file, look for any \r byte.
run bash -c "LC_ALL=C tr -cd '\r' < '$root/build/skills/sample/SKILL.md' | wc -c | tr -d ' '"
[ "$status" -eq 0 ]
[ "$output" = "0" ]
```

Or use `od`:

```bash
run bash -c "od -c '$root/build/skills/sample/SKILL.md' | grep -F '\\r' || true"
[ -z "$output" ]
```

Either form is portable across GNU/BSD/BusyBox and asserts the actual
byte-level invariant rather than relying on a GNU-only flag whose
non-implementation silently satisfies `-ne 0`.

---
finding_id: R3-F04
reviewer_tag: silent-failure-claude
round: 3
task: 12
severity: medium
change_type: correctness
referenced_files:
  - tests/unit/test-await-round.bats
---

# F04 — Shell-metacharacter injection test is vacuous: passes even when `parse_and_validate` is removed entirely

## Location

`tests/unit/test-await-round.bats:215–240` — test `"command-injection: shell-metacharacter await_cmd does NOT spawn a shell"`

## Test setup

```json
"await_cmd": "evil-no-such-binary; touch /tmp/qrspi-…"
```

## Trace WITHOUT `parse_and_validate`

1. `shlex.split("evil-no-such-binary; touch /tmp/qrspi-…")` → `['evil-no-such-binary;', 'touch', '/tmp/…']`
2. `subprocess.run(['evil-no-such-binary;', 'touch', '/tmp/…'], shell=False, cwd=DISPATCH_CWD)` — OS tries to exec a binary literally named `evil-no-such-binary;`. No such binary → `FileNotFoundError`.
3. `except Exception as e: errs.append(…); final_rc = 1`

**Outcome without the guard:** `status != 0`, `! -e "$PWN_PATH"` — both test assertions pass. The evil file is never created not because the guard blocked it, but because `shell=False` alone makes the metachar-laden first token unresolvable. **Removing `parse_and_validate` does not change the test outcome.**

Compare to the `touch $PWN_PATH` test where `await_cmd = "touch /tmp/…"`: `exe = "touch"` IS on `$PATH`, so without the guard `subprocess.run(['touch', '/tmp/…'], shell=False)` would successfully create the file. That test IS behavioral.

The vacuous test produces false confidence — a reviewer reading green tests believes the metachar bypass is blocked by `parse_and_validate`. It is actually blocked by `shell=False` independently.

## Fix

Replace the unreachable binary with a real bare-name binary so guard removal would lead to `echo` running. Better: directly unit-test `parse_and_validate(metachar_input)` and assert it returns `(None, error_string)`.

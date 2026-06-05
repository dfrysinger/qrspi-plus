---
finding_id: R3-F05
reviewer_tag: silent-failure-claude
round: 3
task: 12
severity: medium
change_type: correctness
referenced_files:
  - tests/unit/test-await-round.bats
---

# F05 — `split_cmd` validation path never independently exercised: injection guard can be silently removed

## Location

`tests/unit/test-await-round.bats:183–262` — all three `command-injection:` tests

## Observation

Every new injection test puts the malicious command in `await_cmd` and uses `split_cmd: "true"` (or omits it). `"true"` is a bare-name executable not in `BARE_NAME_ALLOWLIST` and not path-shaped, so `parse_and_validate` would reject it — but it never reaches validation because `await_cmd` fails first with `continue`.

## Coverage gap

No test exercises the path where `await_cmd` is a valid path (e.g., stub that exits 0) but `split_cmd` carries an injection payload. If the `parse_and_validate` call on `split_cmd` were removed from production code (lines 209–214 in `await-round.sh`) and `subprocess.run(argv_s, shell=False, …)` were changed back to `subprocess.run(split_cmd, shell=True, …)`, every existing test would remain green:

- Injection tests fail on `await_cmd` before reaching `split_cmd`.
- Happy-path tests use absolute-path stubs for both, which work under either `shell=True` or `shell=False`.

An attacker who controls the manifest can inject arbitrary commands via `split_cmd` after a legitimate `await_cmd`. The test suite cannot detect such a regression.

## Fix

Add at least one test with a stub `await_cmd` that succeeds and a bare-name or metachar `split_cmd`:

```json
{
  "await_cmd": "/path/to/stub-succeed.sh",
  "split_cmd": "touch /tmp/qrspi-split-cmd-pwned-$$"
}
```

Verify `status != 0`, file not created, diagnostic contains `"rejected"` or `"allowlist"`.

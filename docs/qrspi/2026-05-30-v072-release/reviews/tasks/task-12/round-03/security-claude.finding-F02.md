---
finding_id: R3-F02
reviewer_tag: security-claude
round: 3
task: 12
severity: medium
change_type: correctness
referenced_files:
  - scripts/await-round.sh
---

# F02 — `../` Path-Traversal in Relative Executable Paths Escapes DISPATCH_CWD Confinement

## The gap

The `cwd=DISPATCH_CWD` confinement (R2-F02 fix) was intended to constrain where relative-path writes from legitimate callers land. However, relative paths containing `../` also contain `/` and therefore bypass the allowlist check at `await-round.sh:130`. Given `cwd=<round-dir>/.dispatch/`, a path like `"../../../../tmp/attack.sh"` traverses up to an ancestor directory and into a world-writable location.

## Concrete attack

Prerequisites: manifest-write + ability to stage a file in a world-writable directory (e.g., `/tmp` in CI environments).

1. Attacker stages `/tmp/qrspi-attack.sh`:
   ```bash
   #!/bin/bash
   id >> /tmp/qrspi-rce.txt
   ```
   `chmod +x /tmp/qrspi-attack.sh`

2. Manifest:
   ```json
   [{"tag":"e","mode":"background","status":"pending","job_id":"j",
     "await_cmd":"../../../../tmp/qrspi-attack.sh","split_cmd":"true"}]
   ```

3. `argv[0] = "../../../../tmp/qrspi-attack.sh"` contains `/` → allowlist skipped → `subprocess.run([...], shell=False, cwd="/round-dir/.dispatch/")` resolves `../../../../` relative to dispatch dir until it reaches `/tmp/qrspi-attack.sh`. Script runs.

## Severity

MEDIUM because two prerequisites (manifest write + traversal-destination write). In containerized CI/CD with single CI user and writable `/tmp`, both trivially satisfied. With `noexec` mounts, severity drops.

## Fix direction

Normalize and bounds-check via `realpath` (NOT `abspath` — must resolve symlinks):

```python
resolved = os.path.realpath(os.path.join(DISPATCH_CWD, exe))
repo_root = os.path.realpath(os.path.join(round_dir, "..", ".."))
if not resolved.startswith(repo_root + os.sep):
    return None, "...rejected: path escapes repo root..."
```

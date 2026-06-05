---
finding_id: R3-F04
reviewer_tag: code-quality-claude
round: 3
task: 12
severity: low
change_type: clarity
referenced_files:
  - scripts/await-round.sh
---

# F04 — Silent `except Exception: pass` on `os.makedirs` produces a misleading downstream error

## Location

`scripts/await-round.sh:186–189`

```python
try:
    os.makedirs(DISPATCH_CWD, exist_ok=True)
except Exception:
    pass
```

## Observation

The `pass` swallows any `makedirs` failure without appending to `errs`. The most likely failure scenario is that `DISPATCH_CWD` exists as a regular file (unlikely but possible after a crash leaves a stale artifact). In that case the subsequent `subprocess.run(cwd=DISPATCH_CWD, ...)` raises `NotADirectoryError`, which IS caught — but the error message reads `"await-round: await_cmd execution error for 'X': NotADirectoryError"`, making it look like the command itself failed rather than a directory-setup failure. A debugging operator seeing this message would suspect the `await_cmd` binary, not the confinement directory.

## Suggestion

Replace `pass` with a diagnostic append so the root cause surfaces:

```python
except Exception as e:
    errs.append("await-round: could not create confinement dir %r: %s" % (DISPATCH_CWD, type(e).__name__))
```

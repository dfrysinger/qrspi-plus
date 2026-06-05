---
finding_id: R3-F01
reviewer_tag: silent-failure-claude
round: 3
task: 12
severity: medium
change_type: correctness
referenced_files:
  - scripts/await-round.sh
---

# F01 — `os.makedirs` exception silently swallowed; subprocess failure misattributed

## Location

`scripts/await-round.sh:186–189`

```python
try:
    os.makedirs(DISPATCH_CWD, exist_ok=True)
except Exception:
    pass
```

## What goes wrong

If `os.makedirs` fails (parent path is a regular file, permission denied, EROFS filesystem), execution continues silently. The next call is `subprocess.run(argv, shell=False, cwd=DISPATCH_CWD, ...)` which raises `FileNotFoundError` (or `NotADirectoryError`) — caught by the outer `except Exception as e`, recording: `"await-round: await_cmd execution error for 'my-tag': FileNotFoundError"`.

`FileNotFoundError` is the same exception class you'd see if the executable itself is missing. The operator will chase the wrong root cause — looking for a missing binary, not a missing dispatch directory. The actual cause (makedirs failed) is completely erased. On a read-only filesystem or disk-full error, every entry fails with cryptic FileNotFoundError with no indication the directory couldn't be created.

## Fix

```python
try:
    os.makedirs(DISPATCH_CWD, exist_ok=True)
except Exception as e:
    errs.append("await-round: failed to create dispatch cwd %r for %r: %s: %s"
                % (DISPATCH_CWD, tag, type(e).__name__, e))
    entry["status"] = "failed"
    final_rc = 1
    continue
```

(Overlaps cq R3-F04 which flagged the same swallow as low/clarity — sf reclassifies medium/correctness given the misattribution consequence.)

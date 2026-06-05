---
finding_id: R3-F02
reviewer_tag: silent-failure-claude
round: 3
task: 12
severity: low
change_type: correctness
referenced_files:
  - scripts/await-round.sh
---

# F02 — `shlex.split` `ValueError` drops the actual error message; emits only the type name

## Location

`scripts/await-round.sh` `parse_and_validate()`, line ~118–120

```python
try:
    argv = shlex.split(cmdstr)
except ValueError as e:
    return None, "await-round: %s parse error for %r: %s" % (kind, tag, type(e).__name__)
```

## What goes wrong

`type(e).__name__` = `"ValueError"` for every malformed shlex input. The actual `str(e)` — e.g., `"No closing quotation"` or `"No escaped character"` — is discarded. The operator sees:

```
await-round: await_cmd parse error for 'my-tag': ValueError
```

With no detail about what is malformed, a manifest author cannot self-diagnose.

## Fix

```python
return None, "await-round: %s parse error for %r: %s" % (kind, tag, e)
```

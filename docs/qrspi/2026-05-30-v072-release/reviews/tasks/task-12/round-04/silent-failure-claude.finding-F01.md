---
finding_id: R4-F01
reviewer_tag: silent-failure-claude
round: 4
task: 12
severity: medium
change_type: correctness
referenced_files:
  - scripts/await-round.sh
---

# F01 — `_compute_exec_roots()` silently swallows git exception, leaving EXEC_ROOTS=[] in production

## Location

`scripts/await-round.sh` (Python inline block), `_compute_exec_roots()`, lines ~139–148:

```python
try:
    r = subprocess.run(
        ["git", "-C", round_dir, "rev-parse", "--show-toplevel"],
        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, check=False,
    )
    top = r.stdout.decode("utf-8", "replace").strip()
    if top:
        roots.append(os.path.realpath(os.path.join(top, "scripts")))
except Exception:
    pass   # ← new in R3; swallows FileNotFoundError, OSError, etc.
```

## What goes wrong

`subprocess.run` raises `FileNotFoundError` when `git` is not on `PATH` (bare CI images, restricted containers, some macOS setups after Xcode Command Line Tools removal). Any `OSError` subclass (`PermissionError` on the binary, `NotADirectoryError` for a bad `round_dir`) is also caught. The exception is silently discarded with no record in `errs`.

In production, `QRSPI_AWAIT_EXEC_ROOTS` is empty (the env var is for test fixtures). So after the silent swallow:

```
EXEC_ROOTS = []
```

`_compute_exec_roots()` runs once at module level before the manifest loop. Every subsequent `parse_and_validate` call for a path-shaped command (including legitimate production scripts like `scripts/third-party-finding-splitter.sh`) reaches:

```python
for root in EXEC_ROOTS:   # EXEC_ROOTS = [] → loop body never executes
    if _under_root(resolved, root):
        return argv, None
return None, ("await-round: %s rejected for %r: argv[0] %r resolves to %r "
              "which is outside permitted exec roots %r."
              % (kind, tag, exe, resolved, EXEC_ROOTS))
```

Every path-shaped command is rejected with `"outside permitted exec roots []"`. The error message gives no hint that the real cause is git being unavailable. An operator chases "why is my exec path wrong?" instead of "why isn't git installed?". The root cause is erased globally — this affects the entire drain run, not per-entry.

## Failure scenario in practice

1. CI environment without git on `PATH`
2. `QRSPI_AWAIT_EXEC_ROOTS` unset (normal production value)
3. `EXEC_ROOTS = []`
4. Every pending entry fails with `"outside permitted exec roots []"`
5. `.round-complete.json` shows all entries as `"failed"`
6. No diagnostic explains why the repo scripts/ root is absent

## Why not caught by tests

All tests set `QRSPI_AWAIT_EXEC_ROOTS="$TEST_ROOT"`. This populates EXEC_ROOTS even when git fails. The git-failure path is never exercised because the test env var always provides a fallback root.

## Severity rationale

Medium: the "best-effort" design intent is documented in the header, but the silent swallow transforms an environmental misconfiguration into a misleading cascade of rejection errors with no root-cause diagnostic. The fix is minimal: surface the exception in `errs` so the operator knows why the repo scripts/ root is absent.

## Suggested remediation (informational — budget exhausted, accepted-with-issues)

Capture the exception in `errs` (or a caller-visible side channel) instead of discarding it:

```python
except Exception as e:
    errs.append("await-round: git rev-parse failed while computing exec roots "
                "(falling back to QRSPI_AWAIT_EXEC_ROOTS only): %s: %s"
                % (type(e).__name__, e))
```

Note: `errs` is defined in the outer scope and is not accessible inside `_compute_exec_roots` as currently structured. Either pass it as a parameter, return it as a second value, or move the git lookup inline where `errs` is in scope.

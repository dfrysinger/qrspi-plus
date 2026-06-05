---
finding: F02
reviewer: code-quality-claude
round: 7
severity: medium
area: self-consistent defenses (criterion 12)
---

## dispatch-companion.sh post-source guard verifies `assert_path_under_repo_root` but not `assert_ancestor_under_repo_root`, which is also called

### Location

`scripts/dispatch-companion.sh` lines 66–67 (the guard) vs. line 645 (the call)

```sh
# Guard — checks only one of the two functions that will be called:
command -v assert_path_under_repo_root >/dev/null 2>&1 \
  || { echo "error: assert_path_under_repo_root not defined after sourcing path-guard.sh; aborting (fail-closed)" >&2; exit 1; }

# … later, in the launch block …
assert_ancestor_under_repo_root "launch:--round-dir" "$L_ROUND_DIR"   # line 645
_jobs_dir="$L_ROUND_DIR/.dispatch/.jobs"
mkdir -p "$_jobs_dir" || die "launch: cannot create jobs dir: $_jobs_dir"
assert_path_under_repo_root "launch:--round-dir" "$L_ROUND_DIR"        # line 648
```

### Problem

The post-source guard is the fail-loud defense that ensures the script aborts
rather than continuing silently when `path-guard.sh` is empty or corrupt. It
correctly checks for `assert_path_under_repo_root`, but `dispatch-companion.sh`
also calls `assert_ancestor_under_repo_root` (line 645), which is **not
checked**.

`dispatch-companion.sh` does **not** set `set -e`. Under Bash without `-e`, a
call to an undefined function returns exit 127 and emits a "command not found"
diagnostic to stderr, but **execution continues to the next line**. This means:

1. The guard at lines 66–67 passes (since `assert_path_under_repo_root` IS
   defined).
2. At line 645, `assert_ancestor_under_repo_root` is silently a no-op (command
   not found, non-zero return, execution continues).
3. `mkdir -p "$_jobs_dir"` at line 647 runs — potentially materializing
   directories outside the repository if `L_ROUND_DIR` is out-of-tree.
4. `assert_path_under_repo_root` at line 648 still fires and rejects the path.

**Net effect:** the primary security property (reject out-of-repo paths) is
preserved. The pre-mkdir partial-state protection (`assert_ancestor_under_repo_root`
is there specifically to avoid creating directories outside the repo before
the rejection) is silently bypassed for the corrupt-path-guard.sh case.

This is the criterion-12 failure pattern: the defense (the guard) runs in
the environment it is supposed to protect against — a script with a
partially-defined `path-guard.sh` — but does not route correctly because it
only checks for one of two functions it depends on.

### Fix

Extend the post-source guard to also verify `assert_ancestor_under_repo_root`:

```sh
command -v assert_path_under_repo_root >/dev/null 2>&1 \
  || { echo "error: assert_path_under_repo_root not defined after sourcing path-guard.sh; aborting (fail-closed)" >&2; exit 1; }
command -v assert_ancestor_under_repo_root >/dev/null 2>&1 \
  || { echo "error: assert_ancestor_under_repo_root not defined after sourcing path-guard.sh; aborting (fail-closed)" >&2; exit 1; }
```

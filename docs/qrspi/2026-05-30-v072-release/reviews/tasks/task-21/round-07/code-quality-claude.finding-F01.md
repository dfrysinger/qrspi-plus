---
finding: F01
reviewer: code-quality-claude
round: 7
severity: medium
area: naming / documentation
---

## path-guard.sh header is stale: claims "single exported function" but the file now exports two public functions

### Location

`scripts/lib/path-guard.sh` lines 6–8

```bash
# The single exported function:
#
#   assert_path_under_repo_root <label> <path>
```

### Problem

The file-level header was accurate when `path-guard.sh` only contained
`assert_path_under_repo_root`. It is now incorrect in two ways:

1. **A second public function was added without updating the header.**
   `assert_ancestor_under_repo_root` (lines 71–90) is fully public and is
   called from `dispatch-companion.sh` line 645. The header still says
   "The single exported function."

2. **`_qrspi_canonicalize` is named private but is used as a public API.**
   The leading-`_` convention signals "implementation-private to this file."
   But `dispatch-companion.sh` line 654 calls it directly:

   ```sh
   _canon_round_dir="$(_qrspi_canonicalize "$L_ROUND_DIR")" \
     || die "launch: cannot canonicalize --round-dir after boundary check: $L_ROUND_DIR"
   ```

   A caller relying on an undocumented, private-named helper has no stability
   guarantee and creates a confusing read for anyone auditing the API surface.

### Impact

Any engineer reading `path-guard.sh` before sourcing it will miss
`assert_ancestor_under_repo_root` in the header API contract and will not
know that `_qrspi_canonicalize` is expected to be called externally.
Future callers may duplicate its logic or call it inconsistently.

### Fix

Update the header to document both exported functions:

```bash
# Exported functions:
#
#   assert_path_under_repo_root <label> <path>
#   assert_ancestor_under_repo_root <label> <path>
#
# Internal helper (visible after sourcing, stable for callers that need it):
#   _qrspi_canonicalize <path>
```

Or, if the intent is to keep `_qrspi_canonicalize` truly private, remove the
external call from `dispatch-companion.sh` and inline the canonicalization
there (or expose it under a public name without the leading `_`).

---
reviewer_tag: security-claude
round: 10
status: clean
---

CLEAN — R10 is a pure refactor; no security vulnerabilities introduced.

- FIX-AA `_append_manifest_fail`: `eval "$_saved_opts"` always executes before `exit 1` (line 255); `rmdir "$_lock_dir"` (line 254) via bash dynamic scoping from `_append_manifest_entry`'s frame; all 5 error paths route through helper; traps cover signal window; pre-lock exits bypass helper correctly.
- FIX-AB `_install_fp_traps`: called before `mktemp` while relay is `""` (race-window protected); `mktemp XXXXXX` template preserved (O_EXCL); post-`mv` signal hits non-existent path (relay cleared by `_cleanup_fp_tmp`).
- FIX-Y: `$TMP_DIR` is `local`-scoped via `TMP_DIR="$(mktemp -d)"` — hermetic, function-scoped, mktemp output (not attacker-controlled).
- FIX-Z: both LHS (`keys | sort`) and RHS literal are ASCII-sorted; equality check rejects extra keys too.

---
reviewer_tag: code-simplifier-claude
round: 8
finding_id: R8-F02
severity: low
change_type: clarity
referenced_files: [scripts/run-codex-review.sh]
status: non-blocking-suggestion
---

# F02 — `_lock_age` not declared `local` inside `_append_manifest_entry`

## Location

`scripts/run-codex-review.sh`, line 300 (stale-lock probe inside `_append_manifest_entry`).

## Current pattern

```bash
local _now; _now=$(date +%s)
local _mtime; _mtime=$(stat -f %m "$_lock_dir" 2>/dev/null || stat -c %Y "$_lock_dir" 2>/dev/null || echo "$_now")
_lock_age=$(( _now - _mtime ))     # ← no `local`
if (( _lock_age > 30 )); then
```

`_now` and `_mtime` are correctly declared `local`. `_lock_age` is not — it leaks as an unintended global variable for the duration of the script's execution. While the leaked value is benign (nothing outside this function reads `_lock_age`), the inconsistency is surprising to a reader and violates the principle-of-least-surprise already established by the two adjacent `local` declarations.

## Simpler alternative — add `local`

```bash
local _now; _now=$(date +%s)
local _mtime; _mtime=$(stat -f %m "$_lock_dir" 2>/dev/null || stat -c %Y "$_lock_dir" 2>/dev/null || echo "$_now")
local _lock_age=$(( _now - _mtime ))
if (( _lock_age > 30 )); then
```

This aligns `_lock_age` with its neighbours and eliminates the global side effect. The comment at line 295 already refers to `_lock_age` by name, so keeping the named variable (rather than inlining the expression) preserves the comment-code correspondence.

## Note

Single-character fix; zero behavioral change. The global leak would only matter if some other part of the script happened to read a variable named `_lock_age` — no such reader exists today, but the missing `local` is still a latent maintenance hazard.

Non-blocking suggestion.

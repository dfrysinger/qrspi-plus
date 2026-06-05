---
finding_id: R4-F01
reviewer: sec-codex
severity: high
change_type: correctness
referenced_files:
  - scripts/run-codex-review.sh
---

# F01 — First-party prompt write still has TOCTOU symlink race after R4's `rm -f` fix

**Regression / incomplete fix of R3 sec-codex F01.**

R4 Group B added:
```bash
rm -f "$_fp_prompt_file"
compose_prompt > "$_fp_prompt_file"
```

The `rm -f` + `>` redirect is non-atomic. Race window between rm and the open(2):

1. Attacker observes `$_fp_prompt_file` path (predictable: `$OUTPUT_DIR/.dispatch/$REVIEWER_TAG.prompt`).
2. After our `rm -f` unlinks any existing entry, attacker (with write access to `OUTPUT_DIR/.dispatch/`) symlinks `$_fp_prompt_file → ~/.zshrc` (or `~/.bash_profile`, `~/.ssh/authorized_keys`, or a globally-writable `/var/...`).
3. Our `compose_prompt > "$_fp_prompt_file"` redirect calls open(2) which follows the symlink and writes prompt content to the target.

Prompt content is attacker-influenceable (the task spec + companion artifacts pass through compose_prompt). End-state: arbitrary-file-clobber primitive + potential code execution at next shell startup.

The `rm -f` only closes the trivial "pre-existing symlink" path. A motivated attacker with write access to the dispatch dir wins the race.

**Fix (use O_EXCL via mktemp + atomic rename):**
```bash
_tmp_prompt="$(mktemp "${_fp_prompt_file}.XXXXXX")" || {
  echo "error: mktemp for prompt file failed" >&2
  exit 1
}
if ! compose_prompt > "$_tmp_prompt"; then
  rm -f "$_tmp_prompt"
  echo "error: compose_prompt failed" >&2
  exit 1
fi
# rename(2) replaces destination atomically; if dest is a symlink, dest becomes
# the new regular file (symlink target is NOT followed because we're renaming the
# inode, not opening a path).
if ! mv -f "$_tmp_prompt" "$_fp_prompt_file"; then
  rm -f "$_tmp_prompt"
  echo "error: mv prompt file failed" >&2
  exit 1
}
```

`mktemp` uses O_EXCL|O_CREAT — guaranteed not to follow an existing symlink. `mv` (rename(2)) on the destination path replaces the symlink with the new file inode rather than writing into the symlink target. End-to-end: no window where attacker symlinks redirect our write.

**Severity HIGH because:** arbitrary file write under the running user's privileges, with attacker-influenceable content, gates persistent code execution (rc file modification) on shells of the running user. The OUTPUT_DIR write-access prerequisite is realistic in shared-runner / multi-tenant CI environments.

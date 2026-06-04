---
finding_id: R3-F01
reviewer: sec-codex
severity: high
change_type: correctness
referenced_files:
  - scripts/run-codex-review.sh
---

# F01 — Symlink overwrite on first-party prompt file (arbitrary file clobber)

**File:** scripts/run-codex-review.sh lines 790-794

```bash
_fp_dispatch_dir="$OUTPUT_DIR/.dispatch"
mkdir -p "$_fp_dispatch_dir"
_fp_prompt_file="$_fp_dispatch_dir/$REVIEWER_TAG.prompt"
compose_prompt > "$_fp_prompt_file"
```

The script writes to a predictable filename in a caller-controlled output directory using plain shell redirection, which follows symlinks.

**Attack scenario:** in a shared workspace (CI runner, multi-user host) an attacker pre-creates `$OUTPUT_DIR/.dispatch/spec-codex.prompt` as a symlink to a victim file (`/home/victim/.bashrc`, `~/.ssh/authorized_keys`, etc.). When dispatch runs, `>` redirection truncates and overwrites the symlink target with prompt content. Arbitrary file clobber primitive on every dispatch.

**Impact:** integrity compromise of arbitrary user-writable files; potential RCE via shell-rc overwrite.

**Fix:** use `noclobber` + an explicit unlink before write, or write via `O_NOFOLLOW` semantics. Simplest portable fix:

```sh
rm -f "$_fp_prompt_file"           # unlink any pre-existing entry (incl. symlink) before write
if ! compose_prompt > "$_fp_prompt_file"; then
  # F01 silent-failure fix from sf-codex/cq-codex R3-F01
  exit 1
fi
```

Alternatively use `umask` + `mktemp -p "$_fp_dispatch_dir" --suffix=.prompt` then rename; or `python3 -c 'os.open(..., O_WRONLY|O_CREAT|O_TRUNC|O_NOFOLLOW)'` shell-out for hardened envs.

---
finding_id: R13-F02
severity: low
change_type: clarity
reviewer_tag: code-simplifier-claude
referenced_files: [scripts/dispatch-companion.sh]
---

# `_jobs_dir` assigned twice across the canonicalize step (launch path)

In the `--vendor` launch branch of `scripts/dispatch-companion.sh`,
`_jobs_dir` is computed twice with the post-canonicalization value
silently shadowing the pre-canonicalization value:

```sh
_jobs_dir="$L_ROUND_DIR/.dispatch/.jobs"
mkdir -p "$_jobs_dir" || die "launch: cannot create jobs dir: $_jobs_dir"
assert_path_under_repo_root "launch:--round-dir" "$L_ROUND_DIR"
# ...
_canon_round_dir="$(_qrspi_canonicalize "$L_ROUND_DIR")" \
  || die "launch: cannot canonicalize --round-dir after boundary check: $L_ROUND_DIR"
# ... newline/CR re-check on canonical form ...
_jobs_dir="$_canon_round_dir/.dispatch/.jobs"
```

The first `_jobs_dir` is used only by the `mkdir -p` call (load-bearing —
realpath needs the leaf to exist before canonicalization can succeed),
then it is reassigned to the canonical form for the actual job-record
write. A reader has to track that two adjacent `_jobs_dir=` lines refer
to the same logical directory by different lexical paths.

A behavior-preserving simplification: name the two values to make the
distinction explicit, e.g.:

```sh
_jobs_dir_pre_canon="$L_ROUND_DIR/.dispatch/.jobs"
mkdir -p "$_jobs_dir_pre_canon" || die "launch: cannot create jobs dir: $_jobs_dir_pre_canon"
assert_path_under_repo_root "launch:--round-dir" "$L_ROUND_DIR"
# ... canonicalize ...
_jobs_dir="$_canon_round_dir/.dispatch/.jobs"   # post-canonical, used for record write
```

Or, alternatively, do the `mkdir` against `$L_ROUND_DIR` directly
(no intermediate variable) since the value is single-use:

```sh
mkdir -p "$L_ROUND_DIR/.dispatch/.jobs" \
  || die "launch: cannot create jobs dir: $L_ROUND_DIR/.dispatch/.jobs"
```

Either form removes the silent variable-shadow and clarifies that the
canonicalized path is the single load-bearing reference for the job-record
write.

Behavior-preserving. Non-blocking — purely a clarity simplification.

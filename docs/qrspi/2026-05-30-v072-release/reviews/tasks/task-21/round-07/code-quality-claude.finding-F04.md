---
finding: F04
reviewer: code-quality-claude
round: 7
severity: low
area: naming / semantic clarity
---

## dispatch-companion.sh `await` uses exit code 13 ("upstream hard-error") for a local tag-validation failure

### Location

`scripts/dispatch-companion.sh` lines 551–555

```sh
case "$_job_tag" in
  *[!a-z0-9_-]*|[^a-z]*)
    printf 'dispatch-companion: await: invalid tag in job record %s\n' "$_await_job" >&2
    exit 13 ;;
esac
```

### Problem

The exit-code contract documented in the file header is:

| Code | Meaning |
|------|---------|
| 1    | validation / argument / missing-key failure |
| 13   | **result hard-error from upstream** |

Exit 13 is defined as a transport-level failure (the upstream provider returned
a hard error). An invalid tag in a persisted job record is a **local validation
failure** — the upstream is never contacted. Exit 1 (validation failure) is the
semantically correct code here, consistent with every other validation failure
in the same file (`die()` always exits 1, required-flag checks use `die`).

The `await` block also returns `exit 13` for:
- Missing `tag` or `round_dir` fields in the job record (line 544)
- Inability to create the raw-capture directory (line 564)
- Unknown vendor (line 594)

Some of these are arguably "infrastructure failures" rather than "upstream
hard-errors," but using a single non-zero code for all await-side failures is
an accepted simplification. The inconsistency is most visible on the
tag-validation case because the guard was added alongside the security commentary
(`# Re-validate tag from job record`), where the intent is clearly local
validation.

The test at the call site (`[ "$status" -ne 0 ]`) does not pin the specific exit
code, so the inconsistency is not caught.

### Fix

Either:

1. Change `exit 13` to `exit 1` for the local tag and round-dir validation
   checks (lines 554) to align with the documented validation-failure code.

2. Or, document in the file header that `await` uses exit 13 for all
   await-side failures (both upstream and local), and note that exit 1 is
   reserved for argument-parsing failures before any subcommand dispatch.

Option 2 is lower-risk if callers already treat any non-zero `await` exit as
"this job is unrecoverable."

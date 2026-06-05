---
finding_id: R1-F01
severity: high
change_type: correctness
referenced_files:
  - scripts/dispatch-companion.sh
reviewer: spec-claude
round: 1
---

## `dispatch-companion.sh await <job-id>` is an unimplemented stub — never writes to `.dispatch/<tag>.raw`

**What the spec requires (DoD bullet 3):**
> "dispatch-companion.sh launch writes only `JOB_ID=<id>` to stdout, while `dispatch-companion.sh await <job-id>` writes raw reviewer output to `<round-dir>/.dispatch/<tag>.raw` without echoing payload text to stdout or stderr."

**What is implemented:**

The `await` subcommand (diff lines corresponding to the `if [ "$#" -gt 0 ] && [ "$1" = "await" ]` branch in `scripts/dispatch-companion.sh`) reads the job record from `.dispatch/.jobs/<job-id>`, identifies the vendor, then unconditionally exits 13 with:

```
dispatch-companion: await: vendor <vendor> transport capture for job <job-id> is not wired in this build
```

No `.raw` file is written under any code path. The implementation is explicitly a stub:

```bash
# A found record carries vendor/model/prompt-file/tag/round-dir lines. The
# concrete vendor-transport capture wires through codex-companion-bg.sh for
# the codex vendor; other vendors are not yet wired in this release. Fail
# loudly rather than silently producing an empty raw file.
_job_vendor="$(sed -n 's/^vendor=//p' "$_job_record" | head -1)"
...
printf 'dispatch-companion: await: vendor %s transport capture for job %s is not wired in this build\n' \
  "${_job_vendor:-unknown}" "$_await_job" >&2
exit 13
```

**Impact:**

The `await-round.sh` manifest drain path records `await_cmd: "scripts/dispatch-companion.sh await <job_id>"` for every background dispatch entry (recorded by `emit_dispatch_manifest_entry` in `dispatch-agent.sh`). When a round contains any third-party (background) dispatch, `await-round.sh` calls `dispatch-companion.sh await <job-id>` via Python subprocess, which exits 13. Because no `.dispatch/<tag>.raw` file is created, the subsequent `split_cmd` invocation (`third-party-finding-splitter.sh`) also fails (missing raw input). The entire third-party dispatch chain is non-functional.

**The existing codex transport exists** (`scripts/codex-companion-bg.sh` has a working `await <jobId>` that blocks for Codex results) but is not wired into the new `dispatch-companion.sh await` interface.

**Fix:** For the `codex` vendor, delegate to `scripts/codex-companion-bg.sh await <job-id>` and redirect its stdout to `<round-dir>/.dispatch/<tag>.raw`. For un-wired vendors fail loudly with a clear diagnostic, but still write an empty or error-marker `.raw` file so `await-round.sh` can update the manifest status correctly, OR let `await-round.sh` handle the non-zero exit code by marking the entry `failed` (which is the current behavior in the Python drain loop).

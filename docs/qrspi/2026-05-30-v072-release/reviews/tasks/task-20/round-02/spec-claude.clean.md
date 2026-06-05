# Spec Review — Task 20 Round 2 — CLEAN

Reviewer: spec-claude  
Round: 2  
Verdict: **CLEAN — no findings**

---

## Summary

All round-1 findings (F01, F02) are confirmed closed. The implementation matches
the task spec exactly. No regressions, no out-of-scope additions.

---

## Verification Record

### F01 — Launch/await contract wired in batched mode (CLOSED ✅)

**dispatch-agent.sh batched-mode loop** (diff lines ~420–438):
- Calls `dispatch-companion.sh launch --vendor $v --model $m --prompt-file $f --round-dir $d --tag $t 2>&1`
- Parses `JOB_ID=` line from stdout via `sed -n 's/^JOB_ID=//p'` → `_job_id`
- Calls `emit_dispatch_manifest_entry "$_job_id" "pending"` with the real broker ID

**dispatch-companion.sh `launch` sub-command** (lines ~566–638):
- For `codex` vendor: calls `codex-companion-bg.sh launch <prompt-file` to get broker ID
- Re-validates broker ID against path-traversal grammar (`*/*|*..*|""`)
- Writes job record to `<round-dir>/.dispatch/.jobs/<broker-id>`
- Prints **only** `JOB_ID=<id>` to stdout (no prompt content leakage)

**dispatch-companion.sh `await` sub-command** (lines ~486–559):
- Reads job record at `./.jobs/<job-id>` relative to CWD (matches `await-round.sh`'s `DISPATCH_CWD = <round-dir>/.dispatch/`)
- For `codex` vendor: calls `codex-companion-bg.sh await <codex_job_id> >"$_raw_file"` — writes to `<round-dir>/.dispatch/<tag>.raw`, **no payload on stdout** ✅
- For non-codex vendors: exits 13 with diagnostic — correct per spec Out-scope ("Adding new vendor transports beyond the renamed companion hook")

### F02 — Positive falsifiable fixture tests (CLOSED ✅)

Two positive tests in `test-dispatch-sites.bats` (lines 336–430):

**Launch test** (line 336):
- Stubs `codex-companion-bg.sh` via `CODEX_COMPANION` env var (stub emits `task-stub-<pid>-<ts>`)
- Asserts stdout matches `^JOB_ID=[A-Za-z0-9._-]+$` — **falsifiable**: reverting stub to `exit 13` produces no such line
- Asserts prompt sentinel absent from stdout

**Await test** (line 371):
- Runs with `pushd "$tmp_dir/.dispatch"` — correctly mirrors `await-round.sh` cwd convention
- Pre-seeds `.jobs/<job-id>` record as launch would have written it
- Asserts `<tag>.raw` file exists with expected content
- Asserts stdout does not contain payload — **falsifiable**: removing `>"$_raw_file"` redirect causes both assertions to fail

### All 12 skill docs migrated (✅)

`test-dispatch-sites.bats` lines 172–177 iterate all 12 skill names:
`(goals questions research design structure phasing plan parallelize implement integrate replan test)`,
verifying each skill script references `reviewer-dispatch-prose.md` and sets `REVIEW_OUTPUT_DIR`.

### Rename contract (✅)

- `run-codex-review.sh` → `dispatch-agent.sh`  
- `run-third-party-llm.sh` → `dispatch-companion.sh`  
- `codex-finding-splitter.sh` → `third-party-finding-splitter.sh`

All cross-references updated in skill prose, manifests, and tests.

### Scope / extras (✅)

No out-of-scope files created. No unrequested features or extension points added.
Commit message uses `fix(dispatch): ...` — no task-NN prefix leaked.

### Pre-existing issue (advisory, not a round-2 regression)

The manifest `await_cmd`/`split_cmd` fields carry relative paths
(`scripts/dispatch-companion.sh`, `scripts/third-party-finding-splitter.sh`).
`await-round.sh` resolves these relative to `DISPATCH_CWD=<round-dir>/.dispatch/`,
producing a path not under `<repo-root>/scripts/`; the allowlist check would
reject them in a live run. This format is identical to what existed for the
old `scripts/run-third-party-llm.sh` and `scripts/codex-finding-splitter.sh`
paths before this task, and test-await-round.bats already works around it with
absolute-path stubs and `QRSPI_AWAIT_EXEC_ROOTS`. Round-2 does not introduce
or worsen this issue; it is outside this task's scope.

---

All DoD bullets verified. Implementation is complete and correct.

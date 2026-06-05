---
status: draft
question_ids: [5]
research_type: codebase
---

# Q05: How does `scripts/run-codex-review.sh` wire Codex output to `scripts/codex-finding-splitter.sh`?

## Summary

**TL;DR:** `run-codex-review.sh` does **not** invoke `codex-finding-splitter.sh` internally. It assembles the reviewer prompt and delegates entirely to `scripts/run-third-party-llm.sh`, which itself internally calls `codex-companion-bg.sh launch` + `await` and writes Codex stdout to `--output-file`. The **orchestrator prose** (calling skill) owns the splitter invocation — the skill files show a post-`await` `if [[ $? -eq 0 ]]; then codex-finding-splitter.sh ...` block that the orchestrator executes to produce per-finding files. However, the skill files still reflect the **pre-T04** pattern where the orchestrator called `codex-companion-bg.sh await` directly, not the post-T04 pattern where `run-codex-review.sh --output-file` is the await surface.

**Key findings:**
- `run-codex-review.sh` never calls `codex-finding-splitter.sh` at any point in its execution.
- The `await` call moved **inside** `run-third-party-llm.sh` (`_dispatch_codex_broker()`) as of T04; Codex stdout lands in the `--output-file` argument, not in a temp file the orchestrator creates.
- All orchestrator skill files (design, test, parallelize, goals, integrate) still instruct the main-chat orchestrator to call `codex-companion-bg.sh await <jobId> > /tmp/codex-stdout-<jobId>.txt` directly, then gate the splitter on that `await`'s exit code — the pre-T04 pattern.
- The splitter reads a completed, on-disk Codex stdout file (never stdin); it takes three positional args: `<stdout-path>`, `<round-subdir>`, `<reviewer_tag>`.
- Per-finding files are named `<reviewer_tag>.finding-F<NN>.md`; the clean sentinel is `<reviewer_tag>.clean.md`; both land in the `<round-subdir>` passed by the orchestrator.

**Surprises:** The `reviewer-protocol/SKILL.md` line 13 contains a stale description ("pipes the result to `scripts/codex-companion-bg.sh launch` on stdin"), reflecting the pre-T04 direct-broker pattern rather than the current shim→dispatcher delegation. All skill files' `await`+splitter invocations are also pre-T04 and inconsistent with the current `run-codex-review.sh --output-file` contract.

**Caveats:** This investigation read the full `run-codex-review.sh`, `codex-finding-splitter.sh`, and `run-third-party-llm.sh` scripts, plus the `await`/splitter call sites in `skills/{design,test,parallelize,goals,integrate}/SKILL.md` and `skills/reviewer-protocol/{SKILL.md,codex-emission-override.md}`. No test files were read in detail. The pre-T04 vs. post-T04 discrepancy is characterized as an observation about what the code says; no judgment on correctness or intent is made.

---

## Full findings

### Control-flow trace: `run-codex-review.sh` to per-finding files

#### 1. `run-codex-review.sh`: prompt assembly and dispatcher delegation

`scripts/run-codex-review.sh` (lines 1–648) is described in its own header as a "thin forwarder" (line 2, per T04 of the v0.7 release). The main execution path, after argument parsing and validation, is:

1. **`compose_prompt`** (lines 518–532): concatenates (all frontmatter-stripped):
   - `skills/reviewer-protocol/SKILL.md`
   - Any additional skill bodies declared in the agent's `skills:` frontmatter
   - The named agent body (`--agent-file`)
   - `skills/reviewer-protocol/codex-emission-override.md` (appended AFTER the agent body to override the "Use Write tool" directive)
   - The assembled `## Dispatch parameters` block (subject/artifact bodies, companions, scalars, `round_subdir`, `round`, `reviewer_tag`, optional `diff_file_path`, `scope_hint`)
   - A `<<<AGENT-BODY-END>>>` boundary marker separating the agent body from the dispatch params

2. **Pipe to dispatcher** (lines 640–648):
   ```sh
   ( set -o pipefail; compose_prompt | bash "$DISPATCHER" "${DISPATCHER_ARGS[@]}" )
   exit "$?"
   ```
   `DISPATCHER` = `scripts/run-third-party-llm.sh`. `DISPATCHER_ARGS` = `--provider codex --model "$MODEL" --output-file "$OUTPUT_FILE" --artifact-dir "$ARTIFACT_DIR"` (plus optional `--timeout-seconds`).

   The script exits immediately after with the dispatcher's exit code. **No call to `codex-finding-splitter.sh` occurs anywhere in `run-codex-review.sh`.**

#### 2. `run-third-party-llm.sh`: the `await` lives here

`scripts/run-third-party-llm.sh` handles the codex-broker transport via the internal function `_dispatch_codex_broker()` (lines 385–457):

1. **Launch** (line 401):
   ```sh
   job_id=$(bash "$companion_script" launch < "$STDIN_TEMP") || launch_rc=$?
   ```
   Pipes the prompt (read from stdin and saved to `STDIN_TEMP`) to `codex-companion-bg.sh launch`. Captures the returned job ID.

2. **Await** (lines 422–427):
   ```sh
   bash "$companion_script" await "$job_id" > "$tmp_out" || await_rc=$?
   ```
   Blocks until the job completes. Codex stdout is redirected to a script-managed temp file `$tmp_out`. An optional `QRSPI_CODEX_CEILING_SECONDS` timeout is applied via `TIMEOUT_SECONDS` when set.

3. **On exit 0** (lines 430–435):
   ```sh
   mv "$tmp_out" "$OUTPUT_FILE" || { ... }
   exit 0
   ```
   Atomically moves the temp file to the caller-specified `--output-file` path. The dispatcher exits 0.

   **`codex-finding-splitter.sh` is never called inside `run-third-party-llm.sh`.** A grep for "codex-finding-splitter" in that file returns no matches.

4. **On non-zero `await` exit** (lines 436–456): the temp file is deleted and the dispatcher exits with an error code (10=timeout, 11=job not found, 13=hard-error, 14=malformed, 15=phantom-launch). No splitter invocation occurs on any failure path.

#### 3. Orchestrator prose owns the splitter call

The splitter is invoked by the **calling orchestrator** (the main-chat agent following the skill instructions), not by any script. All skill files include a post-`await` snippet in essentially the same form. From `skills/design/SKILL.md` (lines 236–250):

```sh
# After `await` returns, on exit 0 run the splitter to split Codex output into per-finding files:

scripts/codex-companion-bg.sh await <jobId> > /tmp/codex-stdout-<jobId>.txt
if [[ $? -eq 0 ]]; then
  scripts/codex-finding-splitter.sh /tmp/codex-stdout-<jobId>.txt reviews/design/round-NN/ quality-codex
fi
# On either failure path (await non-zero OR splitter non-zero), the round
# directory has zero output for the tag — step 2's schema guard catches it.

scripts/codex-companion-bg.sh await <scopeJobId> > /tmp/codex-stdout-<scopeJobId>.txt
if [[ $? -eq 0 ]]; then
  scripts/codex-finding-splitter.sh /tmp/codex-stdout-<scopeJobId>.txt reviews/design/round-NN/ scope-codex
fi
```

The same pattern appears in:
- `skills/test/SKILL.md` lines 193–210 (three tags: spec-codex, code-quality-codex, goal-traceability-codex)
- `skills/parallelize/SKILL.md` lines 258–270 (quality-codex, scope-codex)
- `skills/goals/SKILL.md` lines 315–327 (quality-codex, scope-codex)
- `skills/integrate/SKILL.md` lines 158–170 (integration-codex, security-codex)

The gate is explicit: the `if [[ $? -eq 0 ]]` check on the `await` exit code prevents the splitter from running on failed Codex jobs.

#### 4. Pre-T04 vs. post-T04 discrepancy in the orchestrator pattern

The skill files show the **pre-T04** pattern, where the orchestrator issued `codex-companion-bg.sh await <jobId>` directly. In this pattern:
- `run-codex-review.sh` (pre-T04) launched a Codex job and printed job IDs to stdout.
- The orchestrator captured those job IDs and called `await` itself.
- The orchestrator then called the splitter.

Post-T04 (current `run-codex-review.sh`):
- `run-codex-review.sh` is a blocking shim that forwards to `run-third-party-llm.sh`.
- `run-third-party-llm.sh` calls `launch` + `await` internally and writes to `--output-file`.
- `run-codex-review.sh` exits with the dispatcher's exit code after Codex completes; it emits **no job IDs** to stdout.
- The correct post-T04 orchestrator pattern would be: check `run-codex-review.sh`'s exit code (0 = success, Codex stdout in `--output-file`), then call `codex-finding-splitter.sh` with the `--output-file` path.

The skill files have not been updated to reflect this: they still show `codex-companion-bg.sh await <jobId>` as the await surface, which does not match the current script's interface. `reviewer-protocol/SKILL.md` line 13 also contains a stale description: "pipes the result to `scripts/codex-companion-bg.sh launch` on stdin" — this was the pre-T04 direct-broker pattern.

#### 5. `codex-finding-splitter.sh`: per-finding file emission

`scripts/codex-finding-splitter.sh` (lines 1–104) takes 3 positional args:
- `<stdout-path>`: path to the completed Codex stdout file on disk
- `<round-subdir>`: absolute path to the `round-NN/` output directory (must already exist)
- `<reviewer_tag>`: e.g. `quality-codex`, `spec-codex`

**Execution logic:**
1. **NO_FINDINGS sentinel** (lines 40–50): byte-exact match against `NO_FINDINGS` (11 bytes) or `NO_FINDINGS\n` (12 bytes) via `cmp -s`. On match, writes `<reviewer_tag>.clean.md` with YAML frontmatter (`reviewer`, `round`, `findings: 0`) and exits 0.
2. **Empty/malformed guard** (lines 52–62): exits 1 with stderr diagnostic if the input file is empty or contains no `<<<FINDING-BOUNDARY>>>` markers.
3. **Splitting** (lines 66–103): uses awk to split the file on `<<<FINDING-BOUNDARY>>>` lines, writing each segment (zero-padded `seg-NNNN`) to a temp directory. A second pass strips leading blank lines from each segment and writes `<reviewer_tag>.finding-F<NN>.md` to `<round-subdir>`. Zero-byte segments are silently skipped.

**Output filenames** (line 95):
```
<round_subdir>/<reviewer_tag>.finding-F<NN>.md
```
where `<NN>` is a zero-padded two-digit encounter index (01, 02, …).

The splitter never writes outside `<round-subdir>`. It exits 0 on success (findings or clean), 1 on malformed input, 2 on argument/directory errors.

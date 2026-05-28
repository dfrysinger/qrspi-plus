---
task: 33
status: approved
pipeline: full
task_type: code
model: sonnet
phase: 1
goal_ids: [G4]
dependencies: [T03]
loc_estimate: 130
---

# Task 33: G4 Mechanism A cache-probe script and spike report deliverable

- **Phase:** 1
- **Target files:**
  - `scripts/g4-cache-probe.sh` (Create) — shell probe script per the `## Interfaces` `scripts/g4-cache-probe.sh` signature in `structure.md`; takes `--report-out <path>`, dispatches 3 reviewer prompts that share an identical system prefix, captures Anthropic cache-hit usage metadata (`cache_creation_input_tokens` / `cache_read_input_tokens`) from each response, and writes the spike report.
  - `docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md` (Create) — one-page measurement report deliverable that records (a) whether `Agent({})` dispatch responses expose Anthropic cache-hit metadata, (b) the observed `cache_read_input_tokens` value on second-and-later dispatches with an identical prefix, and (c) the Path A vs Path B decision the spike resolves.
- **Dependencies:** T03
- **LOC estimate:** ~130
- **Description:** Implements the G4 Mechanism A spike — the Plan-time measurement that resolves the Mechanism-A-only Path A vs Path B sub-decision. Mechanism A (Anthropic prompt caching) ships unconditionally; the spike only determines, within Mechanism A, whether the Claude Code `Agent({})` dispatch path already caches stable prefixes automatically (Path A: instrument + measure only) or whether `cache_control` markers must be added at the Anthropic SDK boundary before measurement (Path B: Mechanism A scope expands to include marker insertion). Mechanism B (the section-anchor index landed by T34 and T35) ships independent of this spike outcome and is not gated by the result. The `scripts/g4-cache-probe.sh` script dispatches three reviewer prompts via the universal dispatcher from T03 with an identical system-prompt prefix and a varying per-dispatch tail, captures each response's usage metadata, and writes a one-page report at `docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md`. The report records the cache-metadata exposure question (does `Agent({})` surface the Anthropic cache-hit fields at all), the observed `cache_read_input_tokens` value on the second and third dispatches, and the resulting Path A or Path B decision per the spike contract in `design.md`. The decision the spike records is consumed by T36's `test-cache-hit-rate.bats` pin (Path-conditional fixture set) and gates any follow-up `cache_control` marker-insertion task. Exit codes follow the dispatcher convention (`0` report written + decision recorded, `1` dispatch failure or report-write failure).
- **Test expectations:**
  - Invoking `scripts/g4-cache-probe.sh` without `--report-out` exits non-zero with a validation diagnostic on stderr.
  - Invoking `scripts/g4-cache-probe.sh --report-out <path>` dispatches exactly three reviewer prompts whose system-prompt prefix is byte-identical across the three calls. The "system-prompt prefix" is concretely defined as the bytes from the start of the assembled system-message body through the end of the verbatim `skills/reviewer-protocol/SKILL.md` content the probe embeds (the load-bearing stable content for the cache-hit measurement); the per-dispatch varying tail begins at the per-call reviewer-task-body section the probe appends after the stable prefix. The byte-identity assertion compares the two prefix slices using their defined byte ranges.
  - On success the script writes the report file at the `--report-out` path and exits `0`; the report body contains the three captured `cache_read_input_tokens` values and the three captured `cache_creation_input_tokens` values from the dispatched responses.
  - The report body contains an explicit Path A or Path B decision line, derived from whether the second-and-later dispatches observed `cache_read_input_tokens > 0`.
  - The report distinguishes the "no cache metadata exposed at all" outcome from the "metadata exposed but zero hits" outcome and records each as a distinct decision branch.
  - A dispatcher failure during any of the three dispatches causes the script to exit `1` with a loud diagnostic naming the failed dispatch and to NOT write a partial report.
  - The report file lives at `docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md` (the spike-deliverable location declared in `structure.md` Slice 7 file map).
  - Before applying the path-validation check, the script resolves the `--report-out` value to its canonical absolute path via `realpath` (or `cd "$(dirname "$path")" && pwd` for parent-resolution when the file does not yet exist) and applies the `docs/qrspi/` prefix check against the resolved path, not the raw argument string. A path that cannot be resolved (e.g., the parent directory does not exist) exits 1 with a named path-validation diagnostic. When the resolved `--report-out` path lies outside the declared spike-deliverable location under `docs/qrspi/`, the script exits 1 with a named path-validation diagnostic before attempting any dispatch or report write. A fixture invocation with `--report-out docs/qrspi/../../../etc/shadow` (raw argument is string-prefix `docs/qrspi/` but resolves to `/etc/shadow`) exits 1 with the path-validation diagnostic — the realpath normalization is what catches the traversal attempt that a naive string-prefix bash implementation would miss.
  - When the report file cannot be written to the `--report-out` path (parent missing, read-only filesystem, permission denied), the script exits 1 with a loud diagnostic naming the write-failure reason and does NOT exit 0 with a missing report.
  - The report header contains an explicit `run_id:` (or `invocation_timestamp:`) field that uniquely identifies the invocation that produced the report. At script start, the script removes any prior sentinel/lock file at `<report-out-dir>/g4-cache-probe.lock`; on a complete successful run, after the report is written, the script atomically creates a `g4-cache-probe.lock` file containing the same `run_id:` as the report. A mid-run failure leaves no lock file, so downstream consumers (T36) can detect a stale report by the absence of a fresh lock or a `run_id:` mismatch between report and lock, preventing T36 from silently consuming a prior-run report when the current run failed.

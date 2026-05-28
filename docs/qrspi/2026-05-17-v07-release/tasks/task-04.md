---
task: 4
status: approved
pipeline: full
task_type: code
model: sonnet
phase: 1
goal_ids: [G2]
dependencies: [T03]
loc_estimate: 90
---

# Task 04: Retire codex-shim entry behavior to a thin forwarder

- **Phase:** 1
- **Target files:**
  - `scripts/run-codex-review.sh` (Modify) — replace the inline user-facing entry behavior with a thin forwarder that delegates to `scripts/run-third-party-llm.sh` while preserving the existing caller CLI surface.
  - `scripts/codex-companion-bg.sh` (Modify) — update helper-script reference comments only; no behavior change to launch/await/JSONL lifecycle.
- **Dependencies:** T03
- **LOC estimate:** ~90
- **Description:** Rewrites `scripts/run-codex-review.sh` as a thin compatibility forwarder that preserves its existing caller-facing flag surface, then re-invokes `scripts/run-third-party-llm.sh --provider codex --model <id> --output-file <path>` (along with `--artifact-dir`) so every existing call site continues to work during the migration window per Decision 10's safe-default principle. Transport selection is config-driven through the `codex` entry in `config.md`'s `providers:` block (which carries `transport_type: codex-broker`); the shim does NOT pass a transport flag. Stdin is forwarded unmodified to the dispatcher's stdin so the prompt-source contract is preserved. The shim exits with the dispatcher's exit code unchanged so existing callers observe the same exit-code matrix. `scripts/codex-companion-bg.sh` is touched only to update header/inline comments that point at the new helper-script reference layout — no behavior change to its launch, await, or JSONL lifecycle.
- **Test expectations:**
  - Calling `scripts/run-codex-review.sh` with its existing flag set forwards stdin to `scripts/run-third-party-llm.sh` and exits with the dispatcher's exit code unchanged.
  - The forwarded invocation includes `--provider codex` and the model identifier originally passed to the shim, with no transport flag.
  - The forwarded invocation includes `--artifact-dir` with the artifact directory value resolved by the shim from its own caller context (so the dispatcher can read `config.md` from the correct artifact directory; without this flag the dispatcher would exit 1 per T03's required-flag contract).
  - The shim does not source or invoke `scripts/codex-companion-bg.sh` directly; the broker chaining happens inside the dispatcher.
  - Existing callers that pipe a prompt into `run-codex-review.sh` observe identical success-path behavior and explicit per-code exit-code pass-through: a timeout condition forwarded through the shim produces exit 10; a job-not-found condition produces exit 11; an upstream hard-error produces exit 13; a malformed result body produces exit 14; a phantom-launch produces exit 15 (each numeric code enumerated directly rather than cross-referenced by description).
  - `scripts/codex-companion-bg.sh`'s launch, await, and JSONL lifecycle behavior is unchanged (comment-only edits).

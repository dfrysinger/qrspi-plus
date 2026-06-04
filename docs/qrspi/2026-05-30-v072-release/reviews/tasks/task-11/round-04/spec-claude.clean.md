---
reviewer: spec-claude
task: 11
round: 4
status: clean
---

# T11 Spec Review — Round 4: CLEAN

All T11 spec requirements are satisfied. No defects found.

## Verification summary

### Completeness

**Requirement 1 — First-party `dispatch_spec` fields (`subagent_type/host/vendor/model/prompt_file`)**
Implemented in `emit_first_party_manifest_entry` (`scripts/run-codex-review.sh` lines 384–407).
The `jq -nc` call constructs `dispatch_spec: {subagent_type: $subtype, host: $host, vendor: $vendor, model: $model, prompt_file: $pf}` exactly as required.

**Requirement 2 — Third-party `dispatch_spec` provenance + await-and-split job metadata**
Implemented in `emit_dispatch_manifest_entry` (lines 351–376).
Top-level: `tag/agent/mode/status/job_id/await_cmd/split_cmd`.
Nested `dispatch_spec`: `{subagent_type, host, vendor, model}` — all four fields present.

**Requirement 3 — Atomic and append-safe**
`_append_manifest_entry` (lines 252–339) uses mkdir-as-mutex (POSIX-atomic), jq for read-modify-write, atomic `mv` for clobber-free write, stale-lock recovery at 30 s, and 100-attempt spin cap. Tested concurrently in AC4.

**Requirement 4 — Orchestrator-facing dispatch stays a prompt-file reference**
The copilot-cli branch (lines 895–914) writes the assembled prompt to `.dispatch/<tag>.prompt` and emits only `DISPATCH_FILE=<path>` on stdout. The prompt body never enters stdout/tool-call arguments; manifest provenance is recorded via `emit_first_party_manifest_entry`.

**Requirement 5 — `SKILL.md` documents the new entry shapes**
`skills/using-qrspi/SKILL.md` updated (diff lines 425–426): the reviewer-model-audit-field paragraph now documents both the third-party (`mode:"background"`) and first-party (`mode:"first_party"`) entry shapes with their full `dispatch_spec` keys.

### Test expectations (all four covered)

| Spec expectation | Test |
|---|---|
| First-party `dispatch_spec` with `prompt_file` | `[dispatch-manifest AC2]` (source-only helper) + `[dispatch-manifest AC5]` (full copilot-cli dispatch path) |
| Third-party `host/vendor/model` + job metadata | `[dispatch-manifest AC1]` |
| Repeated invocations / multiple reviewer tags → well-formed manifest | `[dispatch-manifest AC3]` |
| Orchestrator payload stays prompt-file reference, manifest records provenance | `[dispatch-manifest AC5]` (asserts `^DISPATCH_FILE=` on stdout, verifies `dispatch_spec.prompt_file` matches) |

Additional regression guards shipped: AC4 (concurrency, N=5 barrier), AC6 (trailing-newline robustness).

### Scope

Implementation confined to the three target files listed in the task spec:
- `scripts/run-codex-review.sh` — manifest schema, atomic append, first-/third-party emit functions, copilot-cli dispatch rewrite.
- `skills/using-qrspi/SKILL.md` — single paragraph update documenting entry shapes.
- `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` — new T11 AC1–AC6 tests; existing T7/T9 tests updated for the new third-party path that requires a JOB_ID line from the mock dispatcher.

No out-of-scope files modified. The `_validate_output_dir` and `_validate_job_id` helpers are directly load-bearing for the manifest-write security surface (OUTPUT_DIR and JOB_ID are interpolated into stored `split_cmd`/`await_cmd` strings) and are correctly scoped to this task.

---
reviewer_tag: test-coverage-claude
round: 11
status: clean
---

# Test Coverage Review — Round 11 — CLEAN

## Verdict

**CLEAN.** The R11 hoist is a pure mechanical refactor with no semantic change to any execution path. All four T11 test expectations are covered by the existing AC1–AC5 suite with meaningful, value-asserting tests. The hoist does not introduce any new code paths, remove any tests, or break any test scaffolding. The 91/91 pass count is consistent with this analysis.

## Behavioral Coverage

| Expectation | Covering test | Assessment |
|---|---|---|
| First-party dispatch → `dispatch_spec` with subagent_type/host/vendor/model/prompt_file | AC2 (source-only) + AC5 (end-to-end) | ✅ Covered |
| Third-party/background dispatch → dispatch_spec + job_id/await_cmd/split_cmd | AC1 | ✅ Covered |
| Repeated invocations → well-formed manifest with all entries | AC3 | ✅ Covered |
| Orchestrator-facing payload stays prompt-file reference | AC5 (asserts `DISPATCH_FILE=` on stdout) | ✅ Covered |

## Edge Cases
- Concurrent appends: AC4 spins N=5 subshells with barrier; no lost-update race
- Trailing-newline manifest: AC6 covers pathological `]\n` shape
- `_validate_job_id`/`_validate_output_dir` allowlists: pre-existing tests intact

## Error Conditions
Hoist does not touch error paths. Both helpers still only called from within copilot-cli branch (lines 930/932/937/942/948); mktemp-fail and compose_prompt-fail paths unchanged.

## Test Quality
- AC1–AC5 use `jq -e` with explicit failure diagnostics
- AC2/AC5 pin exact key sets via `(keys | sort) ==` — strict schema pinning
- AC5 uses `--arg` for injection-safe assertions
- Tests cleanly isolated via `mktemp -d` + `rm -rf` cleanup

## Hoist-Specific Note
After hoist, helpers accessible in `QRSPI_SOURCE_ONLY=1` mode. No isolated source-only test exists for them — **not a gap**: task spec doesn't require it, and helpers have no independent behavior worth unit-testing beyond AC5's end-to-end coverage.

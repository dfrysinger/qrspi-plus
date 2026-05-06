Note: `gh -R dfrysinger/qrspi-plus issue view ...` was attempted for the mapped issues, but this environment cannot reach `api.github.com`. The issue-fidelity findings below rely on repo-local evidence: the artifact itself, prior local review notes, local research artifacts, and live branch state.

## Issue Fidelity

1. `finding_id`: `R1-F01`
   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `G4's Problem/What-we-know-so-far reads like the Codex wrapper still uses the invented JSON contract (`.status`, top-level `.markdown`) and still carries the masked-exit/stub-shape defects, but the live branch state already reflects the corrected contract: the wrapper parses `.job.status`, reads `storedJob.result.rawOutput`, documents the real fallback chain, preserves the real launch exit code, and the stub/test suite explicitly asserts those shapes. As written, G4 now describes a defect that is no longer present in the repo, which misstates the problem to downstream Design/Plan. Rewrite G4 to match the remaining unresolved work, or drop it if #54 is already closed by the current branch state.`
   `referenced_files`: `["docs/qrspi/2026-04-29-v0.4-bundle/goals.md","docs/qrspi/2026-04-29-v0.4-bundle/research/q05-q06-codebase.md","scripts/codex-companion-bg.sh","tests/fixtures/stub-codex-companion.mjs","tests/unit/test-codex-companion-bg.bats"]`

2. `finding_id`: `R1-F02`
   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `G5's Problem says the wrapper hardcodes `/Users/dfrysinger/.../codex-companion.mjs` as the default `CODEX_COMPANION`, but the current wrapper does not do that: it resolves an explicit env var first, otherwise globs `${HOME}/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs` and picks the newest version. The local research artifact calls this discrepancy out explicitly. Leaving G5 as-is creates issue-fidelity drift and directs downstream work at a portability bug that the current source already appears to have fixed.`
   `referenced_files`: `["docs/qrspi/2026-04-29-v0.4-bundle/goals.md","docs/qrspi/2026-04-29-v0.4-bundle/research/q05-q06-codebase.md","scripts/codex-companion-bg.sh"]`

## Goals Iron Rules

no findings

## F-5 Fix-Altitude

no findings

## Goal Independence

no findings

## Cross-Cutting Notes Accuracy

1. `finding_id`: `R1-F03`
   `severity`: `medium`
   `change_type`: `correctness`
   `message`: `The `G6 ↔ G7` cross-cutting note overstates the coupling by claiming that landing one max-case without the other "leaves the remaining piece without its dependency." Repo-local research shows `state.sh` is not just a Bash-containment helper dependency; it is called from pipeline/artifact state-management paths and underpins `.qrspi/state.json` lifecycle independently of `bash-detect.sh`. The goals can still note that G6 and G7 interact, but the current wording implies a dependency relationship the codebase evidence does not support.`
   `referenced_files`: `["docs/qrspi/2026-04-29-v0.4-bundle/goals.md","docs/qrspi/2026-04-29-v0.4-bundle/research/q09-q10-q23-q28-codebase.md","hooks/lib/state.sh"]`

## Constraint Concreteness

no findings

## Additional Findings

no findings

Overall verdict: ship-with-followups
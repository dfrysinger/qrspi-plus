# Spec Review: Clean

**Task:** T21 — G16 path-filter exfil hardening in `dispatch-agent.sh`
**Reviewer:** spec-claude
**Round:** 1
**Result:** CLEAN — no findings

## Summary

The implementation exactly matches the task spec. Every requirement, definition-of-done criterion, and test expectation was verified against the actual code:

1. **Shared guard library** (`scripts/lib/path-guard.sh`): `assert_path_under_repo_root <label> <path>` canonicalizes via `realpath` / `readlink -f` fallback with trailing-slash-anchored prefix match. All three failure modes emit the contract diagnostic substrings (`resolves outside repository`, `cannot canonicalize`).

2. **Guard applied in `dispatch-agent.sh`** after `assert_file_exists` and before `compose_prompt`/`cat` for every required path family: `agent-file` (line 894), `subject_code`/`artifact_body` (line 943), `task-def` (line 951, defense-in-depth), `companion` (line 960), `diff-file` (line 970).

3. **`dispatch-companion.sh` audit**: stdin-only legacy form documented as no-raw-path surface; `launch` subcommand `--prompt-file` path guarded at line 613 after file-existence check and before transport pipe. Shared lib sourced unconditionally.

4. **`agents/qrspi-implementer.md`**: `## Orchestrator-Only Scripts (Bash Allowlist)` section inserted at top of body (lines 9–44), naming both post-rename scripts, covering all four required invocation shapes (relative, absolute, alias, shell-expansion).

5. **Test coverage** in `tests/unit/test-dispatch-agent.bats` G16 section (lines 1412–1618): all ten required test expectations implemented and asserting the correct observable behaviors (non-zero exit + `resolves outside repository` diagnostic; symlink regression; readable-out-of-repo companion boundary-not-missing-file; four path-family table coverage; valid pass cases; canonicalization-failure fail-closed; structural grep assertions for implementer.md and dispatch-companion.sh).

6. **Existing dry-run behavior preserved**: `setup()` relocated `TMP_DIR` under `$REPO_ROOT` so all prior fixture paths pass the new guard; no existing test semantics changed.

7. **Target files**: all five listed target files modified; `scripts/lib/path-guard.sh` is a necessary auxiliary file for the shared-guard requirement. No out-of-scope files touched.

# Spec Review — Task 21 Round 03 — CLEAN

**Reviewer:** spec-claude  
**Round:** 3  
**Verdict:** No findings — implementation fully compliant with task spec.

## Summary

All task-21 spec requirements are implemented and tested. Post-fix-cycle-2 state
closes spec-codex R2-F01 (batch-mode `--artifact` + `--agents` path guarding).
Spec line 19 ("every prompt-ingested file path") is fully covered across both
single-mode and batch-mode surfaces.

## Verification Matrix

| Requirement | Location | Status |
|---|---|---|
| `assert_path_under_repo_root` guard implemented fail-closed | `scripts/lib/path-guard.sh` | ✅ |
| Guard sourced in `dispatch-agent.sh` | `dispatch-agent.sh` line 78 | ✅ |
| `--agent-file` guarded (single-mode) | `dispatch-agent.sh` line 902 | ✅ |
| `--subject-code` / `--artifact-body` guarded | `dispatch-agent.sh` lines 948–953 | ✅ |
| `--task-def` guarded | `dispatch-agent.sh` lines 956–960 | ✅ |
| `--companion` guarded | `dispatch-agent.sh` lines 963–969 | ✅ |
| `--diff-file` guarded | `dispatch-agent.sh` lines 972–978 | ✅ |
| Batch `--artifact` guarded (R2-F01 fix) | `dispatch-agent.sh` lines 575–579 | ✅ |
| Batch `--agents` guarded (R2-F01 fix) | `dispatch-agent.sh` lines 631–633 | ✅ |
| Guard applied after existence check, before any `cat` | All sites above | ✅ |
| Diagnostic substring `resolves outside repository` | `path-guard.sh` line 93 | ✅ |
| Canonicalization failures fail-closed | `path-guard.sh` lines 70–86 | ✅ |
| Symlink resolution via `realpath` / `readlink -f` | `path-guard.sh` lines 44–57 | ✅ |
| `agents/qrspi-implementer.md` allowlist section | `qrspi-implementer.md` line 9 | ✅ |
| Both post-rename script names listed | `qrspi-implementer.md` lines 14–15 | ✅ |
| All four invocation shapes covered | `qrspi-implementer.md` lines 19–32 | ✅ |
| `dispatch-companion.sh` audited — stdin-only form documented | `dispatch-companion.sh` lines 45–65 | ✅ |
| `dispatch-companion.sh` launch `--prompt-file` guarded | `dispatch-companion.sh` line 613 | ✅ |

## Test Coverage Matrix

| Test Expectation | Test Location | Status |
|---|---|---|
| `--subject-code /etc/hosts` exits non-zero, `resolves outside repository` | line 1466 | ✅ |
| `--artifact-body` out-of-repo rejected | line 1477 | ✅ |
| `--companion` out-of-repo rejected (boundary not missing-file) | line 1490 | ✅ |
| `--diff-file` out-of-repo rejected | line 1507 | ✅ |
| Symlink under repo whose canonical target is outside repo rejected | line 1523 | ✅ |
| Symlink rejection happens before prompt emission | line 1541 | ✅ |
| Canonicalization failure fails closed, no sentinel bytes in output | line 1547 | ✅ |
| Valid repo-local `--subject-code` + `--task-def` dry-run passes | line 1573 | ✅ |
| Valid repo-local `--artifact-body` / `--companion` / `--diff-file` passes | line 1587 | ✅ |
| Structural assertion: `assert_path_under_repo_root` in script body | line 1605 | ✅ |
| `qrspi-implementer.md` allowlist section present with all shapes | line 1609 | ✅ |
| `dispatch-companion.sh` audit: guard or no-raw-path comment | line 1622 | ✅ |
| Batch `--artifact /etc/hosts` rejected | line 1644 | ✅ |
| Batch `--artifact` symlink-to-outside rejected | line 1660 | ✅ |
| Batch `--agents /etc/hosts` rejected | line 1679 | ✅ |
| Batch `--agents` symlink-to-outside rejected | line 1693 | ✅ |

## Target Files Check

All changes are in spec-listed target files plus `scripts/lib/path-guard.sh`, a
small shared-library auxiliary explicitly described in the G16 comment at
`dispatch-agent.sh` lines 74–78. The helper is an appropriate auxiliary, not a
scope violation.

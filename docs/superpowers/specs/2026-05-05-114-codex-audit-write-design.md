# #114: Delete the Codex Companion Audit-Write Surface

**Status:** Design
**Issue:** [#114](https://github.com/dfrysinger/qrspi-plus/issues/114)
**Milestone:** v0.5
**Date:** 2026-05-05

## 1. Triage: the original symptom is already fixed

Issue #114's reproduction string —

```
audit-write fail (exit 12): artifact_dir from state.json is not a directory: .../prompt-improvements
```

— came from the **prior** `state.json`-based audit-dir resolver inside `scripts/codex-companion-bg.sh`. That resolver was replaced during the #108/#110 hooks-removal sequence. The current resolver (`resolve_audit_dir`, lines 113–155) accepts a trusted-caller `--artifact-dir` CLI flag and never reads `state.json`. Verified by grep: zero `state\.json` references remain on the audit path. Part 1 of the issue ("fix the immediate exit 12") is already resolved.

Spec E executes Part 2 — the audit-surface inventory and prune.

## 2. Audit surface — what it currently does

Per-`await` invocation, `emit_audit_row` appends one JSONL line to `<artifact_dir>/.qrspi/audit-codex-review.jsonl`:

```json
{"job_id":"...","elapsed_seconds":47,"completion_status":"completed","timestamp":"2026-05-06T..."}
```

That is the entirety of what the audit log captures: **operational telemetry only** — which dispatch ran, how long, did it complete or hit ceiling/error, when. Zero finding content. The actual review artifacts (`reviews/{step}/round-NN/<reviewer_tag>.finding-F<NN>.md`) are written by the reviewer agents directly to disk, not by codex-companion. Removing the audit log doesn't lose any review content.

**Consumer inventory** (`grep -rln "audit-codex-review\.jsonl"` for *readers*):

- No automated check reads the file.
- No skill or agent body parses it.
- No bats test asserts on its content beyond write-side unit tests.
- Doc references (`launch-await-pattern.md`, `README.md`) describe *where* it's written, not how it's consumed.

The log is forensic-only with **no current consumer** and is duplicative metadata: review presence is already trackable via the per-finding files committed each round.

## 3. Fix shape: delete entirely

Three options were considered:

| Option | Action | Verdict |
|---|---|---|
| A | Keep as-is | ❌ Over-engineered for forensic-only log |
| B | Best-effort warn-and-continue | ❌ Half-removal — leaves `--artifact-dir` mystery + dead JSONL on disk |
| **C** | **Delete entirely + strip `--artifact-dir`** | ✅ **Selected** |

Option C wins because the audit log has no consumer, no programmatic dependency, no security role under the post-hooks-removal threat model. Keeping it (Option A) or half-keeping it (Option B) means future readers still wonder why `audit-codex-review.jsonl` is on disk and why `await` requires `--artifact-dir`. Deleting both removes the question. If timing forensics ever become valuable again, re-introduction is cheaper than maintenance.

### 3.1 What gets deleted

**`scripts/codex-companion-bg.sh`:**
- `resolve_audit_dir` function (lines 113–155, ~45 LOC)
- `emit_audit_row` function (lines 158–end of definition, ~80 LOC)
- `QRSPI_AUDIT_FILENAME`, `QRSPI_AUDIT_LOCK_NAME` constants (lines 50–51)
- Audit-path-lockdown header comment (lines 42–49)
- File-header exit-code 12 row (lines 24–26)
- `file_mtime_epoch` helper (lines 86–93) — currently used only by the mkdir-lock stale-reap; dead after audit removal. (Keep if it has another caller; verify by grep.)
- `--artifact-dir` flag handling in the `await` subcommand argument parser
- All `emit_audit_row` callsites in `await_subcommand`

**`skills/_shared/codex/launch-await-pattern.md`:**
- Drop the `--artifact-dir` parameter from every documented invocation
- Drop "**12** = audit-write fail …" from the exit-code list (exit codes go from 6 to 5: `0`, `10`, `11`, `13`, `14`)
- Drop the explanatory prose about audit row writes

**`skills/{research,design,using-qrspi,parallelize,test,goals,integrate,phasing,implement,replan,structure,questions}/SKILL.md`** (12 files):
- Strip `--artifact-dir <ABS_ARTIFACT_DIR>` from every documented `codex-companion-bg.sh await` invocation. Confirmed sites: 22 occurrences across these 12 files plus the canonical template in `_shared/codex/launch-await-pattern.md`.

**Tests:**
- Delete `tests/unit/test-codex-companion-bg.bats` audit-related tests (~80 lines covering `emit_audit_row` write-success / failure / lock-contention / perm-enforcement / jq-escape / etc.)
- Delete audit-related assertions in `tests/unit/test-using-qrspi.bats` (17 lines)

**Docs:**
- `README.md`: drop the audit-log path reference
- `tests/unit/test-no-legacy-disk-write-references.bats:12` comment (already touched by Spec D §2.3 for the dispositions rename — this spec adds removal of `audit-codex-review.jsonl` from the comment's list of legitimate non-reviewer artifacts)

### 3.2 What gets added

**One regression-guard test** — `tests/unit/test-no-codex-audit-references.bats` (new):

```bash
#!/usr/bin/env bats
# Guards #114: the codex-companion audit-write surface was removed in v0.5.
# Reappearance of audit symbols in the script or dispatch sites would be a
# regression — re-introduce only via an explicit issue.

@test "codex-companion-bg.sh has no audit symbols" {
  local offenders
  offenders=$(grep -nE 'emit_audit_row|resolve_audit_dir|QRSPI_AUDIT_|audit-codex-review' \
    scripts/codex-companion-bg.sh 2>/dev/null || true)
  if [ -n "$offenders" ]; then
    echo "audit symbols remain in codex-companion-bg.sh:"
    echo "$offenders"
    return 1
  fi
}

@test "no skill or agent file passes --artifact-dir to codex-companion-bg.sh" {
  local offenders
  offenders=$(grep -rnE 'codex-companion-bg\.sh +await +.*--artifact-dir' \
    skills/ agents/ 2>/dev/null || true)
  if [ -n "$offenders" ]; then
    echo "dispatch sites still pass --artifact-dir:"
    echo "$offenders"
    return 1
  fi
}

@test "regression #114: no state.json read in codex-companion-bg.sh" {
  local non_comment
  non_comment=$(grep -nE '^[^#]*state\.json' scripts/codex-companion-bg.sh 2>/dev/null || true)
  [ -z "$non_comment" ]
}
```

Three assertions: audit-symbols-gone, dispatch-flag-gone, original-state.json-symptom-gone. ~25 lines bats.

### 3.3 Trust-model implication

The current header comment (lines 42–49) describes the audit-path lockdown as the trust boundary. With the audit gone, that boundary doesn't exist and the comment goes with it. The codex-companion's runtime no longer requires any caller-supplied path. `await` becomes argument-shape-simpler: `await <jobId>` instead of `await --artifact-dir <abs> <jobId>`.

## 4. Sequence

Single PR, **three commits**:

1. **`refactor(scripts): #114 delete codex-companion audit-write code path`** — strip `resolve_audit_dir`, `emit_audit_row`, the audit constants, the audit-path-lockdown header comment, and the exit-code 12 row from the file-header table. Also drops `--artifact-dir` parsing from `await_subcommand`. The script's exit codes shrink from 6 to 5.
2. **`docs(skills): #114 strip --artifact-dir from codex dispatch sites`** — sweep `_shared/codex/launch-await-pattern.md` plus the 12 SKILLs that follow it. Mechanical find-and-replace (same shape as the Spec D vocabulary sweep). Updates exit-code prose to reflect the 5-code list.
3. **`test(unit): #114 delete audit tests + add regression guards`** — delete audit-related bats in `test-codex-companion-bg.bats` and `test-using-qrspi.bats`; add `test-no-codex-audit-references.bats`; update `test-no-legacy-disk-write-references.bats:12` comment.

Test plan:
- `bats tests/unit/test-codex-companion-bg.bats` — passes (audit tests deleted; remaining job-tracking tests still green).
- `bats tests/unit/test-using-qrspi.bats` — passes (audit assertions deleted).
- `bats tests/unit/test-no-codex-audit-references.bats` — passes (3/3 guard assertions).
- `bats tests/unit/` full suite — same baseline failures as parent (`a1db28d`); no regressions.
- Manual: dispatch a real codex review against any artifact_dir, confirm the JSONL file is not created and the dispatch result still arrives on stdout.

## 5. Reviewer Suite

This is runtime-touching code (`scripts/codex-companion-bg.sh`). The qrspi-plus prose-handling preference does **not** apply. Full reviewer suite required: spec-review, code-quality, security, silent-failure, goal-traceability, test-coverage. Implement-stage gate enabled.

## 6. Backwards Compatibility

- **Pre-existing `audit-codex-review.jsonl` files on disk** stay untouched (gitignored; not consumed by anything).
- **Callers passing `--artifact-dir` after deletion** see "unknown option" from `await`'s arg parser. This is intentional — the dispatch sites are swept in commit 2 of the same PR; any out-of-tree caller still passing the flag is signaling stale code that needs updating.
- **No data migration.** Forensic-only log with no consumer; deletion is forward-only.

## 7. Out of scope

- **Deleting the legacy hook-layer audit code** (`hooks/lib/audit.sh`, `hooks/pre-tool-use` audit references, `tests/unit/test-audit.bats`, `tests/unit/test-state.bats`). Tracked separately by the dead-hooks cleanup memory; that work is broader than #114's scope and includes the entire `hooks/` tree.
- **Re-introducing structured telemetry** (e.g., OpenTelemetry traces for codex jobs). YAGNI; re-introduce only when a consumer exists.
- **Regression test running an actual codex job end-to-end.** Out of scope for unit-test CI; integration smoke is a manual post-merge step.

## 8. Closes

- Closes #114

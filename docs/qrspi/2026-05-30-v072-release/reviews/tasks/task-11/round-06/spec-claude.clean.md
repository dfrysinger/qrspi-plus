---
reviewer: spec-claude
task: 11
round: 6
verdict: clean
---

# Spec Review — Task 11 Round 6 — CLEAN

Verified all task-11.md requirements against the R6 implementation (commit 749f693, three regression fixes from the R5 8-reviewer fan-out).

## Checklist

### 1. Completeness

**First-party `dispatch_spec`** (DoD item 1): `emit_first_party_manifest_entry` (script lines 408–431) emits `dispatch_spec.subagent_type`, `dispatch_spec.host`, `dispatch_spec.vendor`, `dispatch_spec.model`, and `dispatch_spec.prompt_file`. All five spec-required fields present. ✓

**Third-party `dispatch_spec` + job metadata** (DoD item 2): `emit_dispatch_manifest_entry` (script lines 375–400) emits `dispatch_spec.subagent_type/host/vendor/model` plus top-level `job_id`, `await_cmd`, `split_cmd`. ✓

**Atomic and append-safe** (DoD item 3): `_append_manifest_entry` uses mkdir-as-mutex with 50 ms back-off spin; AC3 tests sequential repeated-invocation / multiple-tag safety; AC4 tests concurrent-write safety (5-way start-barrier). ✓

**Orchestrator-facing payload stays prompt-file reference** (DoD item 4): first-party path (script lines 901–932) emits `DISPATCH_FILE=<path>` to stdout; prompt body never reaches orchestrator tool-call args. AC5 asserts `DISPATCH_FILE=` on stdout and `mode=first_party`/`status=dispatched` in the manifest. ✓

**Acceptance coverage end-to-end** (DoD item 5): AC1 (third-party schema), AC2 (first-party schema via `QRSPI_SOURCE_ONLY=1`), AC3 (repeated invocations multiple tags), AC4 (concurrent writes), AC5 (full first-party dispatch through to `DISPATCH_FILE=`). ✓

**`skills/using-qrspi/SKILL.md`** (target file): dispatch-manifest entry shapes documented at SKILL.md line 1117. Present from prior rounds. R6 is a cap-bend fix cycle only — no new scope changes to SKILL.md are needed or introduced. ✓

### 2. R6 Fix Items

**FIX-G** (`return 1` → `exit 1` in mktemp failure path): script line 316 uses `exit 1`; no `return 1` in the mktemp failure block. Test "mktemp failure path in manifest append uses exit 1 not return 1" (bats line 2786) asserts this with `grep -A5 'mktemp failed for manifest tmp' | grep -qE '\breturn [0-9]'`. ✓

**FIX-H** (`_manifest_tmp` relay var + trap cleanup): relay declared at script line 238 (`_manifest_tmp=""`); traps at lines 279–281 include `rm -f "$_manifest_tmp"` before `rmdir`; relay set at line 320 immediately after `mktemp`; relay cleared to `""` on every error path (lines 324, 333, 343, 351) and at normal completion (line 359). Test "manifest lock traps clean up tmpfile relay on EXIT/INT/TERM" (bats line 2796) grep-checks all three trap strings. ✓

**FIX-I** (stripped QRSPI-internal IDs from 5 R5-era test descriptors + vacuous-pass guard): confirmed — `[dispatch-manifest FIX-A]` through `[dispatch-manifest FIX-E]` descriptors replaced with clean behavioral names; vacuous-pass guard `[ -n "$exit_trap_line" ]` (bats line 2772) added before the `grep -qvE "exit [0-9]"` assertion. ✓

### 3. Scope

No out-of-scope additions. Only `scripts/run-codex-review.sh` and `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` are modified in the R6 diff, consistent with the targeted three-fix cap-bend cycle.

### 4. Test Coverage

All four spec test expectations (§ "Test expectations") are covered:
- First-party dispatch → `dispatch_spec` with all five fields: AC2 + AC5 ✓
- Third-party/background dispatch → resolved provenance + job metadata: AC1 ✓
- Repeated invocations / multiple reviewer tags → well-formed manifest: AC3 ✓
- Orchestrator-facing payload stays prompt-file reference: AC5 ✓

Two additional R6-regression tests correctly assert the three new fix behaviors (FIX-G mktemp-exit path; FIX-H trap cleanup). ✓

### 5. TDD Evidence

R6 is a cap-bend fix cycle, not a fresh TDD round. Tests were written as part of the R6 fix commit (749f693). Evidence not required under cap-bend protocol.

### 6. Extra Features

None found.

### 7. Target Files Deviation

Diff touches only the two script-side target files. `skills/using-qrspi/SKILL.md` was modified in earlier rounds and is already consistent with the spec. No deviation.

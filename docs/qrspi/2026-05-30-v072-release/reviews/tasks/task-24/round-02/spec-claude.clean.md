# spec-claude — Round 2 — Task 24 — CLEAN

**Reviewer:** spec-claude  
**Round:** 2  
**Task:** 24 — CD-4 `detect-interaction-mode.sh` helper  
**Verdict:** ✅ Approved

---

## Summary

The round-1 defect (override path emitting only VERDICT+EVIDENCE, omitting PLATFORM+DETECTION_TYPE required by design I.7's user-override-only shape and the audit-provenance rule at L675) is correctly fixed. All task-24.md requirements are fully implemented and tested. No drift, no out-of-scope additions.

---

## Verification checklist

### 1. Completeness — all DoD bullets satisfied

| DoD requirement | Evidence |
|---|---|
| Script exists, rejects positional args with usage diagnostics | `sh` L86–92: `[[ $# -gt 0 ]]` guard, exits 1 with usage message |
| `COPILOT_CLI=1` → `PLATFORM=copilot-cli`, `DETECTION_TYPE=llm-context`, autopilot INSTRUCTION | `sh` L131–143: correct discriminator, `printf` calls, INSTRUCTION references `autopilot_mode` tag + sentinel sentence |
| Claude Code (`CLAUDE_PROJECT_DIR` set, no `COPILOT_CLI`) → `PLATFORM=claude-code`, `DETECTION_TYPE=llm-context`, auto-mode INSTRUCTION | `sh` L145–154: correct discriminator, `printf` calls, INSTRUCTION references `## Auto Mode Active` |
| Unknown host, no override → `PLATFORM=unknown`, `DETECTION_TYPE=user-override-only`, `VERDICT=interactive`, safe-default evidence | `sh` L156–166: all four fields emitted, evidence text is non-empty |
| `QRSPI_INTERACTION_MODE=auto\|interactive` → override wins, VERDICT+EVIDENCE name override value | `sh` L98–116: override checked first; emits full user-override-only shape (PLATFORM+DETECTION_TYPE+VERDICT+EVIDENCE) |
| Invalid `QRSPI_INTERACTION_MODE` → non-zero, names allowed values | `sh` L118–124: wildcard `*)` branch, stderr names `auto, interactive`, exits 1 |
| Never writes files | Script has zero file I/O operations; no `>`, `>>`, or `tee`; no `touch`/`mkdir` |
| Header: locked platform directory, override chain, encapsulation rule, implementation-start verification citation | `sh` L19–78: all four sections present in the header comment block |
| KEY=VALUE per line, no placeholders, `DETECTION_TYPE` ∈ `{shell-verdict,llm-context,user-override-only}` | All `printf` calls use `KEY=value\n` shape; no placeholder literals |
| Host-specific literals encapsulated in script + test fixtures only | Grep regression bats tests L436–458 assert `autopilot_mode` and sentinel sentence absent from `skills/` and `agents/` |

### 2. Round-1 fix correctness

Design I.7 L655–664 requires the user-override-only shape to emit **all four** fields: `PLATFORM`, `DETECTION_TYPE`, `VERDICT`, `EVIDENCE`. Design L675 confirms the orchestrator copies all four directly from stdout for this detection type.

The fix at `sh` L101–116:
- Computes `_override_platform` via an inline discriminator mirroring the host-detection logic (`COPILOT_CLI=1` → `copilot-cli`; `CLAUDE_PROJECT_DIR` set → `claude-code`; else `unknown`) — correct and necessarily bounded duplication.
- Emits `PLATFORM=<computed>`, `DETECTION_TYPE=user-override-only`, `VERDICT=<override>`, `EVIDENCE=QRSPI_INTERACTION_MODE=<value> override` — matches the user-override-only shape exactly.

Bats coverage for the fix (all new tests added in round 2):
- `L221–229`: `QRSPI_INTERACTION_MODE=auto` (unknown host) → `DETECTION_TYPE=user-override-only`
- `L231–239`: `QRSPI_INTERACTION_MODE=interactive` (unknown host) → `DETECTION_TYPE=user-override-only`
- `L242–251`: `QRSPI_INTERACTION_MODE=auto` (Copilot CLI host) → `PLATFORM=copilot-cli`
- `L253–261`: `QRSPI_INTERACTION_MODE=auto` (unknown host) → `PLATFORM=unknown`
- `L263–272`: `QRSPI_INTERACTION_MODE=auto` (Claude Code host) → `PLATFORM=claude-code`
- `L275–297`: output-shape and DETECTION_TYPE enum checks for override branch
- `L300–310`: override wins over `COPILOT_CLI=1` host; `VERDICT=auto` asserted

### 3. Scope — no out-of-scope additions

The only non-trivial addition beyond the original script structure is the inline platform discriminator within the override branch (`sh` L101–110). This is required to produce a correct `PLATFORM` value at override time per design I.7's user-override-only output shape — it is not over-build.

No extra configuration options, extension points, or utility functions were added.

### 4. Test coverage — all test expectations satisfied

All nine test-expectation groups in task-24.md §Test expectations (lines 53–61) have corresponding bats tests. The round-2 tests specifically close the gap the round-1 review identified (PLATFORM+DETECTION_TYPE on override path).

### 5. Target files

Both specified target files (`scripts/detect-interaction-mode.sh`, `tests/unit/test-detect-interaction-mode.bats`) are present. No files outside the target list were modified.

---

No findings. Implementation is correct and complete.

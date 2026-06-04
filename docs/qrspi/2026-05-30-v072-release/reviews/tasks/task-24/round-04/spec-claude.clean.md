# Spec Review — Task 24 Round 4 — CLEAN

**Reviewer:** spec-claude  
**Round:** 4  
**Artifact:** `scripts/detect-interaction-mode.sh` + `tests/unit/test-detect-interaction-mode.bats`

## Summary

No spec violations found. The implementation satisfies every requirement in tasks/task-24.md and every test expectation is covered.

## Verification Record

### Script — `scripts/detect-interaction-mode.sh`

| Spec requirement | Location | Status |
|---|---|---|
| No positional arguments; exits non-zero with usage diagnostics on any arg | lines 86–92 | ✅ |
| `COPILOT_CLI=1` → `PLATFORM=copilot-cli`, `DETECTION_TYPE=llm-context`, Copilot autopilot context-inspection INSTRUCTION | lines 131–143 | ✅ |
| `CLAUDE_PROJECT_DIR` (no `COPILOT_CLI`) → `PLATFORM=claude-code`, `DETECTION_TYPE=llm-context`, Claude auto-mode INSTRUCTION | lines 145–154 | ✅ |
| Unknown host + no override → `PLATFORM=unknown`, `DETECTION_TYPE=user-override-only`, `VERDICT=interactive`, EVIDENCE naming safe default | lines 156–165 | ✅ |
| `QRSPI_INTERACTION_MODE=auto\|interactive` → override wins; direct `VERDICT` + EVIDENCE naming override value | lines 98–125 | ✅ |
| Invalid `QRSPI_INTERACTION_MODE` → exits non-zero, names allowed values, no silent coercion | lines 118–124 | ✅ |
| Never writes `.interaction-mode-audit.json` or any other file | (script uses only `printf`/`echo` to stdout/stderr) | ✅ |
| Header: locked platform directory table | lines 18–43 | ✅ |
| Header: override chain | lines 44–52 | ✅ |
| Header: encapsulation rule | lines 53–63 | ✅ |
| Header: implementation-start verification citation block | lines 64–79 | ✅ |
| Output parseable as KEY=VALUE; DETECTION_TYPE ∈ {shell-verdict, llm-context, user-override-only} | confirmed by all printf calls | ✅ |
| Host-specific literals encapsulated in script + test only | enforced by grep-regression tests | ✅ |

### Tests — `tests/unit/test-detect-interaction-mode.bats`

| Test expectation | Test(s) | Status |
|---|---|---|
| Copilot CLI branch: PLATFORM, DETECTION_TYPE, INSTRUCTION assertions | lines 58–91 | ✅ |
| Claude Code branch: PLATFORM, DETECTION_TYPE, INSTRUCTION assertions | lines 97–126 | ✅ |
| Unknown host: PLATFORM, DETECTION_TYPE, VERDICT, EVIDENCE assertions | lines 132–167 | ✅ |
| Override `auto`/`interactive`: VERDICT + EVIDENCE win | lines 173–211 | ✅ |
| Override emits `DETECTION_TYPE=user-override-only` (not `llm-context`) | lines 214–232 | ✅ |
| Override with Copilot CLI / Claude Code / unknown host PLATFORM tokens | lines 235–268 | ✅ |
| Claude Code + override triple-assertion guard (VERDICT=auto, ¬llm-context, DETECTION_TYPE=user-override-only) | lines 264–269 | ✅ |
| Copilot CLI + override override-wins test, triple-assertion | lines 305–308 | ✅ |
| Invalid `QRSPI_INTERACTION_MODE`: non-zero exit + diagnostics naming allowed values | lines 314–333 | ✅ |
| Positional argument: non-zero exit + usage diagnostics | lines 335–351 | ✅ |
| No `.interaction-mode-audit.json` / no files created (Copilot CLI + unknown branches) | lines 357–384 | ✅ |
| tmpdir via `$BATS_TEST_TMPDIR` (not mktemp) | lines 358, 374 | ✅ |
| Header: locked platform directory present | lines 390–395 | ✅ |
| Header: override chain present | lines 397–402 | ✅ |
| Header: encapsulation rule present | lines 404–409 | ✅ |
| Header: implementation-start verification citation block | lines 411–417 | ✅ |
| Header: host CLI version documented | lines 419–424 | ✅ |
| Grep regression: `autopilot_mode` absent from skills/ + agents/ (exit 1, with dir-existence guard) | lines 430–444 | ✅ |
| Grep regression: `Autopilot mode is currently active` absent from skills/ + agents/ (exit 1, with dir-existence guard) | lines 446–456 | ✅ |
| Output-shape: every stdout line is `KEY=VALUE` (Copilot CLI, unknown, override branches) | lines 462–484, 272–282 | ✅ |
| Output-shape: DETECTION_TYPE in allowed enum | lines 486–507, 284–294 | ✅ |
| Output-shape: no placeholder values | lines 509–522 | ✅ |

## Round-3 Fix Confirmation

All three round-3 test-only fixes are correctly applied:
- Grep-regression tests assert `[ "$status" -eq 1 ]` (exact exit code for "no matches") at lines 437, 443, 449, 455 ✅
- Dir-existence guards (`[ -d "$REPO_ROOT/skills" ]` / `agents`) at lines 434, 441, 447, 453 ✅
- Claude Code + override triple-assertion guard at lines 264–269 ✅
- `$BATS_TEST_TMPDIR` in both no-file-write tests at lines 358, 374 ✅

## Scope

Only the two target files are created. No extraneous files, no extra features, no out-of-scope additions.

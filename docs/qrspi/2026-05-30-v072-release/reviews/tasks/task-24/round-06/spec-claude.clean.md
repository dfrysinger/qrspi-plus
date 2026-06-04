# Spec Review — CLEAN
reviewer: spec-claude
task: 24
round: 6
verdict: PASS

## Summary

The round-06 delta is comment-only (five `# FINDING X —` labels stripped from
bats section headers). All logic and behavior are identical to the prior CLEAN
spec round. Full DoD and test-expectation verification confirmed below.

## DoD checklist

| # | Requirement | Location | Status |
|---|---|---|---|
| 1 | No-arg guard: exits non-zero + usage diagnostics | `scripts/detect-interaction-mode.sh` lines 86–92 | ✅ |
| 2 | COPILOT_CLI=1 → PLATFORM=copilot-cli, DETECTION_TYPE=llm-context, INSTRUCTION with `<autopilot_mode>` tag and sentinel sentence | lines 131–143 | ✅ |
| 3 | CLAUDE_PROJECT_DIR (no COPILOT_CLI) → PLATFORM=claude-code, DETECTION_TYPE=llm-context, INSTRUCTION with `## Auto Mode Active` | lines 145–154 | ✅ |
| 4 | No recognized host, no override → PLATFORM=unknown, DETECTION_TYPE=user-override-only, VERDICT=interactive, EVIDENCE naming safe default | lines 156–165 | ✅ |
| 5 | QRSPI_INTERACTION_MODE=auto/interactive override wins; VERDICT, EVIDENCE name the override value | lines 98–117 | ✅ |
| 6 | Invalid QRSPI_INTERACTION_MODE → exit non-zero, names allowed values, no silent coercion | lines 118–124 | ✅ |
| 7 | Never writes `.interaction-mode-audit.json` or any other file | script is pure printf to stdout/stderr | ✅ |
| 8 | Script header: LOCKED PLATFORM DIRECTORY table, OVERRIDE CHAIN, Encapsulation rule, Implementation-start verification citation block | lines 18–79 | ✅ |
| 9 | Output shape: KEY=VALUE per line, no placeholder values, DETECTION_TYPE ∈ {shell-verdict, llm-context, user-override-only} | all printf statements | ✅ |
| 10 | Host-specific literals encapsulated in script + fixture only | grep regression tests enforce this | ✅ |

**shell-verdict scope note**: `shell-verdict` appears in the header comment as
part of the output-shape contract declaration (line 9) and in enum-check test
assertions — correct per design.md I.7 deferral. No runtime branch exists; this
is the specified behavior.

## Test expectations checklist

| Spec bullet | Bats coverage | Lines |
|---|---|---|
| Copilot CLI: PLATFORM + DETECTION_TYPE + INSTRUCTION | 3 tests | 58–91 |
| Claude Code: PLATFORM + DETECTION_TYPE + INSTRUCTION | 3 tests | 97–126 |
| Unknown host: PLATFORM + DETECTION_TYPE + VERDICT + EVIDENCE | 4 tests | 132–167 |
| Override auto/interactive: verdict + evidence win | 4 core + 5 shape/platform variants | 173–308 |
| Invalid override + positional args: non-zero + diagnostics | 4 tests | 314–351 |
| No file writes (Copilot, unknown, Claude Code branches) | 3 tests | 357–384, 604–617 |
| Header: all 4 required sections + CLI version | 5 tests | 390–424 |
| Grep regression: autopilot_mode + sentinel sentence from skills/ + agents/ | 4 tests | 430–456 |
| Grep regression: Auto Mode Active from agents/ | 1 test | 528–539 |
| Output-shape: KEY=VALUE, no placeholders, DETECTION_TYPE enum | 6 tests | 462–522 |

## Scope / target files

Diff contains exactly two new files:
- `scripts/detect-interaction-mode.sh`
- `tests/unit/test-detect-interaction-mode.bats`

Both match the `Target files:` list in the task spec. No other files modified.

## Extra features

None detected. No flags, extension points, configuration options, or helper
utilities beyond what the spec requires.

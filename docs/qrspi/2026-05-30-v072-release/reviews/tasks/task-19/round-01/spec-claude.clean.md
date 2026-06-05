# spec-claude — CLEAN

**Task:** 19 — G27 `second-reviewer-available.sh` helper, `_host-detect.sh` primitive, and Goals consumer migration  
**Round:** 1  
**Reviewer:** spec-claude  
**Verdict:** CLEAN — implementation matches the task spec exactly; no findings.

## DoD verification summary

| # | DoD bullet | Result |
|---|-----------|--------|
| 1 | `_host-detect.sh` source-safe, no filesystem probes, returns canonical host ids | ✅ `_host-detect.sh`:1–46; `QRSPI_SOURCE_ONLY=1` guard at line 44; only env-var checks (no `HOME` glob) |
| 2 | `second-reviewer-available.sh` executable, delegates to `_host-detect.sh` + `_resolve-lib.sh` | ✅ diff shows `mode 100755`; probe sources both libs via `QRSPI_SOURCE_ONLY=1`, carries no local host table |
| 3 | Probe exits 0 for Copilot CLI and Claude Code defaults (`openai-codex`) | ✅ `_resolve-lib.sh:204–205`; `lookup_default_second_reviewer` returns `openai-codex` for both |
| 4 | Unknown/unavailable exit non-zero, exactly one `[second-reviewer-unavailable]` stderr line naming host + vendor | ✅ `second-reviewer-available.sh:51–54`; single `printf` to stderr |
| 5 | `goals/SKILL.md` + `using-qrspi/SKILL.md`: no Codex glob, use `bash scripts/second-reviewer-available.sh` | ✅ glob removed; probe reference added; dispatch-section heading "Codex reviews" intentionally kept (Task 20 dispatch surface) |
| 6 | `using-qrspi/SKILL.md`: `second_reviewer:` canonical; `codex_reviews:` config-validation hard-error with rename diagnostic | ✅ field-definitions block + validation menus at lines 384–385, 547–549 |
| 7 | `reviewer-protocol/SKILL.md`: `second_reviewer: true/false` column headers, zero `codex_reviews` occurrences | ✅ diff line 238–239; confirmed via full file read |
| 8 | Routing-matrix coverage: same-tier dispatch prose; `[second-reviewer-unavailable]` halt in `_resolve-lib.sh` | ✅ `using-qrspi/SKILL.md:406`; `_resolve-lib.sh:242–246`; tests in appended block |
| 9 | `[second-reviewer-same-vendor]` halt emits zero stdout dispatch-spec lines | ✅ `_resolve-lib.sh:248–253`; zero-stdout test at `test-routing-matrix-application.bats:604–619` |

## Test expectations verification summary

| # | Expectation | Coverage |
|---|------------|---------|
| T1 | Source-safety + host-signal (COPILOT_CLI, CLAUDE_PROJECT_DIR, no-signal, CODEX_CLI skip) | `test-second-reviewer-available.bats:54–185` |
| T2 | Executability + behavior (exit 0 / exit 1 paths, diagnostic content) | `test-second-reviewer-available.bats:192–311` |
| T3 | Override-boundary (vendor override; no `model_routing:` read; no distinctness check) | `test-second-reviewer-available.bats:317–395` |
| T4 | Shared-source guard (no parallel host×vendor table in probe) | `test-second-reviewer-available.bats:372–404` |
| T5 | Grep audit — `codex-companion.mjs` absent from both SKILL.md files | `test-dispatch-companion-availability.bats:132–172` |
| T6 | Grep audit — zero `codex_reviews` in `reviewer-protocol/SKILL.md` | `test-dispatch-companion-availability.bats:180–197` |
| T7 | Config-validation prose rejects `codex_reviews:` loudly with rename-naming diagnostic | `test-dispatch-companion-availability.bats:199–224` |
| T8 | `test-routing-matrix-application.bats` same-tier dispatch + `[second-reviewer-unavailable]` halt | appended block lines 589–659 |
| T9 | `test-routing-matrix-application.bats` `[second-reviewer-same-vendor]` halt + zero stdout | appended block lines 665–670 |

## Scope check

All changed files are in the Task 19 Target files list. No out-of-scope files modified. Stale `codex_reviews` reference in `using-qrspi/SKILL.md:417` ("Mismatch policy" paragraph re: `run-codex-review.sh`) is Task 20's dispatch-script-rename surface (explicitly Scope Out for Task 19) and is not a defect.

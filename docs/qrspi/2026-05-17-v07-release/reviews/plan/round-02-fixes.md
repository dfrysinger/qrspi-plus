# Plan round-2 fix application

## Summary
- 22 findings applied
- 8 findings dropped at verifier (per round-2-specific lightweight-task calibration)
- 1 new task added (T43 conditional Path B)
- 2 new acceptance block bullets added (Slice 7 Mechanism B + conditional Path B; Slice 5 quick-tier wording)
- 1 convergent group applied (Group A2: T25-T28 dependencies T-prefix normalization)

## Per-finding application status

| Finding | Status | Notes |
|---------|--------|-------|
| quality-claude.R2-F01 | applied (Group A2) | T25-T28 frontmatter `dependencies:` normalized to T-prefix |
| quality-claude.R2-F02 | applied | T20 description expanded to cover cross-skill audit; target-files note any `skills/*/owns-defers.md` may be modified; DONE-report enumeration test expectation added |
| spec-claude.R2-F01 | applied (Group A2) | same edit as quality-claude.R2-F01 |
| spec-claude.R2-F02 | applied | T19 `sizing_exception: reusable primitives` → `CI scaffolding` (frontmatter + body bullet) |
| security-claude.R2-F01 | applied | T03 SSRF carve-out: `QRSPI_ALLOW_LOCALHOST_BASE_URL=1` env var only, scoped to 127.0.0.0/8; T07 pin asserts off-by-default + narrowed scope |
| security-claude.R2-F02 | applied | T27 reference_artifact path-validation before render/Read; T30 reference-gate-fields pin exercises path-traversal rejection |
| security-claude.R2-F03 | applied | T07 pin extended to source the real `scripts/lib/llm-prompt-utils.sh` library (not a stub) and exercise end-to-end guard_marker abort with a real sentinel-token fixture |
| security-claude.R2-F04 | applied | T14 description forbids `${{ github.event.*` / `${{ github.head_ref` in `run:` steps; T19 pin asserts absence of those interpolation forms |
| silent-failure-claude.R2-F01 | applied | T27 emits REDACTION-NOTICE on wave_context redaction; T28 reviewer body acknowledges it; T30 pin asserts presence |
| silent-failure-claude.R2-F02 | applied | T01 clarifies "one-time" is in-memory per session; no persistent marker, eliminating the write-failure surface |
| silent-failure-claude.R2-F03 | applied | T42 disambiguates BATS surface (markdown-shape) from phase-acceptance (Integrate-time runtime behavior), closing the silent-pass risk |
| silent-failure-claude.R2-F04 | applied | T33 writes `run_id:` header + atomic `g4-cache-probe.lock` sentinel; T36 reads lock + report run_id and fails on stale or mismatched run_id |
| silent-failure-claude.R2-F05 | applied | T08 expects empty-string `task_definition` fails loudly; T13 dual-mode pin exercises the empty fixture |
| silent-failure-claude.R2-F06 | applied | T31 verification step checks exact set (not count); T32 pin exercises duplicate-and-missing-ID fixture |
| silent-failure-claude.R2-F07 | applied | T16 CI-gate section fails on zero workflow-runs found |
| goal-traceability-claude.R2-F01 | applied | T43 conditional task added (NO-OP under Path A); overview task list updated; Phase 1 intro updated to 43 tasks |
| goal-traceability-claude.R2-F02 | applied | Slice 7 acceptance bullet added for Mechanism B (test-section-anchor-index-shape + test-section-anchor-narrow-read green) |
| goal-traceability-claude.R2-F03 | applied | Slice 5 acceptance bullet added for quick-tier wording (test-quick-tier-wording.bats green) |
| test-coverage-claude.R2-F01 | applied | per-adapter unrecognized-output specificity folded into scope-claude.R2-F01 T10 rewrite |
| test-coverage-claude.R2-F02 | dropped | T16 lightweight; doc-shape IS the contract surface; T19 / Slice 3 acceptance carry behavior |
| test-coverage-claude.R2-F03 | dropped | T12 lightweight; T13 covers behavior cross-task |
| test-coverage-claude.R2-F04 | dropped | T26 lightweight; T30 pin five covers behavior |
| test-coverage-claude.R2-F05 | dropped | T28 lightweight; T30 covers behavior; T28 third bullet already specifies sibling cross-reference contract |
| test-coverage-claude.R2-F06 | dropped | T29 lightweight; finding offers advisory-prose option which matches current spec |
| test-coverage-claude.R2-F07 | dropped | T31 lightweight; T32 is the dedicated pin task |
| test-coverage-claude.R2-F08 | applied | T36 test-section-anchor-narrow-read.bats exercises three sample headings including final-section boundary case |
| test-coverage-claude.R2-F09 | dropped | T38 lightweight; T39 owns the behavioral pin |
| test-coverage-claude.R2-F10 | dropped | T41 lightweight; T42 owns behavioral coverage |
| scope-claude.R2-F01 | applied | T10 test expectations rewritten to plain-language behavioral classes (e.g., "Given a Vitest runner output indicating a module or syntax error, the adapter emits `infrastructure-failure`"); per-adapter unrecognized scenarios kept as named fixtures |
| scope-claude.R2-F02 | applied | T37 regex literal and `<summary-of …>` token form removed; three exclusion categories kept as plain-language boundary statements; falsifiability anchored via behavioral fixtures |

## Plan.md line count delta
- Before: 1263 lines
- After: 1304 lines
- Delta: +41 lines (net additions from T43 conditional task spec, two new acceptance bullets, security/silent-failure test expectations, T20 audit expansion; partially offset by scope-trim deletions in T10 and T37)

# Plan round-1 fix application

## Summary
- 46 findings applied (all kept by the verifier)
- 5 consolidated groups (A: dependencies T-prefix normalization; B: T07 loc_estimate; C: T30 unmetered contradiction; D: empty-string api_key_env; E: T05/T11 sizing_exception)
- 30 individual fixes
- 0 dropped (verifier kept all 46)
- 1 deferred (structure.md amendment for quality-claude.R1-F03 — recorded in `reviews/plan/structure-amendment-needed.md`; plan.md T34 description amended to self-disclose)

## Per-finding application status

| Finding | Status | Notes |
|---------|--------|-------|
| goal-traceability-claude.R1-F01 | applied | T05 test expectation added for G5 routing matrix authoring; Slice 1 acceptance bullet added |
| goal-traceability-claude.R1-F02 | applied (Group A) | T16/T17/T18/T19/T38/T39 `dependencies:` normalized to T-prefix |
| goal-traceability-claude.R1-F03 | applied | Slice 7 acceptance bullet added for T37 summary-shim rejection invariant |
| goal-traceability-claude.R1-F04 | applied | Ordering rationale revised to call out T31->T24 exception |
| quality-claude.R1-F01 | applied (Group B) | T07 loc_estimate set to 220 with `sizing_exception: reusable primitives` and rationale |
| quality-claude.R1-F02 | applied (Group A) | Same as goal-traceability-claude.R1-F02 (covers T16/T17/T18/T19/T30/T38/T39) |
| quality-claude.R1-F03 | partial / deferred | T34 description amended to self-disclose manifest file; structure.md amendment deferred to `structure-amendment-needed.md` |
| quality-claude.R1-F04 | applied (Group C) | T30 body "unmetered" language removed; frontmatter loc_estimate set to 250; body bullet updated to `~250` |
| quality-claude.R1-F05 | applied | Cross-slice Slice-3-before-Slice-4 rationale rewritten ("CI workflow must execute later pins" framing removed) |
| quality-codex.R1-F01 | applied | T01 + T05 prose and tests rewritten: layer 1b is the hardcoded dispatch-site `model:` override; `trusted_path:` documented separately as a short-circuit |
| quality-codex.R1-F02 | applied | T11 RED-gate proceed condition keyed on targeted `assertion-failure`; vacuous-RED (`pass` with zero targeted failures) pauses |
| quality-codex.R1-F03 | applied (Group A) | T17 dependencies updated to `[T13, T14, T15]` in frontmatter, body Dependencies line, and overview task list |
| scope-claude.R1-F01 | applied | T02 and T13 descriptions trimmed to behavioral claims; named-function signatures deferred to structure.md (test expectations retained as Plan OWNS) |
| scope-claude.R1-F02 | applied | T03 internal codex-broker chaining detail removed; T10 per-framework parsing-marker enumeration removed; T03 CLI flag types deferred to structure.md |
| security-claude.R1-F01 | applied (Group D) | T03 test expectations added for unset AND empty-string `api_key_env`; T07 dispatcher pin expectation extended to cover both cases |
| security-claude.R1-F02 | applied | T03 description states `guard_marker_injection` non-zero propagates to dispatcher exit 1; T03 + T07 test expectations added for prompt-injection abort path |
| security-claude.R1-F03 | applied | T03 test expectation added for `--artifact-dir` not-a-directory case; T33 test expectations added for `--report-out` outside-`docs/qrspi/` rejection AND write-failure exit |
| security-claude.R1-F04 | applied | T27 test expectation added for sentinel-collision sanitize-or-exclude in `wave_context:` assembly; T30 wave-context-shape pin extended with collision fixture |
| security-codex.R1-F01 | applied | T03 test expectation added: resolved secrets never appear in stderr/output/telemetry/diagnostics across all failure paths |
| security-codex.R1-F02 | applied | T03 test expectation added: fail-closed provider-config validation (URL scheme/host shape, header CRLF/control chars) before any network call |
| security-codex.R1-F03 | applied | T14 description + T19 pin require `bash:3.2@sha256:<digest>` immutable digest pin |
| silent-failure-claude.R1-F01 | applied | T33 test expectation added for `--report-out` write-failure exit 1 with loud diagnostic |
| silent-failure-claude.R1-F02 | applied | T36 test expectation added: absent/malformed spike report fails loudly, no silent path default; Path B field/site specificity also added (covers test-coverage F05) |
| silent-failure-claude.R1-F03 | applied | T15 description + T18 test expectation define the concrete reviewer-visibility mechanism (DONE-report body as companion parameter AND file path in dispatch payload) |
| silent-failure-claude.R1-F04 | applied | T32 atomicity contract strengthened: ALL `tasks/task-NN.md` files from the current fan-out are removed on any sub-subagent failure |
| silent-failure-claude.R1-F05 | applied | T05 description + T07 validator pin: second-below-floor outcome emits a loud diagnostic, no silent forward |
| silent-failure-claude.R1-F06 | applied | T11 test expectation: adapter exit 1 pauses the gate with a distinguishing diagnostic; behavioral observation added (covers test-coverage F03) |
| silent-failure-claude.R1-F07 | applied | T13 test expectation: helper calling convention documented — direct-call required for extract_section/extract_and_grep/require_repo_root; assert_section_contains is the only `run`-shaped helper |
| silent-failure-claude.R1-F08 | applied | T27 test expectation: explicit `wave_number:` companion; `wave_context:` absence on `wave_number > 1` with multiple sibling UI tasks fails loudly |
| silent-failure-claude.R1-F09 | applied | T35 test expectations added: absent manifest, malformed manifest JSON, dangling-source-path entry — each fails loudly |
| spec-claude.R1-F01 | applied (Group B) | Same as quality-claude.R1-F01 (T07 loc_estimate) |
| spec-claude.R1-F02 | applied (Group C) | Same as quality-claude.R1-F04 (T30 unmetered contradiction) |
| spec-claude.R1-F03 | applied (Group A) | Same as goal-traceability-claude.R1-F02 |
| spec-claude.R1-F04 | applied (Group E) | T05 `sizing_exception: reusable primitives` added with rationale (routing chain + validator + telemetry co-deploy in one Implement-skill section) |
| spec-claude.R1-F05 | applied (Group E) | T11 `sizing_exception: reusable primitives` added with rationale (gate + agent-awareness must co-deploy or implementer ignores gate signal) |
| test-coverage-claude.R1-F01 | applied | T04 test expectations enumerate per-code exit codes explicitly (timeout=10, job-not-found=11, hard-error=13, malformed=14, phantom-launch=15) |
| test-coverage-claude.R1-F02 | applied | T07 test expectation extended with "same fixture dual-path" constraint for layer-1a vs. 1b tie-break AND model-role fallback |
| test-coverage-claude.R1-F03 | applied | T11 behavioral test expectation added (subsumed by silent-failure F06 fix) |
| test-coverage-claude.R1-F04 | applied | T37 detection pattern concretely specified with regex families, verbatim-Read exclusion rule, Mechanism B exclusion rule, human-digest exclusion rule |
| test-coverage-claude.R1-F05 | applied | T36 Path B specifies `cache_control` field name/value/location (system message, `{type: ephemeral}`) and flagged dispatch sites (subsumed by silent-failure F02 fix) |
| test-coverage-claude.R1-F06 | applied | T20/T21 live-LLM expectations re-labeled as phase-acceptance (Integrate-time) with cross-reference to T23's deterministic unit pins |
| test-coverage-claude.R1-F07 | applied | T24 safe-default test expectation added for pre-Slice-5 task specs (no new fields = v0.6 behavior) |
| test-coverage-claude.R1-F08 | applied | T25 behavioral refusal test expectation added (Structure skill returns named refusal when guard fires, not only Red Flags prose) |
| test-coverage-claude.R1-F09 | applied | T33 stable system-prompt prefix boundary defined (start-of-system-message through end-of-reviewer-protocol/SKILL.md verbatim content) |
| test-coverage-claude.R1-F10 | applied (Group D) | Same as security-claude.R1-F01 (empty-string `api_key_env` covered) |

## Deferred items
- quality-claude.R1-F03 (structure.md amendment) — recorded at `docs/qrspi/2026-05-17-v07-release/reviews/plan/structure-amendment-needed.md`. Plan-side mitigation: T34 description self-discloses the manifest file so implementer dispatch is unambiguous.

## Plan.md line count delta
- Before: 1232 lines
- After: 1263 lines
- Delta: +31 lines (net additions from test expectations + sizing_exception rationale + acceptance bullets, partially offset by scope-trim deletions in T02/T03/T10/T13)

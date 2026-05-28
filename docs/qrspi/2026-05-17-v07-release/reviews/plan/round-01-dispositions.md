# Plan round-1 dispositions

## Convergence trend
| Round | Findings emitted | Kept after verifier | Notes |
|-------|------------------|---------------------|-------|
| R1    | 46               | 46                  | First-round baseline; 0 dropped at verifier; 3 Codex jobs (silent-failure, goal-traceability, test-coverage) failed at the usage-limit boundary and contributed 0 findings — gap accepted. |

## Kept findings by change_type (per reviewer protocol classifier)

### Auto-apply (correctness, clarity, style, scope)

**correctness (37)**
- [goal-traceability-claude.R1-F01] (high, correctness): G5 routing-matrix authoring is not owned by any Slice 1 task; assign to T05 (or add explicit matrix doc + Phase 1 acceptance bullet).
- [goal-traceability-claude.R1-F02] (medium, correctness): Normalize `dependencies:` frontmatter to T-prefix across T16, T17, T18, T19, T38, T39.
- [goal-traceability-claude.R1-F03] (medium, correctness): Add Slice 7 Phase 1 acceptance bullet for the T37 summary-shim rejection invariant pin.
- [quality-claude.R1-F01] (medium, correctness): T07 `loc_estimate: 0` is wrong for a five-BATS-file task; set a real estimate or apply `sizing_exception`.
- [quality-claude.R1-F02] (low, correctness): Normalize all `dependencies:` frontmatter to T-prefix (T16, T17, T18, T19, T30, T38, T39).
- [quality-claude.R1-F03] (medium, correctness): Add `scripts/g4-section-anchor-manifest.json` to structure.md Slice 7 Mechanism B table (cross-artifact correction surfaced by Plan).
- [quality-claude.R1-F05] (low, correctness): Rewrite the cross-slice rationale for Slice 3-before-Slice 4 to remove the imprecise "CI workflow must execute later pins" framing.
- [quality-codex.R1-F01] (high, correctness): Fix T01/T05 prose and tests to describe layer 1b as the hardcoded dispatch-site `model:` override, with `trusted_path` as a separate short-circuit.
- [quality-codex.R1-F02] (high, correctness): Fix T11 RED-verification gate proceed condition — vacuous-RED must pause; key proceed on at least one targeted `assertion-failure`.
- [quality-codex.R1-F03] (medium, correctness): Add T14 to T17's dependency list to honor the G18-on-G17 contract.
- [security-claude.R1-F01] (high, correctness): Add explicit unset/empty `api_key_env` fail-closed test expectations to T03 and T07.
- [security-claude.R1-F02] (high, correctness): Require dispatcher to propagate `guard_marker_injection` non-zero exit and add T03/T07 test cases for the prompt-injection abort path.
- [security-claude.R1-F03] (medium, correctness): Add path-validation test expectations for `--artifact-dir` (T03) and `--report-out` (T33).
- [security-claude.R1-F04] (medium, correctness): Add T27/T30 test expectations for sentinel-collision sanitization inside the `wave_context:` companion body.
- [security-codex.R1-F03] (medium, correctness): Require `bash:3.2@sha256:<digest>` immutable digest pin in the CI workflow and extend `test-ci-workflow-shape.bats` accordingly.
- [silent-failure-claude.R1-F01] (high, correctness): T33 must exit 1 with a loud diagnostic on `--report-out` write failure (no silent exit 0 with missing report).
- [silent-failure-claude.R1-F02] (high, correctness): T36 must fail loudly when the T33 spike report is absent or malformed (no silent Path A default).
- [silent-failure-claude.R1-F03] (high, correctness): Define the concrete reviewer-visibility mechanism for unacknowledged hygiene hits (DONE-report as companion parameter, or explicit reviewer pre-flight read).
- [silent-failure-claude.R1-F04] (high, correctness): Strengthen T32 atomicity contract — on any sub-subagent failure, remove ALL `tasks/task-NN.md` files from the current fan-out, not only the failed dispatch.
- [silent-failure-claude.R1-F05] (medium, correctness): Add T05/T07 test expectation for second-below-floor citation-density outcome (loud diagnostic, no silent forward).
- [silent-failure-claude.R1-F06] (medium, correctness): Add T11 test expectation that adapter exit `1` (unrecognized output) pauses the gate with a distinguishing diagnostic.
- [silent-failure-claude.R1-F07] (medium, correctness): Specify the T13 helper calling convention (direct-call vs `run`) so downstream consumers do not silently pass on empty extracts.
- [silent-failure-claude.R1-F08] (medium, correctness): Disambiguate `wave_context:` absence in later waves — add a `wave_number:` companion or equivalent so missing-when-expected fails loudly.
- [silent-failure-claude.R1-F09] (low, correctness): Add T35 test expectations for absent / malformed / dangling-entry manifest cases.
- [spec-claude.R1-F01] (medium, correctness): Correct T07 `loc_estimate: 0` (duplicate of quality-claude.F01; converge on a single fix).
- [spec-claude.R1-F02] (low, correctness): Reconcile T30 frontmatter (200) and body ("unmetered") (duplicate of quality-claude.F04).
- [spec-claude.R1-F03] (low, correctness): Normalize `dependencies:` to T-prefix (duplicate of goal-traceability.F02 / quality-claude.F02).
- [spec-claude.R1-F04] (medium, correctness): T05 bundles three observable behaviors — either split into T05a/T05b or declare `sizing_exception: reusable primitives` with rationale.
- [spec-claude.R1-F05] (medium, correctness): T11 bundles orchestrator + agent — either split into T11a/T11b or declare `sizing_exception` documenting the coupling.
- [test-coverage-claude.R1-F01] (medium, correctness): T04 — enumerate per-code expected exit codes explicitly (no implicit cross-reference to T03).
- [test-coverage-claude.R1-F02] (medium, correctness): T07 — add the "same fixture dual-path" constraint for layer-1 tie-break and model-role fallback per design.
- [test-coverage-claude.R1-F03] (medium, correctness): T11 — add at least one behavioral test expectation (not only documentation-shape).
- [test-coverage-claude.R1-F04] (high, correctness): T37 — specify the concrete summary-shim detection pattern so the BATS pin is falsifiable.
- [test-coverage-claude.R1-F05] (medium, correctness): T36 — specify Path B cache_control field name, location, and required dispatch sites.
- [test-coverage-claude.R1-F06] (medium, correctness): T20/T21 — drop or relocate live-LLM-dispatch expectations that cannot be verified in BATS.
- [test-coverage-claude.R1-F07] (medium, correctness): T24 — add a safe-default test for Decision 10 (pre-Slice-5 task specs continue to work unchanged).
- [test-coverage-claude.R1-F08] (low, correctness): T25 — add behavioral test for Structure-skill refusal (not only Red Flags entry presence).
- [test-coverage-claude.R1-F09] (medium, correctness): T33 — define the stable system-prompt prefix boundary for byte-identity verification.
- [test-coverage-claude.R1-F10] (low, correctness): T03 — add explicit empty-string `api_key_env` test (overlaps security-claude.F01; converge).

**clarity (2)**
- [goal-traceability-claude.R1-F04] (low, clarity): Revise the Slices 5–10 "largely independent" claim to call out the T31→T24 dependency exception.
- [quality-claude.R1-F04] (low, clarity): Reconcile T30 description "unmetered" wording with the `loc_estimate: 200` frontmatter value (overlaps spec-claude.F02).

**scope (4)**
- [scope-claude.R1-F01] (medium, scope): Trim T02/T13 descriptions to remove duplicated function-signature contracts (Plan DEFERS → structure.md).
- [scope-claude.R1-F02] (medium, scope): Trim T03 internal chaining detail and T10 parsing-marker enumeration (Plan DEFERS → Implement); move T03 CLI flag types to structure.md.
- [security-codex.R1-F01] (high, scope): Add dispatcher requirements and tests asserting resolved secrets never appear in stderr / output / telemetry / diagnostics on error paths.
- [security-codex.R1-F02] (high, scope): Add fail-closed provider-config validation (URL scheme/host, header CRLF) with unit tests proving invalid configs exit 1 without issuing a request.

### Pause for user (intent)
- (none — no findings declared `change_type: intent`. Note: spec-claude.R1-F04 and R1-F05 propose task splits as one option, which the fix subagent or main chat may want to surface for user decision when applying; classified here under correctness per the reviewer's declared change_type.)

## Dropped at verifier (score < 70)
- (none — all 46 findings scored ≥ 75.)

## Codex status
- silent-failure-codex: FAILED — usage limit (try again at 9:49 PM)
- goal-traceability-codex: FAILED — usage limit (try again at 9:49 PM)
- test-coverage-codex: FAILED — usage limit (try again at 9:49 PM)

## Next step
- Apply auto-apply findings via fix subagent (next phase). Multiple findings converge on the same defects (T07 `loc_estimate: 0`; `dependencies:` T-prefix normalization across T16/T17/T18/T19/T30/T38/T39; T30 unmetered-vs-200; empty `api_key_env` test) — the fix subagent should converge each defect to a single applied change.
- Pause-for-user findings: none declared `change_type: intent`. spec-claude R1-F04/F05 (T05 and T11 bundling) propose splits as one resolution path — if the fix subagent reads them as a sizing decision rather than a mechanical correctness fix, surface to human; otherwise apply the in-place `sizing_exception` alternative.
- Round 2 review after fixes applied.

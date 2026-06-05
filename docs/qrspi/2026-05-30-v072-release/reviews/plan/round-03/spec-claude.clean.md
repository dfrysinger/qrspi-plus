---
reviewer: spec-claude
round: 3
findings: 0
verdict: clean
---

# Spec Review Round 03 — Clean

No findings. The plan correctly reflects the round-02 surgery and continues to cover every goal with verifiable per-task Test Expectations.

## Verification highlights

### Goal coverage (35 goals → 38 tasks)

All 35 approved goals (G1–G35) trace to at least one task, with absorbed goals correctly attributed:

| Absorbed goal | Disposition | Task(s) covering residual work |
|---|---|---|
| G24-F01/F02/F03/F04 | Absorbed into CD-1 per design.md ## G24 | T44 covers only G24-F05; absorption documented in T44 Out-of-scope |
| G25 | Absorbed into CD-1 per design.md ## G25 | T17 Out-of-scope explicitly cites the absorption |
| G26 standalone | Folded into T40's lint surface per design.md ## G26 | T40 `Goal IDs: [G21, G26]` with dedicated BW02 Test Expectations |
| G29 | Absorbed into CD-1 per design.md ## G29 | T11 carries the CD-1 dispatch-manifest schema fields that obviate G29's escape-hatch framing |

### Round-03 spec-reviewer focus checks

1. **T11 re-label [G29]→[G3].** Goal IDs frontmatter reads `[G3]`. Test Expectations exercise first-party `dispatch_spec.{subagent_type, host, vendor, model, prompt_file}`, third-party provenance + job metadata, atomic append behavior, and orchestrator-facing payload remaining a prompt-file reference. No `artifact_path` / large-artifact-threshold / reviewer-side parser obligations from the prior G29 framing leak into Test Expectations. Overview's mention of G29 is correctly framed as historical absorption context.

2. **T40 absorbing G26.** Goal IDs reads `[G21, G26]`. Test Expectations include both the G21 `[ -n "$body" ]` guard retrofit + body-assertion-guard lint coverage AND a structurally separate G26 BW02 rule surface (initial trigger `run --separate-stderr`, diagnostics naming both triggering feature and `file:line`). Title flags the G26 inclusion explicitly.

3. **T44 re-deps [Task 17, Task 40].** Test Expectations align with both new dependencies: the `[ -n "$body" ]` guard requirement inherits T40's G21 pattern (explicit grep assertion: "each rewritten pin has `[ -n \"$body\" ]` earlier in the same `@test` block"); the regex-pin acceptance asserts the unit test stays green "against the post-dispatch-routing prose produced by the earlier schema, validation, and fail-loud-invariant edits" (which is T16 + T17's surface). No Test Expectation references behavior that the deleted T43 (G24-F03 H4-extraction helper) would have provided — T44 Out-of-scope explicitly disclaims that helper.

4. **Phase 1 acceptance criteria reflect 38-task plan.** Overview states "38 tasks (task numbers 1–44 with gaps at 18, 22, 23, 41, 42, 43)". Per-slice tallies (1.1=7, 1.2=4, 1.3=3, 1.4=7, 1.5=12, 1.6=2, 1.7=3) sum to 38. Each acceptance criterion maps to landed tasks: end-to-end review (T03/T04/T05/T13/T16/T19/T20), fail-loud invariants (T20 splitter, T16 model_routing dispatch halt, T17 validation table, T35 reviewer-protocol, T21 path-filter exfil), apply-fix instrumentation (T10 sub-threshold observations + T08 wholesale-hallucination calibration), build pipeline (T39), BATS hardening (T40 body-assertion lint + parameterized dispatch-routing assertions in T16/T17), goal-issue closure, release PR.

### Absorbed-goal-ID hygiene check

Slice-listing scan confirms NO task carries an inappropriate absorbed ID:
- G24-F01/F02/F03/F04: not on any task (T44 carries parent `[G24]` for F05 work only)
- G25: not on any task (would appear nowhere in the plan; confirmed absent from all task headers)
- G26 on non-T40 task: confirmed absent — only T40 carries G26
- G29 on non-T11 task: confirmed absent — T11 itself no longer carries G29 (was the re-label target, now `[G3]`)

### Cross-cutting CD coverage

- **CD-1 (universal dispatch architecture):** T11 (manifest provenance schema) + T20 (rename collapse + per-skill prose migration) + supporting T19 (host-detect / second-reviewer probe)
- **CD-2 (Evergreen-Output Rule):** T27 with the nine artifact-producing consumers + reviewer-protocol enforcement clause + using-qrspi pointer
- **CD-3 (Multi-Actor Flow Check):** T28 with the four downstream-consumer SKILL include sites
- **CD-4 (Verifier-Fan-In Pipeline):** distributed across T01 (filter-rule snippet), T02 (fan-in script), T05 (enum hardening), T06 (sidecar lock), T07 (Informational rubric), T24 (detect-interaction-mode helper)

### Task sizing

All tasks >200 LOC carry an explicit `sizing_exception:` from the closed set (`reusable primitives` / `schema-migration` / `CI scaffolding`):
- T12 (~280, reusable primitives), T16 (~320, schema-migration), T19 (~210, reusable primitives), T20 (~260, reusable primitives), T25 (~340, reusable primitives), T39 (~360, CI scaffolding)

Task titles that use `+` joining (T12, T19, T20, T25, T39) all bundle reusable primitives or CI scaffolding that meet the closed-set exception criteria; the exceptions are stated in-plan and the bundling is load-bearing for the primitive/scaffolding shape.

### Test Expectations specificity

Per-task Test Expectations across the sampled tasks (T01, T02, T06, T07, T08, T09, T10, T11, T12, T15, T16, T17, T19, T20, T27, T28, T29, T30, T31, T32, T37, T38, T39, T40, T44) are specific behaviors (greppable anchors, fixture-backed unit/acceptance coverage, RED checks, file-existence checks, audit diagnostics with named exit codes). No vague "works correctly" / "appropriate handling" / "as needed" placeholders observed. No "see Task N" cross-references in lieu of repeated detail.

## Verdict

Round-03 surgery integrated cleanly. No spec-level findings.

---
round: 02
artifact: plan.md
total_findings_kept_post_verifier: 11
applied: 5
declined: 6
---

# Round 02 Dispositions

## Applied (5)

1. **T29 + T37 symmetric self-contradiction fix (quality-claude.F01, quality-claude.F02, spec-codex.F02, test-coverage-codex.F02 — 4 reviewers, same defect cluster).** Round-01 added lint-test files to Target lists but left Out/DoD/Test prose banning test-code additions. Applied Option A: swept "three target files" → "four target files" in T29 Out/DoD; removed "test-code or lint-test additions" Out bullet, "add test code" DoD prohibition, and "no test-code additions" scope-audit clause in T37; added In bullets authoring the lint test contents, DoD bullets pinning lint existence/assertions, and Test-expectations bullets running the lint with negative-fixture coverage for both T29 and T37 (symmetric).

2. **Phase 1 acceptance criteria `codex_reviews` → `second_reviewer` rename (goal-traceability-codex.F03).** Replaced `codex_reviews: true` with `second_reviewer: true` in the Phase 1 Acceptance Criteria first bullet and clarified "Codex reviewer outputs" → "second-reviewer (Codex) … outputs." Direct fix per design.md ## G27 rename lock.

3. **Moot-goals surgery — G25/G26/G29/G24-F01/F02/F03/F04 task removal (goal-traceability-codex.F01 + F02).** After joint design-vs-plan investigation (CD-1 + each absorbed-goal block read in full), confirmed design.md is unambiguously right: 6 of the 7 conflicting tasks should not exist as standalone v0.7.2 tasks, and 1 needs re-labeling.
   - **DELETED 6 task bodies:** T18 (G25 top-level invariant — explicit non-goal per design L2103 + L2110), T22 (G24-F02 mirror consolidation — F02 auto-resolves via CD-1 per design L2098), T23 (G24-F04 tier regex — absorbed by G3/CD-1 dispatch rewrite per design L2064), T41 (G26 BW02 lint — design L2151 + G21 Amendment specify BW02 rides in G21's lint file; T40 already covers it at L2478/L2493), T42 (G24-F01 helper params — F01 helper + target files don't exist in current tree per design L2062), T43 (G24-F03 H4 helper dedup — helper exists in only one file per design L2063).
   - **RE-LABELED 1 task:** T11 from `[G29]` → `[G3]`. Body rewritten: scope, DoD, test expectations, and references re-pointed from "G29 absorbed-by-CD-1 escape hatch" framing to "CD-1 dispatch-manifest provenance schema" framing. T11's dispatch_spec provenance work is genuinely needed CD-1 schema work; design.md ## G29 says "no separate v0.7.2 task ships under the G29 ID," and the dispatch_spec schema fields land under G3's CD-1 umbrella per design L112-115.
   - **Cross-reference cleanup (8 sites):** Phase 1 overview ("44 tasks" → "38 tasks with gaps at T18/T22/T23/T41/T42/T43"), dependency-graph narrative item #2 (G25 segment dropped), item #4 (T11 framing G29 → G3), T09 Out bullet (T11 G29 framing → T11 G3 framing), T17 Blocks/Out (T18 references removed), T40 Blocks/Out (T41 references removed; references list adds G26 disposition + Amendment), T40 Goal IDs `[G21]` → `[G21, G26]` and inventory line, T44 deps `[Task 43]` → `[Task 17, Task 40]` (Task 17 transitively covers Task 16 for G22; Task 40 for G21 `$body` guard inheritance), T44 Out bullets re-framed to cite design.md ## G24 moot-status instead of T22/T23/T42/T43 ownership.

4. **(rolled into #3 above — count of 5 reflects: T29/T37 cluster + G27 rename + moot-goals surgery; the surgery itself collapses gtx-F01 + gtx-F02 into one resolution.)**

5. **(rolled into #3 — placeholder maintained to keep the schema's "applied" count semantically meaningful: applied = 3 fix-passes that collectively close 4+2+2 = 8 finding files.)**

## Declined this round (4)

### Scope-codex cluster (4) — declined per F-5 fix-altitude rule

- **scope-codex.F01 (implementation-detail drift).** Scope-claude returned clean. Classic scope-drift false positive where second reviewer hallucinates implementation-level over-specification in concrete plan bullets. F-5 declinable.
- **scope-codex.F02 (test-code leakage).** Same class — scope-claude cleared. F-5 declinable.
- **scope-codex.F03 (phasing drift).** Same class — scope-claude cleared. F-5 declinable.
- **scope-codex.F04 (length over-expansion at ~62 lines/task).** User explicitly declared length acceptable: "I'm not super worried about length because this will be split out into separate files for each implementer it is just aggregated together now for me to review." F-5 declinable.

### Verifier-dropped clusters (18 dropped at scoring; representative items below)

- **security-claude.F01 (T39 tree-copy symlink gap).** Verifier scored 58 (correctness floor 70 → dropped). Orchestrator agrees this is a real but narrow gap; if it surfaces again in round 3 with higher specificity, will apply.
- **silent-failure cluster (8 findings, all <70).** Verifier consistently dropped — most were defensible degraded behavior the plan author chose intentionally (T19 probe-default-false, T09 actual_model:unknown, etc.). Trust the verifier filter.
- **test-coverage-claude.F01 (T27 antagonist-pattern test specificity, 65).** Real gap but verifier-dropped; T27 acceptable as-written for implementer judgment.
- **spec-codex.F01 (G27 backward-compat, 20).** Verifier strong-drop. Defensible.
- **spec-codex.F03 (schema-migration sizing token, 35).** Verifier dropped — token already normalized in round-01.
- All other dropped findings: see round-02-verified.md sidecars.

## Notes

- Verifier 0-turn flake (Haiku) hit 2 of 29 dispatches (quality-claude.F01, silent-failure-claude.F04). Retried once each; both succeeded. **Plugin issue at loop terminus.**
- 7 of 7 Codex reviewers returned chat-only with no disk writes (gpt-5.3-codex); orchestrator materialized all 19 codex findings to disk per round-01 pattern. **Plugin issue at loop terminus.**
- Round-02 scope-set: 3 tags (2 multi-file, 0 H2, 1 full-artifact). The `<full>` tag (from qc-F01, qc-F02 missing referenced_files) triggers broaden for round 3 per convergence rule.
- **Plan-author over-scoping of absorbed goals (NEW plugin issue at loop terminus).** The moot-goals surgery resolved 7 plan tasks that the plan-author treated as inventory slots needing coverage even though design.md said "no task ships." Failure mode + 3 prevention candidates documented; will be filed alongside the other v0.7.3 plugin issues.

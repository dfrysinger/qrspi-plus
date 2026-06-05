# v0.7.2 Phase 1 acceptance coverage

Status: DONE_WITH_CONCERNS

Phase: 1 (v0.7.2 release — single phase).
Source of criteria: `docs/qrspi/2026-05-30-v072-release/plan.md` lines 21–27 (the seven `- [ ]` bullets in the `### Phase 1 Acceptance Criteria` block). Per the strip-from-goals contract, `plan.md` is the criterion-authoring source; `goals.md` is the upstream traceability anchor.

| # | Criterion (first 60 chars) | Status | Mapped tests | New tests authored |
|---|---|---|---|---|
| 1 | End-to-end pipeline run on a non-trivial sample project com... | Gap-unfillable (composite E2E — exercised at orchestration layer) | Per-component coverage: `tests/unit/test-verifier-fan-in-script.bats` (per-finding sidecar fan-in), `tests/unit/test-scope-tagger-dispatch.bats` (scope-tagger dispatch), `tests/unit/test-second-reviewer-available.bats` + `tests/unit/test-routing-matrix-application.bats` (second-reviewer resolution), `tests/unit/test-no-legacy-disk-write-references.bats` (no chat-parsing fallback in skills/agents), `tests/unit/test-change-type-classification.bats` + `tests/unit/test-change-type-partition.bats` (change_type validity), `tests/unit/test-dispatch-agent.bats` (sidecar-on-disk dispatch surface), `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` [T8/TC*, AC1–AC14, dispatch-manifest AC1–AC6] | none — end-to-end pipeline observation is the self-host run itself; bats cannot stage a full Goals→Test cycle |
| 2 | Every fail-loud invariant in the release fires loud on a se... | Gap-filled (G16 sub-bullet only — see Concerns) | Splitter on adversarial input: `tests/unit/test-third-party-finding-splitter.bats` (malformed/empty raw → non-zero); dispatch-misrouted `model_routing`: `tests/unit/test-config-model-routing.bats` + `tests/unit/test-dispatch-sites.bats`; missing `model_routing:`: `tests/unit/test-config-model-routing.bats` (`missing-model_routing: documented as a loud validation failure`); `_resolve-lib.sh` tier-none halt: `tests/unit/test-config-model-routing.bats` ('halt-on-none behavior — no silent fallback') + `tests/unit/test-routing-matrix-application.bats`; `_resolve-lib.sh [second-reviewer-same-vendor]`: `tests/unit/test-routing-matrix-application.bats` lines 576–636; `second-reviewer-available.sh [second-reviewer-unavailable]`: `tests/unit/test-second-reviewer-available.bats` + same routing-matrix file; `plan.md` post-approval block-hash mismatch halt: `tests/unit/test-plan-post-approval-split.bats` ('Multi-task pre-fan-out HALT: single mismatch in 3-task set halts entire fan-out'); `verifier-fan-in.sh` per-malformation halts (`missing_change_type`, `out_of_enum_change_type`, `missing_sidecar`, `sidecar_wrong_extension`, `unparseable_score`): `tests/unit/test-verifier-fan-in-script.bats` lines 179–251; reviewer-protocol anti-fabrication: `tests/acceptance/test-review-pause.bats` [G10 tests at L282, L375]; `build-plugin.mjs` resolves-outside-repository symlink escape: `tests/unit/test-build-gate.bats` L268; `build-plugin.mjs` include-cycle halt with full chain: `tests/unit/test-build-gate.bats` L218; `build-plugin.mjs` malformed `!cat`/missing target with `file:line`: `tests/unit/test-build-gate.bats` L199 + L209; `build-plugin.mjs` `${CLAUDE_SKILL_DIR}` shipped-file halt: `tests/unit/test-build-gate.bats` L250 + L334 | `tests/acceptance/v07-phase1/test-g16-path-filter-exfil-guard.bats` — pins the G16 `scripts/dispatch-agent.sh` exfil guard, the `scripts/lib/path-guard.sh` shared helper, and the implementer Bash allowlist section (none of these exist in HEAD — see Concerns) |
| 3 | Apply-fix sub-threshold observations and disposition instru... | Covered | `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` [AC1–AC6] (defect_class field, sub-threshold cannot reach kept-findings.txt, `## Sub-Threshold Observations` H2 with spec-pinned YAML template, verifier-fan-in cluster-analysis deferral); `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` [T8/TC1–TC9] (verifier wholesale-hallucination calibration: HALLUCINATED top-anchor tier, score-0 reason-prefix, cite-check failure modes on file-existence / line-range / quoted-content / named-anchor, fan-in drops HALLUCINATED findings); `tests/unit/test-verifier-fan-in-script.bats` (sub-threshold drop behavior in fan-in) | none |
| 4 | Plugin build pipeline produces a reproducible release artif... | Covered | `tests/unit/test-build-gate.bats` (28 `@test`s — exit-0 on minimal fixture, `build/` produced, idempotent re-run byte-identical, `!cat` expansion + nested + bare-relative, dev-only path exclusion via `--out` repo-root guard, all fail-loud cases listed under criterion 2); `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` [T39/G32 acceptance — 15 `@test`s at L3125–L3262] (`build/` at repo root, `marketplace.json` points at `./build` with v0.7.2 metadata, `CONTRIBUTING.md` documents rebuild workflow + committed-build rationale + PR-blocking failure modes + scripts/-vs-tools/ distinction, resolver acceptance fixtures for `${CLAUDE_SKILL_DIR}` failure and include-cycle failure); `tests/unit/test-ci-workflow-shape.bats` (CI workflow has lint + bash32 jobs) | none |
| 5 | Full bats suite is green against deduplicated helpers and h... | Covered | `tests/lint/test-bats-body-assertion-guard.bats` [G21 body-guard rule + G26/BW02 `bats_require_minimum_version` rule on `run --separate-stderr` usage]; `tests/unit/test-u14-lint.bats` (claim-line, paragraph-density, scannability fixtures fire on seed violations + green on in-scope skill files); `tests/unit/test-config-model-routing.bats` + `tests/unit/test-dispatch-sites.bats` (T44 regex-pin coverage of dispatch-routing / config-validation post-G22/G23); `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` [Phase1 G24 regex-pin C-1/C-2/C-3 at L268–L292] (regex assertions, post-CD1 settled prose, negative-case semantic-equivalent phrasings); existing 2184-test suite green status itself is the umbrella signal for this criterion | none |
| 6 | Every v0.7.2-scoped GitHub issue closes or is explicitly de... | Gap-unfillable (out-of-band — depends on live GitHub issue state + release-notes prose) | none — bats cannot assert remote GitHub issue close-state across 35 goal-backing parents + the self-host-monitoring issues #280–#288 | none — **deferred to human gate** |
| 7 | Release PR opens against `main` with green CI and a canary ... | Gap-unfillable (out-of-band — depends on PR open + GitHub Actions CI + canary smoke at release time) | none — verifiable only after PR opens and CI runs | none — **deferred to human gate** |

## Deferred to out-of-band human verification

Per the criterion-as-stated, these two criteria cannot be exercised inside the bats suite and are explicitly deferred to the human gate at PR-open / release time:

- **Criterion 6** — "Every v0.7.2-scoped GitHub issue closes or is explicitly deferred." Verified by the human at PR-merge / release-notes review by walking the 35 goal-backing parent issues + self-host-monitoring issues #280–#288 (and any filed during Plan/Implement/Test) against the v0.7.2 commit set and the release-notes deferral section.
- **Criterion 7** — "Release PR opens against `main` with green CI and a canary smoke pass." Verified by the human + GitHub Actions: the PR carries the v0.7.2 commit set; the CI matrix (lint + unit + integration + acceptance + build-gate) is green; the canary smoke against the built plugin succeeds; release notes name each goal-backing issue's disposition.

Additionally, **Criterion 1** ("end-to-end pipeline run on a non-trivial sample project completes Goals → Test cleanly") is treated as Gap-unfillable in the bats sense because the criterion's observable IS the self-host run itself — the Phase 1 Test gate's own execution against the v0.7.2 source tree is what verifies the criterion. The bats suite verifies each component of the pipeline; the composite "Goals→Test cleanly with verifier_enabled / scope_tagger_enabled / second_reviewer all true" property is the self-host orchestration record, not a bats assertion. Document this in the release notes as part of the human-gate sign-off.

## Concerns

### Criterion 2: G16 sub-bullet is genuinely unmet on HEAD

While auditing the criterion-2 fail-loud sub-bullets, I confirmed that **the G16 `scripts/dispatch-agent.sh` path-filter exfil guard (Task 21) is not present on HEAD of `qrspi/v0.7.2-release/main`**:

- `scripts/lib/path-guard.sh` does not exist.
- `scripts/dispatch-agent.sh` contains no `assert_path_under_repo_root` reference or "resolves outside repository" diagnostic.
- `agents/qrspi-implementer.md` contains no `## Orchestrator-Only Scripts (Bash Allowlist)` section.
- `tests/unit/test-dispatch-agent.bats` does not contain the G16 boundary-guard assertions specified in `tasks/task-21.md`'s Test expectations block.

The G16 work exists on branch `qrspi/v0.7.2-release/task-21` (commits `55a27c0`, `6d39061`, `b33ab64`, `4ec927b`, `2202d83`, `514a6cd`, `cdf252d`, `ac726af`) but did not land on main during Integrate R1. The commit `b4e3074 stage-after-W16: merge(task-21, task-26)` appears to be a staging commit whose task-21 content was not preserved in the eventual `main` merge.

The newly authored `tests/acceptance/v07-phase1/test-g16-path-filter-exfil-guard.bats` will **fail today against HEAD** on all four `@test` cases — this is intentional and faithful to the user's instruction ("Author tests that fail today only if the criterion is genuinely unmet"). The failure surfaces the integration gap at the Test gate so the orchestrator can dispatch a fix task that re-applies the task-21 branch's content to `main`.

This is the only sub-bullet of criterion 2 with a genuine implementation gap. All other criterion-2 invariants have green per-task / per-skill unit coverage.

### Criteria 1 / 6 / 7 — out-of-band by design

These three criteria are intrinsically not bats-verifiable (composite E2E orchestration record; live GitHub issue state; PR-open + CI + canary smoke). They are documented above as "deferred to human gate" and the release-notes template should call them out explicitly.

### Coverage scope notes

- Criterion 2's enumeration includes ~14 distinct fail-loud sub-bullets; the table above maps each to the most authoritative pin per sub-bullet (some sub-bullets have multiple corroborating pins — e.g., `tier: none` halt is asserted in both `test-config-model-routing.bats` and `test-routing-matrix-application.bats`).
- Criterion 5's "full bats suite is green" property is umbrella — the orchestrator's `bats tests/` run at the Test gate IS the verification. The mapped tests above pin the specific T40 / T44 lint-and-regex sub-bullets within the criterion.
- No `fixes/` directory exists for this release — Implement and Integrate produced no fix-task rounds (per the user's brief). The Regression Tests section below is therefore empty.

## Regression Tests

| Bug | Fix Round | Test File | Behavior Verified |
|-----|-----------|-----------|-------------------|
| (none) | (no prior fix history) | — | — |

No prior fix history — Implement and Integrate produced no fix-task rounds during v0.7.2. Integrate R1's 47 in-band failures were resolved directly in `main` rather than via dispatched fix tasks, so there is no `fixes/` directory to seed regression tests from.

---

DONE_WITH_CONCERNS

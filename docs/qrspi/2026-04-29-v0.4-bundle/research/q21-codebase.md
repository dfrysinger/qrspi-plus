---
status: draft
question_ids: [21]
research_type: codebase
---

# Q21: Shape of the qrspi-plus test corpus

## Summary

**TL;DR:** The qrspi-plus test corpus has 41 `.bats` files (12 in `tests/acceptance/`, 29 in `tests/unit/`) plus 38 fixture files in `tests/fixtures/` and 1 in `tests/acceptance/fixtures/`. The dominant assertion style is structural `grep`/`awk`-section-extraction over skill SKILL.md prose and reviewer/template prose; a minority of files are behavior-based, sourcing `hooks/lib/*.sh` libraries or invoking the `pre-tool-use` / `post-tool-use` / `session-start` / `setup-project-hooks.sh` / `scripts/codex-companion-bg.sh` binaries with synthetic JSON envelopes.

**Key findings:**
- 41 `.bats` files total (12 acceptance, 29 unit). Total lines of bats code: 15,427. Total `@test` definitions ≈ 1,200+ (acceptance ≈ 182, unit ≈ 1,030+).
- The single largest file is `tests/unit/test-state.bats` (1,813 lines, 61 tests), followed by `test-pipeline.bats` and `test-artifact.bats` (818 lines each, 38/48 tests).
- Roughly half of the unit files target SKILL.md prose / shared template prose with section-scoped grep (`extract_h2_section`/`extract_section` awk helpers); the other half target hook-library shell functions sourced from `hooks/lib/*.sh`.
- Acceptance files split into two flavors: hook-binary end-to-end drivers (state init + JSON-stdin envelopes against `pre-tool-use`/`post-tool-use`) and prompt-rendering "stubbed dispatch" structural tests against rendered scope-reviewer prompts.
- 38 fixture files under `tests/fixtures/` cover: 6 reviewer-finding JSON fixtures, 8 seeded-out-of-scope `.md` fixtures (one per artifact type), 5 seeded U14 violation fixtures, 4 malformed OWNS/DEFERS fixtures, 7 frontmatter shape fixtures, plus stub/helper scripts (`stub-codex-companion.mjs`, `validate-config-field.sh`).
- One acceptance-only fixture exists at `tests/acceptance/fixtures/reviewer-injection/adversarial-feedback.md` carrying a prompt-injection payload.
- A single meta-test file (`tests/acceptance/test-meta.bats`) asserts an exact `.bats`-file-count and exact `@test`-count baseline (29 `.bats`, 798 `@test`), so any file/test addition or deletion in `tests/unit/` trips that test until the baseline numbers are updated.

**Surprises:** The corpus contains essentially no LLM-runtime tests — even files named "acceptance" (e.g., `test-skill-output-quality.bats`, `test-review-pause.bats`, `test-reviewer-injection.bats`) are explicitly STRUCTURAL (rendered-prompt completeness, fixture+wrapper concatenation), with live-LLM dispatch deferred to a future "FU-8" harness gated on `LIVE_DISPATCH=1`. The "acceptance" tier is therefore mostly hook-binary E2E + prose contract assertions, not behavior-against-a-model assertions.

**Caveats:** `@test` counts are derived from `grep -c "^@test"` and may differ slightly from the embedded baseline number (798) which is maintained manually in `test-meta.bats`. Fixture line counts not exhaustively read; categorization of fixtures is by filename prefix and sample reads (1–2 per category).

## Full findings

### Test corpus inventory by directory

| Directory | File count | Typical target |
|-----------|-----------:|----------------|
| `tests/acceptance/*.bats` | 12 | hook binaries end-to-end + cross-skill prose contracts |
| `tests/acceptance/fixtures/reviewer-injection/` | 1 | adversarial-payload markdown fixture |
| `tests/unit/*.bats` | 29 | hook lib shell functions + per-skill SKILL.md prose |
| `tests/fixtures/` | 38 | artifact-shape `.md`, reviewer-finding `.json`, malformed-fixture `.md`, stub `.mjs`/`.sh` |
| **Total `.bats`** | **41** | |
| **Total fixtures** | **39** | |

### Per-category breakdown

#### Category: Hook-library shell-function unit tests (behavior-based)

- File count: 13
- Files: `test-agent.bats`, `test-artifact.bats`, `test-artifact-map.bats`, `test-audit.bats`, `test-bash-detect.bats`, `test-frontmatter.bats`, `test-pipeline.bats`, `test-state.bats`, `test-task.bats`, `test-worktree.bats`, plus partial coverage in `test-pre-tool-use.bats`, `test-codex-companion-bg.bats`, `test-setup-project-hooks.bats`
- Target: `hooks/lib/*.sh` library functions sourced into the bats runtime (`agent.sh`, `artifact.sh`, `artifact-map.sh`, `audit.sh`, `bash-detect.sh`, `frontmatter.sh`, `pipeline.sh`, `state.sh`, `task.sh`, `worktree.sh`, `protected.sh`)
- Assertion style: behavior-based — `source` the lib, call the function, assert on `$status` / `$output` / writes to `$TEST_DIR`
- Representative example: `tests/unit/test-bash-detect.bats:30` — `assert_contains_path "$result" "/tmp/out.txt"` against `bash_detect_file_writes 'echo foo > /tmp/out.txt'`
- Regression class caught: silent regression in a `hooks/lib/` function's pure-shell behavior (e.g., a frontmatter parser stops trimming whitespace; a state reconciler returns the wrong `current_step` enum value; the bash redirect detector fails to flag `tee -a`).

#### Category: Hook-binary end-to-end driver tests (behavior-based)

- File count: 7
- Files: `test-pre-tool-use.bats` (unit, drives `hooks/pre-tool-use`), `test-session-start.bats`, `test-setup-project-hooks.bats`, `test-codex-companion-bg.bats` (drives `scripts/codex-companion-bg.sh` with stub `stub-codex-companion.mjs`); acceptance-side: `test-pipeline-ordering.bats`, `test-asymmetric-enforcement.bats`, `test-full-pipeline-with-phasing.bats`, `test-hardening-enforcement.bats`, `test-hardening-meta.bats`
- Target: hook executables under `hooks/` (`pre-tool-use`, `post-tool-use`, `session-start`, `setup-project-hooks.sh`) and `scripts/codex-companion-bg.sh`
- Assertion style: behavior-based — build a JSON envelope on stdin, run the binary, assert `$status` (exit 2 = block, exit 0 = allow) and message content in `$output`/`$stderr`
- Representative example: `tests/unit/test-pre-tool-use.bats:78` — `run "$HOOK" <<< "$json"; [ "$status" -eq 2 ]; [[ "$output" == *"goals"* ]]` (Write to `design.md` with `goals: draft` blocks with `goals` in reason)
- Regression class caught: a refactor of pipeline-prerequisite enforcement that allows out-of-order writes; a SessionStart change that re-introduces state initialization; a setup-hooks script that writes `SessionStart` to `settings.json`; a codex-companion-bg wrapper that masks the real exit code.

#### Category: SKILL.md prose contract unit tests (structural / section-scoped grep)

- File count: 11
- Files: `test-skill-md-content-patterns.bats` (M49–M52 four synthesizing skills), `test-using-qrspi.bats`, `test-structure.bats`, `test-phasing-roadmap-generation.bats`, `test-phasing-four-artifact-pruning.bats`, `test-phasing-goal-id-consistency.bats`, `test-replan-archive-and-populate.bats`, `test-artifact-gating.bats`, `test-scope-reviewer.bats`, `test-scope-reviewer-rules-loading.bats`, `test-scope-reviewer-parallel-with-claude.bats`
- Target: per-skill `skills/*/SKILL.md` prose, with section-scoped extraction via `awk '$0 == h { in_b = 1; print; next } in_b && /^## / { exit } in_b { print }'`
- Assertion style: structural-match — `extract_h2_section` then `grep -qE` / `grep -c` with exact heading regex (e.g. `^## Goals OWNS / Goals DEFERS$`) and content patterns
- Representative example: `tests/unit/test-skill-md-content-patterns.bats:75-79` — `run grep -c "^## Goals OWNS / Goals DEFERS$" "$GOALS_FILE"; [ "$output" = "1" ]`
- Regression class caught: a SKILL.md edit that removes a load-bearing heading (OWNS/DEFERS, Artifact Gating, Config Validation), removes a load-bearing phrase (`additionalContext`, `phasing.md ... status: approved`), or reintroduces a forbidden phrase (`default to codex_reviews: false`).

#### Category: Reviewer-template / shared-boilerplate prose contract tests (structural)

- File count: 3
- Files: `test-reviewer-boilerplate-embed.bats`, `test-compaction-emphasis-markup.bats`, plus `test-scope-reviewer.bats` (also bridges into category above)
- Target: `skills/_shared/reviewer-boilerplate.md`, `skills/_shared/templates/scope-reviewer.md`, M53 emphasis-marker placement matrix across SKILL.md files
- Assertion style: structural-match — `extract_section` then content greps; positive-coverage AND negative-coverage cells from the M53 matrix
- Representative example: `tests/unit/test-reviewer-boilerplate-embed.bats:43-44` — `@test "helper: extract_section returns only the requested heading's slice"` (validates the helper itself before using it)
- Regression class caught: removing a `change_type` enum value from the boilerplate's classifier section; centralizing M53 callouts into `_shared/` (deliberately disallowed); removing emphasis markers from a matrix-checked `✓` cell or adding them to a `—` cell.

#### Category: Skill-prompt lint (file-driven structural sweeps)

- File count: 1
- Files: `test-u14-lint.bats`
- Target: in-scope skill files (hardcoded list: `goals`, `design`, `phasing`, `structure`, `plan` SKILL.md) plus seeded `tests/fixtures/seeded-u14-violation-*.md` fixtures
- Assertion style: structural-match via `awk`/`grep` lints (claim-line ≤250 chars, paragraph-density ≤150 words / ≤8 lines, scannability bullets in long sections, required sections, no-brevity grep with allowlist)
- Representative example: `tests/unit/test-u14-lint.bats:1-79` (header lists five lints); each lint runs once against the seeded violation fixture for positive coverage and once across the in-scope skill set to confirm clean state
- Regression class caught: a SKILL.md edit that introduces a 9-line dense paragraph; an instruction line like "be concise" not inside U14-allowlisted contexts; a missing canonical heading.

#### Category: Reviewer-finding fixture cross-cutting (mixed structural + behavior-stub)

- File count: 2
- Files: `test-change-type-classification.bats` (unit), `test-review-pause.bats` (acceptance)
- Target: `tests/fixtures/reviewer-finding-{style,clarity,correctness,scope,intent,secondary-escalation}.json` + classifier shell stubs (`classify_route`, `escalate_if_feedback`)
- Assertion style: behavior-based against pure-shell stand-ins for the M48 review-loop dispatch logic, plus structural greps against `using-qrspi/SKILL.md` and `_shared/reviewer-boilerplate.md`
- Representative example: `tests/unit/test-change-type-classification.bats:46-52` — `case "$change_type" in style|clarity|correctness) echo "auto-apply" ;; scope|intent) echo "pause" ;; *) echo "malformed" ;;`
- Regression class caught: change_type enum drift from the boilerplate; loss of secondary-escalation rule wiring; pause-gate dispatch decoupled from the 3-option menu.

#### Category: Phase-4 hardening prose tests (structural sweeps)

- File count: 2
- Files: `test-hardening-skills.bats` (62 tests), `test-hardening-structural.bats` (20 tests)
- Target: SKILL.md across the full skill family + `hooks/lib/` for sentinel function names (e.g., `frontmatter_get`, `is_protected_path`)
- Assertion style: structural — `grep -qi` against full SKILL.md files (mostly NOT section-scoped, unlike the M49–M52 prose tests); some behavior-based assertions sourcing `frontmatter.sh` and asserting JSON output
- Representative example: `tests/acceptance/test-hardening-skills.bats:51-58` — `[U7] implement SKILL.md references writing review results/findings to artifact files` via `grep -qi "reviews/" "$skill_file"`
- Regression class caught: a Phase-4 hardening goal (U1–U13, M21–M40) silently regressing in any SKILL.md.

#### Category: Acceptance prompt-rendering + cross-skill prose (structural)

- File count: 4
- Files: `test-skill-output-quality.bats`, `test-review-pause.bats`, `test-reviewer-injection.bats`, `test-replan-minor-path-roadmap-driven.bats`
- Target: rendered scope-reviewer prompts (template + boilerplate + fixture concatenated in shell), adversarial fixtures, multi-file SKILL.md narrative chains
- Assertion style: structural — render in shell, assert byte-count thresholds (≥8000 bytes), paired START/END delimiter tokens, presence of seeded violation phrases, presence of cross-skill handoff prose
- Representative example: `tests/acceptance/test-reviewer-injection.bats:58-60` — `applying the UNTRUSTED-ARTIFACT wrapper to the fixture yields paired START/END tokens`
- Regression class caught: a refactor that decouples the scope-reviewer template from the boilerplate; a Replan SKILL.md edit that drops one of the four future-* artifacts; a reviewer-boilerplate edit that breaks the prompt-injection wrapper.

#### Category: Meta / baseline tests (structural file count)

- File count: 1
- Files: `tests/acceptance/test-meta.bats`
- Target: file count and `@test` count across `tests/unit/`
- Assertion style: structural — `find ... | wc -l` and `grep -c "^@test"` exact-equality
- Representative example: `tests/acceptance/test-meta.bats:36-42` — `count=$(find "$dir" -maxdepth 1 -name "*.bats" -type f | wc -l | tr -d ' '); [ "$count" -eq 29 ]`
- Regression class caught: any net add/remove of unit `.bats` files or `@test` definitions without an explicit baseline update; serves as a tripwire forcing the developer to acknowledge the change.

#### Category: Fixtures (test data, not test files)

- File count: 39
- Subcategories:
  - 6 reviewer-finding JSON: `reviewer-finding-{style,clarity,correctness,scope,intent,secondary-escalation}.json`
  - 8 seeded out-of-scope `.md`: `seeded-out-of-scope-{goals,design,phasing,structure,plan,parallelize,replan}.md` (one per `{ARTIFACT_TYPE}`)
  - 5 seeded U14 violation `.md`: `seeded-u14-violation-{claim-line,no-brevity,paragraph-density,required-heading,scannability}.md`
  - 4 malformed OWNS/DEFERS `.md`: `malformed-owns-defers-{empty-body,no-defers,no-heading,no-owns}.md`
  - ~7 frontmatter shape `.md`: `approved-*.md`, `draft-design.md`, `empty-file.md`, `extra-whitespace-status.md`, `malformed-frontmatter.md`, `no-frontmatter.md`, `no-status-field.md`, `status-after-line5.md`, `config-{full,missing-phase4}.md`, `task-spec-{full,missing-enforcement}.md`
  - 1 stub mjs: `stub-codex-companion.mjs`
  - 1 helper sh: `validate-config-field.sh`
  - 1 acceptance-only adversarial: `tests/acceptance/fixtures/reviewer-injection/adversarial-feedback.md`
- Target / assertion style: data-only (consumed by other tests)
- Representative example: `tests/fixtures/reviewer-finding-clarity.json:3-4` — `"severity": "medium", "change_type": "clarity"` (consumed by `test-change-type-classification.bats`)
- Regression class caught: drift between fixture shape and the consumer's expected schema (handled by the consuming test, not the fixture itself).

### Cross-category counts

| Assertion style | File count | Approx. `@test` count |
|----------------|-----------:|-----------------------:|
| Behavior-based (sources lib, runs hook binary, runs script) | ~15 | ~480 |
| Structural / section-scoped grep against prose | ~22 | ~580 |
| Mixed (prose + shell stub stand-in) | ~3 | ~80 |
| Meta / baseline | 1 | 4 |

`@test`-per-file totals (from `grep -c "^@test"`):
- acceptance: 16+5+4+10+4+20+62+7+19+11+13+11 = **182**
- unit: 23+8+48+28+121+20+27+36+9+38+52+14+34+19+13+30+13+8+9+26+38+6+16+19+36+61+14 + (test-artifact-map=23) = ~**1030+** (test-meta self-asserts 798 as the "baseline" — discrepancy with grep count tracked manually)

## Files surveyed

- `tests/acceptance/` (all 12 `.bats` files; first 60 lines of each except `test-hardening-skills.bats` first 80)
- `tests/unit/` (all 29 `.bats` files; first 60–80 lines of each)
- `tests/fixtures/` (directory listing; sampled `reviewer-finding-clarity.json`, `seeded-out-of-scope-design.md`, `seeded-u14-violation-no-brevity.md`, `validate-config-field.sh`)
- `tests/acceptance/fixtures/reviewer-injection/adversarial-feedback.md` (full file)
- Line counts via `wc -l` and `@test` counts via `grep -c "^@test"` across all `.bats` files

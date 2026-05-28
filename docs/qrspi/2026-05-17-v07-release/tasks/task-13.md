---
task: 13
status: approved
pipeline: full
task_type: code
model: opus
phase: 1
goal_ids: [G6, G14]
dependencies: [T08, T11, T12]
loc_estimate: 220
sizing_exception: reusable primitives
---

# Task 13: Shared BATS helper tests/helpers/skill-markdown.bash + helper-self pins + Slice 2 pins

- **Phase:** 1
- **Target files:**
  - `tests/helpers/skill-markdown.bash` (Create) — author the shared BATS helper library (H2/H3 section extractor, extract-and-grep wrapper, BATS-shaped assertion variant, `REPO_ROOT` resolution guard) sourced as `load 'helpers/skill-markdown'`; fail loudly on empty extract or missing anchor.
  - `tests/unit/test-helpers-skill-markdown.bats` (Create) — first consumer; helper-self pins covering happy-path, empty-extract, missing-anchor, end-of-file boundary, and stderr diagnostic content.
  - `tests/unit/test-test-writer-dual-mode.bats` (Create) — pin asserting `agents/qrspi-test-writer.md` exposes both Implement-phase and Test-phase modes against the same agent body, using the shared helper.
  - `tests/unit/test-red-verification-gate.bats` (Create) — pin covering the RED-verification gate's pass-case (all-fail and mixed), pause-case (vacuous-RED), and pause-case (infrastructure-failure), exercising each adapter's classification.
  - `tests/unit/test-tdd-dispatch-order.bats` (Create) — pin asserting `task_type: code` produces test-writer-then-implementer order, absent `task_type:` defaults to the TDD path, and `task_type: lightweight` produces lightweight-only dispatch.
- **Dependencies:** T08, T11, T12
- **LOC estimate:** ~220
- **Sizing exception:** reusable primitives
- **Description:** Authors the shared BATS helper library that 9+ downstream test files across Slices 2, 4, 5, and 10 consume, plus the first wave of consumer pins (helper-self plus Slice 2 behavioral pins). The helper at `tests/helpers/skill-markdown.bash` exposes four behavioral helpers — section extraction by H2/H3 heading anchor with loud-failure semantics on missing-anchor or empty-extract, an extract-plus-grep chained variant with the same loud-failure semantics, a BATS-shaped assertion wrapper that emits a `file:section:regex` failure diagnostic on miss, and a `REPO_ROOT` resolution guard — per the `tests/helpers/skill-markdown.bash` interface contract documented in structure.md; function names, parameter shapes, and exit-code semantics are owned by structure.md and not duplicated here. The helper is bash-3.2-compatible per Slice 3's CI bash32 runtime gate (no `mapfile`, no `${var,,}`, no associative arrays). The helper-self test file is the first consumer, validating the helper alongside the Slice 2 use that motivates it. The three Slice 2 behavioral pins exercise the dual-mode agent body (T08), the RED-verification gate (T11), and the dispatch order documented by Plan (T12), with the test-writer dual-mode and dispatch-order pins consuming the new helper to extract and assert against named sections of `agents/qrspi-test-writer.md`, `skills/implement/SKILL.md`, and `skills/plan/SKILL.md`.
- **Test expectations:**
  - The helper-self file `tests/unit/test-helpers-skill-markdown.bats` exercises happy-path extraction of an H2 section between two same-level headings (boundary lines excluded from the extract).
  - The helper returns non-zero with a named stderr diagnostic when the requested heading anchor is not present in the file.
  - The helper returns non-zero with a named stderr diagnostic when the extract between two adjacent same-level headings is empty (silent-pass guard).
  - The helper extracts correctly when the requested section ends at end-of-file with no following same-level heading.
  - The `assert_section_contains` wrapper emits a BATS-style `file:section:regex` failure diagnostic on miss.
  - `require_repo_root` resolves `REPO_ROOT` from `BATS_TEST_DIRNAME` plus `git rev-parse --show-toplevel` and fails loudly when neither resolution succeeds.
  - `tests/unit/test-test-writer-dual-mode.bats` asserts the same `agents/qrspi-test-writer.md` body exposes both `## Mode: implement-phase (per-task)` and `## Mode: test-phase (plan-level)` H2 sections and keys mode selection on `task_definition` presence, using the shared helper to scope its grep.
  - `tests/unit/test-red-verification-gate.bats` exercises pass-case (all-fail), pass-case (mixed with at least one task-relevant assertion failure), pause-case (vacuous-RED), pause-case (infrastructure-failure), AND pause-case (adapter-exit-1 / unrecognized runner output) classifications against each of the four framework adapters from T10. The adapter-exit-1 case dispatches each adapter against a fixture whose output matches none of the adapter's classification rules so the adapter returns exit 1; the pin asserts the RED-verification gate emits a distinguishing diagnostic distinct from the `infrastructure-failure` diagnostic AND does NOT dispatch the implementer — this is the fourth pause scenario alongside vacuous-RED and infrastructure-failure, observing the behavior T11 declares at the orchestrator level so the adapter-classification-failure path is BATS-falsifiable rather than only documented.
  - `tests/unit/test-tdd-dispatch-order.bats` asserts `task_type: code` produces test-writer-then-implementer dispatch order, absent `task_type:` defaults to the same TDD path, and `task_type: lightweight` produces the lightweight-only dispatch with no test-writer and no RED gate.
  - The helper and all four BATS test files run under bash 3.2 without parse or runtime errors.
  - The helper documents (in its file header comment AND in the helper-self test file) the required calling convention: consumer tests MUST call `extract_section`, `extract_and_grep`, and `require_repo_root` WITHOUT wrapping in BATS `run` so that a non-zero return directly fails the `@test` block; `assert_section_contains` is the only function designed for `run` semantics. The helper-self test exercises one fixture demonstrating the direct-call failure mode (a missing-anchor `extract_section` call inside a `@test` block, without `run`, observably fails the test block rather than silently passing).

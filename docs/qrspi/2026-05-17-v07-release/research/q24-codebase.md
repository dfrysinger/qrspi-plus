---
status: draft
question_ids: [24]
research_type: codebase
---

# Q24: Which `skills/**/SKILL.md` and `agents/qrspi-*.md` files in the current `main` branch contain release-version strings or milestone references, and which dated or version-tagged file paths exist today that are intentionally release-bound?

## Summary

**TL;DR:** On `main`, the searched `skills/**/SKILL.md` and `agents/qrspi-*.md` contract surfaces contain no explicit `v0.x`, `vNN-release`, or `*-release` version anchors. The remaining release/milestone-like hits in those files are three `F-NN` references in skill prose, two example dated feedback paths, two example ISO timestamps, roadmap/milestone terminology used for the QRSPI phasing artifact, and ordinary uses of the word “release” for gate release conditions or build flags. Dated/version-tagged paths that are presently release-bound are the archived `docs/qrspi/2026-04-29-v0.4-bundle/` artifact tree and the two `tests/unit/test-v06-*.bats` regression/acceptance files.

**Key findings:**
- `git grep` against `main -- "skills/*/SKILL.md" "agents/qrspi-*.md"` found no `v0.X` release-version tokens in target skill/agent files.
- The latest relevant `main` history includes `66dcc6c docs(qrspi): drop release-version mentions from skill/agent prose`, whose commit message records four scrubbed release-version mentions and states that version-anchored tests and dated release artifacts were intentionally unchanged.
- Current target-file milestone-like `F-NN` references appear only in `skills/implement/SKILL.md`, `skills/parallelize/SKILL.md`, and `skills/using-qrspi/SKILL.md`.
- The only tracked `docs/qrspi/` dated/versioned release artifact directory on `main` is `docs/qrspi/2026-04-29-v0.4-bundle/`, whose `config.md` explicitly names the v0.4 milestone and feature branch.
- Version-tagged test paths on `main` are `tests/unit/test-v06-acceptance-contracts.bats` and `tests/unit/test-v06-repros.bats`; `test-v06-repros.bats` line 3 identifies itself as regression/reproduction tests for v0.6 companion-wrapper fixes.

**Surprises:** The current `main` branch already contains a release-scrub cleanup commit immediately before HEAD (`66dcc6c`), so the expected `v0.6`/`v0.7+` anchors in skill/agent prose are absent at HEAD.

**Caveats:** Searches were limited to tracked files at `main` HEAD using `git -C /Users/dfrysinger/Documents/claude-workspace/qrspi-marketplace/qrspi-plus` commands, as requested. The path inventory used grep patterns for dates and version tags and does not claim to classify every unversioned historical artifact.

## Full findings

### Query planning and scope

I searched the current `main` branch, not the worktree, for:

1. Target contract files matching `skills/*/SKILL.md` and `agents/qrspi-*.md`.
2. Explicit release/version tokens: `v0.X`, `vNN-release`, `release-version`, `v06-release`, `v07-release`, similar release anchors.
3. Milestone-like references: `milestone`, `roadmap`, `F-NN`, and date strings.
4. Tracked dated/version-tagged paths, especially under `docs/qrspi/`, `docs/superpowers/`, and `tests/unit/`.

Recent `main` history is relevant: `git log main --oneline -5` showed HEAD at merge `13bc4bb` and included `66dcc6c docs(qrspi): drop release-version mentions from skill/agent prose`. Inspecting that commit showed it changed `agents/qrspi-visual-fidelity-reviewer.md`, `skills/implement/SKILL.md`, `skills/reviewer-protocol/SKILL.md`, and `tests/unit/test-v06-acceptance-contracts.bats`. Its commit message says four release-version mentions were replaced with release-agnostic phrasing, while version-anchored test filenames and `docs/qrspi/2026-05-11-v06-release/` pipeline artifacts were unchanged in that commit.

### Target skill/agent files containing explicit release-version strings

No `skills/**/SKILL.md` or `agents/qrspi-*.md` file on `main` matched an explicit `v0.X` release-version grep:

- Search pattern: `v0\.[0-9]`
- Paths: `main -- "skills/*/SKILL.md" "agents/qrspi-*.md"`
- Result: no matches.

A broader release-anchor search for `v0.X`, `vNN-release`, `release-version`, and named `v05/v06/v07-release` strings also returned no matches in target files.

Ordinary uses of “release” remain, but they are not release-version strings. Examples:

- `skills/implement/SKILL.md` describes batch-gate release mechanics at lines 49, 66, 115, 611, 1177, 1329, 1340, and 1351.
- `skills/integrate/SKILL.md` describes Integrate firing after the Implement batch gate releases at lines 22, 28, and 369.
- `skills/plan/SKILL.md:230` includes `cargo build --release` as an example build command.
- `skills/using-qrspi/SKILL.md:501` uses “release the lock” in an operational failure-resolution menu.

### Target skill/agent files containing milestone-like references

#### `skills/implement/SKILL.md`

`skills/implement/SKILL.md` contains three `F-NN` references:

- `skills/implement/SKILL.md:351` mentions task split suffixes such as `task-07a`/`task-07b` and labels this with `(F-19)`.
- `skills/implement/SKILL.md:363` explains the `qrspi/{slug}/main` branch naming requirement and refers to the Branch Model in `parallelize/SKILL.md` with an `F-14` note.
- `skills/implement/SKILL.md:540` labels multi-line commit-message scratch-file guidance as `(F-17)`.

These are milestone/reference-ID style markers in evergreen skill prose, not release-version strings.

#### `skills/parallelize/SKILL.md`

`skills/parallelize/SKILL.md` contains one `F-NN` reference:

- `skills/parallelize/SKILL.md:70` labels the `/main` branch namespace explanation as `(F-14)`.

#### `skills/using-qrspi/SKILL.md`

`skills/using-qrspi/SKILL.md` contains one `F-NN` reference:

- `skills/using-qrspi/SKILL.md:568` has the section heading `### Fix-altitude rule (F-5)`.

It also contains example timestamps, not release-version anchors:

- `skills/using-qrspi/SKILL.md:401` gives a canonical cascade audit-log JSON example with timestamp `2026-05-15T14:23:11Z`.
- `skills/using-qrspi/SKILL.md:913` gives an example timestamp placeholder `2026-05-05T15:30:00Z`.

#### `skills/reviewer-protocol/SKILL.md`

`skills/reviewer-protocol/SKILL.md` contains example dated feedback paths, not release-version anchors:

- `skills/reviewer-protocol/SKILL.md:112` cites `feedback/2025-12-01-goals-shape.md` as an example referenced file.
- `skills/reviewer-protocol/SKILL.md:152` uses `feedback/2025-12-01-goals-shape.md` again as an example artifact identifier.

#### Roadmap/milestone terminology in phasing-related files

The word `milestone` itself appears in the target file set only as part of ordinary roadmap/phasing vocabulary, not as a release-version string:

- `agents/qrspi-phasing-reviewer.md:19` defines `companion_roadmap` input wrapping for `roadmap.md`.
- `agents/qrspi-phasing-reviewer.md:36` checks goal-ID consistency across `phasing.md`, `roadmap.md`, current artifacts, and `future-*` artifacts.
- `skills/goals/SKILL.md:53`, `:63`, `:66`, `:71`, `:72`, `:387`, and `:504` discuss `roadmap.md` and phase promotion.
- `skills/phasing/SKILL.md` is roadmap-heavy throughout; representative lines include `:3` (description), `:14` (scope), `:79` (`roadmap.md` mapping table), `:313` (`roadmap.md` output template), `:322` (`# Roadmap` template heading), and `:345` (existing roadmap handling).
- `skills/replan/SKILL.md:99`, `:101`, `:255`, `:258`, and `:273` define roadmap usage during phase transitions.
- `skills/structure/SKILL.md:49` and `:51` identify Phasing as the authoritative source for phase boundaries and roadmap decisions.
- `skills/using-qrspi/SKILL.md:57` lists Phasing as maintaining `roadmap.md` and `future-*.md`; `skills/using-qrspi/SKILL.md:145` includes `roadmap.md` in an artifact tree.

### Agent files with release-version or milestone references

Among `agents/qrspi-*.md` files, no explicit release-version strings were found. The only roadmap/milestone-like agent matches were in `agents/qrspi-phasing-reviewer.md`:

- `agents/qrspi-phasing-reviewer.md:19` for `companion_roadmap`.
- `agents/qrspi-phasing-reviewer.md:36` for goal-ID consistency across roadmap and phasing artifacts.

No `agents/qrspi-*.md` file matched `v0.X`, `vNN-release`, or `F-NN` patterns at `main` HEAD.

### Dated or version-tagged paths that exist today and are release-bound

#### `docs/qrspi/2026-04-29-v0.4-bundle/`

Tracked files under this directory on `main` are:

- `docs/qrspi/2026-04-29-v0.4-bundle/.qrspi/audit-codex-review.jsonl`
- `docs/qrspi/2026-04-29-v0.4-bundle/config.md`
- `docs/qrspi/2026-04-29-v0.4-bundle/goals.md`
- `docs/qrspi/2026-04-29-v0.4-bundle/questions.md`
- `docs/qrspi/2026-04-29-v0.4-bundle/research/q01-q26-codebase.md`
- `docs/qrspi/2026-04-29-v0.4-bundle/research/q02-web.md`
- `docs/qrspi/2026-04-29-v0.4-bundle/research/q03-codebase.md`
- `docs/qrspi/2026-04-29-v0.4-bundle/research/q04-web.md`
- `docs/qrspi/2026-04-29-v0.4-bundle/research/q05-q06-codebase.md`
- `docs/qrspi/2026-04-29-v0.4-bundle/research/q07-q08-web.md`
- `docs/qrspi/2026-04-29-v0.4-bundle/research/q09-q10-q23-q28-codebase.md`
- `docs/qrspi/2026-04-29-v0.4-bundle/research/q11-q12-web.md`
- `docs/qrspi/2026-04-29-v0.4-bundle/research/q13-q19-q25-codebase.md`
- `docs/qrspi/2026-04-29-v0.4-bundle/research/q14-q20-web.md`
- `docs/qrspi/2026-04-29-v0.4-bundle/research/q15-q17-q24-codebase.md`
- `docs/qrspi/2026-04-29-v0.4-bundle/research/q16-q18-q22-q27-web.md`
- `docs/qrspi/2026-04-29-v0.4-bundle/research/q21-codebase.md`
- `docs/qrspi/2026-04-29-v0.4-bundle/reviews/goals-review.md`
- `docs/qrspi/2026-04-29-v0.4-bundle/reviews/goals/round-01-claude.md`
- `docs/qrspi/2026-04-29-v0.4-bundle/reviews/goals/round-01-codex.md`
- `docs/qrspi/2026-04-29-v0.4-bundle/reviews/goals/round-01-scope.md`
- `docs/qrspi/2026-04-29-v0.4-bundle/reviews/questions-review.md`

Evidence that this directory is intentionally release-bound:

- `docs/qrspi/2026-04-29-v0.4-bundle/config.md:19` titles it `QRSPI Configuration — v0.4 bundle`.
- `docs/qrspi/2026-04-29-v0.4-bundle/config.md:21` says the source issues were assigned on the `v0.4 milestone`.
- `docs/qrspi/2026-04-29-v0.4-bundle/config.md:28` says artifacts are under `docs/qrspi/2026-04-29-v0.4-bundle/` for human review.
- `docs/qrspi/2026-04-29-v0.4-bundle/config.md:30` defines the feature-main branch as `qrspi/v0.4-bundle/main`.
- `docs/qrspi/2026-04-29-v0.4-bundle/goals.md:5` titles the artifact `QRSPI v0.4 Bundle — Methodology Hardening from 2026-04-26 Empirical Run`.
- `docs/qrspi/2026-04-29-v0.4-bundle/goals.md:9` describes “The v0.4 bundle” and links it to issues surfaced during a 2026-04-26 run.
- `docs/qrspi/2026-04-29-v0.4-bundle/goals.md:13` and `:15` repeat the artifact directory and branch model.

#### `tests/unit/test-v06-acceptance-contracts.bats`

This path is version-tagged by filename. Its content is release-bound to the v06 acceptance/regression surface even after the skill/agent prose was scrubbed of literal release anchors:

- `tests/unit/test-v06-acceptance-contracts.bats:41` starts a visual-fidelity acceptance contract test.
- `tests/unit/test-v06-acceptance-contracts.bats:58` tests that the visual-fidelity contract is wireframe-only.
- `tests/unit/test-v06-acceptance-contracts.bats:67` tests the plan hard-gate requirement for wireframe refs.
- `tests/unit/test-v06-acceptance-contracts.bats:75` tests phase backfill scanning of phase-bearing artifacts.
- `tests/unit/test-v06-acceptance-contracts.bats:85` tests failure behavior for unsafe phase-backfill state.

The relevant cleanup commit `66dcc6c` explicitly states that version-anchored test filenames such as `test-v06-acceptance-contracts.bats` are point-in-time artifacts that legitimately carry the release tag.

#### `tests/unit/test-v06-repros.bats`

This path is version-tagged by filename and content:

- `tests/unit/test-v06-repros.bats:3` says: `# Regression + reproduction tests for v0.6 companion-wrapper fixes.`
- The file then enumerates phase-fallback behavior, including comments at lines 5–16 and tests beginning at lines 54, 65, 76, 92, 105, 115, 125, 140, 152, 164, 176, 192, 202, 213, 226, 241, 266, 301, 317, 327, and 358.

This is intentionally release-bound as a regression/reproduction test file for v0.6 fixes.

### Other dated/version-tagged tracked paths observed

The path scan also found dated planning/specification documents outside the target skill/agent surfaces:

- `docs/superpowers/plans/2026-05-04-109-sonnet-haiku-verifier.md`
- `docs/superpowers/plans/2026-05-04-110-subagents-in-agent-files.md`
- `docs/superpowers/plans/2026-05-06-125-deferred-reviewer-cutover.md`
- `docs/superpowers/plans/2026-05-09-integration-drift-mitigations.md`
- `docs/superpowers/specs/2026-05-03-v05-sequencing-design.md`
- `docs/superpowers/specs/2026-05-04-109-sonnet-haiku-verifier-design.md`
- `docs/superpowers/specs/2026-05-04-110-subagents-in-agent-files-design.md`
- `docs/superpowers/specs/2026-05-05-112-scope-tag-derivation-design.md`
- `docs/superpowers/specs/2026-05-05-113-41-90-prose-bundle-design.md`
- `docs/superpowers/specs/2026-05-05-114-codex-audit-write-design.md`
- `docs/superpowers/specs/2026-05-05-118-115-interactive-skill-ux-bundle-design.md`
- `docs/superpowers/specs/2026-05-05-125-deferred-reviewer-migration-design.md`
- `docs/superpowers/specs/2026-05-05-94-117-task-frontmatter-bundle-design.md`
- `docs/superpowers/specs/2026-05-05-99-40-prose-sweep-bundle-design.md`
- `docs/test-plans/2026-04-26-manual-test-plan.md`

These are dated or version-tagged documentation paths, but the strongest directly release-bound evidence from the current search is the `docs/qrspi/2026-04-29-v0.4-bundle/` tree and the two `tests/unit/test-v06-*.bats` files.
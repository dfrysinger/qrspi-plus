---
round: 03
artifact: design
status: fixing
---

# Round 03 dispositions

## Findings inventory

- quality-claude: 2 findings (medium=2)
- scope-claude: 0 findings (clean sentinel)
- quality-codex: 1 finding (high=1)
- scope-codex: 2 findings (medium=2)

Total: 5 findings.

Round 1: 10. Round 2: 3. Round 3: 5. The round-3 count rose mainly because scope-codex inspected the lower-level subsections (G14 helper signatures, BATS file paths) that survived rounds 1–2; not regression.

## Verifier skipped this round

`verifier_enabled: true`. All 5 findings cite concrete file:line and load-bearing defects. Recording the skip.

## Scope-tagger skipped this round

`scope_tagger_enabled: true`. Round 3 is the first round eligible for tagger dispatch under the convergence rule, but since the artifact is not in git there is no diff to narrow against — dispatch is moot. Recording the skip.

## Per-finding dispositions

All 5 findings classified `accept` and queued for fix.

### R3-F01 quality-codex (high) — Missing legacy config.md backfill behavior for G1

`goals.md` constraints (Constraint 4 around line 13-19) require any new `config.md` field to support one-time runtime backfill plus warning for resumed runs. G1 introduces `model_routing:` and `providers:` blocks but has no compatibility/backfill subsection. Downstream Structure/Plan could implement these as hard-required fields and break resumed runs.

**Fix:** Add a "Compatibility — legacy config.md without routing fields" subsection to G1's Recommendation. State:
- If `model_routing:` is absent from `config.md`, all dispatches route to trusted path (Anthropic models). No cheap-path dispatch occurs without explicit configuration.
- If `providers:` is absent, only the default trusted-path provider (Anthropic) is available. Any `model_routing:` entry referencing a missing provider fails loudly at run start (existing fail-loud rule).
- At run resume, the orchestrator emits a one-time warning when `model_routing:` is absent: "config.md has no model_routing block; all dispatches will use the trusted path. Re-run goals to add cost-opt routing."
- No auto-mutation of `config.md` — the user invokes Goals (or hand-edits) to add the blocks. This matches the no-backcompat-cruft preference (runtime-backfill default, not perpetual compat logic).

Add a design-level test bullet: "Legacy-config test: a `config.md` without `model_routing:` or `providers:` resumes successfully; all dispatches route to trusted path; the warning is emitted once per resume."

### R3-F01 quality-claude (medium) — Wrong Decision cross-reference

The Cross-cutting test strategy "Hygiene contract (G7 + G18)" subsection at design.md line ~1061 cites "per Decision 9" but the rationale (G7 enforcement via self-check + reviewer visibility, not BATS) lives in Decision 4. Decision 9 is about not adding new reviewer agents (different topic).

**Fix:** Replace "per Decision 9" with "per Decision 4" in that cross-cutting bullet. Verify Decision 9 reference (if any) elsewhere in the file is intentional.

### R3-F02 quality-claude (medium) — G14 dependents three-way disagreement

Three places list G14's dependents inconsistently:
- G14's own dependency note: G7/G8/G9/G11/G12/G15/G18
- Decision 7: omits G11 from the list of G14 consumers
- Decision 4 + G7's test strategy: G7 has no markdown-inspection BATS pin (round-2 narrowing), so G7 should NOT be in G14's dependents list

Resolution direction: G7 has no BATS backstop per the round-2 narrowing, so G7 is removed from G14's dependents. Final dependent set: G8, G9, G11, G12, G15, G18.

**Fix:** Update three locations to the canonical dependent set (G8, G9, G11, G12, G15, G18):
- G14 "Dependency note" subsection: replace the G7/G8/G9/G11/G12/G15/G18 list with the canonical set.
- Decision 7 (around lines 920-933): update the bulleted dependent list to match — add G11 (missing), remove G7.
- G14 sequencing prose elsewhere: scan and reconcile if any other location lists dependents.

### R3-F01 scope-codex (medium) — G14 helper function signatures too implementation-specific

G14's "Initial function surface" subsection lists exact function names + argument-shaped signatures (`extract_section <file> <section_heading>`, `grep_in_section <file> <section_heading> <pattern>`, `assert_section_contains <file> <section_heading> <pattern>`). Function signatures are Plan/Structure/Implement-owned per DEFERS contract.

**Fix:** Replace the typed-signature list with behavior-level descriptions:
- A function that extracts content between an H2/H3 heading and the next same-level heading, failing loudly on empty extracts or missing anchors.
- A convenience wrapper that extracts a section then greps within it.
- A BATS-shaped assertion variant with diagnostic on miss.
- A `REPO_ROOT` resolution guard sourced from `BATS_TEST_DIRNAME` + `git rev-parse`.

Leave exact function names and parameter shapes to Plan/Structure/Implement.

### R3-F02 scope-codex (medium) — Exact BATS test filenames throughout design.md

Six locations name exact BATS test filenames (lines 367-368, 415-416, 552, 684, 749, 815):
- `tests/unit/test-parallelize-owns-defers-contains-setup-validation.bats`
- `tests/unit/test-parallelize-vocab-canonical.bats`
- `tests/unit/test-implementer-commit-no-scratch.bats`
- `tests/unit/test-replan-skips-ideas.bats`
- `tests/unit/test-ci-workflow-shape.bats`
- `tests/unit/test-no-version-tokens-in-prose.bats`
- (plus G14 itself: `tests/unit/test-helper-skill-markdown.bats`)

Exact filenames are Plan/Implement-owned per DEFERS.

**Fix:** Replace each exact filename with a behavior-level pin description. Examples:
- "BATS pin: `tests/unit/test-parallelize-owns-defers-contains-setup-validation.bats` asserts the OWNS list contains a line matching the canonical pattern." → "BATS pin: a unit test asserts the OWNS list contains a line matching the canonical pattern."
- "BATS pin. `tests/unit/test-no-version-tokens-in-prose.bats` scans evergreen markdown files for version tokens and stale references." → "BATS pin: a CI-runnable unit test scans evergreen markdown files for version tokens and stale references."

Apply same transformation at every site. Keep the behavior description; drop the filename.

## Fix dispatch plan

Single fix subagent. Subagent receives:
- Path to design.md
- Paths to the 5 finding files
- Per-finding fix guidance above

Subagent reports diff summary. Round 4 reviewers fire after fix-subagent confirmation.

## Status

draft → fixing → (post-fix) → re-review round 04.

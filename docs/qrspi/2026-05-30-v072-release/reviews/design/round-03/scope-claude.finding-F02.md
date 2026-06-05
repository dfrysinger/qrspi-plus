---
finding_id: R3-F02
severity: low
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/design.md:L211
  - docs/qrspi/2026-05-30-v072-release/design.md:L1507-L1508
  - docs/qrspi/2026-05-30-v072-release/design.md:L596-L598
  - docs/qrspi/2026-05-30-v072-release/design.md:L2128
  - docs/qrspi/2026-05-30-v072-release/design.md:L3004
artifact: design
round: 3
reviewer: scope-claude
---

**Drift category — full assertion text in acceptance criteria (installed v0.7.1 OWNS/DEFERS).** The installed contract DEFERS "Full assertion text (literal `expect(...).toEqual(...)` lines)" to Implement (TDD). Design OWNS "Test strategy at the design level. What types of tests (unit, integration, E2E), what layers get tested, what frameworks. Behavior-level — assertion text and per-test-file layout are deferred." Several acceptance-criteria sites author the specific test-content the bats suite must contain.

**Concrete sites.**

- **CD-1 acceptance (L211).** "An executable smoke test exercises a tier-resolved-to-`none` dispatch and asserts the dispatcher halts with the loud diagnostic per CD-1 #2's no-silent-fallback rule. Form: a single bats test invoking `dispatch-agent.sh` against a `config.md` fixture with one tier set to `none` and an agent targeting that tier; asserts non-zero exit and a diagnostic written to stderr naming the unconfigured tier." This is per-test-case authoring with assertion conditions ("non-zero exit", "diagnostic written to stderr naming the unconfigured tier") — Implement-altitude content under the installed contract's "Full assertion text" + "per-test-file layout" DEFERS.
- **G14 acceptance (L1507-1508).** "A bats test asserts the verifier rubric contains the literal `Informational:` token in the carve-out clause (regression guard against accidental rubric edits removing the branch). A bats test asserts the reviewer-protocol section is present and contains both the prefix-shape definition and the distinction-from-acknowledged-and-silenced paragraph." Two per-test-file assertions named with their content.
- **CD-4 §H.6 acceptance (L596-598).** "Fixture rounds covering each halt cause × each `orchestrator_rescue` value × each interaction mode produce the expected outcome... Tier 1 mechanical rescue fires silently under rescue=true (no user prompt, not in drift_count) and is logged to `orchestrator_fixes[]`. Tier 1-shaped halt under rescue=false surfaces an escalation menu (interactive) or drops + drift_count++ (auto). Fixture asserts the menu fires for the trivial `category:` rename case." Per-fixture assertion conditions with expected behavior enumerated case-by-case.
- **G26 acceptance (L2128).** "Verification: `bats tests/unit/ 2>&1 | grep -iE \"BW0[0-9]|warning|deprecat\"` against HEAD `6d04842` returns only test-name lines (tests *describing* warnings the project itself emits...); zero bats-core warnings on stderr across 1322 tests." A literal grep pipeline with expected output shape — Implement-altitude verification command.
- **G35 acceptance (L3004).** "`tests/lint/test-structure-altitude-boundary-include.bats` exists and passes on a tree where both consumer source files carry the `!cat skills/_shared/structure-altitude-boundary.md` line; fails (with a halt message naming the missing file) when either consumer source has the include removed." Names the test file path AND the literal include line AND the halt-message shape — three layers of per-test detail.

**Why this matters under the installed contract.** "Test strategy at the design level" is what (types, layers, frameworks); "Full assertion text" is what each test asserts. Authoring the literal assertion content forecloses Plan's per-task `Test Expectations` and Implement's TDD authoring. The R2 scope finding made the same point at the earlier (now-removed) `## Test Strategy` section's T2/T3/T5 sub-blocks; the same pattern reappears scattered across per-goal Acceptance subsections.

**Note on G34's proposed loosening (advisory, NOT applied to this finding).** G34 D2 (L2889) proposes Design OWNS includes "acceptance criteria including concrete examples and rough test-pairing shapes (e.g., 'one bats file per script under `scripts/`'; naming the shape is acceptance-criteria-altitude — authoring the test code is Plan/Implement's job)." Under G34 the "rough test-pairing shape" wording would bless naming the test name + the smoke-test class — but G34 still distinguishes "naming the shape" (OWNS) from "authoring the test code" (DEFERS). Sites that name a literal grep command (L2128), specific assertion conditions like "asserts the verifier rubric contains the literal `Informational:` token" (L1507), or the literal include-line content the test must check (L3004) cross even G34's looser line. So most of these sites remain drift even after G34.

**Recommended disposition.** Operator override at human gate per PI-HKP-005. If the operator wishes to bring the cited sites into altitude, replace literal-assertion text with shape-only references: e.g., L1507 becomes "regression-guard bats test for the verifier rubric's Informational-carve-out clause (presence assertion shape; Plan authors the exact assertion text)"; L3004 becomes "lint bats test for the new shared-snippet include's presence in both consumer source files (Plan authors the assertion shape)." This preserves the design-altitude commitment (these tests will exist; the verifier rubric / shared-snippet include is the guard target) while deferring per-test-file authoring to Plan/Implement per the installed DEFERS list.

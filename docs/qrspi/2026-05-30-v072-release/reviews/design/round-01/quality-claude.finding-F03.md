---
finding_id: F03
artifact: design
reviewer: quality-claude
round: 1
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/design.md
---

## No unified test strategy — test types and what is tested at each level are not stated at design level

### Where

`design.md` — entire file. The design quality check requires: "the design includes a
testing approach; it names the test types (unit, integration, contract, e2e) and explains
what's being tested at each level."

### What is present

Individual goal blocks contain per-goal test notes, but they are scattered across 37
sections and use inconsistent vocabulary:

- **G21**: "lint test as gate" (bats) — a lint test type appears here for the first time
- **G19**: "verified at next self-host signal cycle" — self-host as acceptance mechanism
- **G28**: "bats test asserts the verifier rubric prose contains the literal `defect_class:` token"
- **G22**: "grep across skills/*/SKILL.md for `model: 'sonnet'` returns zero hits" — a grep-based acceptance criterion
- **G32**: "acceptance test for the resolver" + "smoke test" — resolver fixtures, install smoke test
- **G4**: `round-prepare.sh` has bats unit tests (implied)
- Multiple goals explicitly say **"No test coverage"** (G19's cite-check correctness, G20's `actual_model:` field)

### What is missing

There is no section that answers at the design level:

1. **What test types does this release use?** (bats unit, bats lint, integration via self-host
   signal, e2e smoke tests, script acceptance fixtures — all are used, none are defined
   as the release test taxonomy)

2. **What does each test type cover?** For example:
   - Bats unit tests → script behavior in isolation
   - Bats lint tests → structural invariants across the test suite (G21 pattern)
   - Self-host signal → LLM-agent behavioral correctness (cite check, prompt-prose rules)
   - E2E smoke tests → install artifact and plugin load (G32)
   - Grep-based acceptance → prose parity and field-name drift (G22, G24)

3. **What is explicitly out of scope for automated testing and why?** Several goals defer
   correctness verification to self-host signal rather than unit tests. The rationale is
   per-goal ("LLM agent file, not a script") but is never stated as a design-level
   principle.

4. **What is the gap between the test surface and ship confidence?** Goals like G19 (Cite
   Check correctness: deferred to self-host signal), G20 (actual_model emission:
   "self-host signal if field is missing from >5% of emissions"), and G28 (defect_class
   correctness: v0.7.3 calibration pass) rely on the next self-host run as their
   verification mechanism. An implementer reading individual goal blocks may not realize
   the extent to which this release's correctness acceptance rests on post-ship signal.

### Why this matters

An implementer planning tasks needs to know which test type to use for a given deliverable.
A test-coverage reviewer needs to know what "adequate coverage" means across the release.
A phasing author needs to know which tests must be green before each ship gate. Without a
design-level test taxonomy, each of these roles must reconstruct the test strategy from 37
individual sections — and they may reconstruct it differently.

### Minimum adequate fix

A short unified test strategy section (5–10 bullet points) near the top of `design.md`
or at the end of the Cross-Goal Decisions section, stating:

- The four or five test types used in this release and what each covers
- The principle for when self-host signal is the acceptance mechanism vs. automated test
- Which critical paths have explicit "No test coverage" and why (with a pointer to the
  per-goal rationale)

The per-goal test notes do not need to change; the unified section summarizes and
cross-links them.

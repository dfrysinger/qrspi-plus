---
status: approved
task: 44
phase: 1
pipeline: full
goal_ids: [G24]
task_type: code
model: sonnet
---

# Task 44: G24-F05 anti-pattern pin regex hardening

- **Target files:** modify `tests/unit/test-using-qrspi-vocab.bats`; modify `tests/acceptance/v07-phase1/test-phase1-acceptance.bats`; minimally edit `skills/using-qrspi/SKILL.md` if and only if a one-phrase semantically-equivalent rewrite is required to resolve the constraint conflict between the regex's `substitut` branch (DoD bullet 3) and the existing settled prose (the negated-form clause "does not silently substitute defaults" in the missing-`model_routing:` H4 body).
- **Dependencies:** [Task 17, Task 40]
- **LOC estimate:** ~80

**Overview**

Harden the G24-F05 silent-fallback prose pins so they guard the contract's meaning instead of one brittle sentence, then add phase-level acceptance coverage for the hardened pin behavior. The work lands after the dispatch-routing prose settles and stays limited to the four existing pin sites plus their release acceptance surface. (Why: see goals.md ### G24. Approach: see design.md ## G24.)

**Scope**

- **In:**
  - Replace the four existing literal pins for `silently fall back to the agent-bundled default` in `tests/unit/test-using-qrspi-vocab.bats` with in-place regex assertions matching the silent-fallback semantic family rather than that exact phrase.
  - Ensure each rewritten negative regex assertion has a same-`@test` `$body` presence guard (`[ -n "$body" ]`) before the regex is evaluated, so missing or empty extracted bodies fail loudly.
  - Cover equivalent silent-fallback regressions such as `silently substitutes the bundled default`, `silently degrades to the agent default`, and `no silent fallback to a neighboring tier`, while allowing prose that does not describe silent fallback/default behavior.
  - Add release-level coverage in `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` proving the hardened vocab pins are in the phase acceptance path and the semantic negative cases trip the pin.

- **Out:**
  - Consolidating repeated `using-qrspi` per-H4 fail-loud prose, centralizing tier vocabulary regexes, parameterizing dispatch-routing assertion callers, or promoting H4 extraction into shared bats helpers — all four of these G24-F01/F02/F03/F04 surfaces are moot in v0.7.2 per design.md ## G24 (F01/F03 helpers and target files do not exist in current tree; F02 auto-resolves via CD-1; F04 absorbed into the G3/CD-1 dispatch rewrite).
  - Adding a new shared bats helper or utility for the regex pin pattern — explicit non-goal for this four-site surface.
  - Editing the dispatch-routing prose itself — upstream dispatch-routing tasks settle that prose; this task only hardens the pins against the settled wording.

**Definition of done**

- The four literal-substring pins in `tests/unit/test-using-qrspi-vocab.bats` are replaced in place by regex assertions that match silent-fallback intent instead of the exact historical sentence.
- Each rewritten assertion is preceded earlier in the same `@test` block by `[ -n "$body" ]`; no bare `[[ ! "$body" =~ ... ]]` pattern can silently pass on an empty body.
- The regex rejects equivalent contract regressions including `silently substitutes the bundled default`, `silently degrades to the agent default`, and `no silent fallback to a neighboring tier`.
- The regex allows prose that does not describe silent fallback/default behavior.
- The unit test remains green against the post-dispatch-routing prose produced by the earlier schema, validation, and fail-loud-invariant edits.
- `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` exercises the hardened vocab pins as part of phase acceptance and proves the semantic negative cases trip the pin.
- The diff stays scoped to the four pin sites and their acceptance coverage: no new shared bats helper, no new test utility, and no unrelated assertions rewritten.

**Test expectations**

- Inspect `tests/unit/test-using-qrspi-vocab.bats` and confirm the four old literal `silently fall back to the agent-bundled default` pins no longer appear as literal-only assertions.
- Grep or targeted test inspection confirms each rewritten pin has `[ -n "$body" ]` earlier in the same `@test` block before the negative regex assertion.
- Negative-case coverage demonstrates the regex trips on `silently substitutes the bundled default`, `silently degrades to the agent default`, and `no silent fallback to a neighboring tier`.
- Positive/non-regression coverage demonstrates prose without silent-fallback/default semantics is allowed.
- Run the touched unit test so `tests/unit/test-using-qrspi-vocab.bats` passes against the settled dispatch-routing prose.
- Run the phase acceptance coverage in `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` that proves the hardened vocab pins participate in the release-level acceptance path and the semantic negative cases trip the pin.
- Audit the diff to confirm no shared helper, new bats utility, or unrelated assertion rewrite was added.

**References**

- goals.md ### G24 — G24-F05 problem framing: literal anti-pattern pins can silently miss rephrased silent-fallback regressions.
- design.md ## G24 — post-audit re-scope to F05 only, regex-pin deliverables, `$body` guard requirement, and acceptance criteria.
- structure.md ### `tests/unit/test-using-qrspi-vocab.bats` — per-file test block for the four in-place silent-fallback regex pins and G21 guard inheritance.
- structure.md ### `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` — per-file release acceptance block for G24 regex-pin survival and semantic negative cases.

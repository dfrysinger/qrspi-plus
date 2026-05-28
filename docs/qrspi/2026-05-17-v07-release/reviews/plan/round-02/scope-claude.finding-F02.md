---
finding_id: R2-F02
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L1126-L1127]
artifact: plan
round: 2
reviewer: scope-claude
---

The T37 test expectations specify a concrete regex family as the detection criterion for the summary-shim invariant pin (added by test-coverage-claude.R1-F04 to make the pin "falsifiable"):

> "The detection pattern is concretely specified so the BATS pin is falsifiable: a dispatch site is flagged when its prompt-composition prose contains an angle-bracketed `<summary-of …>` token, a phrase matching the regex family `(summary|condensation|digest|recap) of [A-Za-z./_-]+\.(md|json|yml|yaml)` used as the prompt's source-of-truth payload, OR an explicit reference to a derived-summary intermediate file (e.g., `*.summary.md`, `*.digest.md`) substituted for the original stable artifact."

This crosses into assertion-text territory — Plan DEFERS "Full assertion text / `expect(...)` / test code → Implement-TDD." Authoring the literal regex used to classify a dispatch site as a summary-shim is equivalent to writing the detection algorithm in the plan spec. The regex `(summary|condensation|digest|recap) of [A-Za-z./_-]+\.(md|json|yml|yaml)` is an implementation artifact (Implement-TDD writes the `grep`/`awk` command that applies it), not a plain-language behavioral expectation.

The intent behind the fix (making the pin falsifiable) is legitimate — the test expectation block before the fix lacked a concrete definition of what constitutes a summary-shim dispatch, making the pin specification vacuous. The right resolution is to keep the behavioral description in plain language and add a falsifiability anchor without specifying the regex. For example:

- "The detection pattern distinguishes summary-shim dispatch sites (where a derived condensation of a stable artifact is substituted as the prompt source-of-truth) from verbatim-Read sites and Mechanism B narrow-read sites; the distinction is concretely defined in the BATS file itself rather than in the task spec."
- "A fixture summary-shim site causes a test failure; a fixture verbatim-Read site does not; a fixture Mechanism B narrow-read site does not."

The exclusion clauses (verbatim Reads excluded, Mechanism B excluded, human-facing digests excluded) are behavioral boundary statements that Plan can and should own — those should be kept. Only the specific regex literal should be removed and left for Implement-TDD to author.

The affected text runs from approximately "a dispatch site is flagged when..." through "Human-facing digest surfaces are excluded when the dispatch site is documented as user-presentation..." — roughly the final paragraph of T37's test expectations block. The remedy is to replace the regex-literal specification with plain-language behavioral boundary statements, keeping the three exclusion categories but removing the specific regex family `(summary|condensation|digest|recap) of [A-Za-z./_-]+\.(md|json|yml|yaml)` and the `<summary-of …>` token form.

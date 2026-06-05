---
status: approved
task: 7
phase: 1
pipeline: full
goal_ids: [G14]
task_type: code
model: opus
---

# Task 07: G14 verifier rubric correction for `Informational` findings

- **Target files:** `skills/reviewer-protocol/SKILL.md` (modify), `agents/qrspi-finding-verifier.md` (modify), `tests/unit/test-verifier-agent-file.bats` (modify)
- **Dependencies:** Task 06. **Blocks:** T08 (G19 verifier wholesale-hallucination rubric work extends the same verifier file after this carve-out is in place).
- **LOC estimate:** ~100

**Overview**

Formalize the reviewer `Informational:` message-prefix convention and add the matching verifier rubric branch so informational observations are scored on structural confidence instead of the false-positive rubric. This keeps real informational observations in the audit trail while still dropping informational claims whose premise is wrong. (Why: see goals.md ### G14. Approach: see design.md ## G14.)

**Scope**

- **In:**
  - Add `## Informational Findings` to `skills/reviewer-protocol/SKILL.md`, documenting the literal case-sensitive `Informational:` prefix at the start of the first non-blank `message` line, intended use for real observations with no demanded action, downstream structural-confidence scoring, log-only behavior, and unchanged behavior for findings without the prefix.
  - Insert the G14 Informational-carve-out clause in `agents/qrspi-finding-verifier.md` immediately before the existing false-positive-pattern list so first-non-blank-line `Informational:` findings bypass false-positive scoring and receive structural-confidence anchors of 75 / 50 / 25.
  - Extend `tests/unit/test-verifier-agent-file.bats` to pin both prose surfaces: the verifier carve-out and the reviewer-protocol section.
  - Preserve the existing verifier sidecar extension and required sidecar-field assertions in `tests/unit/test-verifier-agent-file.bats` while adding the G14 assertions.

- **Out:**
  - Changing the verifier sidecar path, `.score.md` extension, or required sidecar fields — T06 owns; this task only preserves those existing assertions.
  - Adding hallucination / citation-mismatch screening to the verifier rubric — T08 owns.
  - Adding a structured sixth finding field such as `actionability:` or changing the canonical 5-field finding schema — design.md ## G14 defers that option to v0.7.3 signal.
  - Updating reviewer agent bodies to emit the prefix automatically; this task documents the convention and verifier behavior, but reviewers opt in by using the prefix.
  - Reworking the acknowledged-and-silenced false-positive case; existing CLAUDE.md / feedback silencing remains in the false-positive rubric.

**Definition of done**

- `skills/reviewer-protocol/SKILL.md` contains a `## Informational Findings` section in the G14-specified location and documents prefix shape, intended use, downstream behavior, log-only handling, and backward compatibility for unprefixed findings.
- `agents/qrspi-finding-verifier.md` contains the G14 Informational-carve-out before the false-positive-pattern list, with literal `Informational:` detection on the first non-blank `message` line and structural-confidence scoring anchors for structurally verifiable, partially verifiable, and premise-wrong findings.
- `tests/unit/test-verifier-agent-file.bats` fails against the pre-change verifier/protocol prose and passes only when both G14 prose surfaces are present with the required anchors.
- Existing verifier sidecar extension and required sidecar-field assertions in `tests/unit/test-verifier-agent-file.bats` remain intact.
- No changes are made to the canonical 5-field finding schema or to reviewer agent bodies.

**Test expectations**

- RED check: the added `tests/unit/test-verifier-agent-file.bats` assertions fail before implementation when the verifier lacks the `Informational:` carve-out before the false-positive-pattern list.
- Verifier-prose audit: the test passes only when `agents/qrspi-finding-verifier.md` contains the literal case-sensitive `Informational:` token, the first-non-blank-line detection rule, and the 75 / 50 / 25 structural-confidence anchors for structurally verifiable, partially verifiable, and premise-wrong informational findings.
- Reviewer-protocol audit: the test passes only when `skills/reviewer-protocol/SKILL.md` contains `## Informational Findings` and documents the prefix shape, intended use, downstream structural-confidence scoring, log-only handling, and unchanged behavior for findings without the prefix.
- Regression guard: existing `.score.md` sidecar extension and required sidecar-field assertions in `tests/unit/test-verifier-agent-file.bats` still pass after the informational-rubric assertions are added.

**References**

- goals.md ### G14 — problem framing for the verifier's wrong-rubric treatment of reviewer-labeled informational observations.
- design.md ## G14 — selected prose-prefix convention, verifier carve-out text, placement rules, acceptance criteria, and schema-migration deferral.
- structure.md ### `skills/reviewer-protocol/SKILL.md` — reviewer-protocol placement and required Informational section contents.
- structure.md ### `agents/qrspi-finding-verifier.md` — verifier insertion site and structural-confidence rubric anchors.
- structure.md ### `tests/unit/test-verifier-agent-file.bats` — test file responsibility for G14 rubric pins plus existing G11 sidecar assertions.

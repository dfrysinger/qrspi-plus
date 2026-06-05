---
task: 7
round: 2
fanin_decision: terminal-clean-with-deferred-finding
---

# T07 R2 Fan-In

## Reviewer outcomes (6/6)

| Reviewer | Model | Verdict |
|---|---|---|
| spec-claude | claude-sonnet-4.6 | CLEAN |
| spec-codex | gpt-5.3-codex | CLEAN |
| code-quality-claude | claude-sonnet-4.6 | CLEAN |
| code-quality-codex | gpt-5.3-codex | CLEAN |
| silent-failure-claude | claude-sonnet-4.6 | CLEAN |
| silent-failure-codex | gpt-5.3-codex | CLEAN |
| security-claude | claude-sonnet-4.6 | CLEAN (with residual architectural note — explicitly not-a-finding) |
| security-codex | gpt-5.3-codex | 1 HIGH finding (F01) |

## Divergence on sec-codex F01

Both security reviewers identified the SAME issue (the R1 confused-deputy guard is prose-only, not structurally enforced by the verifier). They diverge on framing:

- **sec-codex (HIGH F01):** "documented but not enforced, so the prefix-injection suppression path remains exploitable." Frames as an in-scope correctness gap.
- **sec-claude (not-a-finding):** "The guard is prose-MUST-NOT, not structural enforcement. The verifier cannot verify post-hoc whether a reviewer's `Informational:` was self-authored or injected. This is inherent to the LLM-prose architecture and not a gap introduced by this diff."

## Disposition: DEFER sec-codex F01 to v0.7.3 backlog

**Rationale:**

1. **T07 spec scope** is the Informational-prefix carve-out + the verifier rubric branch — NOT meta-enforcement of artifact-vs-reviewer provenance in the verifier. Structural enforcement would require the verifier to (a) have access to the original artifact text, (b) perform a semantic re-classification (does this finding logically warrant Informational treatment?), and (c) introduce a new test surface for the enforcement. That is a substantial architectural change properly authored as a separate task.

2. **The R1 fix already added the strongest mitigation available at this scope.** The reviewer-protocol prose now explicitly tells reviewers to NOT honor artifact-directed `Informational:` suggestions (the confused-deputy guard at SKILL.md:157), and the new bats test #35 pins the semantic anchors (`confused.deputy|artifact.directed`, `reviewer.authored`) in CI. If a reviewer correctly follows the protocol, the verifier never sees a confused-deputy `Informational:` prefix. If a reviewer is prompt-injection-compromised, EVERY prose-MUST contract in QRSPI is at risk — that is a defense-in-depth concern broader than this single carve-out.

3. **sec-claude's matching judgment** ("inherent to the LLM-prose architecture and not a gap introduced by this diff") is the dispositive structural argument. The structural enforcement layer sec-codex wants belongs in a separate v0.7.3 task (e.g., "verifier structural-enforcement of reviewer-vs-artifact provenance for Informational findings").

## v0.7.3 backlog item carried forward

**Title:** Structural-enforcement of confused-deputy semantics in qrspi-finding-verifier

**Spec sketch:** Extend `qrspi-finding-verifier` to detect findings whose `Informational:` prefix is plausibly artifact-directed (e.g., by re-reading the original artifact and looking for matching `Informational:` directives embedded in untrusted content, then re-scoring such findings on the standard rubric instead of the informational carve-out). Requires the verifier to gain artifact-read access (which it currently lacks by design) and a new test surface.

## R1 deferred findings still carried (unchanged)

- sec-claude R1 F02 (sidecar Informational field) — T06 territory, out-of-scope per T07 spec "Out:" list
- cq-codex R1 F02 (awk|grep extraction helpers) — same defect class as cq-codex T05 R3 F02 (test file modularization)
- sf-codex R1 F02 (pre-existing `|| true` lines 10/66/118/153) — not introduced by T07

## Decision: T07 terminal CLEAN at HEAD `a0bb0b8`

Fix-cycles consumed: 1 of 3 (R1 fix-cycle). R2 has no in-scope findings requiring a fix-cycle.

Proceed to Wave 6 (T08).

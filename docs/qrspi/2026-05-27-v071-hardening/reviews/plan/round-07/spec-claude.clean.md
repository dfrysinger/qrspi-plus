---
status: clean
reviewer: spec-claude
round: 7
artifact: plan.md
---

# Spec Review — Round 7 — Clean

## Scope this round

R6→R7 diff is narrowly scoped to Task 7's two mock-sentinel test-expectation bullets (Copilot CLI path and Claude Code path). Reviewed against the R6 finding that flagged "provides evidence" as undefined.

## R6 finding resolution

The R6 finding objected that "captured stdout provides evidence that the dispatch invoked the mock transport rather than falling back" was not a falsifiable behavioral assertion — a test author could not derive a concrete check from "provides evidence."

R7 wording replaces "provides evidence" with:

> captured stdout contains a distinguishable marker string emitted by the mock transport (a value the mock produces and no other code path produces), proving the dispatch invoked the mock rather than falling back

This converts the expectation to a specific, falsifiable test:

- **Assertion target**: presence of a marker string in captured stdout (concrete, greppable).
- **Marker source**: emitted by the mock transport (clear ownership — the mock authors the token).
- **Uniqueness criterion**: "a value the mock produces and no other code path produces" — the falsifiability anchor. Without this clause, an author could pick a string that fall-through paths also emit, defeating the test. With it, the test must use a sentinel (e.g., a unique token, UUID, or path-unique literal) that only the mock can produce, so absence proves fall-through and presence proves mock invocation.
- **Negative bound retained**: "exit code 0 alone is insufficient proof" — forecloses the degenerate test where the dispatch silently falls through to a different success path.

Symmetric treatment for both transport paths (task-tool mock for Copilot CLI; `scripts/run-codex-review.sh` mock for Claude Code).

A test author reading this bullet can implement the test without further interpretation: have the mock print a sentinel token to stdout; in the acceptance test, grep stdout for the token and fail if absent. R6 finding resolved.

## Other findings

None within the diffed surface. None observed outside the hinted surface.

## Confirmed set-asides (not raised)

- S1. DKR6 mismatch warning-only
- S2. Task 6 atomicity
- S3. Auth-failure
- S4. codex_reviews absent
- S5. Plan length

---
status: hallucinated
artifact: integration
round: 6
reviewer: integration-codex
model: gpt-5.5
disposition: dropped
disposition_reason: Reviewer output references files, content, and prior findings that DO NOT EXIST in this repository or the actual round-06 diff. Verified by direct grep + Read of cited locations.
materialized_by: orchestrator
---

# Round 6 — integration-codex (gpt-5.5) — HALLUCINATED OUTPUT (DROPPED)

## Summary

integration-codex returned a "HIGH" severity finding R6-F01 claiming the new missing-block validator at `skills/using-qrspi/SKILL.md:516` introduces the forbidden term `widen` ("a widen/ref value"), conflicting with an existing vocab test at `tests/unit/test-using-qrspi-vocab.bats:53-55`. **None of this is true.**

## Verification trace

1. **SKILL.md:516 actual content** (verified by Read):
   > `When \`config.md\` does not contain a \`model_routing:\` block, the dispatcher fires a one-time in-memory warning:`

   The cited string "a widen/ref value" appears nowhere in SKILL.md. The only occurrence of "widen" in the entire file is at L1029 in an unrelated context (scope_hint "widening the diff back to base-branch").

2. **tests/unit/test-using-qrspi-vocab.bats:53-55 actual content** (verified by Read):
   Lines 53-55 are inside the `_extract_h4` helper function body (awk substring match). There is NO `widen` ban test in this repository's `test-using-qrspi-vocab.bats` file. The reviewer cited a test that does not exist.

3. **The reviewer's "tool_uses" output revealed it read fabricated content**, including:
   - A fake "Fix Task 01 — Close R5-F01 Silent-Fallback Validator Gap" spec (no such file exists at the cited path)
   - A fake `tests/unit/test-using-qrspi-vocab.bats` file with hallucinated tests about "ESCAPED" terminology, "MCP", "sign-off", "blacklist", and a "widen" ban (none of which appear in the actual file)
   - Fake R3/R4/R5 findings about "scope_hint", "CLEAN_FILES", "NO_FINDINGS files", and "narrowed-diff fallback to base branch" — none of these findings exist in our `reviews/integration/round-*/` directory

## Why this matters as a red flag

This is the second gpt-5.5 reviewer reliability incident this run (the first was R4 ICX-F02 mischaracterizing the intentional inherit→sonnet collapse, dropped at verifier score 22). Pattern:

- R4: gpt-5.5 mischaracterized intentional design as defect (verifier 22 caught it)
- R6: gpt-5.5 invented files and content wholesale (no verifier needed; direct read invalidates)

The first failure mode (mischaracterization) is caught by the finding-verifier protocol. The second failure mode (whole-cloth fabrication) is NOT caught by the verifier — the verifier would have scored the hallucinated finding on its surface plausibility against the real artifact (where SKILL.md:516 ≠ "widen/ref value"), but the orchestrator caught it earlier via direct verification because the claim was so specific that a 30-second grep refuted it.

The other 3 R6 reviewers (integration-claude, security-claude, security-codex) all returned CLEAN with detailed grounded reasoning. integration-codex's hallucination does not invalidate the R6 convergence verdict.

## Disposition

**DROP — no fix-task, no further action.**

## Filed as post-PR red-flag issue

This incident is logged in the post-PR follow-up list as: "gpt-5.5 reviewer hallucination — R6 integration-codex invented entire file contents while the same reviewer (different model? different run?) returned CLEAN in security-codex R6 with grounded grep audit. Worth investigating whether the prompt structure (long companion-artifact lists, multi-paragraph diff context) triggers gpt-5.5 to hallucinate when uncertain rather than admit uncertainty."

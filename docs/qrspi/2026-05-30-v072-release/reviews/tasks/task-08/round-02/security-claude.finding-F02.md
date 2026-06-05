---
finding_id: R2-F02
severity: medium
change_type: scope
artifact: code
round: 2
reviewer: security-claude
model: claude-sonnet-4.6
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L1073-L1095
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L1098-L1253
---

# Acceptance tests bypass verifier execution entirely — Cite Check logic has no runnable end-to-end coverage

**Problem:** `_t8_write_finding_pair` writes both the finding `.md` file and the pre-scored `.score.md` sidecar in one helper call. TC4–TC7 then invoke only `verifier-fan-in.sh` against those pre-written sidecars. The `qrspi-finding-verifier` agent is never invoked by any test. The comment at line 1073–1076 is explicit: "IF the verifier were invoked…" — the conditional is load-bearing.

**Attack:** A contributor rewrites step 3.5 of `agents/qrspi-finding-verifier.md` to be a no-op. CI runs the acceptance suite: all 53 tests stay GREEN because the pre-written sidecars still contain `score: 0, HALLUCINATED:`. In production, the actual verifier agent now skips Cite Check; hallucinated findings receive normal rubric scoring (75–100 if prose is confident and plausible).

**Note:** The verifier is a markdown agent-prompt, not an executable binary — it cannot be unit-tested directly. But a behavioral contract test (assert the step 3.5 prose is present and matches the spec's wording) would give stronger assurance. As written, the tests are purely fan-in filter tests, not verifier Cite Check tests.

**Convergence:** Same root cause as security-codex.finding-F03.

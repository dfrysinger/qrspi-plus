---
finding_id: R5-F06
severity: low
change_type: clarity
referenced_files: [tests/unit/test-routing-matrix-application.bats]
---
Stale implementation-time comment (evergreen-output violation). The test "agent sweep: no agent carries a tier other than low or medium after sweep" (~line 2102) carries "# this test will be RED now (no tiers exist...) and GREEN after implementation when all 41 agents have a tier: field". Implementation is complete (all 41 swept); the comment describes a transient drafting state and will mislead a future contributor diagnosing a CI failure. Source: cq-claude F04. Fix: replace with a forward-looking invariant description of what the test asserts (no RED/GREEN drafting narration).

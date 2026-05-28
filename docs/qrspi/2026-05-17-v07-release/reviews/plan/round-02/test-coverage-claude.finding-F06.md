---
finding_id: R2-F06
severity: low
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L898-L901]
artifact: plan
round: 2
reviewer: test-coverage-claude
---

T29 test expectations lack a behavioral test for the "no-blanket-merge prohibition" and do not specify what happens when a quick-tier batch attempts to accept all findings without inline-patching any highs or correctness-mediums. The design.md § G11 requires quick-tier finding-disposition guidance; T29 codifies this in `skills/reviewer-protocol/SKILL.md`. The test expectations check (a) that the section "contains" the guidance and (b) that the section "is reachable via the standard section-anchor convention." Both are documentation-shape checks.

Missing: a behavioral test for the prohibition clause. The prohibition "prohibit blanket quick-tier merges" implies an observable outcome when a blanket merge IS attempted — either the skill produces a named diagnostic or the orchestrator rejects the batch. T29's test expectations do not specify what the caller sees when a blanket quick-tier merge is attempted. Acceptable resolutions: (1) add a behavioral test expectation such as "A quick-tier batch that accepts all findings without inline-patching any high-severity or correctness-medium findings causes the orchestrator to surface a named diagnostic identifying the no-blanket-merge violation" — observable in the apply-fix step output; OR (2) explicitly label the prohibition as an advisory prose-only rule (no behavioral enforcement expected) and state what the test covers (the T30 quick-tier-wording pin asserts the prose exists, which is the complete coverage intended). As written, the test expectations do not distinguish between an enforced prohibition and a documented-but-not-enforced norm, leaving the implementer free to treat the prohibition as unenforceable prose.

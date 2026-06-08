---
finding_id: R1-F01
severity: medium
change_type: scope
referenced_files: ["docs/qrspi/2026-06-04-v073-release/goals.md:L142", "docs/qrspi/2026-06-04-v073-release/goals.md:L185"]
artifact: goals
round: 1
reviewer: scope-codex
---

The goals artifact includes per-goal acceptance criteria ("Acceptance must include…" / "Acceptance must measure…"). Under `skills/goals/owns-defers.md`, acceptance criteria are deferred to Design (test strategy) and Plan, and goals.md should not enumerate them. Fix by reframing these as open considerations for downstream artifacts (or removing them here) rather than acceptance requirements.

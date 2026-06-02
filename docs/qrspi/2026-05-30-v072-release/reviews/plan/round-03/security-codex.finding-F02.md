---
reviewer_tag: security-codex
change_type: correctness
severity: medium
artifact: plan.md
location: Task 40 BW02 minimum-version rule Test expectations
referenced_files: [plan.md]
---

# F02 — BW02 minimum-version hardening lacks explicit bypass/regression tests

Task 40 defines a BW02 lint "surface" with initial trigger `run --separate-stderr` and asks reviewers to confirm the rule exists (`plan.md` lines 2305, 2320, 2330), but does not require adversarial tests that the version-check cannot be bypassed.  
As written, an implementation could pass by matching trigger text while still missing fail-closed behavior for common bypasses (e.g., non-effective/minplaced guard, commented guard, malformed guard, or parser edge cases), and the plan's acceptance contract would not catch it.  
Given this task is now the canonical G26 deliverable, the test contract should require seeded bypass fixtures that must fail, not just presence/review of the rule surface.

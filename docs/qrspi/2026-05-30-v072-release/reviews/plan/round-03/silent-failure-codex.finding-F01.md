---
reviewer_tag: silent-failure-codex
change_type: correctness
severity: high
artifact: plan.md
location: Task 40 — Scope + Definition of done + Test expectations; BW02 rule bullets
referenced_files: [plan.md]
---

# F01 — BW02 lint rule is specified as diagnostic-only, not guaranteed fail-closed

Task 40's BW02 language consistently requires diagnostics (`file:line`, triggering feature) but never explicitly requires a non-zero test failure when a violation is found (`plan.md` lines 2305, 2320, 2330).  
That creates a log-and-continue interpretation for version-guard regressions (`run --separate-stderr` without `bats_require_minimum_version`), which is exactly the silent-pass class this release is trying to eliminate.  
This conflicts with the locked design requirement that this condition fail CI loudly (design.md G26 acceptance: post-implementation violating file must fail CI), so the plan currently under-specifies fail-loud behavior for BW02.

---
finding_id: BD-2
severity: low
change_type: scope
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 1
reviewer: scope-claude
---

## Task 1 Description includes call-site control-flow detail

> "The helper is called for each header name and each header value in the pre-flight loop; a positive detection result triggers the existing die path before any network call."

Specifies (a) call sites and (b) conditional branch on detection. Control-flow detail belongs to Implement. Plan-appropriate framing: "Every header name and header value is screened before any network call; a control-character match causes the script to abort with a diagnostic." Advisory; test expectations already pin outcomes.

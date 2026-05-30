---
finding_id: R5-F01
severity: medium
change_type: modified
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 5
reviewer: security-codex
---

Auth failure scenario is not explicitly required for Codex dispatch paths (Tasks 6/7)

Tasks 6/7 don't require an unauthenticated/unauthorized Codex access case. Reviewer suggests pinning an unauthorized-case expectation (non-zero + clear auth error propagation, no fallback/silent success).

DISPOSITION NOTE: This is a RECURRING SET-ASIDE — auth-failure handling for Codex dispatch is existing dispatcher infrastructure handled by run-codex-review.sh's auth layer; the R4 Task 7 added a generic "correctly-routed transport failure propagates non-zero" expectation which subsumes auth failure as a specific case. Not a plan-level scope-add. Set aside.

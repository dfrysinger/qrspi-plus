---
finding_id: R4-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 4
reviewer: security-codex
---

Fail-open host/config mismatch in Codex dispatch (Task 6 + Task 7)

Plan now requires that detected-host vs codex_reviews mismatch logs warning and continues dispatch. Reviewer argues this removes fail-closed guard on environment/config integrity disagreement; a misconfigured or manipulated environment routes through wrong transport without hard failure.

NOTE FOR FIX-SYNTHESIS: This is set-aside. Design DKR6 line 55 explicitly says: "emit a one-line diagnostic naming the disagreement" — diagnostic only, not fail-closed. Goals.md G6 candidate C selected with same intent. The R3 fix correctly aligned plan with approved design. Reviewer is asserting security-best-practice that contradicts the approved design.

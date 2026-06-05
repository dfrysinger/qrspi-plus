---
finding_id: R4-F01
severity: medium
change_type: clarity
referenced_files:
  - skills/reviewer-protocol/SKILL.md:L65-L67
  - tests/unit/test-per-finding-file-emission.bats:L269-L278
artifact: code
round: 4
reviewer: code-quality-codex
---

The new `finding_id` section says the sequence number is "zero-padded," but the documented schema regex (`^R\d+-F\d+$`) allows unpadded values like `F1`. The new test also pins this looser behavior, so the contradiction is now entrenched rather than clarified.

This is a maintainability issue: future implementers won't know whether padding is required or optional. Tighten one side so they agree (either enforce padding in regex/tests, or relax wording to remove "zero-padded").

---

**Orchestrator disposition (R4 final review, fix-cycle budget exhausted):** ACCEPTED-WITH-ISSUES. Per skill cap rule ("If round-4 still has findings, escalate (do NOT dispatch a 4th fix-cycle)"), this is escalated rather than fixed. The contradiction is a 2-character edit (relax wording OR tighten regex/test) but cannot land in this release per the cap. Captured for v0.7.3 task: "Resolve `finding_id` zero-padded vs `^R\d+-F\d+$` regex contradiction in reviewer-protocol SKILL.md and test pin".

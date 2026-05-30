---
finding_id: R6-F01
severity: medium
change_type: modify
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md, docs/qrspi/2026-05-27-v071-hardening/goals.md]
artifact: plan
round: 6
reviewer: spec-codex
---

Task 7 mocked transport success bullets no longer specific/testable (G6 acceptance non-verifiable)

"provides evidence" too ambiguous. G6 requires deterministic per-host dispatch correctness.

Fix: replace with explicit machine-checkable criteria (e.g., exact sentinel string/regex per transport, plus absence of opposite transport's sentinel).

DISPOSITION: Same finding as testcov-claude R6-F01 and testcov-codex R6-F01. Apply middle-ground wording. Three reviewers converging on this signal: the R5 fix went too far in scope-deference direction. Restore "distinguishable marker" wording.

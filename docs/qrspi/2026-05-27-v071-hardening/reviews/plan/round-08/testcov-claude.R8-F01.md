---
finding_id: R8-F01
severity: high
change_type: testability
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 8
reviewer: testcov-claude
---

Task 9 per-file tier-token presence assertion overspecified; likely unreachable GREEN and omits inherit. Each file declares exactly ONE tier in frontmatter. Lint built from this expectation will fail GREEN on correctly-modified files. Also omits inherit despite Task 9 description naming all four tier-name tokens.

R7-F01 closure note: Manual Validation block (line 274) cleanly addresses the per-file-diff verifiability concern from R7-F01. Baseline-relative removal succeeded; new finding is about the replacement's final-state shape.

DISPOSITION: ACCEPT. Convergent with quality-codex, traceability-codex, spec-codex. Resolved in R9 by removing the over-constrained bullet.

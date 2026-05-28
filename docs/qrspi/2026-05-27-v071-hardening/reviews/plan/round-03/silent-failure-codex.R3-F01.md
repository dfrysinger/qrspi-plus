---
finding_id: R3-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 3
reviewer: silent-failure-codex
---

Task 6 still designs a silent fallback for malformed host signals (SILENT_FALLBACK)

Problem: detect_host returns claude-code with exit 0 for any COPILOT_CLI value other than 1 (including 0, true, empty). This is silent fallback by design.

Why mismatch diagnostic does not fully cover it: mismatch only triggers when codex_reviews config disagrees with detected host. If config is absent/defaulted/aligned to claude-code, malformed host signaling is not surfaced.

Silent runtime impact: wrong transport/model-routing path can be selected without explicit host-detection error.

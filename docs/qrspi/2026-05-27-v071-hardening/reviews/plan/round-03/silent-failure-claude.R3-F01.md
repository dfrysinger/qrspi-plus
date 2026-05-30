---
finding_id: R3-F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 3
reviewer: silent-failure-claude
---

SILENT_FALLBACK: Task 6 detect_host fallback to claude-code not fully covered by mismatch diagnostic

detect_host now returns "claude-code" in two structurally different situations: legitimate Claude Code and unexpected truthy COPILOT_CLI like `=true`. The mismatch diagnostic only fires when detect_host output disagrees with codex_reviews config.

Realistic silent cases:
- Case B: COPILOT_CLI=true + codex_reviews=claude-code → both say claude-code → no mismatch → wrong transport silently
- Case C: COPILOT_CLI=true + codex_reviews absent → no check fires → wrong transport silently

No test expectation covers either case.

Fix direction: add test expectation that when COPILOT_CLI is truthy-but-non-1 AND codex_reviews is absent or consonant with the wrong detection, the dispatch surface still emits a diagnostic. Alternatively, require detect_host itself to emit a stderr warning (without changing exit code) when COPILOT_CLI is non-empty non-1.

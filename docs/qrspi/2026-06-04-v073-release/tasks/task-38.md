---
status: approved
task: 38
phase: 1
pipeline: full
goal_ids: [G9]
task_type: tdd
tier: low
---

# Task 38: Create tests/lint/test-skill-trim-audit.bats grep audit

- **Target files:** `tests/lint/test-skill-trim-audit.bats` (Create)
- **Dependencies:** T32, T33, T34, T35, T36
- **LOC estimate:** ~35
- **Description:** A grep audit asserts zero matches across all active SKILL.md files for the documented narrative-restatement patterns: `jobId`, `tmpfile`, `HEAD~1`, `narrow.broaden`, `sidecar.*schema`, `change_type:.*enum`, `verifier.*threshold`, `third-party.*splitter`. The audit's scope is narrative restatements only — concrete script names in process-step calls (e.g., `scripts/round-prepare.sh`, `scripts/verifier-fan-in.sh`) are allowed and not flagged. The lint runs in CI on every PR; reintroduction of script-mechanic restatement narrative is mechanically blocked.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - "A grep-based audit confirms zero matches across all active SKILL.md files for the following patterns: `jobId`, `tmpfile`, `HEAD~1`, `narrow.broaden`, `sidecar.*schema`, `change_type:.*enum`, `verifier.*threshold`, `third-party.*splitter`" (G9 Acceptance bullet 8, verbatim).
  - A fixture skill body that re-introduces a `jobId` narrative restatement fails the lint with a named diagnostic naming the file, line, and offending pattern (fail-direction guard).
  - Concrete script names in process-step calls (e.g., `scripts/round-prepare.sh`) are allowed — a fixture skill body with such a call does not trigger the lint (no-false-positive guard).

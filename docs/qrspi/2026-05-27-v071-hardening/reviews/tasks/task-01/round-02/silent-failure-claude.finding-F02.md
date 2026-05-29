---
reviewer: silent-failure-claude
task: 1
round: 2
finding: F02
severity: low
change_type: correctness
status: pending
model: claude-sonnet-4.6
persistence_note: Claude returned findings inline. Orchestrator manually persisted.
referenced_files:
  - scripts/run-third-party-llm.sh
duplicate_of: silent-failure-codex.finding-F01.md
---

## NUL pre-flight: both `wc -c` calls failing produces empty counts (treated as 0=0), silently passing NUL detection

**Location:** `scripts/run-third-party-llm.sh`, lines 598–602

Same empty-string-as-zero pattern as F01 (and convergent with silent-failure-codex F01 — independent finding by both reviewers). If either `wc -c` invocation fails to produce numeric output, both `_raw_file_bytes` and `_raw_no_nul_bytes` may be empty; `[ "" -ne "" ]` → false → NUL bytes in config.md go undetected.

**Why this is more severe than F01:** `_control_char_check` is a belt-and-suspenders layer; the NUL pre-flight is a **single-layer** control (no fallback) because bash strips NUL at variable assignment.

**Suggested fix:** Validate both counts are non-empty integers before comparing.

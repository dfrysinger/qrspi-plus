---
reviewer: spec-gpt55
task: 1
round: 1
finding: F01
severity: blocking
change_type: correctness
status: pending
model: gpt-5.5
timestamp: 2026-05-28T18:44:00Z
agent_id: t01-r1-spec-gpt55
persistence_note: OpenAI-family models under copilot-task-tool transport return findings in chat only — orchestrator manually persists per audit-trail discipline. See GH issue #213 (Codex) + pending issue for gpt-5.5 (same root cause).
referenced_files:
  - scripts/run-third-party-llm.sh
  - tests/unit/test-run-third-party-llm.bats
  - docs/qrspi/2026-05-27-v071-hardening/tasks/task-01.md
---

## NUL die-path diagnostic does not identify the offending header name

**Spec requirement:** Two normative bullets in `tasks/task-01.md` test expectations:
1. "Every C0 control byte ... in a header value causes the script to exit ... with the standardized die-path diagnostic" (line 1370)
2. "The die message identifies the offending provider and header name" (line 1383)

**Implementation gap:** The NUL pre-flight scan operates at file scope (it must, because bash strips NUL at variable-assignment time, so the scan must happen before the awk parse populates HEADER_NAMES / HEADER_VALUES). The resulting die message:

```
die "header-validation: config.md for provider '$PROVIDER' contains NUL bytes in header configuration"
```

(`scripts/run-third-party-llm.sh` lines 598-601; diff lines 53-57)

names the provider but NOT the offending header name. Compare to the value-side `_control_char_check` path, which fires post-parse and CAN name `$header_name`.

**Test gap:** The NUL test only asserts the `header-validation:` prefix and provider mention (`tests/unit/test-run-third-party-llm.bats` lines 1221-1242). It does NOT assert that the offending header name appears in the message, so the impl-spec mismatch passes the test suite.

**Triage options for apply-fix:**

A. **Spec relaxation.** Acknowledge that for NUL specifically, header-name extraction is structurally impossible from a bash variable (the byte vanishes at assignment). Amend the task spec to carve out NUL: "NUL die message identifies the offending provider; header name extraction not required for NUL." Update test to assert only what's achievable.

B. **Implementation restructure.** Replace the file-scope `wc -c` delta scan with a line-by-line awk pass that flags any line whose pre-parse byte count differs from its post-parse byte count, then extracts the header name token from that line BEFORE bash variable assignment strips the NUL. Higher complexity; preserves spec verbatim.

C. **Hybrid.** Keep file-scope scan for the existence detection (cheap), but on positive detection re-run a per-line scan to localize the offending line and extract the header name. Same diagnostic precision as B with smaller hot-path cost.

Recommend A for v0.7.1 (smallest blast radius; spec text was authored before the bash-NUL-stripping constraint surfaced as the design gap that Test-Writer flagged at TE-6) and capture the choice in the task done-report.

**Why Claude (spec-claude.clean.md) missed this:** Claude validated against the 12 normative bullets and stopped at TE-6 (NUL exit behavior); did not cross-check bullet TE-7-ish ("die message identifies offending provider and header name") against the NUL code path specifically. Sample-vs-cross-product test coverage gap, mirrored in the reviewer attention.

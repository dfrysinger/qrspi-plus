---
reviewer: spec-gpt55
task: 1
round: 1
finding: F02
severity: blocking
change_type: scope
status: pending
model: gpt-5.5
timestamp: 2026-05-28T18:44:00Z
agent_id: t01-r1-spec-gpt55
persistence_note: OpenAI-family models under copilot-task-tool transport return findings in chat only. Manually persisted by orchestrator.
referenced_files:
  - tests/unit/test-run-third-party-llm.bats
  - docs/qrspi/2026-05-27-v071-hardening/tasks/task-01.md
duplicate_of: spec-codex.finding-F01.md
---

## Tests do not cover "every C0 byte" as required (duplicate of spec-codex F01)

Same calibration question raised by spec-codex F01 — gpt-5.5 independently flagged the literal-exhaustive reading of "every C0 byte" (32 explicit tests required) vs the test-writer's universal-quantified-over-equivalence-class reading (4 representative C0 bytes for value-side, 2 for name-side).

See `spec-codex.finding-F01.md` for the full orchestrator counter-reading. Claude's overruling reasoning (the 12 normative bullets assert a universal property which representative testing verifiably establishes given the tr-range implementation has no per-byte branching) applies identically here.

Two independent OpenAI-family reviewers reaching the same finding raises the calibration question's signal: both saw the spec wording differently than Claude did. Orchestrator triage stance: defer to Claude's structural argument (tr-range equivalence class) unless human reviewer wants to override.

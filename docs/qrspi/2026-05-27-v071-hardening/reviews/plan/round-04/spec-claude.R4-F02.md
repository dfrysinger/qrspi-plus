---
finding_id: R4-F02
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 4
reviewer: spec-claude
---

Task 8 self-referential grep assertions in test-phase1-acceptance.bats lack pattern-specificity guidance

Absence assertions live INSIDE test-phase1-acceptance.bats but grep that same file for SPIKE export and run_pin invocations. After implementer removes them, the assertion's own grep arg lines (`run grep "run_pin.*test-cache-control-capability-gate"`) still contain those strings. Unanchored pattern matches itself. Test stuck at RED.

Fix options:
1. Constrain patterns to anchored forms (e.g., `^ *run run_pin `, `^export SPIKE=`) and specify in plan.
2. Move absence assertions to a separate test file that greps test-phase1-acceptance.bats from outside (follows precedent of test-run-third-party-llm.bats greping external scripts/run-third-party-llm.sh).

Recommend option 2 — cleaner and eliminates self-reference entirely.

---
finding_id: R5-F01
severity: low
change_type: scope
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/plan.md]
artifact: plan
round: 5
reviewer: scope-claude
---

Task 6 env-var closure-property over-prescribes test fixture details

R4 fix changed "unrelated env vars" (testcov-codex R4-F01 — unfalsifiable) to a closure property over TERM, HOME, PATH, SHELL, USER, PWD held constant. But the enumerated vars and "two invocations" structure are test-fixture design (Implement-TDD layer).

Behavioral property Plan OWNS: detect_host output is determined solely by COPILOT_CLI.

Fix: "detect_host output is determined solely by COPILOT_CLI; the presence or absence of other environment variables does not affect the result"

DISPOSITION: ACCEPT — refine to pure behavioral form. The testcov-codex F01 worry (unfalsifiability) is addressed by the "determined solely by" framing without enumerating fixture vars.

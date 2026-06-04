---
finding_id: R1-F02
severity: major
change_type: intent
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
reviewer_tag: spec-codex
---

Test coverage does not enforce the DoD DETECTION_TYPE contract on override outputs.
The override tests (L180-231) assert only `VERDICT`/`EVIDENCE`, and the output-shape
test (L385-445) checks `DETECTION_TYPE` only for the Copilot and unknown-host branches.
This allows a missing `DETECTION_TYPE` (and `PLATFORM`) in override mode to pass
undetected. Add assertions that the override path emits an in-enum `DETECTION_TYPE`
and a `PLATFORM` line, and extend the output-shape test to cover the override branch.

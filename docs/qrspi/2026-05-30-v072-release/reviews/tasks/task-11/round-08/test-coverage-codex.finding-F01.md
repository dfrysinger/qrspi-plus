---
reviewer_tag: test-coverage-codex
round: 8
finding_id: R8-F01
severity: low
change_type: scope
referenced_files: [tests/acceptance/v07-phase1/test-phase1-acceptance.bats]
---

# F01 — AC5 (end-to-end first-party dispatch) missing `dispatch_spec.subagent_type` assertion

## Finding

Task 11 test expectation (task-11.md:43-48) requires:
> "Exercise a first-party reviewer dispatch and inspect `.dispatch-manifest.json` for a `dispatch_spec` object containing `subagent_type`, `host`, `vendor`, `model`, and `prompt_file`."

AC5 (`tests/acceptance/v07-phase1/test-phase1-acceptance.bats:2566-2633`) is the only test that exercises a real end-to-end first-party reviewer dispatch (via `bash scripts/run-codex-review.sh`). It asserts `prompt_file`, `host`, `vendor`, and `model` (lines 2621–2630) but does NOT assert `dispatch_spec.subagent_type`.

AC2 (line 2307–2373) does assert `subagent_type` (line 2357–2358), but uses a direct helper-function call (`emit_first_party_manifest_entry "$prompt_file"`) and synthetic globals — it is a unit-test of the manifest helper, not an end-to-end test of the dispatch path.

## Severity rationale

LOW: production code at scripts/run-codex-review.sh:431-437 does write `subagent_type` correctly; AC2's helper test would catch a regression in `emit_first_party_manifest_entry`. The end-to-end gap exists only if a regression breaks the call-site assembly between the dispatch path and the helper (a narrow surface area, but covered by the explicit test expectation language).

## Suggested fix

Append one line to AC5 (after line 2630):
```bash
jq -e '.[0].dispatch_spec.subagent_type | type == "string" and length > 0' "$manifest" >/dev/null \
  || { echo "dispatch_spec missing subagent_type"; cat "$manifest"; return 1; }
```

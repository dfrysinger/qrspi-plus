---
finding_id: F01
severity: medium
change_type: correctness
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
---
FINDING C's negative assertion `! echo "$output" | grep -q '^PLATFORM=claude-code$'` (new round-05 test, bats ~line 578 / diff +756) is VACUOUS under bats `set -eE`: a `!`-prefixed pipeline is exempt from ERR-trap triggering, so when the forbidden `PLATFORM=claude-code` token IS present in output, the trap does not fire and the test silently passes — defeating its purpose as the COPILOT_CLI-over-CLAUDE_PROJECT_DIR precedence regression guard (the exact gap round-04 tc-codex F01 / tc-claude F04 asked to close). Recommended fix: `run grep -q '^PLATFORM=claude-code$' <<< "$output"; [ "$status" -ne 0 ]`. NOTE: same defect exists at pre-existing lines 267 and 306 (out of scope here — pre-existing, not round-05 additions). ORCHESTRATOR: MATERIAL — acting on this (single-line corrective, test-only, non-refactor). sf-codex's competing FINDING-B vacuity claim (its F01) is a FALSE POSITIVE — sf-claude's careful analysis shows empty `$output` yields one empty here-string line that fails the KEY=VALUE regex → return 1 → test fails correctly.

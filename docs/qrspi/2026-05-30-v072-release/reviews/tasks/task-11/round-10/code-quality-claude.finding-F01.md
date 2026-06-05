---
reviewer_tag: code-quality-claude
round: 10
finding_id: R10-F01
severity: medium
change_type: clarity
referenced_files: [scripts/run-codex-review.sh]
---

# F01 — `_install_fp_traps` / `_cleanup_fp_tmp` defined inside main-flow if-block instead of hoisted

## Finding

The two FIX-AB helpers (`_install_fp_traps` and `_cleanup_fp_tmp`) are defined INSIDE the `if [[ "$_detected_host" == "copilot-cli" ]]` main-flow block in scripts/run-codex-review.sh (around lines 907-925), rather than being hoisted to the function-definitions section alongside `_append_manifest_fail` (which IS correctly hoisted before the `QRSPI_SOURCE_ONLY` guard).

This creates structural asymmetry with FIX-AA's helper, and inlines function definitions into procedural flow. Functionally it works — bash defines the functions when the `if` block is entered, and they're only used inside that block — but conventionally function definitions belong at the top of the file with other helpers.

## Suggested fix

Move both `_install_fp_traps` and `_cleanup_fp_tmp` to the file's function-definitions section (the same area where `_append_manifest_fail` lives, near `_append_manifest_entry`). Update the header comments to indicate the helpers are scoped to the first-party (copilot-cli) dispatch block.

## Severity rationale

MEDIUM — structural/clarity issue, not a bug. The asymmetry with `_append_manifest_fail` (correctly hoisted) is the actionable signal. Other reviewers (sf-codex, sec-codex, cq-codex) flagged no issue with placement; this is cq-claude's structural-convention judgment call.

## R11 bundling note

If R11 fires for any additional findings from sf-claude/sec-claude, bundle this with them. If this is the only finding, the question is whether one structural move warrants another cap-bend cycle (cap-bend 9) vs. accept-with-issues + defer to v0.7.3 backlog.

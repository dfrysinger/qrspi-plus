---
finding_id: R4-F01
reviewer: code-quality-codex
round: 4
severity: medium
change_type: clarity
referenced_files:
  - scripts/dispatch-agent.sh
status: open
---

# Manifest command strings not safely encoded for paths with spaces

**Where:** `scripts/dispatch-agent.sh:423-424`

**Issue:** `await_cmd` and `split_cmd` are serialized as plain space-delimited strings:
- `"$REPO_ROOT/scripts/dispatch-companion.sh await $job_id"`
- `"$REPO_ROOT/scripts/third-party-finding-splitter.sh --round-dir $OUTPUT_DIR --tag $REVIEWER_TAG"`

`await-round.sh` later parses these with `shlex.split` (await-round.sh:171-175). If `$REPO_ROOT` or `$OUTPUT_DIR` contains spaces, argv tokenization breaks and argv[0] becomes invalid, causing drain failures.

**Why this is a quality problem:** The fix improves absolute-path correctness, but the command transport format is still brittle and environment-dependent (path-shape assumptions).

**Suggested fix:** Emit manifest commands with shell-escaped tokens (e.g., `printf %q` per token) or, better, store structured argv arrays in JSON instead of a single command string.

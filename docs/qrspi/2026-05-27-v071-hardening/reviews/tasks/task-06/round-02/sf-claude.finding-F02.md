---
finding: F02
round: 2
reviewer: sf-claude
file: scripts/run-codex-review.sh
line: 550
change_type: correctness
severity: medium
title: compose_prompt failure silently masked — pipefail disabled on dispatch pipeline
---

## Summary

Both dispatch paths (lines 550 and 554) use the same pattern:

```bash
compose_prompt | bash "$DISPATCHER" "${DISPATCHER_ARGS[@]}"
exit "$?"
```

With `set -o pipefail` **not** active (confirmed by the comment at line 51:
"pipefail is off because the dispatcher handles its own error contract"), the
pipeline exit code is always taken from the *last* command — the dispatcher.
If `compose_prompt` fails mid-execution (partial output, file not found, awk
error, etc.), the dispatcher receives truncated or empty input on stdin, and the
pipeline's exit code reflects only the dispatcher's response to that bad input.

If the dispatcher exits 0 despite receiving malformed/incomplete prompt input
(e.g., because it validates lazily, or times out and returns 0, or interprets
EOF as end of a valid empty prompt), the overall dispatch reports success while
the prompt was never correctly assembled.

## Relevant code

```bash
# line 546-555 (task-06 addition):
if [[ "$_detected_host" == "copilot-cli" ]]; then
  echo "[transport: task-tool]" >&2
  compose_prompt | bash "$DISPATCHER" "${DISPATCHER_ARGS[@]}"
  exit "$?"
else
  echo "[transport: shell-pipeline]" >&2
  compose_prompt | bash "$DISPATCHER" "${DISPATCHER_ARGS[@]}"
  exit "$?"
fi
```

The `compose_prompt` function assembles the reviewer-protocol body, agent body
(with YAML stripped), codex-emission override, companion files, scalar fields,
diff file, scope hint, and dispatch-parameter block from multiple disk reads.
Any of those reads can fail.

## Failure scenario

1. `compose_prompt` encounters a missing required file and exits 1 after
   emitting partial output to the pipe.
2. The dispatcher reads the truncated prompt, processes it (or times out), and
   exits 0.
3. The pipeline exit is 0 — the caller sees success.
4. The output file (`--output-file`) may be empty or contain a review based on
   an incomplete prompt.  No error is surfaced.

This is a **log-and-continue** variant: the upstream failure (compose_prompt)
goes unreported because the pipeline exit code only reflects the downstream
component.

## Note on the comment justification

The comment "pipefail is off because the dispatcher handles its own error
contract" explains why pipefail was *originally* omitted (the dispatcher had
its own logic).  Task 06 introduces a second stage upstream of the dispatcher
(`compose_prompt`), making the original justification insufficient for the new
pipeline shape.

## Fix

Enable `set -o pipefail` for the dispatch pipelines, or capture
`compose_prompt` output separately and check before dispatching:

```bash
# Option A: enable pipefail just for the dispatch block
(
  set -o pipefail
  compose_prompt | bash "$DISPATCHER" "${DISPATCHER_ARGS[@]}"
)
exit "$?"
```

```bash
# Option B: fail-fast before dispatch
_prompt="$(compose_prompt)" || { echo "error: compose_prompt failed" >&2; exit 1; }
printf '%s' "$_prompt" | bash "$DISPATCHER" "${DISPATCHER_ARGS[@]}"
exit "$?"
```

Option B avoids the subshell but buffers the full prompt in memory; acceptable
for the typical prompt sizes here.

## Relation to task spec (TE16 / TE17)

TE16 and TE17 assert that a non-zero **transport** exit code is propagated.
Those tests use a mock dispatcher and never exercise `compose_prompt` failures.
The gap they leave is exactly the `compose_prompt` failure path described here.

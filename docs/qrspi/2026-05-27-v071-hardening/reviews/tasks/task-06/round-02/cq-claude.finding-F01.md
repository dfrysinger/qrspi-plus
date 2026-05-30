---
reviewer: cq-claude
round: 2
finding: F01
change_type: style
file: scripts/run-codex-review.sh
lines: "548-555"
severity: minor
---

# F01 — Duplicated dispatch body in transport if/else

## Location
`scripts/run-codex-review.sh` lines 548–555 (diff lines 111–119):

```bash
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

## Problem

Both branches execute the identical dispatch call and exit.  The only
difference between them is which marker string is echoed to stderr.
Duplicating `compose_prompt | bash "$DISPATCHER" "${DISPATCHER_ARGS[@]}"` and
`exit "$?"` across both arms means a future change to the dispatch invocation
(a new flag, a timeout wrapper, a different pipe shape) must be applied in two
places, with no mechanical enforcement that they stay in sync.  Readers
scanning the if/else have to diff both halves mentally to confirm there is no
intentional asymmetry — which obscures rather than communicates the intent.

## Recommended fix

Hoist the shared dispatch after the if/else; keep only the marker echo inside
each branch:

```bash
if [[ "$_detected_host" == "copilot-cli" ]]; then
  echo "[transport: task-tool]" >&2
else
  echo "[transport: shell-pipeline]" >&2
fi
compose_prompt | bash "$DISPATCHER" "${DISPATCHER_ARGS[@]}"
exit "$?"
```

This makes the design explicit: the transport selection affects only the
diagnostic marker; the actual dispatch mechanism is identical on both paths.
All existing test assertions (TE13, TE14, TE16, TE17) remain satisfied.

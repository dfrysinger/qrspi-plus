---
finding: F01
reviewer: sec-claude
round: 2
task: 6
severity: low
change_type: correctness
file: scripts/run-codex-review.sh
lines: [548, 556]
---

# Transport-marker log spoofing: both dispatch branches run identical commands

## Summary

`detect_host` keys entirely on the caller-supplied environment variable
`COPILOT_CLI`.  Any process that can set `COPILOT_CLI=1` before invoking
`run-codex-review.sh` can make the audit log say `[transport: task-tool]`
even though the underlying dispatch is byte-for-byte identical to the
`[transport: shell-pipeline]` path — the two branches call the same
command.

## Vulnerable code

```bash
# lines 548-556  scripts/run-codex-review.sh
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

The `if`/`else` bodies differ in one word of stderr output only; the
actual executable path, dispatcher binary, and all arguments are
identical.

## Concrete attack scenario

An operator or a CI bot parses the stderr stream to confirm which
transport was used and alert if the production workflow uses
`shell-pipeline` in a Copilot-CLI environment.

**Before the attack:** normal Claude-Code run emits
`[transport: shell-pipeline]`, monitoring is satisfied.

**Attack:** A malicious step in the same pipeline (or a wrapping
script) prepends `COPILOT_CLI=1` to the invocation:

```sh
COPILOT_CLI=1 bash scripts/run-codex-review.sh \
  --agent-file agents/... \
  --reviewer-tag ... \
  ...
```

The log now shows `[transport: task-tool]` even though the identical
shell-pipeline dispatch executed.  If a downstream alerting or
compliance system treats `task-tool` as "safe/expected" and
`shell-pipeline` as "anomalous", the attacker has silenced the alert.

Because `COPILOT_CLI` is an ordinary environment variable with no
secret component, any child process, wrapper script, or CI
configuration step can supply it.

## Why it matters

The spec (task-06.md §30–31) explicitly promises that the transport
marker tells an operator which routing path ran.  If the marker is
trivially forgeable, the guarantee is hollow.  The two branches
diverge in log output but **not in behavior**, so the marker carries
no ground truth.

## Recommended fix

Either:

1. **Differentiate the actual dispatch commands** between the two
   branches so the marker reflects a real behavioral difference (the
   task-tool path would invoke Codex via the native API / tool rather
   than the generic shell-pipeline dispatcher).  Then the marker
   becomes meaningful.

2. **Or** document explicitly that the marker is an advisory hint
   derived from an untrusted env var and must not be relied upon for
   security decisions.  Pair it with an independent check that cannot
   be forged (e.g., verify the real binary is reachable via the
   task-tool before logging `task-tool`).

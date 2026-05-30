---
reviewer: spec-claude
round: 3
finding: F01
severity: scope-excess
verdict: FLAG
---

# F01 — `eval` elimination + `api_key_env` identifier validation exceeds task-01 scope

## Location

`scripts/run-third-party-llm.sh`, API-key-resolution block (diff lines 109–122):

```bash
# NEW — not in spec
case "$API_KEY_ENV" in
  ''|*[!A-Za-z0-9_]*) die "key-resolution: api_key_env must be a valid shell identifier (for provider '$PROVIDER')" ;;
esac
if ! env | grep -q "^${API_KEY_ENV}="; then
  ...
fi
# Changed — eval replaced with indirect expansion (not in spec)
_API_KEY="${!API_KEY_ENV:-}"
```

## What the spec requires

Task-01 is narrowly scoped: "The control-char detection routine inside the
`openai-chat-completions` security pre-flight block is replaced by a dedicated
internal helper function that is POSIX-clean."

The spec's description and all 12 test expectations are exclusively about
`_control_char_check` for `default_headers` names and values.  Nothing in
task-01 (including the round-1 NUL-carve-out amendment visible in the diff)
mentions:

- How `api_key_env` is dereferenced from the environment (eval vs indirect expansion)
- Any validation gate on the identifier form of `api_key_env`

The existing (pre-task-01) spec tests already cover the two key-resolution
die-paths for **unset** and **empty** env vars (test lines 847–864 of the
bats file).  The new die-path — "api_key_env must be a valid shell identifier"
— is a third key-resolution path not enumerated in any spec test expectation.

## What was added (security-claude F02 fix)

1. A `case` gate that dies with a new message `"key-resolution: api_key_env
   must be a valid shell identifier..."` when `API_KEY_ENV` is empty or
   contains non-identifier characters.
2. Replacement of `eval '_API_KEY="${'"$API_KEY_ENV"':-}"'` with bash indirect
   expansion `_API_KEY="${!API_KEY_ENV:-}"`.

Both changes are correct security hardening (eval-injection defence).  They
were added as a response to a pre-existing security finding (security-claude F02),
not as a task-01 deliverable.

## Why this is a scope finding

The spec reviewer's contract: verify the implementation built exactly what was
requested, not more.  The `eval` elimination introduces:

- A **new observable behaviour**: a novel die-path with a new diagnostic string
  that no spec test expectation validates.  A correctly spec'd test would
  assert `exit 1` + `"valid shell identifier"` for a config with
  `api_key_env: $bad-name` — but no such test exists in the 12 bullets.
- An **implementation constraint** (no eval) that is not stated as a
  requirement.

The `${!var}` substitution itself is safe and non-observable to callers; the
concern is the **identifier validation gate** that generates new output
behaviour untested by the spec.

## Recommendation

The orchestrator has two clean options:

**Option A — Back-name into task-01.md.**  Amend the task-01.md description
to say: "In addition, the `eval`-based API key retrieval is replaced with bash
indirect expansion; a pre-existing guard validates `api_key_env` is a
well-formed identifier before the indirect expansion runs."  Add a 13th test
expectation: "A provider whose `api_key_env` field contains characters outside
`[A-Za-z0-9_]` causes the script to exit 1 with a `key-resolution`
diagnostic."

**Option B — Accept as pre-existing security hygiene outside formal scope.**
Acknowledge in the task record that these two lines were applied from a
pre-existing security review finding (security-claude F02) and do not require
a spec amendment.  The task's formal deliverables (the 12 test expectations)
are fully satisfied regardless.

Either option resolves this finding.  The implementation is **not broken** —
this is a scope-accounting question, not a correctness defect.

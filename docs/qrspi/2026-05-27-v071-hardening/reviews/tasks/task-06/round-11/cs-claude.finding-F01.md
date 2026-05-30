# cs-claude Finding F01 — Duplicated dispatch body in the if/else transport branch

**File:** `scripts/run-codex-review.sh`
**Lines:** 619–627 (post-diff line numbers)
**Category:** Verbose Pattern / Unnecessary Complexity
**Severity:** Advisory / polish backlog
**Security impact:** None — proposed change is semantics-preserving; no path normalization, no
trusted-prefix check, no security guard is touched.

---

## Current code

```bash
if [[ "$_detected_host" == "copilot-cli" ]]; then
  echo "[transport: task-tool]" >&2
  ( set -o pipefail; compose_prompt | bash "$DISPATCHER" "${DISPATCHER_ARGS[@]}" )
  exit "$?"
else
  echo "[transport: shell-pipeline]" >&2
  ( set -o pipefail; compose_prompt | bash "$DISPATCHER" "${DISPATCHER_ARGS[@]}" )
  exit "$?"
fi
```

The two branches are **identical** except for the label string emitted to stderr.
The full subshell pipeline, `exit "$?"`, and `set -o pipefail` are duplicated verbatim.

---

## Problem

Every future edit to the dispatch invocation (e.g. adding a flag to
`DISPATCHER_ARGS`, changing the subshell idiom) must be applied twice and kept
in sync.  The duplication also makes it harder to see at a glance that both
paths run the same dispatch command — the structural repetition implies they
might differ in some meaningful way.

---

## Proposed simplification

Extract the varying label into a variable; run the dispatch body once:

```bash
if [[ "$_detected_host" == "copilot-cli" ]]; then
  _transport_label="task-tool"
else
  _transport_label="shell-pipeline"
fi
echo "[transport: $_transport_label]" >&2
( set -o pipefail; compose_prompt | bash "$DISPATCHER" "${DISPATCHER_ARGS[@]}" )
exit "$?"
```

### Why this is safe

* `detect_host` is unchanged; its security guarantees are not affected.
* The transport label is set to one of two hard-coded literal strings — no
  user-controlled data flows into the variable.
* `exit "$?"` propagates the subshell exit code identically to the current code.
* `set -o pipefail` inside the subshell is preserved.
* The `[transport: …]` stderr message is emitted exactly once, as before.

---

## Why this is out of scope for the `detect_host` narrowing

The finding is in the **call site** of `detect_host`, not inside the function
body.  It is flagged per reviewer-protocol: significant findings outside the
scope hint are reported so the convergence rule can auto-broaden the next diff
ref if needed.

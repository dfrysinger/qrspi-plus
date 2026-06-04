---
finding_id: F01
reviewer: security-codex
model: gpt-5.3-codex
round: 7
task: 11
severity: medium
change_type: correctness
referenced_files:
  - scripts/run-codex-review.sh:930
---

# security-codex — task-11 round-07 — F01 (MEDIUM)

**FIX-M trap-without-exit enables cancellation-bypass.**

The new first-party tmpfile trap handles INT/TERM with:

```bash
trap 'rm -f "$_fp_tmp" 2>/dev/null || true' EXIT INT TERM
```

but does not `exit` on INT/TERM. In bash, trapping INT/TERM without exiting causes execution to continue after the trap.

## Concrete attack scenario

If a supervisor or operator sends SIGTERM/SIGINT to cancel a review before dispatch (e.g., policy timeout, user abort), the script can continue running, still emit `DISPATCH_FILE=...` and persist manifest state, causing unintended dispatch of sensitive prompt contents despite cancellation intent.

## Suggested fix

Same as sf-codex F01 — split into three traps with explicit `exit 130`/`exit 143` on INT/TERM, mirroring the FIX-H pattern in `_append_manifest_entry`.

## Note

This is the same root-cause defect as `silent-failure-codex.finding-F01.md` — same code site, different framing. Two-reviewer convergence is a strong signal that FIX-M needs to be re-fixed (R8).

Reviewer returned chat-only; orchestrator persisted this finding verbatim.

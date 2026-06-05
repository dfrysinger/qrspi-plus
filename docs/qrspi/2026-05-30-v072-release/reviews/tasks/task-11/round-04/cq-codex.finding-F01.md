---
finding_id: R4-F01
reviewer: cq-codex
severity: high
change_type: correctness
referenced_files:
  - scripts/run-codex-review.sh
---

# F01 — DISPATCHER existence check fires BEFORE host routing → first-party path fails when third-party dispatcher missing

**File:** scripts/run-codex-review.sh ~lines 792-796 (DISPATCHER check) and ~895-915 (host-routing branches).

Current order:
```bash
# ~line 792
DISPATCHER="$REPO_ROOT/scripts/run-third-party-llm.sh"
if [[ ! -x "$DISPATCHER" && ! -r "$DISPATCHER" ]]; then
  echo "error: run-third-party-llm.sh not found at $DISPATCHER" >&2
  exit 1
fi
# ... ~100 lines later ...
# ~line 895+
_detected_host="$(detect_host)"
# ... host-conditional dispatch ...
if [[ "$_detected_host" == "copilot-cli" ]]; then
  # first-party branch: writes prompt, emits DISPATCH_FILE, calls
  # emit_first_party_manifest_entry — NEVER invokes $DISPATCHER
  ...
else
  # third-party branch: pipes prompt to $DISPATCHER
  ...
fi
```

Defense-routing violation: the first-party (copilot-cli) branch does not use `$DISPATCHER` at all, yet the up-front check at line ~792 aborts the script when `run-third-party-llm.sh` is missing — even on the first-party path where it would never be invoked.

**Failure mode:** an environment that only has the Copilot CLI installed (no Claude Code shell-pipeline dispatcher) cannot run reviews — the script bails before host detection. The T11 first-party branch's whole point was to add a path that doesn't need the third-party dispatcher; the precondition check defeats that.

**Fix:** move the DISPATCHER existence check INTO the third-party branch, after host routing:

```bash
# Remove the line-792 block entirely. In the host-routing branch:
if [[ "$_detected_host" == "copilot-cli" ]]; then
  # first-party path — no DISPATCHER needed
  ...
else
  # third-party path — check NOW
  DISPATCHER="$REPO_ROOT/scripts/run-third-party-llm.sh"
  if [[ ! -x "$DISPATCHER" && ! -r "$DISPATCHER" ]]; then
    echo "error: run-third-party-llm.sh not found at $DISPATCHER (required for shell-pipeline transport)" >&2
    exit 1
  fi
  # ... pipe prompt to $DISPATCHER ...
fi
```

**Severity HIGH because:** this regression breaks the entire copilot-cli host class. Any v0.7.2 user who only installs the Copilot CLI bits (the smaller, first-party-only install posture) gets a hard failure on every dispatch with a misleading diagnostic that points at the wrong missing file.

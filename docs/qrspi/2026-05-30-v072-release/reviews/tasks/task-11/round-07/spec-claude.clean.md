# Spec Review — Task 11, Round 7: CLEAN

**Reviewer:** spec-claude  
**Round:** 7  
**Artifact:** scripts/run-codex-review.sh + tests/acceptance/v07-phase1/test-phase1-acceptance.bats  
**Verdict:** CLEAN — no findings

## Summary

R7 cap-bend closes all 5 LOW findings from R6 (FIX-J through FIX-N). Each fix was
verified independently against the diff and the on-disk implementation.

### FIX-J — Presence guard on "exit 1 not return 1" inspection test
`scripts/run-codex-review.sh` line 321 carries the anchor text
`"error: mktemp failed for manifest tmp"`. The bats test at lines 2787–2793 now
guards with `grep -q 'mktemp failed for manifest tmp'` before the absence check,
preventing a vacuous-pass when the anchor is absent. ✓

### FIX-K — Removed redundant double `# ---` separator
One of the two consecutive `# ---------------------------------------------------------------------------`
separators before the "Signal-safety and security hardening" section header was
removed (diff lines 74–75). ✓

### FIX-L — Stripped "R6"/"T11" QRSPI-internal tokens from test comments
- `# AC1 — third-party entry: nested dispatch_spec with all T11 provenance`
  → `all provenance` ✓
- `# R6 audit-trail and signal-safety fixes`
  → `# Audit-trail and signal-safety inspection tests` ✓

### FIX-M — `_fp_tmp` signal-cleanup trap (first-party path; subject-code disclosure mitigation)
Script-level `_fp_tmp=""` relay variable declared at line 242.  Immediately after
the mktemp call succeeds (line 923), `trap 'rm -f "$_fp_tmp" 2>/dev/null || true'
EXIT INT TERM` is installed (line 930).  Both error exits (compose_prompt failure,
mv -f failure) clear the relay and disarm the trap.  After successful mv-promotion,
relay is cleared and trap disarmed before calling `emit_first_party_manifest_entry`.
New inspection test "first-party prompt tmpfile has signal-cleanup trap on EXIT/INT/TERM"
(bats lines 2816–2830) verifies all three signal handlers. ✓

### FIX-N — Explicit `_manifest_tmp=""` reset at lock-acquisition (stale-relay hazard)
Reset at script line 282 is inside the `if mkdir "$_lock_dir"` success branch,
after lock acquisition and before the trap install at lines 288–290.  Ordering
confirmed: mkdir_line (274) < reset_line (282) < trap_line (288).  New inspection
test "manifest lock-held block resets _manifest_tmp before trap install"
(bats lines 2835–2855) verifies this ordering programmatically. ✓

## Core task-11 DoD — verified unchanged and intact

- `emit_first_party_manifest_entry` emits `dispatch_spec` with
  `subagent_type`, `host`, `vendor`, `model`, `prompt_file`; `mode=first_party`;
  `status=dispatched` (script lines 417–440). ✓
- `emit_dispatch_manifest_entry` emits `dispatch_spec` with
  `subagent_type`, `host`, `vendor`, `model`; top-level `mode=background`,
  `status`, `job_id`, `await_cmd`, `split_cmd` (script lines 384–408). ✓
- Atomic append via mkdir-as-mutex + mktemp + jq parse-and-append intact. ✓
- Orchestrator payload stays prompt-file reference: first-party path emits only
  `DISPATCH_FILE=<path>` on stdout (script line 948). ✓
- All four spec test expectations covered: AC1 (third-party), AC2+AC5
  (first-party), AC3 (repeated/multi-tag), AC5 (prompt-file-ref contract). ✓

## Scope check

Diff touches only `scripts/run-codex-review.sh` and
`tests/acceptance/v07-phase1/test-phase1-acceptance.bats`.
`skills/using-qrspi/SKILL.md` was updated in prior rounds; no R7 change needed. ✓
No unrequested features, flags, or helpers added. ✓

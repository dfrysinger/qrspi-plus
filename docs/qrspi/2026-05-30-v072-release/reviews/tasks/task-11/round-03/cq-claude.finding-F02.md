---
finding_id: R3-F02
reviewer: cq-claude
severity: med
change_type: correctness
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats
---

# F02 — AC4 concurrent test uses timing-dependent barrier; false-pass risk on loaded CI

**Novel finding.** AC4's purpose is to maximize collision probability at the R-M-W site by releasing N=5 subshells simultaneously. The current barrier:
- Each subshell spins on `[[ ! -f "$SYNC_FILE" ]]`
- Parent sleeps 0.3s then touches the file

On a heavily loaded CI host (low-resource container, I/O-contended NFS), sourcing the 830-line script can take longer than 0.3s. Subshells that haven't reached their spin-loop when the barrier releases will proceed to call `_append_manifest_entry` sequentially rather than concurrently — completely defeating the test's collision-inducing purpose.

This is NOT a traditional flake (test won't fail spuriously). It is a **false-pass risk**: the test can report green on a broken concurrency implementation if timing degrades enough that no two writes overlap.

**Fix:** replace the fixed sleep with per-subshell acknowledgement files. Each subshell writes `"$SYNC_FILE.ready.$i"` after sourcing but before entering its spin-loop; parent counts acks until all N are present before touching the barrier. Guarantees all subshells are at the spin-loop regardless of host speed.

```bash
# In each subshell:
touch "$SYNC_FILE.ready.$i"
while [[ ! -f "$SYNC_FILE" ]]; do sleep 0.01; done
_append_manifest_entry ...

# In parent:
while [[ $(ls "$SYNC_FILE".ready.* 2>/dev/null | wc -l) -lt 5 ]]; do sleep 0.05; done
touch "$SYNC_FILE"
```

---
finding_id: F01
severity: medium
change_type: scope
artifact: structure
referenced_files:
  - /Users/dfrysinger/code/qrspi-plus-v0.7.2/docs/qrspi/2026-05-30-v072-release/structure.md
---

## Test block still contains assertion-level details after the R12 fix

The rewritten `tests/unit/test-second-reviewer-available.bats` block is not fully back at Structure altitude. Although the executable command and mutation-fixture wording were removed, the test bullets still specify assertion-level details:

- `non-zero exit`
- exact stderr token `` [second-reviewer-unavailable] ``
- proof-style wording that the script "reads `_resolve-lib.sh`'s matrix/default lookup rather than a parallel hardcoded host table"

**Location:** structure.md:1793-1796

Structure owns test-file layout and behavior-level coverage summaries, but defers assertion text and test mechanics to Plan/Implement.

**Fix:** Keep this at behavior altitude, e.g. "Pins unavailable-host handling" and "Pins shared-matrix integration," without exit-code checks, stderr-token assertions, or proof mechanics.

(Persisted by orchestrator from Codex chat-only return.)

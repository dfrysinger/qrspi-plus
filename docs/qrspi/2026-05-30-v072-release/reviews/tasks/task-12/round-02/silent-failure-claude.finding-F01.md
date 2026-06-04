---
finding_id: R2-F01
reviewer_tag: silent-failure-claude
round: 2
task: 12
severity: medium
change_type: correctness
referenced_files:
  - tests/unit/test-round-prepare.bats
---

## F01 — Backward-loop deletion-failure test does not assert sidecar correctness

`tests/unit/test-round-prepare.bats` lines 464–484 (deletion-failure test).

The test verifies (1) `status=0`, (2) diagnostic in `$output`, (3) flag path still present. It does NOT assert `.round-prepare.json` was written or its content is correct.

After deletion failure, `round-prepare.sh` sets `BACKWARD_FORCED=1`, then continues through diff write (step 7) and sidecar write (step 8). The sidecar is the artifact downstream consumers read for narrow/broaden decisions.

A future regression that skipped or corrupted the sidecar on this code path would still pass this test — the orchestrator would silently consume a wrong/absent sidecar and dispatch reviewers with incorrect parameters.

**Fix — add to the test:**
```bats
[ -f "$TASK_DIR/round-03/.round-prepare.json" ]
python3 -c "
import json
d=json.load(open('$TASK_DIR/round-03/.round-prepare.json'))
assert d['narrowed'] is False, d
assert 'backward-loop' in (d.get('reason') or ''), d
"
```

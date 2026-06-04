---
finding_id: silent-failure-claude.finding-F01
severity: high
change_type: correctness
artifact: code
round: 2
reviewer: silent-failure-claude
referenced_files:
  - scripts/verifier-fan-in.sh#L269-L275
  - agents/qrspi-finding-verifier.md#L11
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L1098-L1280
---

## HALLUCINATED finding with `change_type: scope` or `change_type: intent` silently reaches kept-findings.txt

### The gap

`scripts/verifier-fan-in.sh` lines 269–275 apply an **always-keep** rule for
`scope` and `intent` findings: they are added to `KEPT_PATHS` and written to
`kept-findings.txt` unconditionally, with **no score check at all**:

```bash
scope|intent)
  # Always-keep: scope/intent flow to the orchestrator pause gate
  # rather than the score filter.
  KEPT=$((KEPT + 1))
  KEPT_PATHS+=("$finding")
  ;;
```

The G19 / Task-08 design uses `score: 0` as the HALLUCINATED sentinel. It
relies on existing threshold semantics to drop hallucinated findings. That
works for `correctness` (threshold 70), `style` (80), and `clarity` (80) —
all of which drop any finding with score < threshold. But the always-keep
arm for `scope` and `intent` has **no threshold** and therefore never drops
anything, including `score: 0`.

### Concrete failure path

1. A reviewer emits a `scope`-typed finding that cites a fabricated file.
2. The verifier runs Step 3.5 Cite Check, finds the file absent, writes
   `score: 0` with `reason: HALLUCINATED: file nonexistent.md does not exist`.
3. The fan-in reads `score: 0` and `change_type: scope`.
4. The fan-in hits the `scope|intent` arm → unconditionally keeps the finding.
5. The HALLUCINATED finding appears in `kept-findings.txt` and propagates to
   the orchestrator pause gate — the exact outcome G19 was designed to prevent.

The failure is entirely silent: no error is emitted, the fan-in exits 0,
`kept-findings.txt` is written normally.

### Acceptance test blind spot

TC4–TC8 all use `change_type: correctness`, `style`, or `clarity`. None of
the eight new test cases exercise a HALLUCINATED sidecar with
`change_type: scope` or `change_type: intent`. The test suite is therefore
GREEN while this failure path exists undetected.

### Why this matters more than threshold findings

`scope` and `intent` findings flow directly to the orchestrator's pause gate,
meaning a hallucinated scope/intent finding can halt or redirect the pipeline,
not just appear in a log. The severity of a hallucinated scope/intent finding
reaching the kept set is higher than a hallucinated correctness finding doing
the same.

### Fix

Two options:

**Option A** — add an explicit HALLUCINATED guard before the always-keep arm
in `verifier-fan-in.sh`:

```bash
# Before the case statement, or as the first case arm:
if (( score == 0 )); then
  # Read reason field; if HALLUCINATED: prefix present, drop regardless of change_type.
  reason=$(extract_frontmatter_field "$sidecar" reason || true)
  if [[ "${reason:-}" == HALLUCINATED:* ]]; then
    DROPPED=$((DROPPED + 1))
    continue
  fi
fi
```

**Option B** — add a TC covering `change_type: scope`, `score: 0`, and
`reason: HALLUCINATED: ...`, asserting the finding is absent from
`kept-findings.txt`. If added, this TC would currently fail RED, surfacing
the bug for the next task to fix.

Option A (fan-in fix) is the load-bearing fix; Option B alone is insufficient
because the bug exists in the script, not just in test coverage.

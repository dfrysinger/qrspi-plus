---
finding_id: R5-F01
reviewer_tag: security-codex
round: 5
artifact: plan.md
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
  - docs/qrspi/2026-05-30-v072-release/design.md
---

# Probe-failure silent downgrade to single-review (fail-open)

## What the plan says

The plan preserves a fail-open default for second-review coverage: on probe failure, Goals/using-qrspi writes `second_reviewer: false` and continues (`plan.md` line 1119; mirrored in design D3 line 2182 "skip silently"). That means any probe breakage/transient host-detect failure can silently disable dual-review instead of forcing an explicit operator decision.

## Why it matters

This bypasses the intended fail-loud security posture that exists only when `second_reviewer: true` reaches dispatch (`plan.md` lines 1138, 1149; design lines 2189-2190). In practice, an attacker or bad environment state only needs to force probe non-zero once to downgrade review depth with no halt, no prompt, and no AC gate explicitly requiring "probe failure must halt or require explicit override."

## Suggested fix

Either:
(a) Require probe failure to prompt the operator (set `second_reviewer: false` only after acknowledgement), and add an AC bullet exercising the prompt path; OR
(b) Document explicitly in design.md ## G27 / D3 that probe-failure silent skip is an accepted trade-off, and add an AC bullet asserting the probe-failure → `second_reviewer: false` path is intentional and operator-visible via a single stderr diagnostic at probe time.

Resolution requires a Design-level decision (D3 is the source-of-truth), so this may warrant a backward loop to Design rather than a Plan-only patch.

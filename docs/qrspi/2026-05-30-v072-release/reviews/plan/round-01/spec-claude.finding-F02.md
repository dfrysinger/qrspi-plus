---
finding_id: R1-F02
severity: low
change_type: clarity
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
artifact: plan.md
round: 1
reviewer: spec-claude
---

# T05 target-file annotation says `(create)` for `scripts/verifier-fan-in.sh` that T02 (its dep) already creates

## What's wrong

T05 (G13 `change_type` enum drift hardening) declares (around plan.md line 353):

> **Target files:** scripts/verifier-fan-in.sh (create), skills/reviewer-protocol/SKILL.md (modify), tests/unit/test-change-type-partition.bats (modify)
> **Dependencies:** Task 02, Task 04

T02 already carries `scripts/verifier-fan-in.sh (create)` in its own Target files (line ~190 — T02 is the canonical creator of the fan-in script under the CD-4 design). T05 explicitly depends on T02, so by the time T05 runs, the script exists. T05's actual work on that file is to add the canonical enum to the script header and the out-of-enum halt cause — described in T05's own Definition of done and Scope sections in terms that fit a **modify**, not a create:

- DoD: "`scripts/verifier-fan-in.sh` exposes one canonical enum definition in its header and uses that same definition for all `change_type` membership checks." — extending the existing script.
- Scope (In): "Add the canonical `change_type` enum … to the `scripts/verifier-fan-in.sh` header …" — incremental edit.
- Scope (Out): "Baseline verifier-fan-in script creation, well-formed-round success behavior, generic halt plumbing, and verifier-dispatch prose — T02 owns." — explicit hand-off.

So the `(create)` annotation on T05 is internally inconsistent with T05's own scope/DoD and with the dep edge to T02.

## Why it matters

The `(modify)` vs `(create)` annotation on `Target files:` is the machine-parsed bullet the implementer agent uses to decide between a Write-tool first-creation flow versus an Edit-tool incremental flow. A spurious `(create)` on a file the predecessor task creates can cause:

- The implementer at T05 to either fail an existence pre-check, or to overwrite (rather than edit) the T02 baseline file — in the worst case losing T02's well-formed-round behavior and dispatch-prose include without that loss showing up in T05's per-task tests (which only exercise the enum-drift cases T05 owns).
- A reviewer audit comparing target-file annotations across the dep chain to flag the mismatch as a finding in a later round (the failure mode this finding is catching now).
- The structure.md per-file cross-reference for `scripts/verifier-fan-in.sh` to ambiguously list two creators, which inverts the single-owner property structure.md is supposed to enforce.

This is a low-severity drift — easy to miss, easy to fix, but exactly the class of small annotation mistakes that the plan-spec contract exists to catch before Implement starts.

## Suggested fix

Change T05's Target files line to:

```
Target files: scripts/verifier-fan-in.sh (modify), skills/reviewer-protocol/SKILL.md (modify), tests/unit/test-change-type-partition.bats (modify)
```

No other text change is required — T05's DoD, Scope, Test expectations, and References are already consistent with a modify. Only the bullet-layer annotation needs updating.

While the spec author is in that file, a one-pass audit of every Target-files line with `(create)` against the dep chain (does any earlier dep already create the file?) is cheap insurance — the same drift pattern could exist on other tasks the reviewer did not exhaustively check (T10's verifier sidecars updates, T15's plan.md updates, etc., would be worth a sweep).

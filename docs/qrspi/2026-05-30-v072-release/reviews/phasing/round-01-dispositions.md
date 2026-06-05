---
artifact: phasing
round: 1
findings_total: 3
kept_after_verifier: 2
dropped_below_threshold: 1
edits_applied: 2
---

# Phasing round 01 dispositions

## Findings kept after verifier filter

### quality-claude.R1-F01 (score 70, correctness) — **applied**

> G25 placed in slice 1.3, belongs in slice 1.4 (dispatch-routing cluster).
> Goals.md's Cross-Cutting Notes explicitly group G25 with G22/G23/G24-F02/
> G24-F04/G27 on the shared H4-paragraph edit surface in
> `using-qrspi/SKILL.md`.

**Fix:** Moved G25 from slice 1.3 to slice 1.4 in both `phasing.md` (slice
1.3 Goals line + slice 1.4 Goals line + slice 1.4 Surface description) and
`roadmap.md` table rows. Slice 1.4 surface description extended to call
out the top-level fail-loud invariant (G25) and the H4-paragraph
co-scheduling rationale.

### quality-claude.R1-F02 (score 72, correctness) — **applied**

> G24 placed wholesale in slice 1.3 but its sub-findings F01–F05 split
> across slices 1.4 and 1.7 per goals.md's Cross-Cutting Notes
> (dispatch-routing schema cluster: F02 + F04; test-gate hardening
> cluster: F05; plus bats-test infrastructure for F01 + F03).

**Fix:** Split G24 per the reviewer's option-1 suggestion: F02 + F04 →
slice 1.4 (dispatch-routing edit surface alongside G22/G23/G25/G27);
F01 + F03 + F05 → slice 1.7 (test-infrastructure / test-gate-hardening
edit surface alongside G21/G26). Slice 1.7 renamed to "Build & release
tooling + test-infrastructure hardening" to reflect the absorbed bats
work. Roadmap.md table mirrored. Goal-ID footer updated to
`7 + 4 + 3 + 8 + 9 + 1 + 4 = 36 slice-entries covering 35 distinct goal
IDs` with explanatory note about G24 spanning two slices.

## Findings dropped below verifier threshold

### scope-codex.R1-F01 (score 55, correctness) — **dropped**

> phasing.md crosses the Phasing boundary by naming concrete file paths
> (`round-NN.diff`, `run-codex-review.sh`, `scripts/build-plugin.sh`,
> `~/.copilot/...`) and step-by-step trap-testing instructions in the
> Phase 1 acceptance gate.

**Verifier reason (paraphrased):** Real boundary drift exists, but
acceptance gates legitimately need some concrete handles to remain
checkable — the proposed full-abstraction fix is partial / debatable
rather than load-bearing. Below correctness threshold (70).

**Disposition:** Dropped per verifier; not applied. If round 02 reviewers
re-raise this with a stronger framing (e.g. specifically flagging the
trap-testing prose rather than the named scripts that anchor the
testability surface), it can be reconsidered.

## Goal-ID consistency post-edit

35 distinct goal IDs in goals.md ↔ 35 in phasing.md ↔ 35 in roadmap.md.
Verified with `python3` set-comparison harness; G24 enumerated in two
slices (1.4 and 1.7) but counted once for distinct-goal totals.

## Sub-Threshold Observations

The scope-codex finding (score 55) sits in the "real but low-severity"
band. The verifier reason captures the partial-truth tension well: there
is genuine boundary drift in the acceptance gate's specificity, but the
proposed full-abstraction rewrite would weaken acceptance-gate
checkability. Future Phasing iterations could explore a narrower
"acceptance-gate prose vs. file-path-naming" boundary refinement at the
SKILL level rather than the artifact level.

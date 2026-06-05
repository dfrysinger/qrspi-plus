---
finding_id: F01
severity: high
change_type: scope
location: plan.md → ### Phase 1 Acceptance Criteria → bullet 2 ("Every fail-loud invariant in the release fires loud on a seeded regression input")
---

## Phase-1 fail-loud acceptance criterion claims exhaustive coverage but enumerates only a subset of the release's fail-loud invariants

### What the plan says

Phase 1 Acceptance Criterion #2 reads (verbatim from plan.md, the round-04 diff):

> **Every fail-loud invariant in the release fires loud on a seeded regression input** — splitter on adversarial Codex stdout, dispatch on misrouted `model_routing` entries, validation table on missing `model_routing:`, `_resolve-lib.sh` halt when CD-1 dispatch resolves `tier: none` against an unknown vendor, reviewer-protocol against fabricated procedural-authority outputs, and the path-filter exfil guard in `scripts/dispatch-agent.sh` each produce non-zero exit with a diagnostic, never silent fallback.

The leading clause is a universal: *"Every fail-loud invariant in the release fires loud on a seeded regression input."* The enumerated list that follows names six invariants: splitter (T20), dispatch model_routing (T16), validation table (T17), `_resolve-lib.sh` `tier: none` halt (T16), reviewer-protocol anti-fabrication (T35), and `dispatch-agent.sh` path-filter exfil (T21).

### Why this is a Plan-altitude security concern, not an Implement-altitude test request

The release introduces several other fail-loud invariants whose per-task DoD or Test Expectations require non-zero exit + diagnostic on a documented failure class, but which are **not** enumerated under this phase-level gate. The gate's leading clause is universal-quantified ("Every fail-loud invariant"), so a regression that breaks an unenumerated invariant between commits would land green at the phase-acceptance boundary because no operative bullet asks the Test phase to seed and exercise that regression. Per-task tests still exist, but the phase gate is the cross-task release boundary that catches regressions introduced *by other tasks* into a shared script — exactly the integration window where these invariants are most likely to silently regress.

This is a Plan-altitude scope concern (the release-gate enumeration is non-exhaustive given its universal-quantified framing), not an Implement-altitude test detail request. The fix is to either narrow the leading clause (e.g., "The following fail-loud invariants fire loud on seeded regression inputs:") or extend the enumeration to cover the invariants below — both are Plan-author decisions about what the phase boundary gates.

### Unenumerated fail-loud invariants visible in the round-04 diff

At least three release-introduced fail-loud invariants are missing from the gate enumeration:

1. **T19 / G27 `[second-reviewer-unavailable]` halt at dispatch time.** Task 19's DoD requires the dispatch-time resolver to halt with `[second-reviewer-unavailable]` "instead of silently falling back to single-reviewer dispatch" when `second_reviewer: true` but no eligible second-reviewer vendor resolves. This is a security-relevant fail-loud invariant — silent degradation defeats the whole point of `second_reviewer: true` (two-model review redundancy). A T20 dispatch-rename regression or a `_resolve-lib.sh` refactor in a later task could silently restore single-reviewer fall-through; the phase gate as written would not catch it.

2. **T34 / G5 post-approval split block-hash mismatch halt.** Task 34's DoD requires `plan.md` post-approval split to halt loudly when a present per-task file's `# block-hash:` header no longer matches the normalized source block. This protects against Implementation silently consuming a stale per-task spec after Plan re-runs (e.g., post-compaction restart). A regression in the hash-check code path lets stale specs feed Implementation without operator awareness — the same fail-open failure mode the round-03 verifier rejections recognized as load-bearing.

3. **T02 / G12 verifier-fan-in halt causes.** Task 02's DoD requires `scripts/verifier-fan-in.sh` to exit non-zero and record a matching `.verifier-fan-in-audit.json` halt cause for each of: missing `change_type`, out-of-enum `change_type`, missing sidecar, wrong sidecar extension, unparseable score. These are the script-owned guards that prevent the apply-fix pipeline from silently consuming a malformed reviewer output as a clean round. The phase-acceptance gate enumerates the upstream splitter halt on the third-party path (T20) and the downstream `_resolve-lib.sh` `tier: none` halt (T16), but not the fan-in halt causes in the middle of the same pipeline.

(Task 13's prior-round artifact halts — missing/malformed `round-(NN-1)-commit.txt`, missing/empty `round-(NN-1)-scope-set.txt` — are similar in shape but arguably already covered by criterion #1's "no orchestrator chat-parsing fallback fires" clause. The three above are not covered by any other phase bullet.)

### Risk

The phase acceptance gate is the cross-task release-boundary check. If its universal-quantified clause does not actually enumerate the invariants it claims to gate, then a regression in a shared script (e.g., `_resolve-lib.sh` touched by both T16 and T19; `scripts/dispatch-agent.sh` touched by both T20 and T21; `scripts/round-prepare.sh` touched by both T12 and T13) can silently restore a fail-open behavior between commits and ship to release with green CI. The per-task tests pin behavior in isolation; only the phase gate exercises the cross-task integration surface end-to-end with the production configuration knobs set.

The three unenumerated invariants all protect against silent-failure modes the rest of the release is explicitly designed to eliminate (second-reviewer redundancy degradation; stale-spec consumption; malformed-sidecar consumption). Letting any one of them regress at integration time would partially undo the security posture v0.7.2 is shipping.

### Suggested fix (Plan-altitude, not Implement-altitude)

Either:

(a) **Narrow the leading clause** so the gate is honest about being selective: replace "Every fail-loud invariant in the release fires loud on a seeded regression input" with "The following fail-loud invariants each fire loud on a seeded regression input:" and leave the existing list as-is. This trades coverage for honesty and pushes the missing invariants back into per-task scope only.

(b) **Extend the enumeration** so the gate matches its universal-quantified framing: add three bullets to the operative list — `[second-reviewer-unavailable]` halt when `second_reviewer: true` and the configured second-reviewer vendor is unavailable; `plan.md` post-approval split halts when a present per-task file's `# block-hash:` no longer matches its source block; `scripts/verifier-fan-in.sh` halts with a matching `.verifier-fan-in-audit.json` halt cause for each of the five documented malformations (missing `change_type`, out-of-enum `change_type`, missing sidecar, wrong sidecar extension, unparseable score).

Either resolution is a Plan-author decision; the current text is internally inconsistent (universal claim, selective enumeration) and that inconsistency is what creates the release-gate gap.

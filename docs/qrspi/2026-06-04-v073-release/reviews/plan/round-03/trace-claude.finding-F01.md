---
finding_id: trace-claude-F01
reviewer: qrspi-goal-traceability-reviewer (claude)
artifact: docs/qrspi/2026-06-04-v073-release/plan.md
round: 3
severity: medium
change_type: scope
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md
  - docs/qrspi/2026-06-04-v073-release/phasing.md
---

# F01 — Phasing's replan-gate criterion "Plugin installs cleanly from the published plugin/marketplace manifests on a fresh Copilot CLI session" was removed from plan.md's Phase 1 Acceptance Criteria block in round-03 with no replacement; the criterion has no other plan-authored home

## Summary

Round-03 removed the phase-1 acceptance bullet:

> The plugin installs cleanly from the published `.claude-plugin/*` and
> `.github/plugin/*` manifests on a fresh Copilot CLI session (Phasing
> replan-gate criterion).

(see `round-03.diff` line 87 — the deletion is unambiguous in the diff
context.)

`phasing.md` § Phase 1 § Replan-gate criteria explicitly enumerates this
criterion as the second of three end-of-phase gates:

> - **Replan-gate criteria (end-of-phase).**
>   - All nine goal Acceptance criteria pass (per each goal's `**Acceptance.**` subsection in `design.md`).
>   - **Plugin installs cleanly from the published plugin and marketplace manifests (G8 lockstep) on a fresh Copilot CLI session.**
>   - A self-host smoke run executes the full QRSPI pipeline end-to-end against a fixture artifact and converges without orchestration-boundary breaches (G5) or parent-SHA drift (G6).

`plan.md` is the home for per-phase acceptance criteria (per the
strip-from-goals contract). When a phasing-mandated replan-gate criterion
exists, plan.md's per-phase Acceptance Criteria block is where it lands.
Round-03 dropped it.

## Why this is not transitively covered by other bullets

The remaining G8 bullet at line 154 is structurally different:

> `VERSION` is bumped exactly once to `0.7.3`, a single `node tools/build-plugin.mjs` invocation propagates to all five consumer manifests, and the `.github/workflows/build-then-diff.yml` CI gate passes on the release commit; `.github/plugin/*` stays in lockstep with `.claude-plugin/*` per `goals.md` § Constraints (G8).

This covers two G8 properties — (a) `VERSION` propagation through the build
script and (b) `.github/plugin/*` ↔ `.claude-plugin/*` lockstep. Neither is
the "install cleanly on a fresh Copilot CLI session" property. Lockstep is a
file-equivalence check between two directory trees; install-cleanly is an
end-to-end runtime check on a freshly-installed plugin in a real host
session. The phasing replan-gate is specifically about catching a class of
release defect (broken manifest, missing file, wrong path) that the
lockstep grep won't see — two manifests can be byte-identical and still
both be broken.

Nor does design.md G8 § Acceptance carry the install-cleanly check (I
verified `design.md` lines 491–496 — they enumerate VERSION existence,
build-script propagation, CI exit-code-1 fixture, runbook prose, and v0.7.3
release commit verification; no fresh-session install check). So the line
140 catch-all "Every goal-level `**Acceptance.**` subsection in `design.md`
passes" does not transitively pick it up either.

The third phasing replan-gate criterion ("self-host smoke run executes the
full QRSPI pipeline end-to-end against a fixture artifact") is partially
covered by the self-host criteria at lines 149 (G5) and 152 (G6), but those
are component-level checks (OBC report empty, stage-commit parents
validate) against the actual v0.7.3 self-host run, not the
"end-to-end-against-a-fixture-artifact" smoke run phasing.md specifies. That
gap is a separate, smaller concern; the install-cleanly removal is the
load-bearing one because it has *zero* transitive coverage.

## Why this matters for traceability

`phasing.md` is the upstream contract for what plan.md's per-phase
acceptance block carries. The forward trace at phase boundary now misses
one phasing-mandated end-of-phase gate:

| phasing.md replan-gate criterion | plan.md Acceptance Criteria coverage |
|---|---|
| All nine goal `**Acceptance.**` subsections pass | line 140 ✓ |
| **Plugin installs cleanly on fresh Copilot CLI session (G8 lockstep)** | **none — removed in round-03** |
| Self-host smoke run end-to-end against fixture artifact, no G5/G6 breaches | lines 149, 152 — partial (real self-host, not fixture-artifact smoke run) |

The removal is unsourced — no round-02 finding asked for it. The round-02
trace-claude F03 finding asked to split a *different* bundled bullet (G5
autopilot + G9 Pass 4) and to dedupe G9 Pass 4 prose; it did not call for
removing the install-cleanly bullet. So this is not a justified
remediation; it is round-03 over-correction that incidentally dropped a
phasing-mandated criterion.

Downstream failure mode: the v0.7.3 release ships with the plugin manifests
in lockstep (line 154 passes) but the plugin fails to install on a fresh
Copilot CLI session because one of the manifests references a moved file or
a stale path. The phase-1 gate would have caught it; with the bullet
removed, the only checkers are the file-equivalence ones, which are blind
to the failure mode.

## Recommended remediation

Restore the bullet, ideally with explicit phasing-replan-gate provenance and
the G8 tag (matching the established pattern of every other bullet in the
block):

```
- [ ] The plugin installs cleanly from the published `.claude-plugin/*` and
      `.github/plugin/*` manifests on a fresh Copilot CLI session (phasing.md
      § Phase 1 replan-gate criterion 2; G8 lockstep).
```

Optional companion fix: add a fixture-artifact smoke-run bullet covering
phasing replan-gate criterion 3 explicitly (the current self-host bullets
at lines 149 and 152 are the actual v0.7.3 release run, not the
fixture-artifact smoke run phasing.md asks for as a separate end-to-end
gate). Out of scope for this finding's core remediation, but worth noting
the symmetric gap.

This is medium severity because the lost gate corresponds to a real
end-of-release failure mode the lockstep check cannot catch, and the
phasing source of truth still names it as a hard gate; the trace edge from
phasing.md → plan.md is missing exactly one phasing-mandated criterion and
the recovery is a one-bullet restore.

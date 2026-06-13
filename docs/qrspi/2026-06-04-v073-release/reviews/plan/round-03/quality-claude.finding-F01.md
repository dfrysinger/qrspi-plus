---
severity: medium
change_type: correctness
location: plan.md § Phase 1 Acceptance Criteria (lines 138–155); diff lines 87–88 (removal)
---

# F01 — Phase-1 Acceptance Criteria dropped a phasing-mandated replan-gate criterion

## What

Round-03 removes the acceptance bullet that read:

```
- [ ] The plugin installs cleanly from the published `.claude-plugin/*` and `.github/plugin/*` manifests on a fresh Copilot CLI session (Phasing replan-gate criterion).
```

(See diff hunk at round-03.diff lines 86–88 — the bullet appears only as a deletion line.) No replacement bullet covering the same surface lands in the current Phase-1 Acceptance Criteria block.

`phasing.md` § Phase 1 § Replan-gate criteria explicitly enumerates three end-of-phase replan-gate criteria the plan must surface:

```
- All nine goal Acceptance criteria pass (per each goal's `**Acceptance.**` subsection in `design.md`).
- Plugin installs cleanly from the published plugin and marketplace manifests (G8 lockstep) on a fresh Copilot CLI session.
- A self-host smoke run executes the full QRSPI pipeline end-to-end against a fixture artifact and converges without orchestration-boundary breaches (G5) or parent-SHA drift (G6).
```

After the round-03 removal, the plan covers replan-gate criterion 1 (via the umbrella "Every goal-level `**Acceptance.**` subsection ... passes" bullet on line 140) and arguably criterion 3 (via the scattered self-host sub-criteria on lines 147–153). Criterion 2 — "Plugin installs cleanly from the published plugin and marketplace manifests on a fresh Copilot CLI session" — is no longer represented anywhere in the plan's acceptance criteria. The G8 bullet on line 154 (`VERSION is bumped... `.github/plugin/*` stays in lockstep with `.claude-plugin/*`...`) covers the authoring/lockstep half of G8, not the install-from-published-manifests smoke half.

## Why it matters

The Phase 1 Acceptance Criteria block is the contract between Plan and the downstream phases (Implement / Integrate / Test) for "what must be true at phase boundary." When Phasing names a replan-gate criterion, the plan is the surface that translates that criterion into an observable phase-boundary check. Dropping the install-from-published-manifests bullet from the plan means:

- No task in the plan owns proving the criterion holds at phase end. (T28 stamps versions, T29 runs build-then-diff in CI, T30 documents the release flow — none of these execute "install plugin on a fresh Copilot CLI session and verify it loads.")
- The Test-phase reviewer dispatched against this plan has no entry to grep for the install-smoke surface, and the autopilot has no acceptance-criterion checklist item to halt on if the install regression returns.

This is exactly the install-time-only defect class that v0.7.2.3 surfaced (the `source: "./"` vs `"./build"` shape that broke marketplace install without breaking any unit test). The CI gate from T29 catches build-artifact drift but does NOT catch "the published manifests fail to install on a fresh Copilot CLI session" — that requires the install-smoke gate Phasing explicitly named.

## Suggested change

Re-add a Phase-1 acceptance bullet covering Phasing replan-gate criterion 2. The bullet should name the install-smoke surface and the verification shape (e.g., a manual or scripted run that installs from the published `.claude-plugin/*` and `.github/plugin/*` manifests on a fresh Copilot CLI session and confirms the plugin loads). If the install-smoke is intended to ride on T29's build-then-diff gate, the plan should make that argument explicitly in the acceptance bullet so a reader can audit whether the CI gate actually exercises the install path (it currently does not — `node tools/build-plugin.mjs && git diff --exit-code` proves source-tree-vs-build-tree parity, not install-from-published-manifest viability).

If the author has decided this criterion does not require a plan-side acceptance bullet (e.g., it's owned by the release runbook only), the deletion should not be silent — it should be paired with a Phasing amendment removing the criterion from `phasing.md` § Replan-gate criteria, since Plan does not own the right to drop a Phasing-mandated criterion unilaterally.

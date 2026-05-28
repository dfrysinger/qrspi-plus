---
task: 20
status: approved
pipeline: full
task_type: lightweight
model: sonnet
phase: 1
goal_ids: [G8]
dependencies: []
loc_estimate: 120
---

# Task 20: Add Worktree-Aware Setup Validation to Parallelize OWNS list + cross-skill OWNS/DEFERS drift audit

- **Phase:** 1
- **Target files:**
  - `skills/parallelize/owns-defers.md` (Modify) — add the Worktree-Aware Setup Validation line to the OWNS list and clarify the matching DEFERS boundary that keeps actual worktree/branch creation, baseline-test execution, and config edits with Implement.
  - `skills/*/owns-defers.md` (Modify — any) — any other skill's `owns-defers.md` MAY be modified during the cross-skill audit if same-pattern drift (skill mandates the work, owns-defers omits it) is discovered. Target files beyond `skills/parallelize/owns-defers.md` are discoverable at Implement time via the audit and are not pre-enumerated.
  - `docs/qrspi/future-goals.md` (Modify) — genuine-scope-debate mismatches discovered during the audit are logged here for a subsequent Goals run.
- **Dependencies:** none
- **LOC estimate:** ~120 (Parallelize OWNS/DEFERS base edit is ~60 LOC; the round-2-added cross-skill audit can yield 0–8 additional same-pattern-drift edits across other `skills/*/owns-defers.md` files, each ~5–10 LOC, so the upper bound is roughly 120 LOC and may approach the 200-LOC threshold if every audited skill exhibits drift — the implementer should escalate to opus if the audit yields more than ~6 drift fixes)
- **Description:** Closes the source-of-truth drift between the Parallelize skill's process (which already requires a Worktree-Aware Setup Validation step and surfaces results in `parallelization.md`) and `skills/parallelize/owns-defers.md` (which does not currently list that validation as an owned responsibility). Adds a Worktree-Aware Setup Validation line to the OWNS list scoped as advisory — Parallelize surfaces remediation guidance but does NOT auto-patch the artifact or perform the setup itself — and adjusts the DEFERS list to make the boundary explicit by stating that actual worktree creation, branch creation, baseline-test execution, and the on-disk config edits remain with Implement. The Parallelize scope reviewer reads `owns-defers.md` as its source of truth at dispatch time, so this OWNS addition is sufficient to eliminate the recurring false-positive scope-drift finding the reviewer emits against skill-mandated sections; no edit to the scope-reviewer agent file is required. **Cross-skill audit (time-boxed):** after applying the Parallelize OWNS/DEFERS edits, the implementer greps every `skills/*/SKILL.md` for instruction patterns (`write … to <artifact>`, `verify …`, `surface …`) and cross-checks each match against the corresponding `skills/*/owns-defers.md`. Mismatches that share the Parallelize pattern (the skill mandates the work but `owns-defers.md` omits it) are fixed in the same task by editing the appropriate `skills/*/owns-defers.md`. Mismatches that warrant genuine scope debate (rather than mechanical drift) are logged to `docs/qrspi/future-goals.md` rather than auto-resolved. Target files beyond `skills/parallelize/owns-defers.md` are discoverable at Implement time via the audit — they are not pre-declared because the audit's findings determine which other files require edits.
- **Test expectations:**
  - The OWNS list in `skills/parallelize/owns-defers.md` contains a Worktree-Aware Setup Validation entry naming the advisory-surface responsibility.
  - The OWNS entry states the validation surfaces remediation and does NOT auto-patch the parallelization artifact.
  - The DEFERS list explicitly retains worktree creation, branch creation, baseline-test execution, and config edits as Implement-owned.
  - The added OWNS line uses canonical vocabulary consistent with `skills/parallelize/SKILL.md` so the Parallelize quality reviewer does not flag it as a style drift.
  - The cross-skill audit is observably executed: the implementer DONE report enumerates every `skills/*/SKILL.md` that was grepped for the three instruction patterns (`write … to`, `verify …`, `surface …`), names each match found, and records the disposition of each match (same-pattern-drift-fix-in-this-task, genuine-scope-debate-logged-to-future-goals, or no-mismatch). Absence of the enumerated grep audit in the DONE report is a STOP condition for the reviewer.
  - When same-pattern drift is discovered in another skill's `owns-defers.md`, the implementer edits that file in the same task and the DONE report names the file and the OWNS or DEFERS entry added.
  - When a genuine scope-debate mismatch is discovered, the implementer appends an entry to `docs/qrspi/future-goals.md` and the DONE report names the appended entry by `id:` or short slug.
  - (Phase-acceptance — Integrate-time, not a BATS unit pin): re-dispatching the Parallelize scope reviewer against a worktree-aware parallelization artifact produces no scope-drift finding on the Worktree-Aware Setup Validation section. Deterministic unit-tier observation lives in T23's `test-parallelize-owns-defers.bats`.

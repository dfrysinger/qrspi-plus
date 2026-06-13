---
status: approved
task: 5
phase: 1
pipeline: full
goal_ids: [CD-2, G9]
task_type: lightweight
tier: medium
---

# Task 05: Replace per-skill diff-emission prose with high-level dispatch in 8 artifact-step SKILLs

- **Target files:** `skills/goals/SKILL.md` (Modify), `skills/questions/SKILL.md` (Modify), `skills/research/SKILL.md` (Modify), `skills/design/SKILL.md` (Modify), `skills/phasing/SKILL.md` (Modify), `skills/structure/SKILL.md` (Modify), `skills/parallelize/SKILL.md` (Modify), `skills/replan/SKILL.md` (Modify)
- **Dependencies:** T04a
- **LOC estimate:** ~80
- **Sizing note:** The `sizing_exception: schema-migration` declaration carried in earlier rounds is removed (quality-claude R4-F01 resolution option (b)): the ~80-LOC estimate satisfies the standard 200-LOC ceiling without the exemption. The mechanical-sweep shape is still load-bearing (same replacement applied to eight SKILL bodies), but no exemption is required because LOC is under ceiling — and removing the exemption removes the schema-migration mandatory-trio existence-check defect (the previously-cited `scripts/structural-lints/check-diff-emit-to-dispatch-replace.sh` did not yet exist at plan-spec review time).
- **cross_task_consumers:**
  - `tests/lint/test-no-diff-redirect-prose.bats` (T06) — disposition: `pass-through` (T06 lints the post-T05 SKILL tree for zero remaining diff-redirect paragraphs; no edit to this task's deliverables required).
- **dependent_tests:**
  - `tests/unit/test-diff-file-emission.bats` — currently asserts every in-scope per-step SKILL.md references `round-NN.diff`; that assertion breaks for the eight files T05 modifies — `co-edit` to update the assertion shape so it asserts the absence of the `round-NN.diff` redirect pattern in the eight artifact-step skills and presence of the dispatch-agent high-level invocation instead.
- **Description:** Each of the eight artifact-step SKILL.md files has its § Review Round section's pre-dispatch Bash diff-redirect paragraph replaced with one `dispatch-agent.sh --step <step> --round NN --artifact-dir <ABS>` invocation. The replacement prose carries the high-level invocation only — no per-step Bash redirect block, no pre-step instruction the orchestrator can skip. The replacement shape is mechanical (same edit pattern applied to eight files). R1 (anchor-phrase preservation for the surrounding "Run the Review Round" prose), R3 (load-bearing dispatch invocation at end of section), R7 (preserve the existing anchor phrases the reviewer dispatch test depends on), and R8 (prose-density tightening of the replacement paragraph) shape the edits.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer verifies via the same content-semantic rules application; specific findings to verify: R1 — anchor-phrase preservation for the surrounding § Review Round prose; R2 — the replacement paragraph is self-contained, carrying only the high-level dispatch invocation; R3 — load-bearing dispatch call at the end of the section; R7 — the dispatch invocation phrasing the T06 lint and the dispatch-agent high-level mode in T04a depend on; R8 — prose-density tightening of the replacement paragraph.
  - Pre-dispatch Bash diff-redirect prose shrinkage across the eight artifact-step SKILLs totals ≥ 80 lines removed versus the v0.7.2 baseline (~≥ 10 lines per file × 8 files) — CD-2 Acceptance bullet 4 quantitative claim, lifted verbatim from design.md.
  - Zero `git diff > round-NN.diff` Bash redirect blocks remain in any of the 8 modified files (verified by the T06 lint).

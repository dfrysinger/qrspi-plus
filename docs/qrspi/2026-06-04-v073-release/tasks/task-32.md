---
status: approved
task: 32
phase: 1
pipeline: full
goal_ids: [G9, CD-3]
task_type: lightweight
tier: high
sizing_exception: reusable-primitives
---

# Task 32: Trim skills/using-qrspi/SKILL.md (Pass 1+2+3) to target <350 lines

- **Target files:** `skills/using-qrspi/SKILL.md` (Modify)
- **Dependencies:** T07, T31, T01, T05, T09, T13a, T15, T16, T20a, T20b, T23, T26
- **LOC estimate:** sizing_exception: reusable-primitives (canonical bootstrapper trim — three-tier placement pass over the universal-orchestrator-behaviour bootstrapper)
- **Sizing rationale:** Trim pass touches a single file but the cross-cutting nature of the canonical bootstrapper makes any per-line scoping arbitrary; the unit of work is the full pass against the trimmed state.
- **Description:** Pass 1 (three-tier placement) reorganises `skills/using-qrspi/SKILL.md` so universal orchestrator behaviours stay, multi-skill load-bearing process boilerplate `!cat`-resolves to the new `skills/_shared/` snippets (T31), skill-specific process moves to the owning skill, and optional examples plus rare-path procedures move to `skills/using-qrspi/references/<topic>.md`. Pass 2 (script-mechanic restatement deletion) removes prose that narrates dispatch / jobId / tmpfile / HEAD~1 / convergence / sidecar-schema / change_type-enum / third-party-splitter mechanics — scripts are SSoT. Pass 3 (R8 tightening) applies the R8 reviewer test to every kept paragraph. The G2/G3/G5/G7 prose-adding changes (T13a, T23, T26, the canonical Apply-fix step 12, the pre-fanout anchor) are preserved through the trim. R1, R2, R3, R5 (`references/` extraction only for genuinely optional content per R5 conditions), R7, R8 shape the trim.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer verifies via the same content-semantic rules application; specific findings to verify: R1 — preservation of using-qrspi's distinctive headings and the G2/G3/G5/G7 prose additions (T13a, T23, T26, the canonical Apply-fix step 12, the pre-fanout anchor) through the trim; R2 — every kept paragraph self-contained post-trim; R3 — load-bearing universal rules retained in the active body, informational content moved to `references/<topic>.md`; R5 — `references/` extraction only for content satisfying R5(a) optional, R5(b) rare-path, or R5(c) pedagogical conditions; R7 — anchor phrases the reviewer dispatch and lint tests depend on are exact post-trim; R8 — R8 reviewer test applied to every kept paragraph; trim audit (T38) produces zero matches for the narrative-restatement pattern set; target <350 lines as a guidepost (the regression guard via the v0.7.2 phase-1 acceptance suite is the real gate).

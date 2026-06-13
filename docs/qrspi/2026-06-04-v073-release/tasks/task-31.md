---
status: approved
task: 31
phase: 1
pipeline: full
goal_ids: [G9]
task_type: lightweight
tier: medium
sizing_exception: reusable-primitives
---

# Task 31: Create the 6 skills/_shared/ snippet files

- **Target files:** `skills/_shared/reviewer-dispatch.md` (Create), `skills/_shared/review-loop.md` (Create), `skills/_shared/config-validation.md` (Create), `skills/_shared/compaction-checkpoint.md` (Create), `skills/_shared/pause-gate.md` (Create), `skills/_shared/feedback-format.md` (Create)
- **Dependencies:** none
- **LOC estimate:** sizing_exception: reusable-primitives (six new shared snippet files — single source of truth for multi-skill load-bearing process boilerplate)
- **Sizing rationale:** Each snippet is the single source of truth for a multi-skill process boilerplate; per-file LOC is small but six files sum above the 200-LOC ceiling. Each snippet replaces N inlined copies across the consuming skills; net active-context footprint decreases.
- **Description:** Six new snippet files under `skills/_shared/` are authored as the single source of truth for the multi-skill load-bearing process boilerplate that consuming skills `!cat`-resolve at skill-load time. `reviewer-dispatch.md` carries the verbatim reviewer-dispatch incantation; `review-loop.md` carries the Standard Review Loop body; `config-validation.md` carries the Config Validation procedure body; `compaction-checkpoint.md` carries the Compaction Checkpoint template; `pause-gate.md` carries the Pause Gate UI; `feedback-format.md` carries the Feedback File Format. Each snippet is self-contained — consuming skills inline-resolve it via `!cat` and reviewers verify the rule against the snippet, not the inlined copy. R1 (anchor-phrase preservation across snippets — consuming skills depend on stable phrasing), R2 (each snippet is self-contained — no cross-snippet references that fragment salience), R3 (snippets carry only load-bearing content — informational templates land at the start of the consuming skill, load-bearing rules at the end), R7 (verbatim phrasing the consuming skills depend on), and R8 (prose-density tightening of all snippet bodies) shape the edits.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer verifies via the same content-semantic rules application; specific findings to verify: R1 — anchor-phrase preservation across snippets (consuming skills depend on stable phrasing); R2 — each snippet is self-contained, no cross-snippet references that fragment salience; R3 — informational templates land at the start of the consuming skill body, load-bearing rules at the end (the consuming-skill `!cat` ordering reflects this); R5 — snippets carry every-invocation content (R5(a)/(b)/(c) ruled out for these — that's why `!cat` rather than Read-on-demand `references/`); R7 — verbatim phrasing the consuming skills, reviewers, and any anchor-phrase greps depend on; R8 — prose-density tightening of all snippet bodies.
- **cross_task_consumers:**
  - `skills/using-qrspi/SKILL.md` (T32) — disposition: `pass-through` (T32's Pass 1 three-tier placement `!cat`-resolves multi-skill load-bearing process boilerplate from `skills/_shared/`; no edit to this task's deliverables required).
  - `skills/implement/SKILL.md` (T33) — disposition: `pass-through` (T33's Pass 1 three-tier placement `!cat`-resolves reviewer-dispatch, review-loop, pause-gate, feedback-format as applicable; no edit to this task's deliverables required).
  - `skills/plan/SKILL.md` (T34) — disposition: `pass-through` (T34's Pass 1 three-tier placement `!cat`-resolves inlined boilerplate; no edit to this task's deliverables required).
  - `skills/{goals,questions,research,design,phasing,structure,parallelize,replan}/SKILL.md` (T35) — disposition: `pass-through` (T35's Pass 1 three-tier placement `!cat`-resolves inlined boilerplate across the 8 artifact-step skills; no edit to this task's deliverables required).
  - `skills/{integrate,test,implementer-protocol,reviewer-protocol,research-isolation,prompt-prose-writer,prompt-prose-reviewer}/SKILL.md` (T36) — disposition: `pass-through` (T36's Pass 1 three-tier placement `!cat`-resolves inlined boilerplate across the 7 cross-cutting skills; no edit to this task's deliverables required).
- **dependent_tests:** none
  - **Search proof:** `grep -rn -- 'skills/_shared/reviewer-dispatch.md\|skills/_shared/review-loop.md\|skills/_shared/config-validation.md\|skills/_shared/compaction-checkpoint.md\|skills/_shared/pause-gate.md\|skills/_shared/feedback-format.md' tests/`
  - The proof pattern matches any test file under `tests/` that asserts a path-equality or content-equality claim against any of the six new shared snippet paths. A zero-match result demonstrates no consuming test file under `tests/` asserts on the snippet contents as its own behavioural-claim subject — the snippets are SSoT prose consumed via skill-load-time `!cat` resolution, not file-content fixtures. The T38 trim-audit script (a future deliverable, not a current test) will lint the snippet boundaries; that auditing surface is a downstream consumer (covered by T38's own task spec, not by listing T38's deliverable as a `dependent_tests` entry here, which would be a forward reference). The reviewer re-runs the command from the repo root and treats any non-zero hit as a contract defect requiring the field to be re-shaped to a path list with per-file dispositions.

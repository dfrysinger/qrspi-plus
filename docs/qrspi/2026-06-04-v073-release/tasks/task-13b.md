---
status: approved
task: 13
phase: 1
pipeline: full
goal_ids: [G5]
task_type: lightweight
tier: medium
---

# Task 13b: Add revert-orchestration-drift fix-task mode to implementer-protocol with halt-on-conflict

- **Target files:** `skills/implementer-protocol/SKILL.md` (Modify)
- **Dependencies:** T19
- **LOC estimate:** ~25
- **cross_task_consumers:**
  - `skills/implementer-protocol/SKILL.md` (T36) — disposition: `pass-through` (T36's Pass-1/2/3 trim of `implementer-protocol/SKILL.md` must preserve the new `revert-orchestration-drift` fix-task mode prose verbatim; the mode body and the per-failure-class halt direction are load-bearing fix-mode definitions under the "What NOT to tighten" guardrail and are not subject to R8 tightening — T36's R1 anchor-phrase preservation expectation covers this verbatim).
- **Description:** A new `revert-orchestration-drift` fix-task mode is added to `skills/implementer-protocol/SKILL.md` § Fix-task modes. The mode consumes the G5 boundary violation report (`reviews/<phase>/orchestration-boundary.md`) and reverts each non-subagent commit it names in reverse chronological order under the subagent's author marker. Every SHA read from the report is validated against the well-formed git object-name shape (lowercase hex, 7–64 characters) before being passed to any `git` invocation; a SHA failing the shape check halts the subagent with a `sha-format-invalid:` named diagnostic and exits non-zero. The mode is halt-on-conflict: if any `git revert --no-edit <SHA>` fails (merge conflict, merge-commit-without-`-m`, deleted file, or any other failure class), the subagent halts immediately, runs `git revert --abort` to leave the working tree clean of partial revert state, writes `orchestration-boundary-revert-failed.md` naming the failed SHA and the failure class, leaves no other state changes, and exits non-zero. Skip-and-continue across remaining SHAs is forbidden. On full success, the subagent writes `orchestration-boundary-revert.md` summarising the reverts. R1 (anchor-phrase preservation for the surrounding § Fix-task modes section), R3 (the new mode lands at the end of § Fix-task modes, the load-bearing position), R7 (verbatim phrasing the G5 boundary report's consumer expects), and R8 (prose-density tightening) shape the edit.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer verifies via the same content-semantic rules application; specific findings to verify: R1 — anchor-phrase preservation for § Fix-task modes; R2 — the new mode is self-contained, names the report path, the halt-on-conflict semantics, and the per-failure-class halt direction inline; R3 — load-bearing position at the end of § Fix-task modes; R7 — verbatim phrasing the G5 boundary report's consumer surface depends on; R8 — prose-density tightening.
  - Every SHA the mode reads from the boundary report is validated against the well-formed git object-name shape before any `git` invocation; a malformed SHA triggers the `sha-format-invalid:` named diagnostic and a non-zero exit, with no `git` command run against the malformed value.
  - A single revert failure (conflict, merge-without-`-m`, deleted file) halts the mode immediately, leaves the working tree clean of partial revert state (the `git revert --abort` cleanup step ran), writes `orchestration-boundary-revert-failed.md` naming the failed SHA and the failure class, and exits non-zero.
  - Skip-and-continue across remaining SHAs after a failure is absent from the prose (a reviewer grep verifies the mode does NOT contain any "continue", "skip", or "next SHA" branch after a revert failure).

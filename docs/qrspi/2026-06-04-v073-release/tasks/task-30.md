---
status: approved
task: 30
phase: 1
pipeline: full
goal_ids: [G8]
task_type: lightweight
tier: low
---

# Task 30: Document the new release flow in docs/release-runbook.md

- **Target files:** `docs/release-runbook.md` (Modify if existing, else Create)
- **Dependencies:** T28
- **LOC estimate:** ~30
- **Description:** The release runbook is updated (or created) to name `VERSION` as the only file an author edits to bump, describe the `node tools/build-plugin.mjs` propagation step that writes the new version into all five consumer files, and document the release-commit shape — one commit containing the `VERSION` edit, the propagated stamps in the five consumer files, and the regenerated `build/` content. R1 (anchor-phrase preservation for any existing release-runbook structure), R2 (the new section is self-contained — names the file, the command, and the commit shape inline), R3 (load-bearing release-flow section at a discoverable position), R7 (verbatim phrasing of `VERSION` and the build command), and R8 (prose-density tightening) shape the edit.
- **Test expectations:**
  - Implementer applies R1-R7 + cross-cutting principles from `skills/_shared/prompt-design-rules.md`; reviewer (`qrspi-code-quality-reviewer` and/or `qrspi-design-reviewer` per surface in scope) verifies via the same content-semantic rules application; specific findings to verify: R1 — anchor-phrase preservation for any existing release-runbook structure; R2 — the new section is self-contained, names `VERSION`, the build command, and the release-commit shape inline; R3 — release-flow section at a discoverable position; R7 — verbatim phrasing of `VERSION` as the single authoring path and `node tools/build-plugin.mjs` as the propagation step; R8 — prose-density tightening.

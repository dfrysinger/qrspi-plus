---
status: approved
task: 29
phase: 1
pipeline: full
goal_ids: [G8]
task_type: tdd
tier: medium
---

# Task 29: Create .github/workflows/build-then-diff.yml CI gate

- **Target files:** `.github/workflows/build-then-diff.yml` (Create)
- **Dependencies:** T28
- **LOC estimate:** ~40
- **Description:** A new CI workflow runs `node tools/build-plugin.mjs && git diff --exit-code` on every PR and fails on any divergence between the freshly-built tree and the committed tree. The gate catches the entire class of "did the committed `build/` artifact match the source?" regressions — version drift, build-artifact drift in `build/`, marketplace `source` field shifts (the v0.7.2.3 `source: "./"` vs `"./build"` shape) — not version-only drift.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - The CI step "runs `node tools/build-plugin.mjs && git diff --exit-code` and fails on any divergence" (G8 Acceptance bullet 3, first half).
  - A fixture commit that "hand-edits `"version"` in one consumer file (without bumping `VERSION`) causes the CI step to fail" (G8 Acceptance bullet 3, second half).
  - A non-version drift fixture commit causes the CI step to fail — specifically, a fixture commit that hand-edits a non-`"version"` field in `build/.claude-plugin/plugin.json` (e.g., flipping a `"description"` string) without re-running the build script, OR a fixture commit that shifts the marketplace `source` field (the v0.7.2.3 `source: "./"` vs `"./build"` shape) in `.github/plugin/marketplace.json` so the committed marketplace points at a stale tree; the build-then-diff step must fail in both cases (coverage-codex R4-F02 — proves the gate catches the entire build-artifact-drift class, not version-only drift).
  - The workflow triggers on every PR (not only on release branches) — pull_request event configured.
  - Workflow failure output names the diverging file(s) (named-diagnostic discipline via `git diff --exit-code`'s natural output).
  - Happy-path success: a fixture commit where the committed `build/` tree exactly matches the source tree (the post-`node tools/build-plugin.mjs` shape) passes the CI step — `git diff --exit-code` returns 0, the workflow exits 0, and no divergence diagnostic is emitted (test-coverage-codex R6-F03 — the gate is observably reachable in the no-drift case, not only the failure cases).

---
status: approved
task: 28
phase: 1
pipeline: full
goal_ids: [G8]
task_type: tdd
tier: high
---

# Task 28: Create VERSION file and stamp the five consumer manifests from tools/build-plugin.mjs with bats coverage

- **Target files:** `VERSION` (Create), `tools/build-plugin.mjs` (Modify), `.claude-plugin/marketplace.json` (Modify), `.claude-plugin/plugin.json` (Modify), `.github/plugin/marketplace.json` (Modify), `.github/plugin/plugin.json` (Modify), `build/.claude-plugin/plugin.json` (Modify), `tests/unit/test-version-stamping.bats` (Create)
- **Dependencies:** none
- **LOC estimate:** ~120
- **Description:** A repo-root `VERSION` file (bare one-line containing the version string, e.g., `0.7.3`) becomes the sole authoring path for the plugin version. `tools/build-plugin.mjs` reads `VERSION` and writes the value into the `"version"` field of all five consumer files on every build. The build script halts non-zero with `version-source-missing-or-malformed: VERSION at repo root must contain a single non-empty version string` on missing, empty, or multi-line `VERSION`. Per design.md § Dependencies + edge cases the build script does not parse or validate semver — it reads the line and writes it through; stricter validation is deferred ("Stricter validation can land later if it matters"). The five consumer files are updated in this task to reflect the current version stamped from VERSION (mechanical update on first run).
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - `VERSION` exists at repo root and "contains exactly one version string".
  - `echo "9.9.9" > VERSION && node tools/build-plugin.mjs && grep '"version": "9.9.9"'` matches in all five consumer files.
  - The build script halts with the named diagnostic `version-source-missing-or-malformed:` on missing-file and empty-file cases.
  - A multi-line `VERSION` triggers the `version-source-missing-or-malformed:` named diagnostic (edge case per design § Dependencies bullet 1).
  - `build/.claude-plugin/plugin.json` is updated by the build script (not by hand) — proves the sole-writer discipline for `build/`.
- **cross_task_consumers:**
  - `.github/workflows/build-then-diff.yml` (T29) — disposition: `pass-through` (T29 is the operational consumer of the build-script change; the CI gate runs the build-then-diff flow that depends on `tools/build-plugin.mjs` stamping VERSION into the five consumer manifests).
  - `docs/release-runbook.md` (T30) — disposition: `pass-through` (T30 documents the new release flow, naming `VERSION` as the sole authoring path and the `version-source-missing-or-malformed:` named diagnostic — the runbook references contracts this task defines, but no edit to this task's deliverables is required).
- **Author Note (defer-to-upstream):** security-claude R2-F02, security-claude R4-F01, and security-codex R7-F03 all request stricter validation of the VERSION string in the build script (a semver-shape allowlist regex check beyond the structural one-line-non-empty check; explicit rejection of JSON metacharacters `"`, `\`, control bytes that would break the consumer manifests when stamped through); design.md § Dependencies + edge cases contracts the opposite direction — "Build script does not parse or validate semver — just reads the line and writes it through. Stricter validation can land later if it matters." Re-opening requires a Design-phase amendment per `skills/plan/owns-defers.md` § Upstream-contract deferrals.
- **Author Note (defer-to-upstream):** silent-failure-codex R4-F03 and silent-failure-codex R7-F03 request the build script atomically replace all five consumer manifests (single transaction, all-or-nothing) so a mid-write failure cannot leave inconsistent stamped versions across consumers; design.md § Dependencies + edge cases contracts a sequential per-file write (`tools/build-plugin.mjs` reads VERSION and writes the value into each consumer's `"version"` field; the CI gate at T29 catches divergence post-build by running `git diff --exit-code`). apply-fix-grep-ambiguous: requires user confirmation — the design contract is sequential-write + CI-gate-catches-divergence, not transactional; whether to upgrade to atomicity is a Design-phase decision per `skills/plan/owns-defers.md` § Upstream-contract deferrals.

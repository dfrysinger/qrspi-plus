---
status: approved
task: 39
phase: 1
pipeline: full
goal_ids: [G32]
task_type: code
model: opus
sizing_exception: CI scaffolding
---

# Task 39: G32 plugin build pipeline (`tools/build-plugin.mjs` + `render-skill.sh` + `g4-section-anchor-refresh.sh` + marketplace.json + CI workflow + CONTRIBUTING)

- **Target files:** `tools/build-plugin.mjs`; `tools/render-skill.sh`; `tools/g4-section-anchor-refresh.sh`; `.claude-plugin/marketplace.json`; `.github/workflows/ci.yml`; `CONTRIBUTING.md`; `tests/unit/test-build-gate.bats`; `tests/unit/test-ci-workflow-shape.bats`; `tests/acceptance/v07-phase1/test-cache-retirement-invariants.bats`; `tests/acceptance/v07-phase1/test-phase1-acceptance.bats`; existing callers/references to `scripts/render-skill.sh`, `scripts/g4-section-anchor-refresh.sh`, and `${CLAUDE_SKILL_DIR}` sites.
- **Dependencies:** Task 21, Task 25
- **LOC estimate:** ~360

**Overview**

Implement the G32 plugin build pipeline that turns the source repo into a committed `build/` install artifact, expands `!cat` includes at build time, strips dev-only paths, moves dev helpers into `tools/`, and points marketplace installs at the built tree. This preserves Task 25/G31 shared-snippet authoring while making every supported host receive fully-expanded runtime plugin content. (Why: see goals.md ### G32. Approach: see design.md ## G32.)

**Scope**

- **In:**
  - Create `tools/build-plugin.mjs` as a Node.js ES module using only stdlib; it reads `.claude-plugin/plugin.json` component paths plus the fixed runtime include list and emits a reproducible `build/` tree.
  - Implement the D3 `!cat` resolver with the single whole-line bare-relative grammar, repo-root path resolution, transitive expansion, cycle detection, CR stripping, byte-faithful replacement, idempotence, and fail-loud diagnostics.
  - Fail non-zero with file:line plus reason for malformed `!cat` lines, missing targets, include cycles with full cycle printed, absolute/path-traversal attempts, outside-root includes, and any `${CLAUDE_SKILL_DIR}` occurrence in shipped files.
  - Copy runtime plugin content and defensive shared snippets into `build/`, while omitting dev-only paths including `docs/`, `tools/`, `tests/`, and review/work artifacts.
  - Move `scripts/render-skill.sh` and `scripts/g4-section-anchor-refresh.sh` to `tools/`, update callers/docs/references, remove old `scripts/` paths, and preserve `scripts/` as runtime-only while `tools/` remains dev-only and unshipped.
  - Convert legacy `${CLAUDE_SKILL_DIR}` sites to bare-relative form and prove shipped files contain no remaining `${CLAUDE_SKILL_DIR}`.
  - Update `.claude-plugin/marketplace.json` in place so the `qrspi` plugin source points at `./build` and v0.7.2 release metadata lands.
  - Extend the single CI workflow so PRs run `node tools/build-plugin.mjs` followed by `git diff --exit-code build/ .claude-plugin/marketplace.json`, include the recursive BATS/lint coverage required for this release, and avoid Actions auto-commit behavior.
  - Update `CONTRIBUTING.md` with the edit → build → add source plus `build/` → commit → push workflow, build-sync failure modes, rationale for committing `build/`, and the `scripts/` runtime vs `tools/` dev-time distinction.
  - Add/update the named unit and acceptance tests that pin resolver behavior, stale-build diagnostics, CI workflow shape, build tree strip/copy invariants, release-level G32 acceptance, and the two resolver fixtures.

- **Out:**
  - No sibling task shares G32, so there are no Goal-ID sibling deferrals.
  - Variables, conditionals, fenced `!cat` syntax, and `${CLAUDE_SKILL_DIR}` resolver support are not introduced for v0.7.2.
  - Tarball/release-asset publishing, sibling build branches, separate build workflows, CI auto-commit steps, and pre-commit hooks are out of scope for v0.7.2.
  - Rewriting or extending `tools/render-skill.sh` with recursion/cycle semantics is out of scope; `tools/build-plugin.mjs` owns production expansion.
  - Codex CLI `skills:` frontmatter portability is a v0.7.3+ open question and is not solved by this task.

**Definition of done**

- `node tools/build-plugin.mjs` creates a reproducible `build/` tree from source using `.claude-plugin/plugin.json` component paths plus the fixed runtime include list: `scripts/`, `templates/`, `LICENSE`, `README.md`, optional `AGENTS.md`/`CLAUDE.md`, and `.claude-plugin/`.
- Built output includes runtime plugin content and defensive shared snippets, including `build/skills/_shared/prompt-prose-detection.md`, and excludes dev-only `build/docs/`, `build/tools/`, and `build/tests/`.
- The built `build/skills/goals/SKILL.md` contains inlined `skills/goals/owns-defers.md` content and no remaining `!cat` directive for that include.
- The resolver accepts only the strict whole-line bare-relative grammar, expands nested includes transitively, preserves included content without extra blank lines, strips CR characters, and is byte-identical/idempotent when run against already-expanded output.
- The resolver fails non-zero with file:line plus reason for all listed D3 fail-loud conditions, including malformed directives, missing targets, include cycles, absolute/path-traversal attempts, outside-root includes, and `${CLAUDE_SKILL_DIR}` in shipped files.
- Legacy `${CLAUDE_SKILL_DIR}` sites are converted to bare-relative form, and shipped-file grep proves zero remaining `${CLAUDE_SKILL_DIR}` occurrences.
- `tools/render-skill.sh` and `tools/g4-section-anchor-refresh.sh` exist at their new paths; `scripts/render-skill.sh` and `scripts/g4-section-anchor-refresh.sh` no longer exist; callers/docs/reference sites are updated.
- `.claude-plugin/marketplace.json` remains in place, points the `qrspi` plugin source at `./build`, and carries the v0.7.2 release metadata.
- CI remains a single workflow, runs the build-sync gate, includes the recursive BATS/lint coverage needed for this release, and contains no Actions auto-commit step.
- `CONTRIBUTING.md` documents the local rebuild workflow, PR-blocking failure modes, why `build/` is committed, and the runtime/dev-time split between `scripts/` and `tools/`.
- No variables, conditionals, fenced `!cat` syntax, tarball/release-asset pipeline, sibling build branch, pre-commit hook, or CI auto-commit behavior is introduced.
- `tools/build-plugin.mjs` canonicalizes every `!cat` target path with `fs.realpathSync` (or equivalent) BEFORE reading the target's bytes, and fails non-zero with a `resolves outside repository` diagnostic when the canonical path is not lexically prefixed by the canonical `$REPO_ROOT/`. This closes a symlink-escape exfiltration surface where a checked-in `skills/<dir>/<name>.md` symlink could point at `/etc/passwd` or any other path outside the repo and have its contents inlined into a shipped `build/` file. The guard mirrors T21's `assert_path_under_repo_root <label> <abs-path>` shape from `scripts/dispatch-agent.sh` (see Task 21 Definition of done — both guards canonicalize with `realpath` / `readlink -f` and reject canonical targets outside canonical `$REPO_ROOT/`).

**Test expectations**

- Run `node tools/build-plugin.mjs`; assert it exits 0 and creates a reproducible `build/` tree from the manifest plus fixed include list.
- Audit the built tree for required runtime content and defensive snippets, and assert `build/docs/`, `build/tools/`, and `build/tests/` do not exist.
- Inspect `build/skills/goals/SKILL.md` for inlined `skills/goals/owns-defers.md` content and absence of the corresponding `!cat` directive.
- Unit-test resolver success cases for strict grammar acceptance, repo-root resolution, transitive nested expansion, CR stripping, no extra blank lines, and idempotent byte-identical re-run behavior.
- Unit-test resolver failure cases for malformed `!cat` lines, missing targets, include cycles with full cycle printed, absolute paths, path traversal/escaping attempts, outside-root includes, and `${CLAUDE_SKILL_DIR}` in shipped files.
- Grep source/shipped files to confirm legacy `${CLAUDE_SKILL_DIR}` sites are converted and no shipped file still contains `${CLAUDE_SKILL_DIR}`.
- Verify the old `scripts/render-skill.sh` and `scripts/g4-section-anchor-refresh.sh` paths are gone, the new `tools/` paths exist, callers/docs are updated, `scripts/` remains runtime-only, and `tools/` is omitted from `build/`.
- Assert `.claude-plugin/marketplace.json` points the `qrspi` plugin source at `./build`, carries v0.7.2 release metadata, and is included in the build-sync diff gate.
- Assert CI runs `node tools/build-plugin.mjs` followed by `git diff --exit-code build/ .claude-plugin/marketplace.json`, keeps one workflow, includes recursive BATS/lint coverage needed for this release, and has no Actions auto-commit step.
- Verify `CONTRIBUTING.md` documents the edit → build → add source plus `build/` → commit → push workflow, the two PR-blocking failure modes, the committed-`build/` rationale, and the `scripts/` vs `tools/` distinction.
- Acceptance fixtures cover a legacy `${CLAUDE_SKILL_DIR}` directive failure and a deliberate include-cycle failure with the required diagnostics.
- Symlink-escape regression: a fixture commits a `!cat`-targeted file that is itself a symlink whose canonical target is outside `$REPO_ROOT` (e.g., `/etc/passwd` or `/tmp/secret`); the build fails non-zero before any byte of the symlink's referent enters the `build/` tree, with a stderr diagnostic containing `resolves outside repository`. Mirrors T21's symlink-out-of-repo regression in `tests/unit/test-dispatch-agent.bats` so the two canonicalization surfaces use the same audit-friendly diagnostic phrase.

**References**

- goals.md ### G32 — problem framing for source/install divergence, non-portable `!cat` expansion, and dev-only content leakage.
- design.md ## G32 — build output, strip-scope, resolver semantics, CI gate, marketplace, CONTRIBUTING, and v0.7.2 non-goals.
- structure.md ### `tools/build-plugin.mjs` — build script responsibilities, D1-D4 outline, acceptance spot-checks, and legacy-form cleanup.
- structure.md ### `tools/render-skill.sh` — relocated dev-only helper contract and non-goal for resolver semantics.
- structure.md ### `tools/g4-section-anchor-refresh.sh` — relocated dev-only anchor-refresh helper contract and post-move `scripts/` invariant.
- structure.md ### `.claude-plugin/marketplace.json` — source-field flip, unchanged file location, version bump, and build-sync dependency.
- structure.md ### `.github/workflows/ci.yml` — single workflow, recursive BATS/lint coverage, build-sync gate, and no auto-commit step.
- structure.md ### `CONTRIBUTING.md` — local rebuild workflow, failure-mode explainer, committed-build rationale, and `tools/` vs `scripts/` guidance.
- structure.md ### `tests/unit/test-build-gate.bats` — resolver, fixture, idempotence, recursion, grammar, and stale-build diagnostic coverage.
- structure.md ### `tests/unit/test-ci-workflow-shape.bats` — CI build-sync and recursive coverage assertions.
- structure.md ### `tests/acceptance/v07-phase1/test-cache-retirement-invariants.bats` — built-tree strip/copy and shipped-file invariants.
- structure.md ### `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` — release-level G32 acceptance for `build/`, marketplace source, and resolver fixtures.

---
status: draft
question_ids: [9, 10, 23, 28]
research_type: codebase
---

# Q9 + Q10 + Q23 + Q28: state.sh, hooks layer, integrate orchestration, CI configuration

## Summary

**TL;DR:** `hooks/lib/state.sh` is a 5-function locked R-M-W library over `<artifact_dir>/.qrspi/state.json`, called from skill SKILL.md prose (Goals/Replan), the artifact-sync hook (artifact.sh), and pipeline cascade (pipeline.sh). The hook layer is 8 source files plus a 12-file `lib/` directory enforcing target-based subagent containment, pipeline ordering, hook-managed-file protection, and audit logging; `bash-detect.sh` is a hand-rolled bash-command parser that emits write-target paths or an `__OPAQUE_WRITE__` sentinel. `skills/integrate/SKILL.md` orchestrates per-phase merge → 2 Claude reviewers (+ optional Codex) → CI gate → fix-task routing. There is **no CI configuration in the repo** — no `.github/workflows/`, no `Makefile`, no CI-runner config; "CI" inside Integrate is a narrative gate that runs whatever CI exists in the consuming project.

**Key findings:**
- `state.sh` exposes 5 public functions (`state_compute_current_step`, `state_init_or_reconcile`, `state_update`, `state_read`, `state_write_atomic`) and persists exactly one artifact: `<artifact_dir>/.qrspi/state.json`, plus a transient `state.json.lock` (flock or mkdir-mutex) (state.sh:190, 218, 389, 516, 542; state.sh:43, 122).
- Callers of state.sh public functions live in `hooks/lib/pipeline.sh` (cascade reset), `hooks/lib/artifact.sh` (PostToolUse sync), and **prose-only references** in `skills/{goals,replan,using-qrspi,plan}/SKILL.md` instructing the model to call them — there are no other binary callers.
- Hooks layer = 8 hook-surface files (`pre-tool-use`, `post-tool-use`, `session-start`, `run-hook.cmd`, `setup-project-hooks.sh`, `hooks.json`, `hooks-cursor.json`) + 12 `lib/*.sh` files; entrypoints are registered in `hooks/hooks.json` for Claude Code and `hooks/hooks-cursor.json` for Cursor.
- `bash-detect.sh` provides 3 functions: `bash_detect_file_writes` (split on `&&`/`||`/`;`, parse 7+ write-pattern families and 5+ opaque-interpreter patterns, emit one path per line or `__OPAQUE_WRITE__`); `bash_detect_destructive_universal` (rm/git push --force/git reset --hard non-HEAD/git clean -fd/`>/dev/sd*`/DROP DATABASE|SCHEMA); `bash_detect_destructive_subagent` (DROP TABLE, TRUNCATE) (bash-detect.sh:43, 556, 660).
- `skills/integrate/SKILL.md` orchestrates: merge task branches per `parallelization.md` Branch Map (leaf-only for chains, leaves for parallel groups, never stage branches) → run integration-reviewer + security-integration-reviewer in parallel (+ optional Codex via `scripts/codex-companion-bg.sh`) → human gate → CI sub-gate (push, wait, fix-route via `fixes/ci-round-NN/`) → invoke next route skill (integrate/SKILL.md:73-110, 84-94).
- **No CI configuration exists in the repo.** No `.github/workflows/`, no `Makefile`, no test-runner config; tests are 30 unit + 13 acceptance bats files runnable manually. The only env-flag/skip in the suite is `flock not available` (test-state.bats:1697) and 2 lint skips (test-u14-lint.bats:327, 363).

**Surprises:**
- The `tests/` directory has 43 bats files (308 unit / 134 acceptance per README.md:725-726) but the repo ships with no automation to run them — no Makefile, no script, no GitHub Actions. CI is referenced as a contract Integrate enforces against the consumer-project's CI, not against qrspi-plus itself.
- `scripts/` contains a single file (`codex-companion-bg.sh`) and no test runner.
- `hooks/setup-project-hooks.sh` is a temporary workaround for Claude Code bug #17688 that copies plugin hook registrations into `<project>/.claude/settings.json`.

**Caveats:** Scanned all `*.yml`/`*.yaml` and git-tracked files at the repo top level; `.git` is a worktree-style file (not a directory), and the canonical repo's tracked file list contains no CI-config files. If CI exists upstream (e.g., on GitHub via repo settings), it is not represented in the working tree. Did not enumerate every `lib/*.sh` line-by-line beyond the 5 files most directly tied to Q9/Q10.

## Full findings

### Q9: state.sh

#### Public functions

All in `hooks/lib/state.sh`:

| Function | Definition | Purpose |
|---|---|---|
| `state_compute_current_step` | state.sh:190 | Scans the 8 file-backed pipeline-step artifacts, returns the first step whose frontmatter status ≠ `approved`; falls back to `implement` (state.sh:195, 209). |
| `state_init_or_reconcile` | state.sh:218 | Builds (or rebuilds) `<artifact_dir>/.qrspi/state.json` from artifact frontmatter, preserving any existing `phase_start_commit`. Acquires the file lock for the read-and-write critical section (state.sh:275, 282-301). |
| `state_update` | state.sh:389 | Locked atomic R-M-W: reads state.json, applies a jq filter (with `--arg`/`--argjson` bindings), validates `current_step` against the 12-value allowlist, writes via temp + mv (state.sh:425-460). |
| `state_read` | state.sh:516 | Cats `<artifact_dir>/.qrspi/state.json` to stdout; returns 1 if absent. No lock (read-only) (state.sh:520-526). |
| `state_write_atomic` | state.sh:542 | Lock-protected single-write of a JSON blob with allowlist validation; warns callers doing multi-step R-M-W to use `state_update` instead (state.sh:539-541, 552-562). |

Internal helpers: `_state_current_step_is_allowed` (state.sh:28), `_state_have_flock` (state.sh:56), `_state_lock_acquire` / `_state_lock_release` (state.sh:64, 74), `_state_lock_acquire_flock` / `_state_lock_release_flock` (state.sh:91, 115), `_state_lock_acquire_mkdir` / `_state_lock_release_mkdir` (state.sh:123, 177), `_state_write_inline_locked` (state.sh:468).

#### Callers per function

| Function | Callers |
|---|---|
| `state_compute_current_step` | `hooks/lib/state.sh:251` (within `state_init_or_reconcile`); `hooks/lib/artifact.sh:102` (sync after approval). |
| `state_init_or_reconcile` | `hooks/lib/pipeline.sh:221` (cascade reset bootstrap when state.json missing). Prose-only call sites (model is instructed to invoke): `skills/goals/SKILL.md:58`, `skills/goals/SKILL.md:94`, `skills/replan/SKILL.md:181`, `skills/using-qrspi/SKILL.md:228, 233, 235, 322`, `skills/plan/SKILL.md:329`. |
| `state_update` | `hooks/lib/pipeline.sh:233` (cascade-reset write); `hooks/lib/artifact.sh:103` (approval write); `hooks/lib/artifact.sh:140` (wireframe_requested sync). |
| `state_read` | `hooks/lib/pipeline.sh:73` (`pipeline_check_prerequisites`). |
| `state_write_atomic` | No internal callers in hooks/ or scripts/. Referenced in `hooks/lib/protected.sh:58` (commentary) and `skills/using-qrspi/SKILL.md:247` (prose). |

#### Persisted artifacts and lifecycle

Single persisted artifact: `<artifact_dir>/.qrspi/state.json` (state.sh:11-15, 266, 503).

JSON shape (state.sh:321-339): `{version, current_step, phase_start_commit, artifact_dir, wireframe_requested, artifacts: {goals, questions, research, design, phasing, structure, plan, parallelize, implement, test}}`.

Lifecycle:
- **Created:** by `state_init_or_reconcile` on first call; called from Goals SKILL on session start when missing (skills/goals/SKILL.md:58), from Replan minor-path before next-phase Goals (skills/replan/SKILL.md:181), and from `pipeline_cascade_reset` when state.json is absent (hooks/lib/pipeline.sh:221).
- **Updated:** by `state_update` from `artifact.sh:103,140` (PostToolUse hook on artifact frontmatter changes) and from `pipeline.sh:233` (cascade reset on artifact demotion).
- **Read:** by `state_read` (hooks/lib/pipeline.sh:73) for prerequisite checks; by `_audit_resolve_artifact_dir_from_state` (hooks/lib/audit.sh:89) for fallback artifact_dir resolution.
- **Protected:** `hooks/lib/protected.sh:69-75` (`is_protected_qrspi_target`) blocks any non-hook write to `<...>/.qrspi/state.json`, and pre-tool-use enforces it (pre-tool-use:262-272).
- **Lock artifact:** `<artifact_dir>/.qrspi/state.json.lock` — file (flock) at state.sh:93 or directory (mkdir-mutex) at state.sh:125; transient, removed on release (state.sh:115-120, 177-181). 10-second acquire timeout (state.sh:106, 167).
- **No deletion:** state.sh contains no delete code path; the file persists for the life of the artifact_dir. (Phase rollover via `artifact_promote_next_phase` in `artifact.sh` recomputes contents but does not unlink the file.)

Other `.qrspi/` artifacts written by sibling hook code (NOT state.sh): `audit.jsonl` (audit.sh:352), `audit-orphan.jsonl` (audit.sh:314), `audit-codex-review.jsonl` (referenced in protected.sh:71), `task-NN-runtime.json` (referenced in protected.sh:71).

### Q10: hooks/ layer

#### Every file under hooks/ — what it enforces or audits, where invoked from

| File | Role | Invoked from |
|---|---|---|
| `hooks/hooks.json` | Plugin-level hook registration for Claude Code: maps PreToolUse / PostToolUse / SessionStart events to `run-hook.cmd <name>` calls; matchers `Write|Edit|Bash` for tool hooks, `startup|clear|compact` for session (hooks.json:1-40). | Claude Code reads at session start. |
| `hooks/hooks-cursor.json` | Cursor-equivalent registration; v1 schema, `preToolUse` / `postToolUse` / `sessionStart` arrays pointing at the bare hook scripts (hooks-cursor.json:1-20). | Cursor reads at session start. |
| `hooks/run-hook.cmd` | Cross-platform polyglot wrapper (cmd.exe batch on Windows + bash on Unix); finds bash via Git for Windows and execs the named hook script (run-hook.cmd:21-54). | hooks.json command field. |
| `hooks/pre-tool-use` | PreToolUse blocker. Rejects malformed JSON; routes by tool_name; for Write/Edit/NotebookEdit on artifact paths runs `pipeline_check_prerequisites`; for Bash runs `bash_detect_destructive_universal`; for subagents adds the worktree wall (regex `\.worktrees/[^/]+/(task-[0-9]+[a-z]?\|baseline)(/\|$)`) and `bash_detect_destructive_subagent`; for everyone runs `is_protected_qrspi_target` and the artifact-dir `.qrspi/` regex (pre-tool-use:120-272). Exits 2 to block. | run-hook.cmd from hooks.json PreToolUse. |
| `hooks/post-tool-use` | PostToolUse state syncer. For Write/Edit/NotebookEdit, resolves the target → artifact_dir, calls `artifact_is_known` then `artifact_sync_state` (which updates state.json and may trigger cascade reset). Always exits 0 (post-tool-use:46-98). Does NOT audit (audit is owned by pre-tool-use). | run-hook.cmd from hooks.json PostToolUse. |
| `hooks/session-start` | Reads `skills/using-qrspi/SKILL.md` and emits it as `additionalContext` (Claude Code) or `additional_context` (Cursor) JSON. Does NOT touch state.json (session-start:14-32). | run-hook.cmd from hooks.json SessionStart. |
| `hooks/setup-project-hooks.sh` | Workaround for Claude Code bug #17688 — copies plugin hook registrations from `hooks/hooks.json` into `<project>/.claude/settings.json` so subagent tool calls fire the hooks (setup-project-hooks.sh:5-37). | Manual user invocation. |
| `hooks/lib/state.sh` | State R-M-W primitives (Q9 above). | Sourced by pipeline.sh, artifact.sh (transitively from post-tool-use); via prose by skill SKILL.md files. |
| `hooks/lib/pipeline.sh` | `pipeline_check_prerequisites` (line 73 — used by pre-tool-use:150) and `pipeline_cascade_reset` (used by artifact.sh on draft demotion). | post-tool-use (via artifact.sh), pre-tool-use. |
| `hooks/lib/artifact.sh` | `artifact_is_known`, `artifact_sync_state`, `artifact_snapshot_phase`, `artifact_promote_next_phase` (artifact.sh:74-117, 156). | post-tool-use:23, prose calls in replan SKILL.md. |
| `hooks/lib/audit.sh` | `audit_log_event` (line 181) writes JSONL to `<artifact_dir>/.qrspi/audit.jsonl` with target → artifact_dir resolution and symlink hardening (audit.sh:329-352); `audit_resolve_artifact_dir`, `_audit_find_repo_root`, `_audit_resolve_target_to_artifact_dir`, `_audit_resolve_artifact_dir_from_state`, `_audit_target_is_qrspi_scope`. | pre-tool-use:60, 67. |
| `hooks/lib/agent.sh` | `agent_is_subagent` — reads `agent_id` field from envelope (agent.sh:13-19). | pre-tool-use:94. |
| `hooks/lib/worktree.sh` | `worktree_is_inside`, `worktree_detect`, `worktree_extract_task_id`, `worktree_extract_slug` (with `..`-segment rejection at worktree.sh:43-47). | audit.sh, pre-tool-use (transitively). |
| `hooks/lib/protected.sh` | `is_protected_path` (legacy worktree-only) and `is_protected_qrspi_target` (canonical regex `(^\|/)\.qrspi/(state\.json\|audit\.jsonl\|audit-codex-review\.jsonl\|task-[0-9]+-runtime\.json)$`) (protected.sh:14-49, 69-75). | pre-tool-use:262-272. |
| `hooks/lib/bash-detect.sh` | See Q10 detail below. | pre-tool-use:209, 275; audit.sh:203. |
| `hooks/lib/frontmatter.sh` | `frontmatter_get`, `frontmatter_get_status`, etc. (sourced by state.sh:7). | state.sh, artifact.sh. |
| `hooks/lib/artifact-map.sh` | `artifact_map_get` (step → filename) and `artifact_map_get_step` (filename → step) for the 8 file-backed steps (artifact-map.sh:8-44). | state.sh:8, pre-tool-use:127, post-tool-use:79. |
| `hooks/lib/task.sh` | Task-level helpers (referenced but not surveyed in detail). | sourced as needed. |

#### hooks/lib/bash-detect.sh in particular

File at `hooks/lib/bash-detect.sh` (677 lines).

Three exported functions:

1. **`bash_detect_file_writes <command>`** (line 43): emits one path per line on stdout for every detected write target; emits `__OPAQUE_WRITE__` sentinel when target is unparseable; always returns 0 (lines 11-16, 530-541).

   Pipeline:
   - Splits the command on `&&`/`||`/`;` (lines 53-75).
   - Tracks `cd_escaped` flag per part: any `cd`, `pushd`, or `popd` whose target is absolute (`/...`), contains `..`, is `~`/`-`, or contains `$`/backtick variable expansion sets `cd_escaped=1`; bare-word `cd src` does not (lines 89, 122-295). Once set, any RELATIVE write target in subsequent parts is converted to opaque (lines 109-115). This closes the cd-then-write subagent escape (round-2 task-43 S-2; comments at lines 84-89, 117-149).
   - Detects opaque-write interpreter invocations: `python[0-9]* -c`, `perl -e`, `ruby -e`, `bash -c`, `sh -c`, `node -e`, `node --eval` via two regex (lines 317-321); awk with embedded `>` redirect (line 326).
   - Detects redirect targets in three families: leading-redirect `>file cmd` (line 334); generic `>`/`>>`/`>|` walker that handles space and no-space, single/double quoting, skips `>(` process substitution and `>&N` FD-dup, treats `<>file` as RW open = write (lines 347-434).
   - Detects command-style write targets: `sed -i[.ext]` (lines 437-453), `cp` last-positional (lines 456-463), `mv` last-positional (lines 466-473), `tee [-a]` (lines 476-484), `dd of=path` (lines 487-499), `install` last-positional (lines 502-515), `rsync` last-positional (lines 518-527).
   - `_bd_add_path` strips surrounding quotes/whitespace and converts to opaque if `cd_escaped` is set on a relative path (lines 94-115).

2. **`bash_detect_destructive_universal <command>`** (line 556): blocks for everyone (main chat included). Patterns:
   - `rm -rf` with target containing `*` (wildcard), `~` (home glob), absolute path NOT under `$PWD` (F-3 minimal allow), or `..` parent traversal — tokenized after stripping flags (lines 562-608).
   - `git push --force` / `-f` (lines 611-617).
   - `git reset --hard <ref>` where ref ≠ `HEAD`/`HEAD~*`/`HEAD^*` (lines 619-626).
   - `git clean -fd`/`-fdx`/`-fdX`/`-df`/`-dfx`/`-dfX` (lines 629-633).
   - Redirect to `/dev/sd*` (lines 635-639).
   - `DROP DATABASE`/`DROP SCHEMA` case-insensitive (lines 641-645).
   Echoes the matched pattern name on stdout and returns 0 if blocked, else 1.

3. **`bash_detect_destructive_subagent <command>`** (line 660): blocks for subagents only.
   - `DROP TABLE` (lines 664-667).
   - Word-boundary `TRUNCATE` (lines 670-673).
   Echoes pattern name; returns 0 to block, 1 to allow.

### Q23: skills/integrate/ orchestration

File: `skills/integrate/SKILL.md` (270 lines).

#### Steps run

Process Steps section (SKILL.md:84-101):
1. **Merge task branches** per `parallelization.md` Branch Map (SKILL.md:85). Merge Strategy (SKILL.md:73-81): leaf-only for sequential chains, each leaf for parallel groups, never merge stage branches directly; delete `qrspi/{slug}/stage-after-G*` after leaf merges complete; STOP and present conflicts to user (no auto-resolve).
2. **Integration reviews** in parallel via Review Pattern 2 (Outer Loop) (SKILL.md:86-94). Pre-review-loop compaction recommended (SKILL.md:88).
3. **Fix task dispatch** if findings — write to `fixes/integration-round-NN/`, route through Implement → back to Integrate (SKILL.md:97-101). Fix tasks include `pipeline: full` field.
4. **CI Pipeline Gate** sub-gate (SKILL.md:103-110): push branch → wait → on failures dispatch fixes to `fixes/ci-round-NN/` → re-run; skip entirely if no CI exists.
5. **Phase Learnings Gate** at human gate before terminal state (SKILL.md:167-180): asks user for current-phase items vs future ideas; appends ideas to `future-goals.md` `## Ideas`.
6. **Terminal State** (SKILL.md:182-188): invoke next route skill from `config.md`; recommend `/compact` before next skill.

TodoWrite list (SKILL.md:200-208) tracks: merge → integration-reviewer → security-integration-reviewer → present results → dispatch fixes → push to CI → handle CI results.

#### Review passes dispatched

Two Claude reviewers in parallel (SKILL.md:90):
- `skills/integrate/templates/integration-reviewer.md` — 6 cross-task criteria: Cross-Task Consistency, Interface Mismatches, Data Flow Correctness, Integration Test Coverage, Duplicate/Conflicting Implementations, Dependency Ordering (integration-reviewer.md:16-77).
- `skills/integrate/templates/security-integration-reviewer.md` — 6 cross-task security criteria: Broken Access Control, Data Exposure, Injection Vectors, Dependency Vulnerabilities, Privilege Escalation Paths, Race Conditions/Shared State (security-integration-reviewer.md:14-87).

Each Claude reviewer subagent embeds `skills/_shared/reviewer-boilerplate.md` verbatim (SKILL.md:90); 5-field finding schema (`finding_id`, `severity`, `change_type`, `message`, `referenced_files`).

Untrusted-data wrapping: merged code, `design.md`, `structure.md` interpolated between `<<<UNTRUSTED-ARTIFACT-START id={artifact_name}>>>` and `<<<UNTRUSTED-ARTIFACT-END id={artifact_name}>>>` markers (SKILL.md:90).

Optional Codex parallel reviews via `scripts/codex-companion-bg.sh launch --prompt-file ...` and `scripts/codex-companion-bg.sh await <jobId>` (SKILL.md:90-93). Two launches (one per template). Exit codes per await: 0 = success (append stdout under `#### Codex` 4-hash heading); 10 = 20-min ceiling (note only); 11 = companion crash (note + surface to user); 12 = audit-write fail (note + surface, no retry).

Convergence: up to 3 rounds on unchanged code to build complete issue list (SKILL.md:96).

#### Gates enforced

HARD-GATE (SKILL.md:65-70):
- No CI push without integration AND security review on merged code.
- No CI push without user approval of integration review results.
- No production code fixes directly — all routes through Implement → Integrate.

Iron Laws restated at end (SKILL.md:259-269): NO CI PUSH WITHOUT INTEGRATION REVIEW, ONCE PER PHASE NEVER PER TASK, no production code fixes from Integrate.

Artifact gating (SKILL.md:48-58) — required inputs (refuse if missing/unapproved):
- All current-phase task review files in `reviews/tasks/`
- Task branches and stage commits ready to merge
- `design.md` approved, `structure.md` approved, `phasing.md` approved, `parallelization.md` approved
- `config.md` (for `route` and `codex_reviews`)

Config Validation Procedure applied to `route` and `codex_reviews` fields (SKILL.md:62-63).

Human Gate (SKILL.md:163-165): user must approve at every review round and CI run; on rejection write feedback to `feedback/integrate-round-{NN}.md`.

#### Artifacts consumed and produced

Consumed (SKILL.md:48-58):
- `parallelization.md` — branch map for merge ordering.
- `reviews/tasks/*` — per-task review files.
- `design.md`, `structure.md`, `phasing.md` — cross-task context.
- `config.md` — route + codex_reviews flag.

Produced (SKILL.md:158-161):
- `reviews/integration/round-NN-review.md` — integration + security findings per round, with `## Integration Review` and `## Security Integration Review` headers (Codex appended under `#### Codex` 4-hash subheadings).
- `reviews/ci/round-NN-review.md` — CI failure analysis per round.
- `fixes/integration-round-NN/*.md` — integration fix tasks (SKILL.md:114-133, format spec).
- `fixes/ci-round-NN/*.md` — CI fix tasks (SKILL.md:135-156, format spec).
- `feedback/integrate-round-{NN}.md` — on user rejection (SKILL.md:165).
- Appends to `future-goals.md` `## Ideas` (SKILL.md:176).

### Q28: CI configuration

#### Workflow files

**None present.** No `.github/workflows/`, no `Makefile`, no `ci.yml`/`ci.yaml`, no test-runner script in `scripts/` (which contains only `codex-companion-bg.sh`).

`git ls-files` returns no `*.yml` / `*.yaml` files except `tests/unit/test-compaction-emphasis-markup.bats` (a `.bats` file). No tracked `Makefile`, no top-level `ci/` directory.

`README.md:725-726` documents test counts ("308 unit tests (bats-core)", "134 acceptance tests (bats-core)") but neither README nor AGENTS.md describes a CI runner; AGENTS.md grep for "CI"/"workflow" returns no matches.

`STATUS.md` (24 lines) is a status board for active agent work and does not reference CI.

The `Integrate` skill's "CI Pipeline Gate" (SKILL.md:103-110) is a contract over *the consuming project's* CI: "Push branch, trigger CI (GitHub Actions or equivalent)" and "If no CI pipeline exists, skip this gate entirely" (SKILL.md:104, 110).

#### Suites that run; platform matrix

The qrspi-plus repo carries a manually-runnable bats-core test suite, no automated runner:

- `tests/unit/` — 30 `.bats` files (test-agent.bats, test-artifact-gating.bats, test-artifact-map.bats, test-artifact.bats, test-audit.bats, test-bash-detect.bats, test-change-type-classification.bats, test-codex-companion-bg.bats, test-compaction-emphasis-markup.bats, test-frontmatter.bats, test-phasing-{four-artifact-pruning,goal-id-consistency,roadmap-generation}.bats, test-pipeline.bats, test-pre-tool-use.bats, test-replan-archive-and-populate.bats, test-reviewer-boilerplate-embed.bats, test-scope-reviewer{,-parallel-with-claude,-rules-loading}.bats, test-session-start.bats, test-setup-project-hooks.bats, test-skill-md-content-patterns.bats, test-state.bats, test-structure.bats, test-task.bats, test-u14-lint.bats, test-using-qrspi.bats, test-worktree.bats).
- `tests/acceptance/` — 13 `.bats` files (test-asymmetric-enforcement.bats, test-full-pipeline-with-phasing.bats, test-hardening-{enforcement,meta,skills,structural}.bats, test-meta.bats, test-pipeline-ordering.bats, test-replan-minor-path-roadmap-driven.bats, test-review-pause.bats, test-reviewer-injection.bats, test-skill-output-quality.bats).

No platform matrix — there is no CI configuration to declare one. Bats runs on whatever host invokes it.

#### Conditional / environment-flagged gating

The only conditional/skip patterns in the suite:

- `tests/unit/test-state.bats:1697` — `skip "flock not available on this host (mkdir-mutex fallback in use); test does not apply"` gated on `command -v flock`. Documents flock vs mkdir-mutex platform variance.
- `tests/unit/test-u14-lint.bats:327, 363` — two `skip "FU-7: in-scope skill files have pre-existing U14 ... violations"` lines (documented future-followup deferrals, not env-flagged).
- `tests/acceptance/test-meta.bats:122` — comment-only reference to "skip on non-flock hosts" pattern.

No `RUN_*`, `CI=`, `QRSPI_TEST_*`, `BATS_*`-suite-selection, or other env-flagged gating. Tests are intended to be run wholesale against a developer host.

The companion-bg test (`tests/unit/test-codex-companion-bg.bats:21, 28`) wires a stub of the codex CLI via env-overridable path (described as "constraint C3: env-overridable" in the test comment), but this is in-test injection, not test-suite gating.

## Files surveyed

- hooks/lib/state.sh
- hooks/lib/bash-detect.sh
- hooks/lib/audit.sh
- hooks/lib/protected.sh
- hooks/lib/worktree.sh
- hooks/lib/agent.sh
- hooks/lib/artifact-map.sh
- hooks/lib/artifact.sh (partial — first ~145 lines)
- hooks/pre-tool-use
- hooks/post-tool-use
- hooks/session-start
- hooks/run-hook.cmd
- hooks/setup-project-hooks.sh
- hooks/hooks.json
- hooks/hooks-cursor.json
- skills/integrate/SKILL.md
- skills/integrate/templates/integration-reviewer.md
- skills/integrate/templates/security-integration-reviewer.md
- AGENTS.md
- STATUS.md (partial — first 24 lines)
- README.md (grep-only)
- tests/unit/ (directory listing + grep)
- tests/acceptance/ (directory listing + grep)
- tests/unit/test-state.bats (offset 1690 only)
- scripts/ (directory listing)
- .claude-plugin/ (directory listing)

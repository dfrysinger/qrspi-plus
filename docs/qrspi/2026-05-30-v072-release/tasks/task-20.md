---
status: approved
task: 20
phase: 1
pipeline: full
goal_ids: [G3]
task_type: code
model: opus
sizing_exception: reusable primitives
---

# Task 20: G3 dispatch-script rename collapse (`run-codex-review.sh` → `dispatch-agent.sh`; `run-third-party-llm.sh` → `dispatch-companion.sh`; `codex-finding-splitter.sh` → `third-party-finding-splitter.sh`) and per-skill prose migration

- **Target files:** rename `scripts/run-codex-review.sh` → `scripts/dispatch-agent.sh`; rename `scripts/run-third-party-llm.sh` → `scripts/dispatch-companion.sh`; rename `scripts/codex-finding-splitter.sh` → `scripts/third-party-finding-splitter.sh`; modify `scripts/await-round.sh`; create `skills/_shared/reviewer-dispatch-prose.md`; modify `skills/goals/SKILL.md`, `skills/questions/SKILL.md`, `skills/research/SKILL.md`, `skills/design/SKILL.md`, `skills/structure/SKILL.md`, `skills/phasing/SKILL.md`, `skills/plan/SKILL.md`, `skills/parallelize/SKILL.md`, `skills/replan/SKILL.md`, `skills/implement/SKILL.md`, `skills/integrate/SKILL.md`, `skills/test/SKILL.md`; rename/update `tests/unit/test-run-codex-review.bats` → `tests/unit/test-dispatch-agent.bats`; modify `tests/unit/test-dispatch-sites.bats`
- **Dependencies:** Task 09, Task 11, Task 12, Task 13, Task 19. **Blocks:** T21 (G16 path-filter exfil hardening in `dispatch-agent.sh`).
- **LOC estimate:** ~260

**Overview**

Collapse the Codex-named shell review path into vendor-neutral dispatch primitives and one shared reviewer-dispatch prose include, so reviewer output persistence stays inside the script chain instead of repeated orchestrator-side prose. The hard rename and 12-skill consumer migration must land atomically to avoid mixed old/new dispatch paths. (Why: see goals.md ### G3. Approach: see design.md ### CD-1 and design.md ## G3.)

**Scope**

- **In:**
  - Hard-rename the three dispatch scripts to `scripts/dispatch-agent.sh`, `scripts/dispatch-companion.sh`, and `scripts/third-party-finding-splitter.sh` with no compatibility shim or live caller left on the old names.
  - Preserve the universal dispatcher contract: `dispatch-agent.sh` emits one `MODE=first_party ... PROMPT_FILE=<absolute-path>` spec line per first-party reviewer, records third-party entries in `.dispatch-manifest.json`, and routes background jobs through `dispatch-companion.sh`.
  - Implement the companion/splitter chain so `dispatch-companion.sh` launch prints only `JOB_ID=<id>`, `await <job-id>` captures raw reviewer output under `<round-dir>/.dispatch/`, and `third-party-finding-splitter.sh` materializes stable `F01`, `F02`, ... finding files or a clean sentinel.
  - Update `await-round.sh` to drain every pending background manifest entry, invoke `third-party-finding-splitter.sh`, update manifest statuses, write `.round-complete.json`, remove `.dispatch/` only after completion, and remain no-op-safe for first-party-only rounds.
  - Create `skills/_shared/reviewer-dispatch-prose.md` with the locked dispatch-agent invocation, spec-line parsing contract, one-Task-call-per-spec-line iron law, `DISPATCH_FILE=<path>` prompt rule, and unconditional `await-round.sh --round-dir` follow-up.
  - Migrate the 12 listed review-producing `SKILL.md` files to a thin per-skill `$REVIEW_*` preamble plus `!cat skills/_shared/reviewer-dispatch-prose.md`, removing inline Claude/Codex dispatch blocks and old splitter pipe recipes.
  - Rename/update `tests/unit/test-run-codex-review.bats` to `tests/unit/test-dispatch-agent.bats` and update `tests/unit/test-dispatch-sites.bats` for the new dispatch names and shared-include migration.

- **Out:**
  - Evergreen-output-rule snippet creation and include sites that overlap the artifact-producing skill files — T27 owns.
  - G16 path-filter exfil hardening and canonicalize-under-`$REPO_ROOT/` behavior inside `dispatch-agent.sh` — T21 owns after this rename lands.
  - Changing `round-prepare.sh`'s diff-anchor / commit-anchor logic — T12 owns; this task only consumes the existing dispatch-chain integration surface.
  - Adding new vendor transports beyond the renamed companion hook; the G3/CD-1 contract only requires the vendor-neutral dispatch surface.

**Definition of done**

- The old script names are gone as live entry points, and the renamed scripts are the only live dispatch-chain command names used by migrated skill prose and dispatch tests.
- `dispatch-agent.sh` accepts the renamed entry-point invocation, emits exactly one first-party spec line per first-party reviewer, appends first-party/background entries to `.dispatch-manifest.json`, and never requires callers to invoke `run-codex-review.sh`.
- `dispatch-companion.sh` launch writes only `JOB_ID=<id>` to stdout, while `dispatch-companion.sh await <job-id>` writes raw reviewer output to `<round-dir>/.dispatch/<tag>.raw` without echoing payload text to stdout or stderr.
- `third-party-finding-splitter.sh` reads `<round-dir>/.dispatch/<tag>.raw`, writes stable per-finding files or the `NO_FINDINGS` sentinel, and fails loudly for missing flags, missing raw output, missing boundaries, or write errors.
- `await-round.sh` resolves all pending background manifest entries, invokes the renamed splitter for each resolved entry, persists updated manifest and `.round-complete.json` state, removes `.dispatch/` only after completion, and is safe to call when the round is first-party-only.
- `skills/_shared/reviewer-dispatch-prose.md` contains the shared dispatch-agent invocation, spec-line parsing, parallel Task-call, `DISPATCH_FILE=<path>`, iron-law, and await-round follow-up contract.
- Each of the 12 listed `SKILL.md` consumers sets the required `$REVIEW_*` preamble and includes `skills/_shared/reviewer-dispatch-prose.md` at its reviewer-dispatch section, with no remaining inline per-reviewer Claude/Codex dispatch blocks or old splitter pipe recipes.
- The renamed/updated bats coverage pins the new command names, reviewer-dispatch include migration, first-party spec-line parsing, third-party split materialization, and payload-output bounding.

**Test expectations**

- File/rename audit: old script/test paths no longer exist as live files; `scripts/dispatch-agent.sh`, `scripts/dispatch-companion.sh`, `scripts/third-party-finding-splitter.sh`, `skills/_shared/reviewer-dispatch-prose.md`, and `tests/unit/test-dispatch-agent.bats` exist.
- Grep audit for `run-codex-review.sh`, `run-third-party-llm.sh`, and `codex-finding-splitter.sh` in migrated skill prose and dispatch tests returns no live call sites except historical fixtures that explicitly assert those names are absent.
- Dispatch-agent unit coverage verifies renamed entry-point invocation, first-party spec-line parsing, `.dispatch-manifest.json` entries, `PROMPT_FILE=<absolute-path>` emission, and no dependency on `run-codex-review.sh`.
- Companion/splitter fixture coverage verifies `JOB_ID=<id>` launch output, payload-silent await behavior, raw capture under `.dispatch/`, stable `F01`, `F02`, ... materialization, `NO_FINDINGS` sentinel writing, and loud failure for missing flags/raw output/boundaries/write errors.
- `await-round.sh` fixture coverage verifies manifest iteration, pending background drain, splitter invocation, manifest status updates, `.round-complete.json` writing, `.dispatch/` teardown after completion, and first-party-only no-op behavior.
- Shared-prose inspection verifies the locked dispatch-agent command, spec-line parse instructions, one Task call per emitted spec line, `prompt = "DISPATCH_FILE=<PROMPT_FILE-value>"`, and unconditional `scripts/await-round.sh --round-dir "$REVIEW_OUTPUT_DIR"` follow-up.
- Consumer-skill grep/lint verifies all 12 listed `SKILL.md` files include `!cat skills/_shared/reviewer-dispatch-prose.md` at reviewer dispatch and no longer contain inline per-reviewer Claude/Codex dispatch blocks or old splitter pipe recipes.
- `tests/unit/test-dispatch-sites.bats` and the renamed `tests/unit/test-dispatch-agent.bats` cover the new command names, include migration, first-party dispatch parsing, third-party split materialization, and bounded stdout/stderr so raw third-party reviewer text cannot leak into orchestrator output.

**References**

- goals.md ### G3 — problem framing for shell-pipeline splitter collapse and silent finding-loss risk.
- design.md ### CD-1 — universal dispatch architecture, rename inventory, shared reviewer-dispatch prose body, and acceptance criteria.
- design.md ## G3 — G3-specific vendor-neutral outcome and acceptance layered on CD-1.
- structure.md ### `scripts/run-codex-review.sh` — rename source and post-rename `dispatch-agent.sh` responsibilities/interface.
- structure.md ### `scripts/run-third-party-llm.sh` — rename source and `dispatch-companion.sh` launch/await contract.
- structure.md ### `scripts/codex-finding-splitter.sh` — rename source and `third-party-finding-splitter.sh` raw-output split contract.
- structure.md ### `scripts/await-round.sh` — manifest-driven async drain and output-bound contract.
- structure.md ### `skills/_shared/reviewer-dispatch-prose.md` — shared snippet body and required hook-point include.
- structure.md ### `skills/goals/SKILL.md` — representative 12-consumer reviewer-dispatch preamble/include migration pattern.
- structure.md ### `tests/unit/test-dispatch-sites.bats` — consumer include-site regression coverage.
- structure.md ### `tests/unit/test-run-codex-review.bats` — test rename source for `tests/unit/test-dispatch-agent.bats`.

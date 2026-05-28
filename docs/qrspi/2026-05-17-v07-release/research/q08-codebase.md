---
status: draft
question_ids: [8]
research_type: codebase
---

# Q8: How is prompt composition currently assembled at dispatch sites across `skills/` and `agents/`, and what inputs are typically composed at each site?

## Summary

**TL;DR:** Prompt composition in qrspi-plus is split between two transport paths but governed by the same parameter contract (`skills/reviewer-protocol/SKILL.md:38-51`). Claude-side dispatches assemble parameters inline as `Agent({ subagent_type: ..., model: ... })` calls whose prompt body is "only" a structured Dispatch-parameters block — `artifact_body` (or `subject_code`), zero-to-many `companion_*` artifacts, plus `round_subdir`/`round`/`reviewer_tag`/`diff_file_path`/`scope_hint` — with all artifact bodies fenced between `<<<UNTRUSTED-ARTIFACT-START id=...>>>` / `<<<UNTRUSTED-ARTIFACT-END id=...>>>` markers and the reviewer-protocol body delivered out-of-band via the agent file's `skills: [reviewer-protocol]` frontmatter preload. Codex-side dispatches use one canonical assembler — `scripts/run-codex-review.sh` (`scripts/run-codex-review.sh:1-557`) — which concatenates the frontmatter-stripped reviewer-protocol body, any additional agent-declared `skills:` bodies, the agent body, the Codex emission override, a structural `AGENT-BODY-END (3-angle-bracket form)` marker, and a generated `## Dispatch parameters` block, then pipes the whole prompt to `scripts/codex-companion-bg.sh launch`. Non-reviewer dispatch sites (per-question research specialist, research collator, replan analyzer, test-writer, implementer) follow the same wrap-in-markers convention but use site-specific parameter names (`question_body`, `qfile_paths`, `output_path`, `mode`, `task_definition`, `companion_pipeline_inputs`, `companion_review_findings`, `companion_codebase_context`, etc.).

**Key findings:**
- The shared "Reviewer Dispatch Contract" enumerates five always-present parameters and one optional (`artifact_body`/`subject_code`, `round_subdir`, `round`, `reviewer_tag`, `diff_file_path`, optional `scope_hint`) and is the canonical schema every reviewer dispatch site emits (`skills/reviewer-protocol/SKILL.md:38-51`).
- Claude dispatches embed `Agent({ subagent_type: "qrspi-{tag}-reviewer", model: "sonnet" })` literals inside per-skill SKILL.md prose with a bulleted "prompt containing only" parameter list (e.g. `skills/goals/SKILL.md:240-258`, `skills/design/SKILL.md:150-170`, `skills/structure/SKILL.md:136-158`, `skills/phasing/SKILL.md:112-134`, `skills/plan/SKILL.md:271-302`, `skills/parallelize/SKILL.md:168-188`, `skills/replan/SKILL.md:121-140`, `skills/questions/SKILL.md:83-92`, `skills/research/SKILL.md:125-154`, `skills/integrate/SKILL.md:102-120`, `skills/implement/SKILL.md:797-811,872-901`, `skills/test/SKILL.md:126-150`).
- Codex dispatches all funnel through one wrapper (`scripts/run-codex-review.sh`) whose `compose_prompt()` function (`scripts/run-codex-review.sh:508-538`) concatenates: (1) frontmatter-stripped `skills/reviewer-protocol/SKILL.md`, (2) frontmatter-stripped bodies of every additional skill named in the agent file's `skills:` frontmatter, (3) frontmatter-stripped agent body, (4) `skills/reviewer-protocol/codex-emission-override.md`, (5) the literal `AGENT-BODY-END (3-angle-bracket form)` boundary marker, (6) `## Dispatch parameters` with wrapped artifact + companion blocks plus scalar fields.
- The wrapper's `emit_dispatch_parameters()` (`scripts/run-codex-review.sh:442-502`) emits the primary-artifact field (`subject_code` or `artifact_body`) first, then `task_definition` (only when `--task-def` is passed; absence is load-bearing per `skills/reviewer-protocol/SKILL.md:170-204`), then companions concatenated under one field-name (parallel arrays so repeats merge), then scalar `--field` values, then always `round_subdir`/`round`/`reviewer_tag`, then optional `diff_file_path` and `scope_hint` (the latter wrapped between `<<<UNTRUSTED-SCOPE-HINT-START id=scope_hint>>>` / `<<<UNTRUSTED-SCOPE-HINT-END id=scope_hint>>>` markers).
- Reviewer-protocol material is delivered **out-of-band** in both paths: Claude reviewers preload it via the agent file's `skills: [reviewer-protocol]` frontmatter (preload mechanism — every reviewer agent file carries this field, e.g. `agents/qrspi-design-reviewer.md:6`); Codex pipelines load it via the wrapper's concatenation. Per-skill SKILL.md prose explicitly states "do NOT embed reviewer-protocol content in the dispatch prompt" at every reviewer dispatch site (e.g. `skills/design/SKILL.md:160`, `skills/goals/SKILL.md:248`).
- A `AGENT-BODY-END (3-angle-bracket form)` boundary marker emitted by the wrapper (`scripts/run-codex-review.sh:536`) separates the trusted protocol/agent body from orchestrator-supplied dispatch parameters; orchestrator-supplied inputs are rejected if they contain the literal marker (`scripts/run-codex-review.sh:357-413`).
- Per-question research specialists receive a different shape: `question_body` (the wrapped q*.md body), `output_path`, `question_ids`, and (on re-dispatch only) `defect_summary` — explicitly NO `companion_goals` and NO sibling questions (`skills/research/SKILL.md:58-71`).
- Research collator receives `qfile_paths` (paths, not bodies — collator Reads them itself) plus `output_path` (the staging filename `_collated.md`, renamed to `summary.md` by the orchestrator post-dispatch) (`skills/research/SKILL.md:85-95`).
- Implementer dispatch carries `mode` (`implement`|`fix`), `task_definition` (wrapped task spec), `companion_pipeline_inputs` (concatenated wrapped upstream-artifact bodies per the task's `pipeline` field), and `companion_review_findings` (fix-mode only, wrapped reviewer-finding bodies) (`skills/implement/SKILL.md:514-525`).
- Replan analyzer uses a path-vs-body split: large fan-out inputs (completed phase code, fixes/, reviews/, tasks/) travel as absolute paths the analyzer Reads at runtime; small fixed artifacts (plan/design/phasing) travel as wrapped bodies; NO `goals.md` (`skills/replan/SKILL.md:77-93`).
- The verifier (`qrspi-finding-verifier`) and scope-tagger (`qrspi-scope-tagger`) dispatches in `using-qrspi/SKILL.md` (lines 673-721, 798-821) pass file paths only — finding/sidecar/artifact/diff paths plus a newline-separated `upstream_paths` list of upstream-artifact + SKILL paths the verifier may lazy-Read.
- The test-writer dispatch (`skills/test/SKILL.md:92-100`) composes 5 wrapped companions (`companion_plan`, `companion_goals`, `companion_design_or_research`, `companion_fix_history`, `companion_codebase_context`) plus an `output_dir`; no reviewer-protocol involvement.

**Surprises:**
- The reviewer-protocol body is also concatenated for non-reviewer agents whose `skills:` frontmatter names other shared skills (e.g. `qrspi-research-collator.md`, `qrspi-research-specialist.md` declare `skills: [research-isolation]`); the wrapper's `extract_skill_names()` (`scripts/run-codex-review.sh:281-321`) appends each named skill's body before the agent body and skips the hardcoded `reviewer-protocol` only — there is no opt-out for callers that do not want reviewer-protocol concatenation.
- A single `--companion NAME=PATH` flag passed multiple times with the same NAME results in concatenation under one field header rather than overwrite (`scripts/run-codex-review.sh:464-478`); this is how `companion_qfiles`, `companion_tasks`, `companion_task_review_findings`, etc., are emitted as multi-block sections in plan/integrate/parallelize/research dispatches.
- The replan-analyzer Codex pipeline is hand-rolled in-line in `skills/replan/SKILL.md:146-148` (an `awk … printf …` heredoc that pipes directly to `scripts/codex-companion-bg.sh launch`) rather than using `run-codex-review.sh`, because the analyzer is a worker, not a reviewer — it does NOT preload `reviewer-protocol` and does NOT pass `reviewer_tag`/`output`/`round`.
- The Research reviewer dispatch is the only reviewer that passes companions as **paths, not bodies**: `companion_qfile_paths` is a list of absolute paths the agent Reads directly; the orchestrator does NOT embed file bodies inline (`skills/research/SKILL.md:139-145`).
- The visual-fidelity reviewer dispatch passes `wireframe_paths` as a YAML list of paths (not wrapped bodies) and is the only reviewer that performs upstream path-validation, audit-record emission, and silent-skip-sentinel writing as part of dispatch preparation (`skills/implement/SKILL.md:817-870`).

**Caveats:** Investigation enumerated dispatch blocks across all 13 step skills + the shared reviewer-protocol + using-qrspi orchestration patterns + the Codex wrapper script. The 4 owns-defers.md sidecars (one per scope-reviewed step), the implementer-protocol skill body, and the per-agent body files were not exhaustively read — only the prompt-composition surface (skill-side dispatch instructions and the wrapper's assembly code) was traced. The exact runtime mechanism Claude Code uses to preload `skills: [reviewer-protocol]` frontmatter at agent activation was not source-traced; the skill prose names it as "preload" (`skills/reviewer-protocol/SKILL.md:11-13`).

## Full findings

### Two transport paths, one parameter contract

The QRSPI pipeline has **two** dispatch transport paths and **one** shared parameter contract.

The shared contract — the **Reviewer Dispatch Contract** in `skills/reviewer-protocol/SKILL.md:38-51` — enumerates the parameters every reviewer dispatch emits (whether Claude or Codex):

1. `artifact_body` (or `subject_code` per-step convention) — wrapped between `<<<UNTRUSTED-ARTIFACT-START id={artifact_name}>>>` / `<<<UNTRUSTED-ARTIFACT-END id={artifact_name}>>>` markers.
2. `round_subdir` — absolute path to `<ABS_ARTIFACT_DIR>/reviews/{step}/round-NN/`.
3. `round` — integer round number.
4. `reviewer_tag` — dispatcher-supplied tag (e.g. `quality-claude`, `spec-codex`).
5. `diff_file_path` — absolute path to the orchestrator-emitted `round-NN.diff` (omitted when not in a git repo).
6. `scope_hint` (optional) — wrapped between `<<<UNTRUSTED-SCOPE-HINT-START id=scope_hint>>>` / `<<<UNTRUSTED-SCOPE-HINT-END id=scope_hint>>>` markers; emitted only when the convergence rule narrowed for this round (`using-qrspi/SKILL.md` step 7.5).

The reviewer-protocol body (5-field finding schema, change-type classifier, untrusted-data handling, disk-write contract) is **never embedded in the dispatch prompt** by the dispatcher itself. Every per-skill SKILL.md states this verbatim at each reviewer dispatch site (representative: `skills/design/SKILL.md:160` "do NOT embed reviewer-protocol content in the dispatch prompt"; `skills/goals/SKILL.md:248`; `skills/plan/SKILL.md:282`; etc.).

### Path 1 — Claude-side dispatch (`Agent({...})`)

Claude-side reviewer/worker dispatches are written into per-skill SKILL.md as literal `Agent({ subagent_type: "qrspi-{name}", model: "sonnet" })` lines followed by a bulleted "prompt containing only" parameter list. Representative sites:

- **Goals reviewers** (`skills/goals/SKILL.md:240-258`) — `qrspi-goals-reviewer` + `qrspi-goals-scope-reviewer`. Both receive `artifact_body` (wrapped `goals.md`), `round_subdir`, `round`, `reviewer_tag`, `diff_file_path`, optional `scope_hint`. No companions.
- **Questions quality reviewer** (`skills/questions/SKILL.md:83-92`) — `qrspi-questions-reviewer`. Adds `companion_goals` (wrapped `goals.md`).
- **Research quality reviewer** (`skills/research/SKILL.md:125-154`) — `qrspi-research-reviewer`. Adds `companion_qfile_paths` (YAML-list of absolute paths the agent Reads directly — paths, not bodies). NO `companion_goals` / `companion_questions` per the research-isolation invariant. The dispatch has a Bash precondition gate (`tests/fixtures/check-qfile-paths.sh`) that must exit 0 before dispatch (`skills/research/SKILL.md:127-135`).
- **Design reviewers** (`skills/design/SKILL.md:150-170`) — `qrspi-design-reviewer` + `qrspi-design-scope-reviewer`. Quality adds `companion_goals` + `companion_research` (wrapped `goals.md` + `research/summary.md`); scope reviewer takes no companions.
- **Phasing reviewers** (`skills/phasing/SKILL.md:112-134`) — `qrspi-phasing-reviewer` + `qrspi-phasing-scope-reviewer`. Quality adds `companion_roadmap`, `companion_pruned_pairs` (concatenated 4 pruned + 4 future-* artifacts, each wrapped), `companion_goals_snapshot`, `companion_design_snapshot`.
- **Structure reviewers** (`skills/structure/SKILL.md:136-158`) — `qrspi-structure-reviewer` + `qrspi-structure-scope-reviewer`. Quality adds `companion_goals`, `companion_research`, `companion_design`, `companion_phasing`.
- **Parallelize reviewers** (`skills/parallelize/SKILL.md:168-188`) — `qrspi-parallelize-reviewer` + `qrspi-parallelize-scope-reviewer`. Quality adds `companion_plan` + `companion_tasks` (concatenated current-phase `tasks/*.md`, each wrapped).
- **Plan reviewers** (`skills/plan/SKILL.md:260-302`) — seven Claude reviewers in parallel: `qrspi-plan-reviewer` (unified quality), `qrspi-plan-spec-reviewer`, `qrspi-plan-security-reviewer`, `qrspi-plan-silent-failure-hunter`, `qrspi-plan-goal-traceability-reviewer`, `qrspi-plan-test-coverage-reviewer`, `qrspi-plan-scope-reviewer`. The six quality + artifact reviewers share companions (`companion_goals`, `companion_research`, `companion_phasing`, and full-pipeline-only `companion_design` + `companion_structure`) plus a plain scalar `route: full|quick`. Scope reviewer takes no companions and no `route`.
- **Replan reviewers** (`skills/replan/SKILL.md:121-140`) — `qrspi-replan-reviewer` + `qrspi-replan-scope-reviewer`. Quality adds `companion_goals`, `companion_plan`, `companion_design`, `companion_prior_review_findings` (concatenated `reviews/` files). `artifact_body` is the analyzer's inline-returned proposed-changes payload (not an on-disk artifact).
- **Integrate reviewers** (`skills/integrate/SKILL.md:95-120`) — `qrspi-integration-reviewer` + `qrspi-security-integration-reviewer`. Both receive `subject_code` (concatenated merged-task code files, each wrapped), `companion_design`, `companion_structure`, `companion_task_review_findings` (concatenated review-findings files).
- **Per-task implement reviewers** (`skills/implement/SKILL.md:797-811`) — eight reviewer dispatches (four correctness always; four thoroughness in deep mode): `qrspi-spec-reviewer`, `qrspi-code-quality-reviewer`, `qrspi-silent-failure-hunter`, `qrspi-security-reviewer`, plus `qrspi-goal-traceability-reviewer`, `qrspi-test-coverage-reviewer`, `qrspi-type-design-analyzer`, `qrspi-code-simplifier`. All receive `subject_code` (concatenated production code files, each wrapped) + `task_definition` (wrapped `tasks/task-NN.md`); goal-traceability adds `companion_plan` + `companion_goals`; test-coverage adds `companion_plan` + `companion_test_expectations`. Worked literal example at `skills/implement/SKILL.md:738-765`.
- **Visual-fidelity reviewer** (`skills/implement/SKILL.md:872-901`) — `qrspi-visual-fidelity-reviewer`. Receives `artifact_body` (wrapped task spec), `wireframe_paths` (YAML list of absolute paths, NOT wrapped bodies), `round_subdir`, `round`, `reviewer_tag: visual-fidelity-claude`, `diff_file_path`. Conditional on activation gate + path-validation precondition.
- **Test-phase reuse reviewers** (`skills/test/SKILL.md:126-150`) — three dispatches reuse per-task agents (`qrspi-spec-reviewer`, `qrspi-code-quality-reviewer`, `qrspi-goal-traceability-reviewer`). Each receives `subject_code` (test files), `companion_plan`, `companion_goals`, `output`, `round`, `reviewer_tag`. `task_definition` is **deliberately omitted** — its absence is the load-bearing phase-routing signal per `skills/reviewer-protocol/SKILL.md:170-204`.
- **Implement-gate reviewer** (`skills/implement/SKILL.md:1207`) — `qrspi-implement-gate-reviewer` at the batch gate.

The agent files for every reviewer carry `skills: [reviewer-protocol]` in frontmatter — this is the preload mechanism that delivers the protocol body to the agent at activation time. The reviewer-protocol skill body documents the mechanism at `skills/reviewer-protocol/SKILL.md:10-13`. All 38 reviewer agent files (and the implementer + lightweight implementer) carry this preload field (see frontmatter scan in agents/*.md).

### Path 2 — Codex-side dispatch (`scripts/run-codex-review.sh`)

Every Codex reviewer dispatch in every step skill calls one wrapper — `scripts/run-codex-review.sh` — with a CLI shape documented at `scripts/run-codex-review.sh:11-30`:

```
--agent-file <agent-md>
--reviewer-tag <tag>
--output-dir <ABS>
--round <N>
(--subject-code <path> | --artifact-body <path>)   # exactly one; repeatable
[--task-def <path>]
[--companion NAME=PATH ...]                         # repeatable
[--field NAME=VALUE ...]                            # plain scalar
[--diff-file <ABS>]
[--scope-hint '...']
[--dry-run]
```

The wrapper's prompt assembly is implemented in `compose_prompt()` (`scripts/run-codex-review.sh:508-538`). The composition order is fixed:

1. **Reviewer-protocol body**, frontmatter-stripped (`scripts/run-codex-review.sh:509`).
2. **Additional skills** named in the agent file's `skills:` frontmatter, frontmatter-stripped, each separated by `\n\n---\n\n` (`scripts/run-codex-review.sh:513-518`). Hardcoded `reviewer-protocol` is skipped to avoid double-loading (`scripts/run-codex-review.sh:315`). The frontmatter parser (`extract_skill_names()`, lines 281-298) accepts only the inline-list form `skills: [a, b]`; block-list or scalar forms are rejected with exit code 2.
3. **Agent body**, frontmatter-stripped (`scripts/run-codex-review.sh:519`).
4. **Codex emission override** — verbatim contents of `skills/reviewer-protocol/codex-emission-override.md` (`scripts/run-codex-review.sh:521`). This appears AFTER the agent body so it supersedes the agent's "Use the Write tool" directive (Codex runs in a read-only sandbox and emits findings on stdout).
5. **Structural boundary marker** — the literal line `AGENT-BODY-END (3-angle-bracket form)` (`scripts/run-codex-review.sh:536`). Everything BEFORE this marker is trusted protocol/agent body; everything AFTER is orchestrator-supplied dispatch parameters. The marker enables a positional carve-out for agent self-reference exception clauses (e.g. research-isolation Pre-Flight Check). The wrapper enforces marker uniqueness via the marker-injection guard at lines 376-413: any orchestrator-supplied input (file body OR scalar value) containing the literal marker is rejected with `exit 1` before composition runs.
6. **Dispatch parameters block** (`scripts/run-codex-review.sh:442-502`), under a `## Dispatch parameters` heading. The emission order is:
   - Primary-artifact field (`subject_code:` OR `artifact_body:`, header once) followed by every wrapped block from `--subject-code` / `--artifact-body` flags concatenated under that header.
   - `task_definition:` followed by the wrapped task-def body — emitted **only** when `--task-def` was passed. Absence is load-bearing for the Phase-Routing fail-loud check (per `skills/reviewer-protocol/SKILL.md:170-204`); the wrapper enforces this by inspecting `OUTPUT_DIR` for the `/reviews/test/` substring at agent-runtime, not at wrapper-emit time.
   - Companions: walked via parallel NAME/PATH arrays so multiple `--companion foo=A --companion foo=B` flags concatenate under a single `foo:` header (`scripts/run-codex-review.sh:464-478`). Each PATH's body is emitted wrapped between `<<<UNTRUSTED-ARTIFACT-START id={path}>>>` / `<<<UNTRUSTED-ARTIFACT-END id={path}>>>` (`emit_untrusted_artifact()`, lines 432-438).
   - Scalar fields from `--field NAME=VALUE` (no wrapping) — used for things like `route: full` (`scripts/run-codex-review.sh:480-483`).
   - `round_subdir: <OUTPUT_DIR>` (always), `round: <ROUND>` (always), `reviewer_tag: <REVIEWER_TAG>` (always) (`scripts/run-codex-review.sh:488-490`).
   - `diff_file_path: <DIFF_FILE>` — emitted only when `--diff-file` was passed (`scripts/run-codex-review.sh:492-494`).
   - `scope_hint: <<<UNTRUSTED-SCOPE-HINT-START id=scope_hint>>>{value}<<<UNTRUSTED-SCOPE-HINT-END id=scope_hint>>>` — emitted unconditionally when `--scope-hint` was passed, even with empty value (semantically equivalent to absence on the reviewer side per `skills/reviewer-protocol/SKILL.md:47`).

The composed prompt is piped to `scripts/codex-companion-bg.sh launch` on stdin (`scripts/run-codex-review.sh:555`), which spawns the Codex companion in background mode and prints a jobId to stdout (`skills/_shared/codex/launch-await-pattern.md:25`). The orchestrator captures the jobId from Bash stdout, runs `await <jobId>` redirected to a stdout-capture file later, and then `scripts/codex-finding-splitter.sh` materializes the per-finding files from Codex's stdout (e.g. `skills/goals/SKILL.md:315-320`).

The frontmatter-stripper used throughout (`strip_frontmatter()`, `scripts/run-codex-review.sh:426-428`) only eats the leading YAML frontmatter (between the file's first two `^---$` lines) and preserves body-level horizontal rules and fenced YAML mini-frontmatter examples.

### Non-reviewer dispatch sites

Several worker subagents have their own per-site parameter shapes that diverge from the reviewer contract:

- **Research specialist** (`qrspi-research-specialist`, `skills/research/SKILL.md:58-71`) — dispatched in parallel via concurrent Claude `Agent({...})` calls (one per assigned question or grouped set). Dispatch parameters:
  - `question_body` — wrapped body of the assigned `research/q*.md` question(s), bracketed between `<<<UNTRUSTED-ARTIFACT-START id=question>>>` / `<<<UNTRUSTED-ARTIFACT-END id=question>>>` markers.
  - `output_path` — absolute path the specialist writes its report to.
  - `question_ids` — comma-separated numeric IDs.
  - `defect_summary` (re-dispatch only) — orchestrator-authored sanitized defect summary.
  - Explicit isolation invariant: NO `companion_goals`, NO other-question content, NO raw `feedback/research-round-*.md` files (`skills/research/SKILL.md:71`). The agent file carries `skills: [research-isolation]` to deliver the Pre-Flight Isolation Check.

- **Research collator** (`qrspi-research-collator`, `skills/research/SKILL.md:85-95`) — dispatched once after all specialists complete. Parameters:
  - `qfile_paths` — list of absolute paths to `research/q*.md` files (paths, not bodies — collator Reads each file itself).
  - `output_path` — absolute path to the staging file `_collated.md` (orchestrator renames to `summary.md` after dispatch).
  - `defect_summary` (re-dispatch only).
  - Isolation invariant: NO `companion_goals`, NO `companion_questions`.

- **Replan analyzer** (`qrspi-replan-analyzer`, `skills/replan/SKILL.md:77-95`) — path-vs-body split:
  - Path inputs (analyzer Reads at runtime): `target_artifact`, `path_completed_phase_code`, `path_fixes_dir`, `path_reviews_dir`, `path_remaining_tasks_dir`.
  - Wrapped body inputs: `companion_plan`, `companion_design`, `companion_phasing`.
  - Explicit: NO `goals.md`. Returns proposed-changes payload inline (not on disk).
  - The Codex parallel for this dispatch is hand-rolled in-line (not via `run-codex-review.sh`) because the analyzer is a worker, not a reviewer (`skills/replan/SKILL.md:144-148`).

- **Test-writer** (`qrspi-test-writer`, `skills/test/SKILL.md:92-100`) — dispatched with a model resolved from `plan.md.test_writer_model` (default `sonnet`). Parameters:
  - `companion_plan` — wrapped `plan.md`.
  - `companion_goals` — wrapped `goals.md`.
  - `companion_design_or_research` — single key, route-selected: full pipeline → wrapped `design.md`; quick fix → wrapped `research/summary.md`.
  - `companion_fix_history` — concatenated wrapped bodies of every file under `fixes/` (or `NONE` sentinel when empty).
  - `companion_codebase_context` — concatenated wrapped bodies of key source files selected by the dispatcher from `structure.md`'s file map.
  - `output_dir` — absolute directory for written test files.

- **Implementer** (`qrspi-implementer` or `qrspi-implementer-lightweight`, `skills/implement/SKILL.md:514-525`) — model + variant resolved per task-frontmatter routing (`skills/implement/SKILL.md:490-506`). Parameters:
  - `mode` — `implement` or `fix`.
  - `task_definition` — wrapped `tasks/task-NN.md` (or `fixes/{type}-round-NN/task-NN.md` for fix mode).
  - `companion_pipeline_inputs` — concatenated wrapped bodies of upstream artifacts listed in the task's `pipeline` field (full pipeline: `goals.md`, `design.md`, `structure.md`, `parallelization.md` excerpts; quick fix: `goals.md`, `research/summary.md`).
  - `companion_review_findings` (fix-mode only) — wrapped bodies of prior-round Claude reviewer findings + Codex per-round files. The agent file's `skills: [implementer-protocol]` preload delivers the status-reporting contract and dispatch-parameter contract.
  - Across fix cycles, main chat retains the agent ID and re-enters via `SendMessage` rather than fresh `Agent({...})` dispatch (`skills/implement/SKILL.md:527`).

- **Finding verifier** (`qrspi-finding-verifier`, `using-qrspi/SKILL.md:673-721`) — dispatched once per finding-file in parallel. Parameters are all paths (no wrapped bodies):
  - `finding_file_path`, `sidecar_path`, `artifact_path`, `diff_file_path`.
  - `upstream_paths` — newline-separated list of upstream-artifact paths the current step consumes (per a per-step table in lines 709-720) plus `skills/<step>/SKILL.md` + `skills/using-qrspi/SKILL.md` appended on every step. The verifier may lazy-Read these for context.

- **Scope-tagger** (`qrspi-scope-tagger`, `using-qrspi/SKILL.md:798-821`) — dispatched once per round after the verifier filter. Parameters:
  - `round_subdir`, `output_path` (scope-set txt file), `step`.
  - `artifact_path` / `artifact_body` — per-step shape; single-file artifacts pass path + wrapped body; multi-file artifacts pass literal `null`.
  - `kept_findings` — newline-separated absolute paths to surviving finding-files.

### Wrapping convention — untrusted-data delimiters

Every embedded artifact body across both dispatch paths is fenced between paired tokens per `skills/reviewer-protocol/SKILL.md:142-152`:

```
<<<UNTRUSTED-ARTIFACT-START id={artifact_name}>>>
... raw content ...
<<<UNTRUSTED-ARTIFACT-END id={artifact_name}>>>
```

The `{artifact_name}` is a short stable identifier (e.g. `goals.md`, `tasks/task-18.md`, `src/lib/cas/artifacts.ts`, `question`, `replan-proposed-changes`, `test-expectations`, `fix-history`). For per-question research, the `id=question` form is used in the specialist dispatch (`skills/research/SKILL.md:62`). For visual-fidelity, the wrapper-applied `id` includes the source path (e.g. `id=tasks/task-NN.md`, `skills/implement/SKILL.md:878-880`).

`scope_hint` uses its own wrapper pair `<<<UNTRUSTED-SCOPE-HINT-START id=scope_hint>>>` / `<<<UNTRUSTED-SCOPE-HINT-END id=scope_hint>>>` (`skills/reviewer-protocol/SKILL.md:47`). Visual-fidelity's path-filtered audit record uses `<<<UNTRUSTED-PATH-START id=path-NN>>>` / `<<<UNTRUSTED-PATH-END id=path-NN>>>` per dropped path (`skills/implement/SKILL.md:831`).

The wrapping invariant is asserted by cross-cutting unit tests at `tests/unit/test-reviewer-boilerplate-embed.bats` (referenced in `skills/reviewer-protocol/SKILL.md:161`).

### Compaction-checkpoint signaling around dispatch

Every step skill's review-round section opens with a "Compaction checkpoint: pre-fanout" `TaskCreate` call that recommends `/compact` before the parallel reviewer dispatch fires (representative: `skills/goals/SKILL.md:232-234`, `skills/design/SKILL.md:140-142`, `skills/research/SKILL.md:117-119`, `skills/plan/SKILL.md` similar). The rationale stated at each site is that the parallel reviewer fan-out reads the artifact body + companions + the agent-embedded reviewer protocol, and saturated context multiplies bloat across the parallel set. The contract reference for this checkpoint is `using-qrspi/SKILL.md` `## Compaction Checkpoints`.

### Diff and scope-hint emission contract

Before each round's reviewer dispatch, the orchestrator runs `git -C "<repo>" diff "<ref>" -- "<artifact_path>" > "<ABS_ARTIFACT_DIR>/reviews/{step}/round-NN.diff"` as a Bash redirect (`skills/design/SKILL.md:146`, and identical paragraphs in goals/questions/research/phasing/structure/parallelize/plan/replan/implement). The diff content never enters main-chat context — reviewer dispatches carry `diff_file_path: <ABS_PATH>` only, and reviewers Read the file via the Read tool. Test-step is the documented opt-out from both the diff-file emission and the scope-tagger machinery (`skills/test/SKILL.md:104-106`).

`<ref>` selection follows the convergence rule in `using-qrspi/SKILL.md` step 7.5: rounds 1 and 2 always use `<base-branch>`; round NN+1 uses `HEAD~1` only when scope-set comparison narrows. The orchestrator follows a fail-loud preconditions sequence — artifact tracked in git, `mkdir -p`, `rm -f` of any pre-existing target as a regular file, then the redirect with quoted placeholders and exit-code check (`using-qrspi/SKILL.md:537-546`).

### Implementer SendMessage continuity

Implementer dispatches differ from reviewer dispatches in that main chat retains the agent ID per task across fix cycles and re-enters via `SendMessage` with the next round's `companion_review_findings` rather than via a fresh `Agent({...})` call (`skills/implement/SKILL.md:527`). The first fix cycle is a fresh dispatch; cycles 2 and 3 re-enter the same agent. The escape hatch (`BLOCKED` → model switch or task decomposition) explicitly requires a fresh `Agent({...})` dispatch and breaks the SendMessage chain (`skills/implement/SKILL.md:728`).

### Reviewer dispatch template (literal example)

`skills/implement/SKILL.md:738-765` carries a literal copy-paste reviewer dispatch prompt body example showing the assembled Path-1 shape:

```
## Dispatch parameters

subject_code: <<<UNTRUSTED-ARTIFACT-START id=src/lib/cas/artifacts.ts>>>
<full body of src/lib/cas/artifacts.ts, verbatim>
<<<UNTRUSTED-ARTIFACT-END id=src/lib/cas/artifacts.ts>>>

<<<UNTRUSTED-ARTIFACT-START id=src/lib/actions/memory.ts>>>
<full body of src/lib/actions/memory.ts, verbatim>
<<<UNTRUSTED-ARTIFACT-END id=src/lib/actions/memory.ts>>>

task_definition: <<<UNTRUSTED-ARTIFACT-START id=tasks/task-18.md>>>
<full body of tasks/task-18.md, verbatim>
<<<UNTRUSTED-ARTIFACT-END id=tasks/task-18.md>>>

output: <ABS_ARTIFACT_DIR>/reviews/tasks/task-18/round-01/
reviewer_tag: spec-claude
round: 1
diff_file_path: <ABS_ARTIFACT_DIR>/reviews/tasks/task-18/round-01.diff
```

The anti-pattern list at `skills/implement/SKILL.md:776-781` enumerates what is NOT in a dispatch prompt: no inlined diff content, no paraphrase of the task spec, no restatement of worktree path as English prose, no restatement of reviewer-protocol rules.

### Expected-Reviewer Matrix

The per-step set of expected reviewer tags is enumerated in `skills/reviewer-protocol/SKILL.md:19-36` as the Expected-Reviewer Matrix; the apply-fix step-2 schema guard uses this matrix to assert every expected tag emitted at least one `<tag>.finding-*.md` or `<tag>.clean.md` file under the round directory after dispatch. The matrix has two columns (codex_reviews: true vs false) and one row per artifact step; it is the canonical reference for "what dispatches fire at each site."

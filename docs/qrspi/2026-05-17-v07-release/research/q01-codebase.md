---
status: draft
question_ids: [1,26]
research_type: codebase
---

# Q1, Q26: Subagent model-choice surfaces and dispatcher classes

## Summary

**TL;DR:** Existing subagent dispatches express model choice through two layers: agent-file frontmatter (`model: sonnet|inherit|haiku|opus`) and dispatch-time overrides in `Agent({ ..., model: ... })` calls. The dominant dispatch-time pattern is a hardcoded inline `model: "sonnet"`; the two dynamic dispatch-time exceptions are Implement reading each task's `model` frontmatter and Test reading `plan.md`'s `test_writer_model` frontmatter. Dispatcher shapes fall into a small set of classes: research specialist/collator/reviewer, artifact reviewers, implementers, per-task/test reviewers, visual-fidelity reviewer, replan analyzer, verifier, scope-tagger, Codex wrapper dispatches, and SendMessage continuation for retained fix agents.

**Key findings:**
- Agent frontmatter is a session/agent-activation surface: `reviewer-protocol` and `implementer-protocol` state Claude Code preloads skill bodies via agent frontmatter at activation, so `model:` and `skills:` are agent-file metadata rather than prompt parameters (`skills/reviewer-protocol/SKILL.md:10-15`, `skills/implementer-protocol/SKILL.md:10-12`).
- Inline `Agent(..., model: "sonnet")` is the standard dispatch-time override across research, artifact review, implement review, integration, test review, and replan sites (`skills/research/SKILL.md:58`, `skills/implement/SKILL.md:736`, `skills/test/SKILL.md:126-146`, `skills/replan/SKILL.md:77`).
- Implement dispatch is task-frontmatter driven at dispatch time: main chat reads `task_type` and `model` from `tasks/task-NN.md` immediately before dispatch and forwards `model` as the per-invocation override (`skills/implement/SKILL.md:488-516`). Plan is the authoring site for the default heuristic and operator override (`skills/plan/SKILL.md:134-162`).
- Test-writer dispatch is plan-frontmatter driven at dispatch time: Test reads `test_writer_model` from `plan.md` and defaults to sonnet (`skills/test/SKILL.md:90-100`); Plan's template defines `test_writer_model: sonnet` as `sonnet|opus` (`skills/plan/SKILL.md:168-172`).
- Verifier and scope-tagger are frontmatter-only Haiku agents, dispatched by generic Task/Agent prompt shapes without an inline `model` field in the documented dispatch snippets (`agents/qrspi-finding-verifier.md:1-6`, `agents/qrspi-scope-tagger.md:1-6`, `skills/using-qrspi/SKILL.md:673-721`, `skills/using-qrspi/SKILL.md:776-819`).
- One mismatch exists between an agent-file default and a dispatch override: `qrspi-replan-analyzer.md` declares `model: opus`, but `replan/SKILL.md` dispatches it with inline `model: "sonnet"` (`agents/qrspi-replan-analyzer.md:1-4`, `skills/replan/SKILL.md:75-93`).

**Surprises:** The codebase contains no model-selection environment-variable dispatch surface in the searched `skills/`, `agents/`, `scripts/`, `hooks/`, and `tests/` paths; environment/config fields found in dispatch-adjacent code gate whether dispatches occur, not which model is used.

**Caveats:** This report is based on `skills/**/SKILL.md`, `agents/qrspi-*.md`, and dispatch-adjacent `scripts/`, `hooks/`, and `tests/` grep searches. I did not execute the QRSPI pipeline, so “read at session start” is inferred from documented Claude Code preload/activation contracts rather than runtime traces.

## Full findings

### Q1: Existing subagent dispatch sites and model-choice surfaces

#### Query planning

I searched for dispatch and model-choice markers in `skills/**/SKILL.md` and `agents/qrspi-*.md`: `subagent_type`, `Agent({`, `SendMessage`, `model:`, `test_writer_model`, and model/env terms (`MODEL`, `SONNET`, `OPUS`, `HAIKU`, `env var`, `ANTHROPIC`). I then read the dispatch-contract sections for Research, Implement, Test, Replan, the shared Reviewer/Implementer protocols, verifier, and scope-tagger.

#### Model surfaces present today

1. **Agent-file frontmatter (`model:`)**
   - Every `agents/qrspi-*.md` file has frontmatter `model:`. Counts from the current tree are: 33 `model: sonnet`, 5 `model: inherit`, 2 `model: haiku`, and 1 `model: opus`.
   - `model: inherit` appears on `qrspi-implementer`, `qrspi-implementer-lightweight`, `qrspi-research-specialist`, `qrspi-research-collator`, and `qrspi-test-writer`. Example: `qrspi-implementer` says model choice is handled by dispatcher per-invocation override and declares `model: inherit` (`agents/qrspi-implementer.md:1-6`).
   - `model: haiku` appears on the verifier and scope-tagger utility agents (`agents/qrspi-finding-verifier.md:1-6`, `agents/qrspi-scope-tagger.md:1-6`).
   - `model: opus` appears on `qrspi-replan-analyzer` (`agents/qrspi-replan-analyzer.md:1-4`), but the Replan skill dispatches that agent with inline `model: "sonnet"` (`skills/replan/SKILL.md:75-93`).

2. **Inline dispatch override (`Agent({ subagent_type: ..., model: ... })`)**
   - Research specialist and collator dispatches hardcode `model: "sonnet"` even though both agent files declare `model: inherit` (`skills/research/SKILL.md:54-65`, `skills/research/SKILL.md:73-91`).
   - Artifact reviewer dispatches hardcode `model: "sonnet"`. Examples include Goals quality/scope reviewers (`skills/goals/SKILL.md:240-250`), Design quality/scope reviewers (`skills/design/SKILL.md:150-162`), Research reviewer (`skills/research/SKILL.md:125-152`), Plan's seven-reviewer fanout (`skills/plan/SKILL.md:271-294`), and Implement per-task reviewers (`skills/implement/SKILL.md:736-811`).
   - Replan analyzer is dispatched with inline `model: "sonnet"` despite its agent-file `model: opus` (`skills/replan/SKILL.md:75-93`, `agents/qrspi-replan-analyzer.md:1-4`).
   - Visual-fidelity reviewer is dispatched with inline `model: "sonnet"` (`skills/implement/SKILL.md:872-901`), matching its frontmatter (`agents/qrspi-visual-fidelity-reviewer.md:1-3`).

3. **Task frontmatter (`tasks/task-NN.md` `model`) read at dispatch time**
   - Plan defines the classification heuristic for per-task `task_type` and `model`: lightweight tasks get `model: sonnet`; code tasks get `model: opus` for multi-file/core-surface/retry/sizing-exception cases, otherwise `sonnet`; operators may override before approval (`skills/plan/SKILL.md:134-162`).
   - Implement reads `task_type` and `model` from each task's frontmatter before dispatch, defaults missing legacy fields to `code`/`sonnet`, chooses the implementer subagent from `task_type`, and dispatches `Agent({ subagent_type: implementer_subagent, model: <model> })` (`skills/implement/SKILL.md:488-508`).
   - Implement explicitly says the agent file's `model: inherit` is the default that the per-invocation override replaces (`skills/implement/SKILL.md:514-516`).
   - Fix-cycle implementer dispatch reuses the same variant and model resolved from per-task routing; subsequent fix cycles use `SendMessage`, where model cannot change, and a BLOCKED escape requires fresh `Agent` dispatch for model switch (`skills/implement/SKILL.md:725-730`).

4. **Plan frontmatter (`plan.md` `test_writer_model`) read at dispatch time**
   - The Test skill reads `test_writer_model` from `plan.md` frontmatter and defaults to `sonnet`, then dispatches `Agent({ subagent_type: "qrspi-test-writer", model: "<plan.test_writer_model || 'sonnet'>" })` (`skills/test/SKILL.md:90-100`).
   - The Plan template defines `test_writer_model: sonnet` with allowed values `sonnet|opus` and describes it as an operator override for `qrspi-test-writer` (`skills/plan/SKILL.md:168-172`).

5. **No environment-variable model surface found**
   - Searches across `skills`, `agents`, `scripts`, `hooks`, and `tests` found environment/config fields for dispatch gating (`codex_reviews`, `verifier_enabled`, `scope_tagger_enabled`, `visual_fidelity_required`) but no environment-variable model selector. Codex availability is detected by plugin-path glob and persisted as `codex_reviews` in `config.md` (`skills/using-qrspi/SKILL.md:405-411`); that selects whether Codex reviews run, not a model value.

#### Dispatch time vs. session/activation time

- **Session/agent activation:** Agent-file frontmatter (`model`, `tools`, `skills`) is read by the Claude Code runtime when the agent activates. The shared protocols document that Claude reviewer agents load `reviewer-protocol` via `skills: [reviewer-protocol]` frontmatter at activation (`skills/reviewer-protocol/SKILL.md:10-15`) and implementers load `implementer-protocol` the same way (`skills/implementer-protocol/SKILL.md:10-12`). These lines document the frontmatter preload behavior; they do not describe a runtime prompt-field read.
- **Dispatch time:** Inline `Agent({ ..., model: ... })` values are resolved by the dispatching skill when it creates the subagent call. Hardcoded examples include Research and reviewer dispatches (`skills/research/SKILL.md:58`, `skills/implement/SKILL.md:736`). Dynamic examples include task-frontmatter implementer routing (`skills/implement/SKILL.md:488-516`) and plan-frontmatter test-writer routing (`skills/test/SKILL.md:90-100`).
- **Continuation time:** `SendMessage` is not a model-choice surface. Implement says the same retained implementer-fix agent is continued by agent ID, and model switching requires a fresh `Agent` dispatch because “model is fixed at spawn time and cannot change via `SendMessage`” (`skills/implement/SKILL.md:725-730`).

### Q26: Dispatcher classes and input/output shapes

#### Query planning

I grouped dispatch sites by input/output contract rather than by individual agent filename, because many reviewers share the same `reviewer-protocol` shape. I used `grep` for `Agent({`, `subagent_type`, `Dispatch parameters`, `Input contract`, `Output schema`, and `Per-Finding Disk-Write Contract`, then read representative sections and line-cited the canonical contract for each class.

#### Dispatcher classes in `skills/` and `agents/`

1. **Research specialist dispatcher**
   - **Dispatch site/model:** `Agent({ subagent_type: "qrspi-research-specialist", model: "sonnet" })` (`skills/research/SKILL.md:54-65`).
   - **Input shape:** `question_body` wrapped as untrusted artifact, `output_path`, `question_ids`, and optional sanitized `defect_summary` (`skills/research/SKILL.md:60-65`).
   - **Output shape:** The specialist writes `q*.md` directly to `output_path`; it does not return findings as text (`skills/research/SKILL.md:67-69`). The file template is defined in the agent contract and includes frontmatter plus `## Summary` and `## Full findings` (agent body, not re-read here beyond the dispatch contract).

2. **Research collation dispatcher**
   - **Dispatch site/model:** `Agent({ subagent_type: "qrspi-research-collator", model: "sonnet" })` (`skills/research/SKILL.md:73-91`).
   - **Input shape:** `qfile_paths` as absolute paths, `output_path` to `_collated.md`, and optional sanitized `defect_summary` (`skills/research/SKILL.md:87-91`).
   - **Output shape:** The collator writes `research/_collated.md`; orchestrator renames it to `summary.md` afterward (`skills/research/SKILL.md:75-81`, `skills/research/SKILL.md:95`).

3. **Artifact Claude reviewer dispatcher**
   - **Dispatch sites/models:** Standard artifact steps dispatch one or more `qrspi-*-reviewer` agents with inline `model: "sonnet"`; examples include Goals (`skills/goals/SKILL.md:240-250`), Design (`skills/design/SKILL.md:150-162`), Questions (`skills/questions/SKILL.md:79-83`), Research (`skills/research/SKILL.md:121-152`), Plan (`skills/plan/SKILL.md:257-294`), Phasing (`skills/phasing/SKILL.md:104-126`), Structure (`skills/structure/SKILL.md:132-150`), Parallelize (`skills/parallelize/SKILL.md:166-180`), Replan (`skills/replan/SKILL.md:103-132`), Integrate (`skills/integrate/SKILL.md:91-112`), and Implement gate (`skills/implement/SKILL.md:1207-1209`).
   - **Input shape:** The shared reviewer contract says every reviewer prompt carries `artifact_body` or `subject_code`, `round_subdir`, `round`, `reviewer_tag`, optional `diff_file_path`, and optional `scope_hint` (`skills/reviewer-protocol/SKILL.md:38-49`). Step-specific skills add companion inputs such as `companion_goals`, `companion_plan`, `companion_qfile_paths`, or `companion_test_expectations`; Research reviewer uses `artifact_body`, `companion_qfile_paths`, `round_subdir`, `round`, `reviewer_tag`, `diff_file_path`, and optional `scope_hint` (`skills/research/SKILL.md:137-152`).
   - **Output shape:** Claude reviewers write one file per finding as `<reviewer_tag>.finding-FNN.md` or a clean sentinel `<reviewer_tag>.clean.md` in the round directory; they return a five-line brief summary (`skills/reviewer-protocol/SKILL.md:208-258`).

4. **Codex reviewer dispatcher/wrapper**
   - **Dispatch site/model:** Codex reviews are not Claude `Agent` calls. The canonical wrapper is `scripts/run-codex-review.sh`, which concatenates reviewer protocol, frontmatter-stripped agent body, Codex emission override, and dispatch params, then pipes to `scripts/codex-companion-bg.sh launch` (`skills/reviewer-protocol/SKILL.md:10-15`). Implement documents the CLI shape for per-task Codex reviews (`skills/implement/SKILL.md:903-918`).
   - **Input shape:** Wrapper flags include `--agent-file`, `--reviewer-tag`, `--output-dir`, `--round`, repeatable `--subject-code`, optional `--task-def`, repeatable `--companion NAME=PATH`, `--diff-file`, and `--scope-hint` (`skills/implement/SKILL.md:903-918`).
   - **Output shape:** Codex emits findings on stdout because it is read-only; the orchestrator's splitter materializes the same per-finding files/sentinels as Claude reviewers (`skills/reviewer-protocol/SKILL.md:208-210`). `using-qrspi` states Codex review jobs are background-launched and awaited, with stdout redirected/split to the per-round directory rather than pasted into main chat (`skills/using-qrspi/SKILL.md:584-605`).

5. **Implementer dispatcher**
   - **Dispatch site/model:** Implement reads task frontmatter and dispatches `Agent({ subagent_type: implementer_subagent, model: <model> })`, where `implementer_subagent` is `qrspi-implementer` or `qrspi-implementer-lightweight` (`skills/implement/SKILL.md:488-516`).
   - **Input shape:** `mode`, wrapped `task_definition`, `companion_pipeline_inputs`, and `companion_review_findings` for fix mode (`skills/implement/SKILL.md:518-525`; also canonicalized in `skills/implementer-protocol/SKILL.md:14-23`).
   - **Output shape:** Implementer statuses are `DONE`, `DONE_WITH_CONCERNS`, `NEEDS_CONTEXT`, or `BLOCKED`, and main chat action depends on status (`skills/implement/SKILL.md:665-675`). `implementer-protocol` defines DONE as tests/build/typecheck/lint plus a committed worktree (`skills/implementer-protocol/SKILL.md:128-137`).

6. **Implementer SendMessage continuation dispatcher**
   - **Dispatch site/model:** First fix cycle is a fresh `Agent`; subsequent fix cycles use `SendMessage` to the retained implementer-fix agent ID (`skills/implement/SKILL.md:725-730`).
   - **Input shape:** The continued prompt supplies the new issue list / `companion_review_findings` for the same task context (`skills/implement/SKILL.md:725-727`).
   - **Output shape:** Same implementer status/action contract as fresh implementer dispatch. Model is not mutable on this path; model switch requires fresh `Agent` dispatch (`skills/implement/SKILL.md:727-728`).

7. **Per-task Implement reviewer dispatcher**
   - **Dispatch site/model:** Implement dispatches per-task reviewers with inline `model: "sonnet"` (`skills/implement/SKILL.md:734-811`).
   - **Input shape:** `subject_code`, `task_definition`, optional `companion_plan`, `companion_goals`, `companion_test_expectations`, `output`/`round_subdir`, `reviewer_tag`, `round`, optional `diff_file_path`, and optional `scope_hint` (`skills/implement/SKILL.md:738-797`).
   - **Output shape:** Same reviewer-protocol per-finding files or clean sentinel (`skills/reviewer-protocol/SKILL.md:208-258`).

8. **Visual-fidelity reviewer dispatcher**
   - **Dispatch site/model:** Conditional `Agent({ subagent_type: "qrspi-visual-fidelity-reviewer", model: "sonnet" })` when activation gates and path validation pass (`skills/implement/SKILL.md:813-872`).
   - **Input shape:** Exact prompt parameters are wrapped `artifact_body`, `wireframe_paths`, `round_subdir`, `round`, `reviewer_tag`, and optional `diff_file_path` (`skills/implement/SKILL.md:872-901`).
   - **Output shape:** Same reviewer-protocol finding/clean files; skip paths instead write orchestrator sentinels/audit files before proceeding (`skills/implement/SKILL.md:827-872`).

9. **Test-writer dispatcher**
   - **Dispatch site/model:** Test reads `test_writer_model` and dispatches `Agent({ subagent_type: "qrspi-test-writer", model: "<plan.test_writer_model || 'sonnet'>" })` (`skills/test/SKILL.md:90-100`).
   - **Input shape:** Wrapped `companion_plan`, wrapped `companion_goals`, route-selected `companion_design_or_research`, wrapped `companion_fix_history`, `companion_codebase_context`, and `output_dir` (`skills/test/SKILL.md:92-99`).
   - **Output shape:** The test-writer writes test files under `output_dir`; the skill text states the agent writes tests and does not fix code or run tests (`skills/test/SKILL.md:90-100`).

10. **Test-phase reviewer dispatcher**
    - **Dispatch site/model:** Test reuses `qrspi-spec-reviewer`, `qrspi-code-quality-reviewer`, and `qrspi-goal-traceability-reviewer` with inline `model: "sonnet"` (`skills/test/SKILL.md:126-146`).
    - **Input shape:** `subject_code`, `companion_plan`, `companion_goals`, `output`, `round`, and `reviewer_tag`; `task_definition`, `diff_file_path`, and `scope_hint` are intentionally omitted (`skills/test/SKILL.md:102-124`, `skills/test/SKILL.md:126-146`).
    - **Output shape:** Same reviewer-protocol files/sentinels; reviewer-protocol adds a fail-loud phase-routing violation when `task_definition` is present with `/reviews/test/` output (`skills/reviewer-protocol/SKILL.md:165-204`).

11. **Replan analyzer dispatcher**
    - **Dispatch site/model:** Replan dispatches `Agent({ subagent_type: "qrspi-replan-analyzer", model: "sonnet" })` (`skills/replan/SKILL.md:75-93`).
    - **Input shape:** Path inputs (`target_artifact`, `path_completed_phase_code`, `path_fixes_dir`, `path_reviews_dir`, `path_remaining_tasks_dir`) plus wrapped `companion_plan`, `companion_design`, and `companion_phasing` (`skills/replan/SKILL.md:77-91`).
    - **Output shape:** The analyzer returns proposed changes inline in its response; main chat captures that text and feeds it as `artifact_body` to replan reviewers (`skills/replan/SKILL.md:93-97`).

12. **Finding verifier dispatcher**
    - **Dispatch site/model:** Standard review loop dispatches one `qrspi-finding-verifier` Task per finding file when `verifier_enabled` is true (`skills/using-qrspi/SKILL.md:656-723`). The agent frontmatter declares `model: haiku` (`agents/qrspi-finding-verifier.md:1-6`).
    - **Input shape:** `finding_file_path`, `sidecar_path`, `artifact_path`, optional `diff_file_path`, and newline-separated `upstream_paths` (`skills/using-qrspi/SKILL.md:673-721`; `agents/qrspi-finding-verifier.md:32-40`).
    - **Output shape:** Writes `<finding>.score.yml` containing either `score: <int 0..100>` and `reason`, or `score: VERIFY_FAILED`; returns exactly one line `<reviewer_tag>.<finding_id>: <score>` or `VERIFY_FAILED` (`agents/qrspi-finding-verifier.md:49-65`).

13. **Scope-tagger dispatcher**
    - **Dispatch site/model:** Standard review loop dispatches one `qrspi-scope-tagger` Task per round after verifier fan-in when `scope_tagger_enabled` is true (`skills/using-qrspi/SKILL.md:776-819`). The agent frontmatter declares `model: haiku` (`agents/qrspi-scope-tagger.md:1-6`).
    - **Input shape:** `round_subdir`, `step`, `output_path`, `artifact_path`, `artifact_body`, and newline-separated `kept_findings` (`skills/using-qrspi/SKILL.md:798-819`; `agents/qrspi-scope-tagger.md:14-24`).
    - **Output shape:** Writes `round-NN-scope-set.txt` as comments plus one tag per line; returns two brief lines summarizing tag counts (`agents/qrspi-scope-tagger.md:50-96`).

#### Cross-class output normalization

- Reviewer-like dispatchers normalize to the same on-disk output shape regardless of Claude vs Codex environment: one finding per `<reviewer_tag>.finding-FNN.md` file, or one `<reviewer_tag>.clean.md` sentinel for zero findings (`skills/reviewer-protocol/SKILL.md:208-258`).
- Utility fanout dispatchers use small sidecar/fan-in files instead of modifying source findings: verifier writes `.score.yml` sidecars (`agents/qrspi-finding-verifier.md:49-65`), and scope-tagger writes a single `round-NN-scope-set.txt` (`agents/qrspi-scope-tagger.md:50-85`).
- Research and collation are direct-write report assembly dispatchers rather than reviewer dispatchers: specialists write `q*.md`, collation writes `_collated.md`, and the orchestrator performs a rename to `summary.md` (`skills/research/SKILL.md:67-95`).

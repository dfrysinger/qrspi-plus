## Config File Format and Writing

`config.md` lives in the artifact directory and is written during the Goals skill (after the artifact directory is created). It is the single source of truth for pipeline configuration.

**Full format:**

```yaml
---
created: YYYY-MM-DD
pipeline: full  # or: quick
second_reviewer: true  # or false
route:
  - goals
  - questions
  - research
  - design
  - phasing
  - structure
  - plan
  - parallelize
  - implement
  - integrate
  - test
review_depth: deep  # or: quick — added by Implement at phase start
review_mode: loop   # or: single — added by Implement at phase start
verifier_enabled: true  # set at run creation; edit directly between rounds to disable for the whole run
scope_tagger_enabled: true  # set at run creation; edit directly between rounds to disable convergence narrowing for the whole run
visual_fidelity_required: false  # set at run creation; when true, activates the visual-fidelity binding chain (design → phasing → plan → implement reviewer)
question_budget: 5  # integer; written only when pipeline: quick (caps Research specialist dispatch count for the run)
---
```

**Field definitions:**
- `created`: ISO date the run was created (set once, never updated)
- `pipeline`: human-readable label (`full` or `quick`) — informational only; `route` is authoritative
- `second_reviewer`: include a second-model reviewer in review rounds
- `route`: ordered list of skill names this run will execute (see `using-qrspi/SKILL.md` → "Route Templates")
- `review_depth`: `quick` (4 correctness reviewers) or `deep` (all 8) — written by Implement at phase start
- `review_mode`: `single` or `loop` — written alongside `review_depth`
- `verifier_enabled` (default `true`): gates `qrspi-finding-verifier` parallel dispatch + `change_type` score filtering. `false` skips dispatch; all findings flow via "no sidecar → keep"
- `scope_tagger_enabled` (default `true`): gates `qrspi-scope-tagger` per-round dispatch and convergence narrowing
- `visual_fidelity_required` (default `false`): activates the visual-fidelity binding chain (Design → Phasing → Plan → Implement reviewer)
- `question_budget` (default `5`, range 1-50): caps Research specialist dispatch under `pipeline: quick`. Written ONLY when `pipeline: quick`; absent on full-pipeline runs

A stray legacy `codex_reviews:` field is a hard validation error — never silently aliased to `second_reviewer:`.

**Writing `config.md`:** After the user selects a pipeline mode and answers the second-reviewer question, Goals writes `created`, `pipeline`, `second_reviewer`, `route`, `verifier_enabled: true`, `scope_tagger_enabled: true`, and `visual_fidelity_required` atomically. On `pipeline: quick`, Goals additionally writes `question_budget: 5`. `review_depth` and `review_mode` are added later by Implement.

**Behavioral semantics — `pipeline: quick` (auto-approve cascade and surviving human gates):**

1. **Auto-approve cascade for Questions, Research, and Plan.** These three autonomous steps still run their full review loops (primary reviewers, second-model reviewers, the verifier); findings still write to disk under `reviews/{step}/round-NN/`. The cascade auto-writes `status: approved` when a round produces zero kept findings AFTER verifier filtering (initial-clean OR first-fix-clean). The cascade is a single hop per step; if the fix round still carries kept findings, the step pauses via the standard Review-Loop Pause Gate. Per-skill cascade wiring lives in each skill body.

   **Trust model.** The cascade trigger reads the orchestrator's in-session "kept findings" count after fan-in; it does NOT read any on-disk `<reviewer-tag>.clean.md` sentinel. The on-disk sentinel is audit-trail, NOT trigger. The orchestrator is the EXCLUSIVE writer of the cascade clean sentinel (and of `path-filtered.md` and `bypass-attempt-NN.md` records); reviewer subagents MUST NOT write or emit the cascade clean sentinel. Pinning the trigger to the in-session count closes the clean-sentinel forgery surface.

   **Cascade audit log.** Every cascade auto-approval event MUST append-only a `cascade-auto-approve` JSON Lines entry to `<artifact_dir>/cascade-audit.log` BEFORE writing `status: approved`. The entry records the artifact name, ISO-8601 UTC timestamp, trigger round, contributing reviewer tags + sentinel file paths, and rationale (`initial-clean` or `first-fix-clean`). On audit-log write failure, HALT the cascade — same hard-stop pattern as the runtime-backfill write-back failures.
2. **Two mandatory human gates: Goals and Design (excluded from the cascade).** Goals captures user intent; Design captures the option-selection decision. The canonical Quick-Fix route omits Design; the exclusion-from-cascade contract applies whenever Design runs.
3. **Test phase: binary ship/fix gate.** Test under `pipeline: quick` presents a binary ship-or-fix decision rather than the multi-option per-failure menu. "ship" terminates; "fix" routes back to **Plan** and the fix round resumes from Plan onward.

**Second-model-reviewer detection:** Run `bash scripts/second-reviewer-available.sh`. On non-zero exit, skip the second-reviewer question and write `second_reviewer: false`. `second_reviewer: true` dispatch reuses the resolved agent `tier:` for both primary and second reviewer (no separate tier knob). If the probe exits 0, ask:

> Second-model reviews:
> 1) No second-model reviews
> 2) Use a second model for second reviews

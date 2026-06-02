---
status: approved
task: 11
phase: 1
pipeline: full
goal_ids: [G3]
task_type: code
model: sonnet
---

# Task 11: G3 dispatch-manifest provenance fields (`subagent_type` / `host` / `vendor` / `model` / `prompt_file` in `.dispatch-manifest.json`)

- **Target files:** skills/using-qrspi/SKILL.md (modify), scripts/run-codex-review.sh (modify), tests/acceptance/v07-phase1/test-phase1-acceptance.bats (modify)
- **Dependencies:** none. **Blocks:** T20 (G3 dispatch-script rename consumes this task's `scripts/run-codex-review.sh` dispatch-manifest provenance edits).
- **LOC estimate:** ~110

**Overview**

CD-1's universal dispatch architecture needs the `.dispatch-manifest.json` schema extended with resolved per-dispatch provenance so the off-LLM dispatch path is auditable end-to-end. This task lands the schema and write-side wiring on the pre-rename `scripts/run-codex-review.sh` so the changes are in place before T20 hard-renames the script to `scripts/dispatch-agent.sh`. (Why: see design.md ## CD-1 → "Dispatch manifest schema" subsection. Goal G3 is the dispatch-architecture umbrella; this task lands one of its CD-1 schema deliverables. G29 — the formerly-planned large-artifact escape-hatch goal — is moot per design.md ## G29 (absorbed by CD-1, no separate task ships).)

**Scope**

- **In:**
  - Persist resolved reviewer-dispatch provenance in `<round-dir>/.dispatch-manifest.json` entries emitted by the reviewer dispatch script under a `dispatch_spec` object: `subagent_type`, `host`, `vendor`, `model`, and first-party `prompt_file`.
  - Persist equivalent third-party dispatch provenance plus the job metadata needed to await and split third-party results.
  - Keep first-party orchestrator-facing dispatch payloads to the emitted spec line / `DISPATCH_FILE=<PROMPT_FILE>` reference shape; reviewer prompt assembly remains outside orchestrator tool-call arguments.
  - Make manifest writes atomic and append-safe for repeated invocations and multiple reviewer tags in the same round.

- **Out:**
  - Renaming `scripts/run-codex-review.sh` to `scripts/dispatch-agent.sh` and migrating consumer SKILLs — T20 owns under G3.
  - Adding host/vendor matrix branching inside the dispatch script — T20 owns under G3 (this task only records what the matrix resolved to).
  - Authoring a threshold rule or reviewer-side `artifact_path` parser contract — explicit non-goal per design.md ## G29 (G29 absorbed-by-CD-1).
  - Adding cleanup or regression-prevention prose to `skills/using-qrspi/SKILL.md` for the absorbed G29 surface — explicit non-goal per design.md ## G29 ("no separate v0.7.2 task ships under the G29 ID").

**Definition of done**

- First-party manifest entries written by the dispatch script include `dispatch_spec.subagent_type`, `dispatch_spec.host`, `dispatch_spec.vendor`, `dispatch_spec.model`, and `dispatch_spec.prompt_file` for every emitted first-party dispatch.
- Third-party manifest entries include the same resolved `host` / `vendor` / `model` provenance plus the third-party job metadata needed by the await-and-split path.
- Manifest append behavior is atomic and append-safe across multiple reviewer tags in one round and repeated invocations for the same output directory; no entries are lost or malformed.
- Orchestrator-facing dispatch remains a prompt-file reference / spec-line flow; no reviewer artifact body is assembled into orchestrator tool-call arguments.
- Acceptance coverage proves a reviewer dispatch is auditable end-to-end through `.dispatch-manifest.json`'s `dispatch_spec` object.

**Test expectations**

- Exercise a first-party reviewer dispatch and inspect `.dispatch-manifest.json` for a `dispatch_spec` object containing `subagent_type`, `host`, `vendor`, `model`, and `prompt_file`.
- Exercise a third-party/background dispatch path and inspect `.dispatch-manifest.json` for resolved `host`, `vendor`, `model`, plus the job metadata consumed by the await-and-split flow.
- Run repeated dispatch-script invocations against the same round output directory with multiple reviewer tags, then validate the manifest remains well-formed JSON with all expected entries present.
- Acceptance coverage verifies the orchestrator-facing dispatch payload stays a prompt-file reference while the manifest records resolved host/vendor/model provenance.

**References**

- goals.md ### G3 — dispatch-architecture umbrella goal (shell-pipeline splitter collapse + third-party renaming + provenance recording).
- design.md ## CD-1 → "Dispatch manifest schema" — locked first-party and third-party `dispatch_spec` shapes consumed by this task.
- design.md ## G29 — locked disposition that G29 is moot/absorbed by CD-1 with no standalone task; this task supplies the CD-1 schema fields that obviate G29's escape-hatch framing.
- structure.md ### `scripts/run-codex-review.sh` — Slice 1.2 manifest-provenance persistence, atomic append behavior, and cross-slice rename note.
- structure.md ### `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` — Slice 1.2 acceptance coverage for the manifest-auditable dispatch path.
- structure.md ### 10. Dispatch manifest schema — canonical first-party and third-party manifest entry shapes.

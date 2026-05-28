---
task: 16
status: approved
pipeline: full
task_type: lightweight
model: sonnet
phase: 1
goal_ids: [G17]
dependencies: [T14]
loc_estimate: 60
---

# Task 16: Update Integrate skill CI-gate to consume the new ci.yml workflow as canonical CI signal

- **Phase:** 1
- **Target files:**
  - `skills/integrate/SKILL.md` (Modify) — rewrite the existing CI-gate section so it consumes the `.github/workflows/ci.yml` run status on the head commit of the integrate branch via the `gh` CLI as the canonical green-CI signal.
- **Dependencies:** T14
- **LOC estimate:** ~60
- **Description:** Updates the CI-gate section of `skills/integrate/SKILL.md` so the canonical green-CI signal consumed by Integrate is the success of all jobs in the new `.github/workflows/ci.yml` workflow on the head commit of the integrate branch, queried via the `gh` CLI. The edit names the workflow by file path (`.github/workflows/ci.yml`) as the authoritative signal source, instructs Integrate to query workflow run status for the head commit of the integrate branch using the `gh` CLI, and requires success of all jobs in that workflow run (both the `lint` job and the `bash32` job) as the gate condition. The edit removes any prior ambiguity in the CI-gate prose about which workflow or which run is canonical for this repo and replaces it with a single named source. Exact `gh` invocation form (e.g., `gh run list`, `gh run view`, JSON query path) is left to Implement at execution time — the skill prose names the contract surface, not the literal command line.
- **Test expectations:**
  - The CI-gate section in `skills/integrate/SKILL.md` names `.github/workflows/ci.yml` as the canonical CI workflow file.
  - The CI-gate section states that Integrate queries the workflow run status on the head commit of the integrate branch via the `gh` CLI.
  - The CI-gate section requires success of all jobs in the workflow run as the gate condition rather than a subset.
  - The CI-gate section states that when the `gh` CLI query for the head commit returns zero workflow runs for `.github/workflows/ci.yml`, the gate FAILS with a named diagnostic identifying the missing run (e.g., "No CI workflow run found for commit SHA <sha>; CI may not have triggered yet") and does NOT pass — vacuous success (no runs found ≠ all jobs passed) is closed so an Integrate session against a head commit whose CI hasn't been triggered (for example immediately after a force-push) cannot bypass the gate.
  - No prior wording in the CI-gate section contradicts the `.github/workflows/ci.yml` canonical-signal contract.

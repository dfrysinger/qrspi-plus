---
status: approved
task: 4
phase: 1
pipeline: full
goal_ids: [G5]
task_type: tdd
tier: high
---

# Task 04b: Add subagent author-marker env wrap to scripts/dispatch-agent.sh

- **Target files:** `scripts/dispatch-agent.sh` (Modify), `tests/unit/test-dispatch-agent-author-marker.bats` (Create)
- **Dependencies:** none
- **LOC estimate:** ~50
- **Description:** Every dispatched subagent git command is wrapped with the subagent author-marker scheme so subagent commits carry the marker the G5 boundary check filters on. The `<agent>` interpolation is validated against the valid agent-name charset (lowercase letters, digits, hyphen) before being injected into the `GIT_AUTHOR_NAME` environment variable; an `<agent>` string failing the charset check halts dispatch with the `agent-name-charset-invalid:` named diagnostic and exits non-zero. The author-marker scheme is the literal Implement-layer chooses; Plan commits the behavioural shape (the marker prefix is `qrspi-`, the agent-name field is validated charset-safe before injection, the wrap is set on every dispatched git command not just the first one).
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - Subagent git commits in a synthetic fixture round carry the `qrspi-<agent>` author marker in `git log --format='%an'` (G5 Acceptance bullet 5).
  - An `<agent>` value containing characters outside the valid agent-name charset (e.g., a space, a control byte, a path separator) halts dispatch with the `agent-name-charset-invalid:` named diagnostic and exits non-zero before any git command runs (no silently-malformed marker).
  - The marker is set on every dispatched git command in the subagent's session, not just the first — proven by a fixture round with multiple commits.
  - The low-level (non-high-level) dispatch path is also wrapped (regression guard — the marker is a G5 invariant independent of CD-2 high-level mode).
  - A zero-length `<agent>` value (the empty string) halts dispatch with the `agent-name-charset-invalid:` named diagnostic and exits non-zero before any git command runs — the charset check rejects empty strings explicitly, not merely strings containing out-of-charset characters (test-coverage-claude R6-F03 — prevents the silent-`GIT_AUTHOR_NAME=qrspi-` failure mode where an empty agent name produces a marker with no discriminator).
- **cross_task_consumers:**
  - `skills/integrate/SKILL.md` (T21), `skills/test/SKILL.md` (T22) — disposition: `pass-through` (T21/T22 depend on the subagent author-marker behaviour to make G5's boundary check meaningful, but neither edits scripts/dispatch-agent.sh).
  - `scripts/orchestration-boundary-check.sh` (T19) — disposition: `pass-through` (T19's author-marker filter consumes the marker scheme this task installs; T19 does not edit this script).

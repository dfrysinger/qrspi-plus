# Quick-Fix Auto-Approve Branch

Read this file only when the run carries `pipeline: quick` in `config.md`. Full-pipeline runs do not invoke this branch.

When `pipeline: quick`, the human-approval gate is skipped after any review round (initial or post-fix) that produces zero kept findings. When this branch fires, the split, `status: approved` write, and `phase_start_commit` capture proceed automatically without waiting for user input.

## Verifier-gate precondition

"Zero kept findings" is satisfied only when the verifier has affirmatively confirmed the count — a vacuously-zero count from an undispatched verifier does NOT satisfy the gate and surfaces the round to the user as unverified (matching the HARD-GATE contract in `skills/implement/SKILL.md`). If `config.md` is missing or unreadable, the auto-approve branch does NOT fire — the orchestrator surfaces a named diagnostic and falls through to the standard human-approval gate (fail-loud, not silent fallback).

The gate passes when ANY of the following hold for the current round's directory (`reviews/plan/round-NN/`):

- At least one `.score.md` sidecar file exists AND every sidecar evaluates to no kept-blocker findings per the verifier's scoring rubric (see `agents/qrspi-finding-verifier.md` and `skills/implementer-protocol/SKILL.md`). A zero-byte sidecar does not constitute verifier affirmation. OR
- A `round-NN-verifier-disabled.md` marker file is present AND the marker conforms to the canonical schema defined in `skills/implement/SKILL.md` HARD-GATE (a marker failing schema validation, or whose round identifier does not match the current round, is treated as absent). OR
- `config.md` carries `verifier_enabled: false`. When this satisfies the gate, the orchestrator MUST append an audit-log entry before writing the split, `status: approved`, and `phase_start_commit` capture — recording: timestamp, run slug, step name (`plan`), and branch label (`auto-approve-verifier-disabled-config`). The audit entry is written to the cascade audit log if one exists, otherwise to the round directory. An attempt to auto-approve via `verifier_enabled: false` without successfully writing this audit entry MUST abort with a named diagnostic (fail-loud).

When none of these hold, the gate does NOT fire; the review round surfaces to the user as unverified and the standard human-approval gate runs.

## Post-fix round behavior

If a fix round still produces kept findings, the auto-approve branch does NOT fire. The orchestrator surfaces the remaining kept findings to the user. The branch fires only when the most recent review round — initial or post-fix — produces verifier-affirmed zero kept findings.

## Relationship to existing single-task plan behavior

The auto-approve branch supplements the quick-fix single-task plan behavior already documented in § Quick-Fix Plan Behavior. The single-task plan constraint continues to apply; the auto-approve branch adds only the conditional skip of the human-prompt step at the end of the existing approval flow.

Full-pipeline runs are unaffected — the human-approval gate runs as before and the branch is inert.

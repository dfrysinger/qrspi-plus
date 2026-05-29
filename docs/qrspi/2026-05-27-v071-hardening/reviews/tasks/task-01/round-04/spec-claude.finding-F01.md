---
finding_id: F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/tasks/task-01.md]
artifact: subject_code
round: 4
reviewer: spec-claude
orchestrator_override: FALSE_POSITIVE
override_reason: Claude read the wrong files. The worktree copy at .worktrees/qrspi-plus-v071/task-01/docs/qrspi/2026-05-27-v071-hardening/tasks/task-01.md contains the amended 14-bullet version per commit 9bebed0. The "stale" copies Claude cited are (a) the feature-branch-main copy at /Users/dfrysinger/code/qrspi-plus-v0.7.1/docs/qrspi/.../tasks/task-01.md (not yet merged from task-01 branch — expected stale) and (b) the agent-echo workspace copy at /Users/dfrysinger/Library/CloudStorage/Dropbox/copilot-workspace/agent-echo/v071-hardening/tasks/task-01.md (independent stale snapshot, not in the workflow). Verified manually: worktree file shows 14 bullets including bullet 14 "An `api_key_env` field containing characters outside [A-Za-z0-9_]..."
---

(See override frontmatter for adjudication. Original finding text preserved below for verifier audit.)

The dispatch task_definition and round-04.diff describe an amended 14-bullet spec for commit 9bebed0, but both on-disk copies of task-01.md are the pre-amendment 12-bullet version. The "current task-01.md" on disk does not accurately describe the implementation — it's missing the spec for two implemented behaviors.

Required action: Apply the amendment to both canonical file paths (or confirm git checkout state in qrspi-plus-v0.7.1).

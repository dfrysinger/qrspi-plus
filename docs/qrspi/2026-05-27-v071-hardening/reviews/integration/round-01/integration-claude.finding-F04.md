---
finding_id: R1-F05
severity: low
change_type: clarity
referenced_files: [agents/qrspi-test-writer.md]
artifact: integration
round: 1
reviewer: integration-claude
---

## qrspi-test-writer.md reference to .git/info/exclude is single-mechanism after T2 added a second mechanism

**Surface:** `agents/qrspi-test-writer.md:28`

Prose says: "The worktree-local `.git/info/exclude` already lists `.qrspi-commit-msg.txt`."
Describes only pre-T2 mechanism. T2 added committed root `.gitignore:4`. Both apply post-merge;
test-writer prose mentions only the older mechanism.

**Cross-task impact:** trivial — agent's commit will still work — but prose is incomplete.

**Suggested fix:** rewrite as "The scratch file is excluded by two independent mechanisms:
the worktree-local `.git/info/exclude` (added during worktree setup) and the committed
`.gitignore` entry (covers fresh clones). Both apply."

Worth fixing alongside F02 (R1-F02) since same file.

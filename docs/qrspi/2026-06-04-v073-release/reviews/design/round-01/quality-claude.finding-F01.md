---
finding_id: R1-F01
severity: high
change_type: correctness
referenced_files: ["docs/qrspi/2026-06-04-v073-release/design.md"]
artifact: design
round: 1
reviewer: quality-claude
---

The prose-design block for `skills/{integrate,test}/SKILL.md § Process Steps` (G5 solution (b)) contains the command:

  `git log <phase-base>..HEAD --author='!qrspi-' --oneline`

described as listing "any non-subagent-authored commits." Git's `--author` flag does NOT support `!` as a negation prefix — it treats `!qrspi-` as a literal regex pattern and matches commits whose author name contains the string `!qrspi-`. Since no commit author is named `!qrspi-something`, the command always returns empty output. The non-subagent-commit detection leg of `scripts/orchestration-boundary-check.sh` would silently report clean on every run, even when main chat has committed directly to the integration branch. This defeats the entire point of G5's observability check for committed violations.

The same erroneous command appears in G5's descriptive design prose (solution paragraph (b)) and in the prose-design block both, so the design document is consistently wrong on this point.

Fix: Replace `--author='!qrspi-'` with a pipeline that correctly isolates non-subagent commits, for example:
  `git log <phase-base>..HEAD --format='%H %an' | awk '$2 !~ /^qrspi-/ {print $1}' | head -10`
or (if `--perl-regexp` is available and acceptable):
  `git log <phase-base>..HEAD --perl-regexp --author='^(?!qrspi-)' --oneline`

The prose-design block must be corrected before implementation proceeds — as authored, the skill will instruct the orchestrator to run a command that returns nothing, making `orchestration-boundary.md` always empty on the commit-detection dimension.


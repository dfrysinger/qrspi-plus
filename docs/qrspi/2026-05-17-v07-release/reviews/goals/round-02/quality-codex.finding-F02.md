---
finding_id: R2-F02
severity: medium
change_type: correctness
referenced_files: [/Users/dfrysinger/Library/CloudStorage/Dropbox/claude-workspace/agent-bravo/docs/qrspi/2026-05-17-v07-release/goals.md:L299-L303, AGENTS.md:L9-L10, AGENTS.md:L100-L101]
artifact: goals
round: 2
reviewer: quality-codex
---

G17's trigger example is factually inconsistent with this repo's branch naming contract. The goal says a candidate CI trigger is pushes to `qrspi/*` branches, but the repo's agent protocol defines working branches as `{your-handle}/issue-{NNN}-{slug}` with handles like `qrspi-alpha/...`, `qrspi-bravo/...`, etc. A workflow keyed to `qrspi/*` would not match the actual agent branches this repo uses, so the "What we know so far" section is encoding the wrong baseline. Fix by rewriting the trigger candidate to match the real branch namespace or by describing the trigger requirement without a wrong concrete pattern.

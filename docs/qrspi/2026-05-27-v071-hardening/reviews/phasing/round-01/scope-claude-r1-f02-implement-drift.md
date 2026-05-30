---
finding_id: R1-F02
severity: medium
change_type: boundary-drift
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/phasing.md]
artifact: phasing
round: 1
reviewer: scope-claude
defers_to: implement
---

Three locations prescribe the concrete implementation mechanism at a level that belongs to Implement (or Design), not to Phasing. The DEFERS rule: "Implementation prose, code, hook syntax, subagent dispatch verbs -> owned by Implement and downstream skills. Skill-implementation jargon is a boundary-drift signal in phasing.md."

Instances:

- Slice 1: "`tr`+`wc` idiom" -- names the specific shell implementation technique. Phasing should say the detection logic is rewritten for POSIX correctness; the idiom choice belongs to Implement.
- Slice 6: "`task` tool with `model: gpt-5.3-codex`" -- prescribes the exact tool-call API signature for the Copilot CLI dispatch path. This is hook syntax owned by Implement.
- Replan gate criterion 3: "shell pipeline on Claude Code, `task` tool with `model: gpt-5.3-codex` on Copilot CLI" -- repeats the full transport-dispatch detail as a pass/fail condition. The gate criterion is appropriate (OWNS); the transport mechanism naming inside it is not. The criterion should reference the G6 acceptance condition by outcome (e.g., "dispatches succeed using the host-appropriate transport per design.md DKR7") without re-specifying which tool and model string to use.

Recommended fix: Remove `tr`+`wc` from Slice 1; replace with outcome language ("detection logic is rewritten to be POSIX-clean and BSD-grep-safe"). Strip the `task`/`model:` detail from Slice 6 and replan criterion 3; reference DKR7 by name for the mechanism.

(Materialized from inline subagent return; Claude scope-reviewer environment does not write to disk.)

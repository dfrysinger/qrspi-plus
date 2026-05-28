---
finding_id: R1-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/questions.md:L16-L17, docs/qrspi/2026-05-17-v07-release/goals.md:L108]
artifact: questions
round: 1
reviewer: quality-claude
---

Q16 cites the user's private memory path `~/.claude/projects/.../reference_keeplii_vfr_agent.md` directly inside the question text. Two problems with this citation:

1. **Unreachable for researchers.** The QRSPI Research step dispatches per-question specialist subagents. Those subagents do not run inside the operator's main Claude Code session and cannot Read paths under `~/.claude/projects/<session>/memory/` — that location is operator-private state, not a repo artifact. A specialist subagent receiving Q16 cannot fulfill the citation, so the question will either be answered without the referenced material or the specialist will spend tool calls failing to read the path. Either outcome makes the question worse than a version that does not reference the memory file at all.

2. **Goal leakage by citation.** The fact that the user has captured a reference to "a working Keeplii `qrspi-visual-fidelity-reviewer.md`" in memory is itself a goal signal — it tells the researcher that the v0.7 release intends to import or adapt that reviewer. The goal's framing ("study it before authoring related reviewer work") is the deliverable shape, not background. The question text "prescribes for handling explicit spec deltas vs. source-fidelity" further mirrors G11's exact framing ("implementers over-index on external source fidelity when specs include explicit deltas") and "drop this from source" instructions copies G11's "spec said to drop" phrasing.

Recommended fix: rewrite Q16 to ask only about the in-repo agent file (`agents/qrspi-visual-fidelity-reviewer.md`) and how current lift-style task specs surface delta-from-source instructions, without citing the memory path or reproducing G11's vocabulary. If the Keeplii reference truly is needed as a research input, surface it through the main-chat Research dispatch's per-question input attachments (the operator can paste the file body into the dispatch), not by asking the specialist to Read a path it cannot reach.

A revised Q16 might be: "How does the in-repo `agents/qrspi-visual-fidelity-reviewer.md` (if present) handle the relationship between task specs and the reference source they cite, and how do current task-spec templates surface intentional deviations from a referenced source?"

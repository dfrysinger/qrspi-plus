---
finding_id: R3-F02
severity: high
change_type: clarity
referenced_files: [docs/qrspi/2026-05-17-v07-release/questions.md:L26]
artifact: questions
round: 3
reviewer: quality-claude
---

Q20 lifts three distinctive G15 phrases verbatim into a single question, making the goal trivially inferrable from the question alone. The question asks about the boundary "between Replan's mechanical phase-snapshot work and the interactive scope-capture work owned by `skills/goals/SKILL.md`, and how does Replan today handle informal 'Ideas' surfaced during a phase?" — `mechanical phase-snapshot`, `interactive scope-capture`, and the quoted `Ideas` term are all G15's framing of the problem. A researcher reading Q20 alone can conclude the work is to draw or clarify exactly this Replan/Goals boundary, including how Ideas should be handled. Rewrite to ask current-state without the goal-derived vocabulary — for example, "What scope or responsibility does `skills/replan/SKILL.md` currently describe for itself relative to `skills/goals/SKILL.md`, and how does `skills/replan/SKILL.md` currently describe handling new items surfaced during phase completion that are not already formal goals?"

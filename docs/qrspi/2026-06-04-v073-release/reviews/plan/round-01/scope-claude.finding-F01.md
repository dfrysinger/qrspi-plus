---
finding_id: R1-F01
severity: high
change_type: scope
referenced_files: [docs/qrspi/2026-06-04-v073-release/plan.md:L152, docs/qrspi/2026-06-04-v073-release/plan.md:L711]
artifact: plan
round: 1
reviewer: scope-claude
---

plan.md contains TWO `## Task Specs` H2 sections — one beginning at L152 (markdown-bullet format, 38 tasks T01–T38) and a second beginning at L711 (YAML-front-matter-per-task format, also enumerating T01 onward). Per `skills/plan/owns-defers.md` § Plan OWNS, "Ordered task specs" names a single ordered list as the OWNS unit; every paragraph in plan.md "must trace to one of these" items. A second copy of the same OWNS surface does not trace to a distinct OWNS slot — it duplicates one.

The duplication is also a length-band drift signal. The OWNS preamble flags ~52 lines per task as the Keeplii corpus mean, projecting a 38-task plan to ~1976 lines (inside the 1000–2000 soft window). The two-section shape pushes plan.md to >2000 lines and ~6.8 KB per task — outside the band on the side the rule explicitly flags ("4000 lines signals task specs that have grown into design or implementation prose"). The second section's per-task content is in fact heavier and drifts into Implement-layer detail (see R1-F02), so the length signal is load-bearing here, not cosmetic.

Resolution scope: collapse to one `## Task Specs` section. The choice of which format to retain (compact markdown bullets vs. YAML-front-matter per-task block) is an authoring call, not a scope call; the scope concern is that exactly one ordered task-spec list exists under exactly one H2.

---
finding_id: R3-F02
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-06-04-v073-release/design.md]
artifact: design
round: 3
reviewer: quality-claude
---

The G5 prose-design block for `skills/using-qrspi/SKILL.md` (verbatim content destined for the skill file) states: "The structural observability hook (`scripts/orchestration-boundary-check.sh`) runs at every phase boundary and surfaces any violation in the batch-gate menu before the next phase advances." This is inaccurate under the design's own scope. Per G5(b), Step N — the directive that actually invokes `scripts/orchestration-boundary-check.sh` — is scoped to `<!-- prose-design: skills/{integrate,test}/SKILL.md § Process Steps -->` only. `skills/implement/SKILL.md` does NOT receive a Step N directive, so `reviews/implement/orchestration-boundary.md` is never produced. The G5 acceptance criteria confirm the asymmetry explicitly: "skills/integrate/SKILL.md and skills/test/SKILL.md both contain a `### Step N — Orchestration boundary observability check` block" (implement omitted). Consequently: (1) the cross-cutting note destined for `using-qrspi/SKILL.md` will tell orchestrators the hook "runs at every phase boundary" when it does not run at implement-phase completion; (2) the batch gate additions scoped to `{implement,integrate,test}/SKILL.md` add a conditional item ("when `reviews/<phase>/orchestration-boundary.md` is non-empty") that for implement will always see absent/empty — dead code. The fix is either: (a) scope the cross-cutting note to "runs at the Integrate and Test phase boundaries" and scope the batch gate changes to `{integrate,test}/SKILL.md` only, deferring implement coverage with an explicit note; OR (b) also add Step N to `implement/SKILL.md` to make the "every phase boundary" claim accurate.


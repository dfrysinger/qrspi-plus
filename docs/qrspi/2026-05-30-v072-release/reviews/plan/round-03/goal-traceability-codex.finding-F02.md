---
reviewer_tag: goal-traceability-codex
change_type: correctness
severity: low
artifact: plan.md
location: Task 44 → Scope → Out bullet enumerating G24-F01/F02/F03/F04 dispositions
referenced_files: [plan.md, goals.md, design.md]
---

# F02 — T44 moot-status rationale for G24-F04 does not match the cited design anchor

`plan.md:2370` says G24-F04 is "absorbed into the G3/CD-1 dispatch rewrite" and cites `design.md ## G24`.  
In the cited design section, F04 is marked moot because the old regex pattern is no longer present at meaningful volume (`design.md:2064`), not absorbed into CD-1/G3.  
That makes the citation rationale inaccurate for F04 in this bullet, even though the "no standalone task" outcome is correct.

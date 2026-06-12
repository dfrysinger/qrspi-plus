---
verifier_status: passed
score: 80
actual_model: unknown
defect_class: unanchored-claim
---

Cite Check: design.md L389–407 contains G6 as quoted; L395–397 contain the validation steps including "the recorded task-tip SHA list (the wave manifest / branch map records this at task-creation time)"; L404 explicitly says "Depends on the wave manifest / branch map recording the task-tip SHAs at task-creation time (existing — implement/SKILL.md § Wave Dispatch step 6, parallelize/SKILL.md § Branch Map both already capture this)." research/summary.md L160–168 (Q11/Q12 section) directly contradicts: L160 "explicitly prohibits writing resolved SHAs back to that artifact"; L166 "The `Base` column in `parallelization.md`'s Branch Map is **always symbolic** … Implement resolves each to a concrete commit in-memory at runtime; resolved SHAs are never written back to `parallelization.md`." All cites verified.

The finding is correct: G6 leans on a "recorded task-tip SHA set" that research explicitly says is not recorded — the Branch Map is symbolic by design, and SHAs are resolved in-memory at dispatch time. The validation as written is "meaningless against an absent expected set" (G6 itself acknowledges this in passing but defers to alleged existing capture). The expected set must come from somewhere — either captured at merge-prep time from the named branch tips, or otherwise constructed. This is a load-bearing correctness gap in the Solution + Dependencies section.

Not 100 because there is a defensible read where the "expected set" can simply be `git rev-parse <task-branch-tip>` at the moment of merge prep (no artifact recording needed) — i.e., the design's intent may be sound but the prose is wrong about where the SHAs come from. Either way, G6 needs revision to fix the contradiction. Strong, well-cited correctness finding.

---
verifier_status: passed
score: 55
actual_model: unknown
defect_class: step-order-mismatch
---

Verified L393–397 of design.md. The numbered steps in the G6 Solution are indeed presented out of execution order: step 1 describes a post-merge read ("After `git merge --no-ff …` creates the stage commit, read the actual parent SHAs"), while step 2 contains a pre-merge capture procedure ("immediately before invoking `git merge --no-ff …`, the wave-dispatch step captures …"). The quoted strings in the finding match the artifact exactly, so Cite Check passes.

The criticism is structurally real: a numbered list in a design doc should be readable in execution order, and reversing pre- vs post-merge steps creates a foot-gun for an implementer who skims. However, the severity is moderated by two facts:

1. Step 2's prose is explicit and self-locating ("immediately before invoking `git merge --no-ff`"), so a careful implementer cannot actually mis-sequence the capture — the procedural anchor is in the text itself, not just in the list ordinal.
2. Step 3's validation invariants reference "captured_integration_base_sha" and "captured_task_tip_shas" by name, again signaling that capture must precede merge.

So the design is correct-in-prose but confusing-in-presentation. The proposed reorder (capture → merge+read → validate) is a clean, mechanical fix and improves readability without changing semantics. Worth fixing, not load-bearing for correctness. Scoring 55 — real moderate issue, clearly verifiable, but not a true blocker because the procedural text disambiguates the order even when the list ordinal misleads.

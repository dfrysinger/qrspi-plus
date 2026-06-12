---
artifact: design
reviewer_tag: quality-codex
finding_id: quality-codex-F01
change_type: correctness
---

# G6 solution orders parent capture AFTER the merge it must precede

## Location

design.md G6 Solution L393-397 (numbered steps).

## Finding

Step 1 says "after `git merge --no-ff`, read actual parents". Step 2 says "immediately before invoking `git merge --no-ff`, capture HEAD as integration-base". Step 2 is pre-merge but listed after step 1 (post-merge). An implementer following list order cannot perform the capture correctly — HEAD is already mutated by the merge.

## Expected fix

Reorder: step 1 = capture expected parents (pre-merge); step 2 = merge + read actual parents (post-merge); step 3 = validate both invariants.

---
finding_id: R1-F03
severity: medium
change_type: clarity
referenced_files: [skills/implementer-protocol/SKILL.md, .gitignore]
artifact: integration
round: 1
reviewer: integration-claude
---

## implementer-protocol/SKILL.md justification line factually incorrect after T2's gitignore landing

**Surface:** `skills/implementer-protocol/SKILL.md:241` ↔ `.gitignore:3-4`

T2 added committed gitignore entry for `.qrspi-commit-msg.txt` at `.gitignore:3-4`.
`test-commit-hygiene-invariants.bats:211-216` pins this; design DKR2 makes the
committed gitignore the new structural mechanism.

But `implementer-protocol/SKILL.md:241` step 4 of the "Commit Before Reporting" procedure
still reads:
> `rm <worktree>/.qrspi-commit-msg.txt` (the scratch file is not gitignored and you don't want it in the next round's diff).

The parenthetical justification is now factually false at the repo level; line 174's
Invariant 3 description of worktree-local-exclude is not updated to mention the new
gitignore as a sibling guard.

**Cross-task impact:** T2 added one mechanism without retiring/reconciling the older
mechanism's prose. The `rm` step is still useful (worktree-local diff hygiene), but the
stated reason misleads any future maintainer auditing the invariants.

**Suggested fix:**
1. Line 241: replace parenthetical with round-NN-diff justification ("the file is gitignored
   but you don't want it in the worktree at all between rounds").
2. Lines 176-181: extend Composition section with a fourth bullet noting the committed-gitignore
   as a structural fourth layer that closes the fresh-clone gap independently of worktree setup.

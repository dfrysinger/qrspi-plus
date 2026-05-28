---
finding_id: R5-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L555-L564]
artifact: design
round: 5
reviewer: quality-claude
---

G12's commit-sequence prose contains an incorrect self-description about which steps changed relative to the prior protocol, in a way that obscures the actual behavioral delta downstream agents are being asked to implement.

The proposed sequence (L555-L562) is:

1. `git status --porcelain` — nothing-to-commit guard.
2. Stage tracked work: `git add -A`.
3. Write commit message to `<worktree>/.qrspi-commit-msg.txt`.
4. Commit: `git commit -F <worktree>/.qrspi-commit-msg.txt`.
5. Post-commit cleanup: remove the scratch file.
6. Capture commit SHA: `git rev-parse HEAD`.

Immediately after, L564 asserts: "Step 5 (scratch removal) is the round-1 reorder relative to the prior protocol; steps 1-4 and 6 are unchanged."

That claim does not match the prior protocol documented in `skills/implementer-protocol/SKILL.md` § Commit Before Reporting (per research summary Q17, lines 244–252), which is:

1. `git -C <worktree> status --porcelain`.
2. Write commit message to `<worktree>/.qrspi-commit-msg.txt`.
3. `git -C <worktree> add -A && git -C <worktree> commit -F .qrspi-commit-msg.txt`.
4. `rm <worktree>/.qrspi-commit-msg.txt`.
5. `git -C <worktree> rev-parse HEAD`.

Two changes are present in the proposed sequence, not one:

- **Step split:** the prior single step (`git add -A && git commit -F`) is split into two distinct steps (proposed step 2 `git add -A`, proposed step 4 `git commit -F`).
- **Order swap:** the scratch-file write is moved from BEFORE staging (prior step 2) to AFTER staging (proposed step 3).

The order swap is the load-bearing change that actually prevents the bug — within a single commit cycle, the scratch file does not exist on disk when `git add -A` runs, so it cannot be staged. The post-commit `rm` (proposed step 5) is a secondary defense for the NEXT round's staging cycle, not the primary fix.

The line-564 rationale ("The reorder guarantees the scratch file is gone before any subsequent `git add -A` runs, so even when `.git/info/exclude` is absent ... the next staging cycle finds nothing to accidentally include") describes only the secondary defense. It does not describe the primary fix that the proposed step order accomplishes.

Why this matters: downstream agents (Phasing, Structure, Plan) read this section to author the protocol edit. If an agent trusts the "steps 1-4 and 6 are unchanged" assertion, it may write a task spec that preserves the prior `git add -A && git commit -F` combined form while only adding a post-commit `rm` — which would leave the original bug intact when `.git/info/exclude` is absent (e.g., a worktree set up by a non-QRSPI mechanism, exactly the case the design's "defense in depth" framing is meant to cover at L580). The resilience test at L589 ("even with `.git/info/exclude` artificially emptied, the post-commit cleanup still removes the scratch file after `git commit -F`, so a subsequent `git add -A` finds nothing to stage") is correct for the proposed sequence but only because the staging-vs-message-write order has been swapped — the test wording itself does not surface the swap.

Suggested fix: replace L564 with explicit before/after numbering or call out both changes:

> Two changes relative to the prior protocol: (a) `git add -A` is split out from `git commit -F` and runs BEFORE the commit message is written to scratch, so the scratch file does not exist on disk during staging; (b) a new post-commit cleanup step removes the scratch file after `git commit -F`, so the next round's `git add -A` also finds nothing to stage. Together with the `.git/info/exclude` entry from G12's primary defense, the bug is closed even when one of the three defenses is absent.

The behavioral outcome the design intends is correct; only the prose self-description of what changed is wrong.

---
finding_id: R3-F02
reviewer: security-claude
verifier_score: 80
verdict: KEEP
---

Verified confused-deputy: T27 L866 "sibling-allowed path enumerated in the task spec" is unbounded set. Bound to within artifact-dir or project worktree. Add T30 pin expectation covering rejection of out-of-tree sibling-allowed paths.

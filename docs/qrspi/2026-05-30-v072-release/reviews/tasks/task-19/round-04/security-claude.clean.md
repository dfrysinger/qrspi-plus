---
reviewer_tag: security-claude
round: 4
status: clean
head: a312e49
---

# security-claude — round 4 — CLEAN

The `[ -z "$_default_vendor" ]` guard closes a pre-existing fail-open path
(empty lookup + recognised override vendor) and introduces no new fail-open
path. The fault-injection bats test uses single-quoted heredocs (no shell
expansion), mktemp-generated paths, and static literal arguments — no
injection or path-traversal risk.

---
finding_id: R2-F03
severity: medium
change_type: correctness
referenced_files:
  - tests/unit/test-plan-post-approval-split.bats
reviewer_tag: silent-failure-claude
---

Hash normalization ambiguity. Two distinct patterns compute hashes:
- Pattern A (+327, +376-377): direct printf '...\n' → block fed to shasum ends with \n (preserved after sed)
- Pattern B (+461, +476, +570, +583, +684-685, +920): block_v1=$(printf '...\n') captures-and-strips trailing newlines; printf '%s' "$block_v1" → block fed to shasum ends WITHOUT \n

Produces different SHA-256 hashes for equivalent block content. Self-consistent within each test (both sides use same pattern), so each test passes. But:
1. Two tests exercise same contract property with incompatible hash computations.
2. If real orchestrator implements one variant, tests provide false green signal for the other.
3. Contract (+37) does not specify whether terminating newline of final line is in hash input.

Most affected: partial-crash (Pattern A, +327/+352) vs mismatch HALT (Pattern B, +461/+476).

Fix: contract must specify trailing-newline normalization explicitly, then tests must use one consistent pattern matching contract.

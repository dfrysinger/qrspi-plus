---
finding_id: R3-F02
reviewer_tag: cq-claude
round: 3
severity: low
change_type: clarity
referenced_files: [tests/acceptance/v07-phase1/test-phase1-acceptance.bats]
---

# cq-claude F02: ~15-line dispatch-env fixture setup copy-pasted across AC9/10/11

**Location:**
- AC9 setup: 1519-1538
- AC10 setup: 1593-1612
- AC11 setup: 1658-1677
- (Pre-existing AC5 also: ~1393-1421)

Each test opens with an identical ~15-line block (tmp src, stub skill/agent/dispatcher, etc.). BATS supports helper functions outside @test blocks. Future changes (e.g., new required skill file in compose_prompt) require updates to all 4 blocks.

**Suggested fix:** Extract `_setup_t09_dispatch_stub_env()` helper; tests call it then proceed to unique assertions.

**Convergent with cq-codex F02. DEFER candidate** (test-file modularization is already in v0.7.3 backlog).

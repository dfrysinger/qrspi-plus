---
finding_id: R3-F02
reviewer_tag: cq-codex
round: 3
severity: low
change_type: clarity
referenced_files: [tests/acceptance/v07-phase1/test-phase1-acceptance.bats]
---

# cq-codex F02: Duplicated test setup in AC9/AC10/AC11

**Where:**
- Repeated fixture scaffolding: tests/acceptance/v07-phase1/test-phase1-acceptance.bats:1519-1539, 1593-1613, 1658-1677
- Repeated dispatch invocation pattern: 1544-1555, 1623-1634, 1686-1697

The three new tests duplicate large setup blocks (tmp repo layout, stub files, mock dispatcher, output dir, command launch), adding substantial repeated code to a ~1.9k-line file.

**Why this matters:** Maintenance cost and drift risk; future setup changes must be synchronized across multiple blocks.

**Suggested fix:** Extract shared setup + runner helpers (e.g., `_t9_setup_minimal_dispatch_fixture`, `_t9_run_dispatch_capture`) and keep each test focused on only its unique assertions.

**DEFER candidate:** The test-file modularization v0.7.3 backlog item already exists; this finding is convergent with that.

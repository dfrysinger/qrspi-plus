---
finding_id: F02
reviewer_tag: code-quality-codex
round: 3
severity: low
change_type: scope
referenced_files:
  - tests/unit/test-change-type-partition.bats
artifact: tests/unit/test-change-type-partition.bats
---

# Continued growth of a monolithic test file hurts maintainability

Materialized from chat-only response by gpt-5.3-codex.

The file now ~550+ lines mixing protocol text checks, fixture integration checks, helper-hardening checks, and repository-grep lint checks. The +101 R2 lines increase cognitive load.

Recommendation: split into focused Bats files (helper behavior vs fan-in enum behavior vs protocol/duplication lint assertions).

**Status:** DEFER to v0.7.3 backlog — test-file modularization is out of T05's scope (G13 change_type enum drift hardening). Recording for replan.

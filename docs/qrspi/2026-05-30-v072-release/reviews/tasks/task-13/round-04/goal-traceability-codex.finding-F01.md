---
finding_id: R4-F01
severity: medium
change_type: correctness
referenced_files: [tests/unit/test-scope-tagger-dispatch.bats, scripts/round-prepare.sh]
---

# F01 — Missing pinning test for the later-round happy path ("advances past prior anchor")

**Goal anchor:** goals.md G9 requires durable per-round artifacts and correct between-round orchestration (goals.md:234-264).

**Task criterion:** Test expectation explicitly calls for happy-path commit-anchor write when SHA matches HEAD AND advances past prior anchor (tasks/task-13.md:47).

**Implementation behavior exists:** later-round non-advance guard is implemented in round-prepare.sh (L145-160), and anchor write is implemented (L228-237).

**Current tests are incomplete for this criterion:**
- Round-1 happy path is tested (test-scope-tagger-dispatch.bats:592-619).
- Later-round failure (equal prior anchor -> exit 12) is tested (~L698-717).
- But there is no test proving later-round success when prior anchor exists and implementer SHA is newer/different.

**Why this matters:** The criterion's "advances past prior anchor" happy path is only indirectly inferred, not pinned; a regression could break later-round success while keeping current tests green. Convergent with test-coverage-claude.finding-F01.

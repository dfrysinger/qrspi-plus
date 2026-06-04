---
finding_id: R4-F03
reviewer: cq-codex
severity: low
change_type: style
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats
---

# F03 — Test-file decomposition is becoming unwieldy; consider extracting fixture builders / splitting acceptance file

**File:** tests/acceptance/v07-phase1/test-phase1-acceptance.bats lines 2217-2633.

T11 added a large block (AC1/AC2/AC3/AC4/AC5/AC6) to an already-very-large acceptance file. Repeated fixture setup boilerplate across all 6 ACs (mock dispatcher, fake REPO_ROOT, fake artifact-dir, etc.) totals ~400 lines of copy-paste. The fixture builder pattern is screaming for extraction.

**Suggestion (deferred to v0.7.3 backlog):**
- Extract `_setup_dispatch_manifest_fixture()` helper into a `tests/acceptance/v07-phase1/helpers/dispatch-manifest.bash` and source it.
- Or split the dispatch-manifest acceptance coverage into a dedicated file `test-dispatch-manifest.bats`.

**Severity LOW** — purely maintainability; no functional defect. File as v0.7.3 backlog.

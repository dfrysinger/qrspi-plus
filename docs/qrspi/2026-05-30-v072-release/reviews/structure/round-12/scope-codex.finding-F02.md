---
finding_id: F02
severity: medium
change_type: scope
artifact: structure
referenced_files:
  - /Users/dfrysinger/code/qrspi-plus-v0.7.2/docs/qrspi/2026-05-30-v072-release/structure.md
---

The new `tests/unit/test-second-reviewer-available.bats` block specifies test-body detail rather than behavior-level layout: it gives an executable command (`COPILOT_CLI=1 bash ...; echo $?`), exact expected exit checks, stderr token assertions, and a mutation-fixture proof. Structure owns test file existence plus one-line behavior, but defers assertion code/assertion text to Implement/TDD.

**Location:** structure.md:1790-1794

**Fix:** Collapse this to behavior-level coverage, e.g. "pins default second-reviewer availability for supported hosts, unavailable diagnostics for unknown hosts, and shared-matrix use," leaving concrete commands/assertions to Plan/Implement.

(Persisted by orchestrator from Codex chat-only return.)

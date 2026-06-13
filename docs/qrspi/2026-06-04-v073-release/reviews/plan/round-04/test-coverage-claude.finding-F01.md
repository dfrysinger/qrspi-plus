---
finding_id: R4-F01
severity: medium
change_type: correctness
referenced_files: ["docs/qrspi/2026-06-04-v073-release/plan.md:L185"]
artifact: plan
round: 4
reviewer: test-coverage-claude
---

T01's test expectation at line 185 reads: "Plan-step with missing or malformed `config.md` halts with the documented named diagnostic and exits non-zero (G4 Acceptance bullet 3)." The phrase "the documented named diagnostic" references a diagnostic that is never named anywhere in the plan — not in the T01 description (line 178, "halts non-zero with its own named diagnostic"), not in the Phase 1 acceptance criteria (line 141, "exits non-zero with its own named diagnostic"), and not in any cross-task reference. A test writer implementing `tests/unit/test-upstream-paths.bats` cannot write a deterministic `assert_output --partial "<diagnostic>"` assertion without the specific string. Compare: every other fallible operation in the plan names its diagnostic explicitly (e.g., `sha-format-invalid:` in T03/T25, `review-prep-corrupt-artifact-dir:` in T03, `obc-unknown-phase:` in T19, `version-source-missing-or-malformed:` in T28). The missing/malformed `config.md` case should name its diagnostic (e.g., `config-missing:` / `config-malformed:`) so the RED gate test can assert both non-zero exit AND the correct diagnostic prefix.


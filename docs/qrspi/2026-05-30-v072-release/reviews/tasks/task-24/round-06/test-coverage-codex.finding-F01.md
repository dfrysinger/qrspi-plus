---
finding_id: F01
severity: medium
change_type: correctness
referenced_files: [tests/unit/test-detect-interaction-mode.bats]
---
Coverage gap: grep-regression tests check absence of host literals only in skills/ and agents/, not an allowlist asserting the literals appear ONLY in scripts/detect-interaction-mode.sh + the test file. Literals could drift into other consumer paths undetected. Recommendation: allowlist-style repo-wide grep limiting matches to the two allowed files. ORCHESTRATOR: DECLINED — same ask as round-04 gt-codex F01, previously declined as over-broad/infeasible (allowlist would be brittle against legitimate doc/precedent occurrences, e.g. skills/goals/SKILL.md:12). Coverage-completeness, not a defect. Cap exhausted — accepted-with-issue, deferred.

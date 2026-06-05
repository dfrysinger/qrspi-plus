---
finding_id: R6-F02
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-30-v072-release/plan.md]
---

AC #2 (plan.md:22) includes only one build-plugin boundary halt (`resolves outside repository` on canonicalized `!cat` target), but Task 39's locked fail-loud set is broader and includes additional security-relevant parser/path guards:
- fail non-zero for absolute/path-traversal attempts (plan.md:2224, 2246)
- fail non-zero for malformed `!cat` directives and missing targets/cycles (plan.md:2224, 2246)
- fail non-zero on `${CLAUDE_SKILL_DIR}` occurrence in shipped files (plan.md:2224, 2246)
Because AC #2 is the release-level seeded-regression gate, omitting these listed fail-loud conditions means phase acceptance can pass without proving those T39 security controls remain enforced.

---
finding_id: R6-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-30-v072-release/plan.md]
---

AC #2 at plan.md:22 enumerates only the G5 hash-mismatch halt (`plan.md post-approval split halt when ... '# block-hash:' no longer matches`), but Task 34 defines two additional halt paths that are not represented in the phase-level fail-loud gate:
- missing header halt (plan.md:1951, test pin at 1965)
- malformed header halt (plan.md:1952, test pin at 1966)
This leaves the phase acceptance under-specified for idempotent-split integrity: a release could satisfy AC #2 while regressing the pre-G5/malformed-header fail-loud protections that T34 explicitly requires.

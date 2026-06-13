---
finding_id: R4-F04
severity: high
change_type: correctness
referenced_files: ["docs/qrspi/2026-06-04-v073-release/plan.md:L700-L722"]
artifact: plan
round: 4
reviewer: quality-claude
---

T35 (`Trim the 8 artifact-step skills (goals/questions/research/design/phasing/structure/parallelize/replan) to target <300 lines each`) is sweep-shaped: it targets 8 `.md` files (same file type, strictly > 5) and its description body contains the word `replace` at word boundary ("`` `_shared/` `!cat` references replace any inlined boilerplate``"). The `dependent_tests:` field is therefore required.

T35 carries:
```
- **dependent_tests:**
  - `tests/lint/test-no-diff-redirect-prose.bats` (T06 — …)
  - `tests/lint/test-skill-trim-audit.bats` (T38 — …)
```

Neither file exists at review time:
- `tests/lint/test-no-diff-redirect-prose.bats` is T06's deliverable (T06 depends on T05, which depends on T04a → T03 → T02; T35 depends on T07, T31, T05 — T06 is in the same plan but not a prerequisite of T35).
- `tests/lint/test-skill-trim-audit.bats` is T38's deliverable (T38 depends on T32–T36; T38 runs AFTER T35).

Both listed files will not exist until after T35 is implemented. The Sweep Task Contract requires listed files to "exist in the repository at review time."

The same semantic issue applies as in R4-F03: these are tests that will verify T35's correctness post-trim, not existing tests that T35's sweep would break. The correct shape would list any existing tests that assert on content in the eight artifact-step SKILL.md files being trimmed, or use `none` + grep proof if no such tests exist.

Contract reference: `skills/plan/SKILL.md` § Sweep Task Contract — malformed field (listed files do not exist at review time).


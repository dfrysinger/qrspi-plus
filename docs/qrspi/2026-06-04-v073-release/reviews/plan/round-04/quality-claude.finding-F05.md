---
finding_id: R4-F05
severity: high
change_type: correctness
referenced_files: ["docs/qrspi/2026-06-04-v073-release/plan.md:L722-L745"]
artifact: plan
round: 4
reviewer: quality-claude
---

T36 (`Trim the 7 cross-cutting skills (integrate/test/implementer-protocol/reviewer-protocol/research-isolation/prompt-prose-writer/prompt-prose-reviewer) to target <300 lines each`) is sweep-shaped: it targets 7 `.md` files (same file type, strictly > 5) and its description body contains `replace` at word boundary ("`` `_shared/` `!cat` references replace any inlined boilerplate``"). The `dependent_tests:` field is required.

T36 carries:
```
- **dependent_tests:**
  - `tests/lint/test-skill-trim-audit.bats` (T38 — …)
  - `tests/lint/test-integrate-test-skill-phase-base-write.bats` (T24 — …)
```

Neither file exists at review time:
- `tests/lint/test-skill-trim-audit.bats` is T38's deliverable; T38 is declared as depending on T32–T36, so it runs AFTER T36. The file cannot exist before T36 is implemented.
- `tests/lint/test-integrate-test-skill-phase-base-write.bats` is T24's deliverable. T24 depends on T21 and T22, which depend on T19/T04b. T36 depends on T21 and T22. While T24 is reachable before T36 in the dep graph, T24 is itself a deliverable of this plan and does not exist at review time.

The Sweep Task Contract requires listed files to "exist in the repository at review time." Both listed files are deliverables of this plan that will not exist until after their creating tasks are implemented. The correct shape would list any existing tests that assert on content in the seven cross-cutting SKILL.md files being trimmed (candidates include `tests/unit/test-implement-skill-vocab.bats`, `tests/unit/test-implement-verifier-wiring.bats`, `tests/lint/test-bats-body-assertion-guard.bats`, and similar), or use `none` + grep proof if no such existing tests are affected.

Contract reference: `skills/plan/SKILL.md` § Sweep Task Contract — malformed field (listed files do not exist at review time).

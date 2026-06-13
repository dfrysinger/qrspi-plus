---
finding_id: R4-F03
severity: high
change_type: correctness
referenced_files: ["docs/qrspi/2026-06-04-v073-release/plan.md:L580-L602"]
artifact: plan
round: 4
reviewer: quality-claude
---

T26 (`Replace HEAD~1 with anchor-file lookup in using-qrspi Apply-fix step 12, sweep inlining skills, and validate the anchor-file SHA`) is sweep-shaped: it targets 14 `.md` SKILL files (same file type, strictly > 5) and its title contains both `Replace` and `sweep` — matching the keyword triggers with word-boundary semantics. The `dependent_tests:` field is therefore required per `skills/plan/SKILL.md` § Sweep Task Contract.

T26 carries:
```
- **dependent_tests:**
  - `tests/unit/test-narrow-round-anchor-lookup.bats` (T27 — three fixtures…)
```

The file `tests/unit/test-narrow-round-anchor-lookup.bats` does not exist in the repository at review time. It is T27's deliverable — T27 depends on T26 (T26 → T27 in the dep graph), so the file cannot exist until after T26 is implemented. The Sweep Task Contract requires each listed file to "exist in the repository at review time"; this file does not.

Additionally, the field is semantically misused: `dependent_tests:` is intended to list **existing** tests that the sweep might break, along with their disposition. T27's test is a **new** test that will verify T26's correctness — it cannot break if it does not yet exist, and it is not a consumer of the swept surface. The correct `dependent_tests:` shape for T26 would be either (a) a list of existing tests that assert on `HEAD~1` in SKILL.md files and would break when T26's sweep removes those occurrences, or (b) `none` followed by a `grep -rn -- '<pattern>' tests/` proof showing no such existing tests exist.

Contract reference: `skills/plan/SKILL.md` § Sweep Task Contract — malformed field (file does not exist at review time).


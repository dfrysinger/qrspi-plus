---
finding_id: R2-F02
severity: high
change_type: correctness
referenced_files:
  - tests/unit/test-per-finding-file-emission.bats:63-74
artifact: task-03
round: 2
reviewer: silent-failure-claude
---

# F02 — Vacuous escape hatch in test 1: `reviewer-protocol` keyword passes any agent body (high · correctness)

**Convergence:** Same as `silent-failure-codex.finding-F02.md` — vacuous regex test at line 69. Two independent reviewers caught it.

The third escape hatch in `@test "every reviewer agent body references per-finding emission"` (line 69):

```bash
if echo "$body" | grep -qE 'Per-Finding Disk-Write Contract|reviewer-protocol'; then
  continue   # other protocol cross-reference
fi
```

This passes for any agent body containing the string `reviewer-protocol` anywhere — including the `skills:` frontmatter reference. An agent containing only `"This reviewer follows the reviewer-protocol skill."` passes despite having no per-finding ref, no clean-sentinel ref, no protocol-deferral language.

**Second defect:** `Per-Finding Disk-Write Contract` matches a heading REMOVED from SKILL.md as part of this task (G6 split). Stale agents referencing the old heading still pass.

**In-scope T03 R3 fix:** Remove the `Per-Finding Disk-Write Contract|reviewer-protocol` branch entirely. The two meaningful hatches (inline per-finding ref regex + protocol-deferral language) are sufficient and non-vacuous.

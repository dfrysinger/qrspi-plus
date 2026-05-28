---
id: quality-claude-005
artifact: questions
severity: MEDIUM
check: comprehensiveness
---

## Finding

No question covers the Plan-reviewer template's current Branch Map linting rules — an area explicitly called out in G4 as requiring an update alongside the Branch Map presentation change.

### What the goals say

G4 ("Wave-grouped task presentation in `parallelization.md`") states:

> Test debt: **the Plan-reviewer template that lints Branch Map shape needs an update**; the Parallelize "Worked Example — Good" / "— Bad" examples need to be re-rendered in the new shape.

Q6 addresses the Branch Map table's current shape in `skills/parallelize/SKILL.md` worked examples. It does not cover the Plan-reviewer template — a separate artifact that contains linting rules (structural assertions or prose checks) tied to the Branch Map's current format.

### What is missing

No question asks:
1. Which file(s) constitute the Plan-reviewer template, and which section(s) define Branch Map linting rules?
2. What specific structural properties of the Branch Map does the Plan-reviewer template currently assert (column names, required rows, ordering conventions, wave/execution-order presence)?
3. Are the linting assertions expressed as BATS tests, inline prose checks, or reviewer-prompt instructions?

### Impact

Without this baseline, Design cannot specify what changes the Plan-reviewer template needs when the Branch Map gains a Wave-grouped column structure. If the template's current assertions are not catalogued, the Plan deliverable for G4 will omit a required test-update sub-task — exactly the pattern the goals are trying to prevent.

### Suggested additional question

> [codebase] What file(s) make up the Plan-reviewer template, which sections assert properties of the Branch Map, and what specific structural rules does the template currently enforce (column names, row requirements, wave/execution-order presence)?

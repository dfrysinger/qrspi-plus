# Spec Review — Task 33 (round 1)

**Verdict:** clean

## Verification

### 1. Completeness
- ✅ Schema-migration task shape added to `skills/plan/SKILL.md` (new "## Schema-Migration Task Shape" section).
- ✅ Mandatory trio defined together — `sizing_exception: schema-migration`, `sizing_rationale:`, `structural_lint:` — with explicit "all three required together" prose (SKILL.md "Mandatory trio").
- ✅ `structural_lint:` defined as a bash check proving mechanical-only diff content (SKILL.md, mandatory-trio bullet).
- ✅ N-files ungated only after lint passes; LOC ceiling exempted only with full trio (SKILL.md "Effect on sizing limits").
- ✅ `agents/qrspi-plan-reviewer.md` adds "Schema-migration exception review" with 4 steps: trio presence → command validation → execute → grant. Exemption denial path explicit.
- ✅ Reviewer emits `severity: high, change_type: correctness` finding for each missing field / malformed command / failed lint — matches DoD "fails clearly".
- ✅ Closed exception set preserved; SKILL prose explicitly says no new category is added and ordinary discipline is not relaxed for non-migration work.

### 2. Scope
- No out-of-scope content. T14/T15 surfaces (G15/G18) untouched. G31 prompt-prose work absent. No edits to ordinary task-size limits.

### 3. Interpretation
- "Re-runs or otherwise requires successful execution" → reviewer Step 3 executes the command from repo root. Command-validation step (Step 2) is a sensible safety addition derivable from "concrete bash command" requirement; not over-engineering.

### 4. Test expectations
- Field-name grep: exact strings `sizing_exception: schema-migration`, `sizing_rationale:`, `structural_lint:` all appear in both files.
- Reviewer rubric ties LOC/file-count exemption to lint success (Step 4).
- Prose covers mandatory-together, ungated-only-under-exception, missing-`structural_lint` defect.

### 5. TDD evidence
- N/A — prose-only contract task.

### 6. Extras
- Step 2 "validate the structural-lint command" (metachar/flag rejection) is a small safety add not literally enumerated in the spec but follows directly from "must execute the named lint" + "concrete bash command". Borderline but proportional and explicitly listed as a plan-spec defect in SKILL.md, so consistent across both files.

### 7. Target files
- Diff modifies exactly the two Target files: `skills/plan/SKILL.md`, `agents/qrspi-plan-reviewer.md`. No deviation.

LOC: ~75 added across two files, within ~80 estimate.

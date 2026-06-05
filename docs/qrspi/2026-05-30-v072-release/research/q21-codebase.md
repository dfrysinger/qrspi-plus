---
status: draft
question_ids: [21]
research_type: codebase
---

# Q21: How does the `change_type` enum get enforced on its consuming side?

## Summary

**TL;DR:** The spec designates step 2's schema-violation guard as the enforcement point for out-of-enum `change_type` values (citing it as a loud failure), but the only executable code path shown in the SKILL.md — the step 5 assembly bash loop — silently keeps any finding whose `change_type` does not match `style|clarity|correctness`. No test exercises the codepath with an actual out-of-enum value in an execution context; the two tests that name "out-of-enum" behavior both reduce to grep checks against prose text, not against running code.

**Key findings:**
- The threshold lookup and drop logic lives in the step 5 bash assembly loop at `skills/using-qrspi/SKILL.md:880–889`. It reads `change_type` from the finding file, defaults `threshold=80`, sets `threshold=70` only for `"correctness"`, and only increments `dropped` when the regex `^(style|clarity|correctness)$` matches. An out-of-enum value (anything not `style`, `clarity`, or `correctness`) fails the regex test, so `dropped` is not incremented and the finding is **silently kept**.
- The spec asserts that out-of-enum values are intercepted earlier: step 2 (the schema-violation guard, `SKILL.md:759`) lists "malformed `change_type` enum values that are out-of-enum" as a loud failure that routes to the §3 failure menu. Step 8 (`SKILL.md:987`) explicitly notes "Out-of-enum `change_type` values are loud failures from step 2's schema guard (already caught before reaching step 8)." However, no executable bash code for step 2's enum check appears in the SKILL.md; the guard is specified in prose only.
- `tests/unit/test-change-type-partition.bats:20–22` has a test named `"out-of-enum change_type triggers loud failure"`, but its body is `grep -qE 'out-of-enum.*loud failure|change_type.*loud failure|schema guard.*change_type'` against the `$PROTOCOL` variable (extracted from the SKILL.md text). This confirms only that the prose mentions the loud-failure contract — it does not execute any assembly or routing code with an out-of-enum input.
- `tests/unit/test-verifier-dispatch-contract.bats:76–79` has `"step 2 schema guard fails loud on malformed change_type enum"`, also a prose grep (`grep -qiE 'change_type.*enum|out-of-enum.*change_type|invalid change_type'`), not a code-execution test.
- The fixture used by the fixture-backed partition test (`tests/fixtures/issue-109/round-mixed-change-types/round-04/`) contains only the five valid enum values (`style`, `clarity`, `correctness`, `scope`, `intent`); it does not include an out-of-enum value.
- No test under `tests/unit/` or `tests/integration/` exercises the assembly or routing code with an out-of-enum `change_type` value as an actual input.

**Surprises:** The assembly bash loop (step 5) has no guard against out-of-enum values — it silently keeps them rather than raising. The spec claims this is harmless because step 2's guard fires first, but step 2's guard exists only as prose; the gap means a non-conforming finding file that reaches the loop would pass through to `kept` without any error signal in the executable code.

**Caveats:** Step 2's schema-violation guard is described in prose but its bash implementation is not shown in the SKILL.md; it is possible an implementation exists elsewhere (e.g., in an orchestrator agent file not reflected in the SKILL.md snippets). The integration test directory (`tests/integration/`) contains only one file (`test-reference-gate-pause.bats`), which does not touch `change_type` at all.

## Full findings

### The threshold lookup in `skills/using-qrspi/SKILL.md` around L835

The question references a "table around L835 mapping `change_type` to threshold values." L835 is actually a prose-and-parameter-derivation block for the verifier dispatch contract. The actual threshold lookup table is embedded in the bash assembly loop at **L880–889**:

```bash
ct=$(awk -F': *' '/^change_type:/ {print $2; exit}' "$f")
# Threshold split: style/clarity require ≥80 (high bar for nitpicks);
# correctness requires ≥70 (lower bar for silent failures, attack
# surface, and hardening-relevant correctness gaps that the rubric
# tends to score in the 72-78 "real but low-severity" band).
threshold=80
[[ $ct == "correctness" ]] && threshold=70
if (( score < threshold )) && [[ $ct =~ ^(style|clarity|correctness)$ ]]; then
  dropped=$((dropped + 1))
fi
```

The "table" is not a markdown table but a two-step implicit mapping encoded in the shell conditionals:

| `change_type` value | `threshold` | Drop condition |
|---|---|---|
| `style` | 80 | `score < 80` |
| `clarity` | 80 | `score < 80` |
| `correctness` | 70 | `score < 70` |
| `scope` | 80 (default, unused) | never — regex won't match |
| `intent` | 80 (default, unused) | never — regex won't match |
| *(any out-of-enum value)* | 80 (default, unused) | never — regex won't match |

The surrounding prose at L921 documents the header semantics: `dropped` = sidecars where `change_type ∈ style|clarity` AND `score < 80`, OR `change_type = correctness` AND `score < 70`.

### What happens with an out-of-enum value in the assembly loop

An out-of-enum value (e.g., `"security"`, `"performance"`, `""`, or any value not in `style|clarity|correctness`) causes:

1. `ct` receives the value as-is from `awk`.
2. `threshold` stays at `80` (the `[[ $ct == "correctness" ]]` check fails).
3. The `if` condition evaluates `[[ $ct =~ ^(style|clarity|correctness)$ ]]` — this regex does **not** match — so the entire `if` block is skipped.
4. `dropped` is **not** incremented.
5. The finding flows into `kept` (= `${#findings[@]} - dropped`).

**Outcome: silent keep.** The finding is kept without any error signal in this code path.

### The specified enforcement point: step 2's schema-violation guard

The spec designates step 2 — not the assembly loop — as the enforcement point for out-of-enum values.

`skills/using-qrspi/SKILL.md:759`:
> "Step 2 also fails loud on: malformed YAML, missing required fields, malformed `change_type` enum values that are out-of-enum (not one of style/clarity/correctness/scope/intent), unrouted `(step, tag)` route…"

`skills/using-qrspi/SKILL.md:987`:
> "Out-of-enum `change_type` values are loud failures from step 2's schema guard (already caught before reaching step 8)."

Step 2 is specified to route to the §3 failure menu. However, the SKILL.md does not contain an executable bash snippet for step 2's enum check — the check is prose-only. Step 5's bash assembly loop (the only shown executable snippet for this pipeline stage) has no out-of-enum guard.

### Tests that name "out-of-enum" behavior

**`tests/unit/test-change-type-partition.bats:20–22`** — test named `"out-of-enum change_type triggers loud failure"`:
```bash
echo "$PROTOCOL" | grep -qE 'out-of-enum.*loud failure|change_type.*loud failure|schema guard.*change_type'
```
- `$PROTOCOL` is extracted from `skills/using-qrspi/SKILL.md` (the Apply-fix protocol section, from `**Apply-fix protocol.**` to `**Diff handling between rounds`).
- This test passes because `SKILL.md:987` contains the string "Out-of-enum `change_type` values are loud failures from step 2's schema guard", which matches the pattern `out-of-enum.*loud failure`.
- The test does NOT execute any assembly code or routing code with an out-of-enum value.

**`tests/unit/test-verifier-dispatch-contract.bats:76–79`** — test named `"step 2 schema guard fails loud on malformed change_type enum"`:
```bash
echo "$PROTOCOL" | grep -qiE 'change_type.*enum|out-of-enum.*change_type|invalid change_type'
```
- Same structure: grep against prose, not code execution.

**`tests/unit/test-change-type-partition.bats:34–54`** — fixture-backed partition test:
- Runs the partition logic against `tests/fixtures/issue-109/round-mixed-change-types/round-04/`.
- That fixture contains exactly the five valid enum values (`style`, `clarity`, `correctness`, `scope`, `intent`) across five finding files (F01–F05). No out-of-enum value is present.
- The test asserts `kept=4` and `dropped=1` using only valid enum inputs.

### Integration test coverage

`tests/integration/` contains a single file: `tests/integration/test-reference-gate-pause.bats`. It exercises the reference-gate/pause cross-skill flow and makes no reference to `change_type`.

### Enum definition location

The canonical 5-value enum is defined in `skills/reviewer-protocol/SKILL.md:232`:
> "Schema fields (the canonical 5-field finding schema): `finding_id`, `severity` ∈ `low|medium|high`, `change_type` ∈ `style|clarity|correctness|scope|intent`, `referenced_files` (list), `message` (body)."

The `classify_route` helper in `tests/unit/test-change-type-classification.bats:46–52` also encodes the same partition as a shell `case` statement, returning `"malformed"` for anything outside the five values — but that helper is a test stub, not invoked by the actual pipeline code.

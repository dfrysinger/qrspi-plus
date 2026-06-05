---
reviewer_tag: quality-claude
change_type: correctness
severity: high
artifact: plan.md
location: "Task 37 (G35 Structure SKILL absorbs unified architecture content)"
---

# F01 — T37 Target list contradicts its own Scope-Out, Definition of Done, and Test expectations after round-01 added the lint test

## Defect

The round-01 fix added a fourth Target file to T37 — `tests/lint/test-structure-altitude-boundary-include.bats (create)` — but the rest of the task body still says "no test code." Three separate places in the spec now contradict the Target list:

1. **Out** (line 2285):
   > "Test-code or lint-test additions for the include guard — explicitly out of this prompt-prose task."

   This explicitly excludes the very file the Target list now tells the implementer to create.

2. **Definition of done** (line 2296):
   > "The task does not edit reviewer agents, add test code, assume unresolved runtime `!cat` expansion beyond the primitive's intended source form, introduce implementation-level test assertions, or rewrite unrelated Structure procedures."

   "Does not … add test code" is a direct contradiction with creating `tests/lint/test-structure-altitude-boundary-include.bats`.

3. **Test expectations** (line 2304):
   > "Scope audit confirms no reviewer-agent edits, no test-code additions, no implementation-level test assertions, and no unrelated Structure procedure rewrites were introduced by this task."

   The acceptance check itself would fail the task for creating the file the Target list requires.

The **In** section (lines 2276–2280) also has no bullet authoring the lint test's contents, so even if the implementer believes the Target list, they have no guidance for what the file must contain or assert.

## Impact

The implementer running T37 cannot satisfy both Target and Out/DoD/Test simultaneously. Either:
- they create the lint file as Target says → the post-implementation scope audit (Test expectations line 2304) fails the task, and the DoD "does not add test code" clause is violated; or
- they skip the lint file to honor Out/DoD/Test → the Target list is unsatisfied, and the structure-altitude-boundary include guard ships untested.

This is the classic round-01 patch-collision pattern: the Target list was updated without sweeping the Scope/DoD/Test prose, leaving the spec self-contradictory.

## Recommended fix

Pick one resolution and apply it through the whole task body:

**Option A — keep the lint test in scope (preferred, matches T29's symmetric round-01 fix):**
- Add an explicit In bullet authoring the lint test's contents (e.g., "Create `tests/lint/test-structure-altitude-boundary-include.bats` asserting that `agents/qrspi-structure-scope-reviewer.md` contains the literal `!cat skills/_shared/structure-altitude-boundary.md` directive on the line immediately after the introducer prose, and that `skills/structure/owns-defers.md` contains the same directive in place of the previous inline body").
- Delete the Out bullet at line 2285 ("Test-code or lint-test additions for the include guard").
- Delete or rewrite the DoD clause at line 2296 to drop "add test code" from the negative list (the include-guard lint is the one exception).
- Delete or rewrite the Test-expectations scope-audit clause at line 2304 to allow the named lint file under `tests/lint/`.
- Add a DoD line and a Test-expectations line that pin the lint test's required assertions.

**Option B — keep the lint test out of scope:**
- Remove `tests/lint/test-structure-altitude-boundary-include.bats (create)` from Target files at line 2266.
- Defer the include-guard lint to a follow-up task (or absorb it into T38, the reviewer-enforcement sibling).

Apply the same resolution direction to T29 (see F02) so the two sibling altitude-boundary tasks stay symmetric.

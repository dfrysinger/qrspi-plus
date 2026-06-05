---
reviewer_tag: quality-claude
change_type: correctness
severity: medium
artifact: plan.md
location: "Task 29 (G34 Design scope-reviewer alignment with detailed-solution boundary)"
---

# F02 — T29 Out/DoD still say "three target files" after round-01 expanded the Target list to four, and the lint test has no In/DoD/Test coverage

## Defect

The round-01 fix expanded T29's Target list from three files to four — adding `tests/lint/test-design-altitude-boundary-include.bats (create)` — but the rest of the task body was not swept to match. Three problems remain:

1. **Out section literal mismatch** (line 1819):
   > "Adding or modifying files outside the three target files, unless a directly coupled include-resolution break prevents those files from being valid."

   This still says "three target files" while the Target list at line 1797 names four. The implementer cannot tell whether the lint test is in scope (Target says yes; Out's "three target files" formulation implies the lint file *is* one of the "outside the three" cases this very clause prohibits).

2. **DoD literal mismatch** (line 1838):
   > "Diff audit confirms only the three target files changed, unless the implementer documents a directly coupled include-resolution break."

   The post-implementation diff will show four changed files (or three modified + one created), which causes this check to fail on its face.

3. **In bullets and Test expectations never mention the lint test** (lines 1807–1811 and 1833–1839). There is no In bullet authoring the file's required assertions and no Test-expectations bullet validating its behavior. The implementer who creates the file from the Target list alone has no spec for what the file must contain; the reviewer has no acceptance check to run on it.

## Impact

Less severe than the T37 sibling defect (F01) because T29's Scope/DoD does not include an *explicit prohibition* against test code — but the numeric "three target files" wording in Out and DoD still actively rejects the very file the Target list adds, and the absence of any In/DoD/Test bullet for the lint test means it would either ship empty/trivial or be skipped silently.

## Recommended fix

Apply the same resolution direction chosen for T37/F01 so the two sibling altitude-boundary tasks stay symmetric. For Option A (keep lint test in scope, preferred):

- Replace "three target files" with "four target files" (or just "target files") at line 1819 (Out) and line 1838 (DoD).
- Add an In bullet authoring the lint test contents — e.g., "Create `tests/lint/test-design-altitude-boundary-include.bats` asserting that `agents/qrspi-design-scope-reviewer.md` contains the literal `!cat skills/_shared/design-altitude-boundary.md` directive on the line immediately after the Step 1 Read citation introducer prose, and that `skills/design/owns-defers.md` contains the same directive in place of the previous inline contract body."
- Add a DoD bullet pinning the lint test's required assertions.
- Add a Test-expectations bullet running/inspecting the lint test.

For Option B (remove lint test):
- Delete `tests/lint/test-design-altitude-boundary-include.bats (create)` from Target files at line 1797 and leave "three target files" wording in place.

Either way, T29 and T37 should resolve in the same direction so the two altitude-boundary tasks remain structurally symmetric.

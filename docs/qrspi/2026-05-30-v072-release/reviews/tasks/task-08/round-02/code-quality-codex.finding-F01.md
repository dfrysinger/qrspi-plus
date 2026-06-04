---
finding_id: R2-F01
severity: medium
change_type: clarity
artifact: code
round: 2
reviewer: code-quality-codex
model: gpt-5.3-codex
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L1150
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L1154-L1155
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L1188
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L1192-L1193
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L1226
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L1230-L1231
---

# TC5–TC7 fixture diagnostics are inconsistent with the cited evidence they now generate

**Evidence:**
- `tests/acceptance/v07-phase1/test-phase1-acceptance.bats:1150` reason says `agents/fake.md ... 500-510 out of range`, but the finding now cites `README.md#L99999-L99999` (`:1154`) and body text also references `README.md` (`:1155`).
- `...:1188` reason says quoted content missing at `SKILL.md:516`, but citation/body point to `README.md` (`:1192-1193`).
- `...:1226` reason says anchor missing in `agents/fake-agent.md`, but citation/body point to `README.md` and `nonexistentFunc` (`:1230-1231`).

**Why this is a problem:**
The new R2 comments claim these fixtures model concrete Cite Check failure shapes, but the sidecar reasons now describe different files/anchors than the fixture citations. This makes the tests internally misleading and harder to maintain/debug.

**Recommended fix:**
Update TC5–TC7 `reason` strings to match each test's `refs`/`body` citation target (or assert only prefix everywhere and remove shape-specific claims from comments).

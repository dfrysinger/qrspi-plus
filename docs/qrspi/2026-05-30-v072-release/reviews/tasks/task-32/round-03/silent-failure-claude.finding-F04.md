# F04 — Goals finalize test passes if finalize block deleted (mid-phase prohibition independently satisfies grep)

**Severity:** medium
**Category:** Test design / silent test pass on prose regression
**File:** `tests/unit/test-interactive-skill-prompts.bats:162-165`, `skills/goals/SKILL.md:166,168`

The piped check `grep -F "status: draft" | grep -qF "approved"` succeeds when any single line contains both. Two lines in goals/SKILL.md satisfy it: the finalize bullet (L166) AND the mid-phase prohibition text (L168). Deleting the entire finalize block but keeping the prohibition still passes.

**Required fix:** Pin completeness-validation text or a finalize-specific phrase (e.g. `grep -F "Validate that every locked goal"`).

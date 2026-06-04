---
finding_id: code-quality-claude.finding-F01
severity: medium
change_type: clarity
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats
---

## Sidecar reason strings in TC5/TC6/TC7 don't match the realistic finding bodies added by the R1 fix

### What the R1 fix intended

The R1 fix was motivated by spec-reviewer feedback that TC4–TC7 had generic fixture
data (`referenced_files: []`, body `"Fixture finding body."`) making the
citation-failure-type assertions tautological. The fix added specific `refs` and
`body` values so that _if the verifier were invoked_, the fixture would actually trigger
the claimed cite-check failure shape.

### The inconsistency introduced

The fix added new `body` and `refs` locals in each TC but left the pre-existing
`reason` strings from the round-1 implementation unchanged. Those placeholder reason
strings reference completely different files and identifiers than the new realistic
fixture bodies, producing an internally inconsistent fixture in TC5, TC6, and TC7:

**TC5** (`test-phase1-acceptance.bats:1150–1155`):
```bash
local reason="HALLUCINATED: agents/fake.md has 10 lines, cited 500-510 out of range"
local refs="[README.md#L99999-L99999]"
local body="As documented in README.md lines 99999-99999, the pipeline configuration …"
```
The sidecar reason describes a range failure for `agents/fake.md` at lines 500–510.
The finding body describes a range failure for `README.md` at lines 99999–99999.
A reader trying to understand what failure shape TC5 exercises sees two incompatible
stories.

**TC6** (`test-phase1-acceptance.bats:1188–1193`):
```bash
local reason="HALLUCINATED: quoted content 'widen/ref' not found at SKILL.md:516"
local refs="[README.md]"
local body="The implementation contains \`const fabricatedFunction = () => {}\` … per README.md."
```
The sidecar reason cites `'widen/ref'` at `SKILL.md:516`; the finding body quotes
`` `const fabricatedFunction = () => {}` `` attributed to `README.md`. Different
quoted content, different file.

**TC7** (`test-phase1-acceptance.bats:1226–1231`):
```bash
local reason="HALLUCINATED: anchor 'FakeFunction' not found in agents/fake-agent.md"
local refs="[README.md]"
local body="The nonexistentFunc() documented in README.md should be split …"
```
The sidecar reason names anchor `FakeFunction` in `agents/fake-agent.md`; the finding
body names anchor `nonexistentFunc` in `README.md`. Different anchor, different file.

### Why this matters

The test assertions only check `score: 0` and `HALLUCINATED:*` prefix — they don't
verify specific reason content — so all tests pass. The correctness of the fan-in
drop path is not affected. The problem is readability and maintainability:

- The "representative fixture" goal of the R1 fix is only half-achieved: the finding
  body is now realistic, but the sidecar reason still describes a different, unrelated
  failure.
- A maintainer reading TC5 sees the comment "line-range failure for README.md
  L99999-L99999" but then reads a sidecar reason about `agents/fake.md` at lines
  500–510. The fixture does not coherently describe one failure scenario.
- Future changes that add assertions on reason-string content (e.g., checking that
  the filename in the reason matches the file in `refs`) would fail immediately because
  the fixture data is contradictory.

### Suggested fix

Update the `reason` strings in TC5, TC6, and TC7 to match the `refs`/`body` values
added by the R1 fix:

```bash
# TC5 — line-range
local reason="HALLUCINATED: README.md has ~944 lines, cited L99999-L99999 out of range"

# TC6 — quoted-content
local reason="HALLUCINATED: quoted content 'const fabricatedFunction = () => {}' not found in README.md"

# TC7 — named-anchor
local reason="HALLUCINATED: anchor 'nonexistentFunc' not found in README.md"
```

TC4's reason string (`HALLUCINATED: file nonexistent/fabricated/path.md does not
exist`) already matches its `refs` (`[src/does-not-exist.ts]`) closely enough — a
nonexistent-file scenario references a nonexistent file — so TC4 does not need
updating. TC8 has no reason string.

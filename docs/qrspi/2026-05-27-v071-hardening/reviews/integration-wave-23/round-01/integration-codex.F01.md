---
finding_id: integration-codex.F01
severity: high
change_type: correctness
referenced_files:
  - skills/parallelize/SKILL.md
  - skills/implement/SKILL.md
  - tests/unit/test-parallelize-vocab.bats
artifact: integration-wave-23
round: 1
reviewer: integration-codex
---

# Cross-skill contract mismatch: `## Execution Order` removed from parallelize spec, still required by implement spec

## Claim

T4's parallelize reshape removed the standalone `## Execution Order` section from the parallelize artifact contract (`skills/parallelize/SKILL.md:132` — Wave ordering is now read from `### Wave N` sub-section headings under Branch Map, and `tests/unit/test-parallelize-vocab.bats:288-293` pins the absence of any `## Execution Order` H2 in parallelize/SKILL.md).

But the consumer side — `skills/implement/SKILL.md` — was not updated to match:

- **`skills/implement/SKILL.md:361`** still lists "Execution Order narrative" as a required section to read from `parallelization.md`:
  > "Read inputs. Full pipeline: read `parallelization.md` (Branch Map + Stage Commits + Execution Order narrative; if a `## Runtime Adjustments` section exists ...)"

- **`skills/implement/SKILL.md:371`** still names the iteration source:
  > "**Full pipeline — for each wave** in the Execution Order, in order:"

A correctly-produced post-T4 parallelization.md will not contain a section named "Execution Order." The producer's spec says the section must not exist, the producer's reviewer pins that constraint, and a consumer following implement/SKILL.md literally would read a non-existent section and iterate over a non-existent ordering field.

## Impact

Producer/consumer contract mismatch. The actual ordering is recoverable (read it from `### Wave N` sub-section headings under Branch Map — the parallelize spec at line 132 documents this explicitly), so a careful operator can bridge the gap. But the implement skill text instructs the reader to look for something that does not exist; future implementations of this skill — including subagent invocations that read it literally — can read past the missing section without noticing and proceed without a wave-ordering source. The fact that the integration passed Wave 2/3 dispatch in this run does not refute the mismatch; it reflects this orchestrator's manual bridging, not a documented contract.

## Suggested fix

Update both lines in `skills/implement/SKILL.md` to match T4's reshape:

- Line 361: remove "Execution Order narrative" from the required-sections list; cite that Wave ordering now comes from `### Wave N` sub-section headings under Branch Map. E.g.:
  > "read `parallelization.md` (Branch Map organized into `### Wave N` sub-sections + Stage Commits; ..."

- Line 371: replace "for each wave in the Execution Order, in order" with explicit reference to the Branch Map's Wave sub-sections. E.g.:
  > "**Full pipeline — for each `### Wave N` sub-section under Branch Map**, in ascending N order:"

No test changes required — the only test pinning Execution Order vocabulary (`tests/unit/test-parallelize-vocab.bats:288-293`) targets parallelize/SKILL.md and is already satisfied.

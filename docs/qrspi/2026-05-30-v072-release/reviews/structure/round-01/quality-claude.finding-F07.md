---
finding_id: R1-F07
artifact: structure
severity: low
change_type: clarity
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
---

## Test Architecture: G25 absent from T1-T5 Feeds; traceability gap to CD-1 smoke test

### What is wrong

G25 ("top-level fail-loud invariant for the dispatch-routing section") does not appear
in any T1–T5 Feeds line in the Test Architecture section. It is implicitly covered only
by T6 (Self-host acceptance), which feeds all G1–G35.

G25's acceptance criteria, per design.md, are primarily exercised by the CD-1
acceptance smoke test:

> An executable smoke test exercises a tier-resolved-to-none dispatch and asserts
> the dispatcher halts with the loud diagnostic per CD-1 #2's no-silent-fallback rule.
> Form: a single bats test invoking `dispatch-agent.sh` against a `config.md` fixture
> with one tier set to `none` and an agent targeting that tier; asserts non-zero exit
> and a diagnostic written to stderr naming the unconfigured tier.

This smoke test is unit-test shaped (a single bats invocation against a fixture) and
would fall under T1 (unit tests) or T2 (integration tests, since it exercises
dispatch routing). CD-1 does appear in T2 Feeds, so the coverage is transitively
present — but the traceability from G25 to its specific test type is invisible in the
Test Architecture section.

### Why this matters

The Test Architecture section's stated purpose is "Structure stitches design acceptance
blocks into those boundaries." G25 has a concrete acceptance block in design.md that
names a specific test type (bats fixture, script invocation). The absence of G25 from
T1 or T2 Feeds breaks the traceability chain that lets the Test phase verify whether
G25's acceptance criteria have been covered by the right test type.

This is not a coverage gap — G25's requirements ARE tested through CD-1's coverage —
but it is a traceability gap. A Test phase reviewer reading the Test Architecture
section cannot trace G25 to its test type without consulting design.md directly to
discover the CD-1 absorption relationship.

### Expected fix

Add G25 to T2 Feeds (integration tests, since CD-1's fail-loud smoke test spans
dispatch routing which is multi-script behavior):

> Feeds: CD-1, CD-3, CD-4, G3, G4, G6, G9, G12, G15, G16, G18, G22, G23, **G25**, G27, G32.

Alternatively, add it to T1 Feeds if the smoke test is classified as a unit test
(single script invocation against a fixture is arguably T1). Either T1 or T2 is
defensible; what matters is that G25 is explicitly traced rather than relying on
implicit CD-1 absorption.

If the design.md decision to absorb G25 into CD-1 means G25's acceptance is
considered fulfilled by CD-1's coverage alone, a parenthetical note in the Test
Architecture section would close the traceability gap without changing Feeds lines:
e.g., in the CD-1 cross-cutting invariant entry, append "(G25 acceptance subsumed by
this invariant — see design.md CD-1 Acceptance)".

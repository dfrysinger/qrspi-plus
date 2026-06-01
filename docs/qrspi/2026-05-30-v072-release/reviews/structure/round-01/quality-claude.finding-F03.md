---
finding_id: R1-F03
artifact: structure
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
---

## Missing component: `skills/_shared/verifier-dispatch-prose.md` absent from file map

### What is missing

`skills/_shared/verifier-dispatch-prose.md` is not listed as a Create action in any
slice of structure.md's file map. CD-4 component H in the approved design.md explicitly
requires this file:

> **Shared dispatch prose snippet — `skills/_shared/verifier-dispatch-prose.md`.**
> Mirror of `skills/_shared/reviewer-dispatch-prose.md` (CD-1 §11). Carries the
> `dispatch-agent.sh --verifier-fanout` invocation, the spec-line iteration contract,
> and the `await-round.sh` follow-up. `!cat`-included into every consumer skill that
> runs verification (`using-qrspi/SKILL.md` artifact-level Apply-fix protocol;
> `implement/SKILL.md` task-level Apply-fix protocol).

The G12 acceptance criteria in design.md additionally state:

> `skills/_shared/verifier-dispatch-prose.md` exists and is `!cat`-included into both
> `using-qrspi/SKILL.md` (artifact-level Apply-fix protocol) and `implement/SKILL.md`
> (task-level Apply-fix protocol).

That acceptance check will permanently fail if the snippet is never scheduled for
creation.

### Why this is a problem

`skills/using-qrspi/SKILL.md` and `skills/implement/SKILL.md` are both in the file map
with Modify entries (Slices 1.2 and 1.3). Both need to adopt the `!cat` include for
the verifier dispatch prose. Without a Create entry for the source file, neither
consumer can satisfy CD-4's DRY requirement — they would have to inline the
`--verifier-fanout` invocation prose independently, re-introducing exactly the drift
pattern CD-4 and G12 were designed to eliminate.

The reviewer-dispatch-prose snippet (`skills/_shared/reviewer-dispatch-prose.md`) IS
in the file map (Slice 1.4, Create). Its symmetric verifier counterpart is absent.

### Expected fix

Add a Create entry for `skills/_shared/verifier-dispatch-prose.md` to Slice 1.1
(Apply-fix / verifier backbone) or Slice 1.2 (Verifier rubric calibration +
instrumentation), alongside the other verifier infrastructure. Suggested table row:

| `skills/_shared/verifier-dispatch-prose.md` | Create | Hold the shared verifier dispatch prose snippet (`dispatch-agent.sh --verifier-fanout` invocation + spec-line contract + `await-round.sh` follow-up) consumed by `using-qrspi/SKILL.md` and `implement/SKILL.md`. | G12 |

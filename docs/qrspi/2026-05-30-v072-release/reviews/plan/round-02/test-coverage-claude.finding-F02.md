---
reviewer: test-coverage-claude
round: 2
artifact: plan.md
task: T27
severity: medium
change_type: clarity
---

# F02 — T27 using-qrspi pointer site: "artifact-quality section" anchor is unspecified

## What

T27's round-01 extension added a new DoD bullet:

> `skills/using-qrspi/SKILL.md` carries exactly one by-reference pointer line
> to `skills/_shared/evergreen-output-rule.md` at the artifact-quality
> section, with no `!cat` include of the snippet body (per CD-2 acceptance #5).

And matching test expectation:

> Grep audit of `skills/using-qrspi/SKILL.md` confirms exactly one pointer
> line to `skills/_shared/evergreen-output-rule.md` at the artifact-quality
> section and zero occurrences of `!cat skills/_shared/evergreen-output-rule.md`
> (pointer-only contract per CD-2 acceptance #5).

The "exactly one pointer line" count and "zero `!cat`" occurrence count are
both deterministic and good.

But **"at the artifact-quality section"** has no literal heading text or
greppable anchor. `skills/using-qrspi/SKILL.md` is a large file with many
sections; there is no current heading literally named "artifact-quality" (the
phrase only appears in plan/design narrative). The test cannot deterministically
verify that the pointer landed at the intended location vs. somewhere else.

## Why this matters

An implementer could place the pointer line at the top of the file, in the
dispatch-routing section, or in the schema-validation table — all of which
satisfy "exactly one pointer line" and "zero `!cat`" but none of which match
CD-2's intent that operators discover the rule near artifact-quality guidance.

Tests would pass even though the discoverability goal (the whole reason
for the pointer per CD-2 acceptance #5) is missed.

## Recommended fix

Either:

1. Name the literal H2 / H3 heading text the pointer must appear under
   (e.g., "Artifact-quality guidance" or whatever the locked CD-2 / structure
   heading actually is — design.md ### CD-2 and structure.md ###
   `skills/using-qrspi/SKILL.md` should carry an authoritative phrase), and
   make the test expectation say "pointer line appears within N lines after
   the literal heading `## <Heading>`".
2. Or, name a stable anchor sentence the pointer text must contain or be
   adjacent to (e.g., the pointer must include the phrase "artifact-output
   quality contract" so a positional grep can confirm it).

Whichever wording the design/structure documents already lock as canonical
should be carried into both the DoD anchor and the test expectation
verbatim — that is the standard greppable-anchor pattern used by other T27
expectations (e.g., the "named antagonist patterns" anchor phrase for the
snippet body itself).

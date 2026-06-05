# stitching-audit.finding-F03

**reviewer_tag:** stitching-audit
**round:** 9
**artifact:** structure
**section:** ## Hook-Point Locations (§G31 intro paragraph)
**severity:** should-fix
**kind:** asymmetric disclosure / reader trap

## Finding

The R8 fix adds an intro-level callout explaining that Consumer #6
(`qrspi-design-reviewer`) appears in **both** the skills-preload group and the
inline-permanent group. This is useful. However, the new disclosure creates an asymmetric
treatment of Consumer #9 that is likely to confuse readers.

**The intro paragraph now reads (paraphrased):**
> "Additions A, B, C, and D are inline-permanent text in their consumer files. This is
> distinct from the `skills:` frontmatter preload used by agent files
> **(Consumers #4–#8** per design.md G31 Distribution Table). Consumer #6 appears in
> BOTH groups …"

**Consumer #9** (`agents/qrspi-plan-test-coverage-reviewer.md`) is also an agent file.
The intro's "(Consumers #4–#8)" boundary explicitly excludes it from the preload group.
But unlike Consumer #6 — which gets an intro-level "BOTH" explanation — Consumer #9's
exclusion from the preload group receives **no intro-level explanation**.

The table row for Consumer #9 does explain the rationale:
> "standalone — does NOT preload `prompt-prose-reviewer` per design rationale that the
> full reviewer block would compromise judgment on `task_type: code` tasks where RED IS
> required"

However, a reader following the intro's logic encounters:
1. Agents #4–#8 use preload.
2. Consumer #6 (an agent) is special — it's in BOTH groups; the intro says why.
3. Consumer #9 (also an agent) is… in the table, but not in #4–#8 and not explained
   in the intro. Why isn't it #4–#9? Why isn't it "BOTH"?

The R8 fix established the pattern of surfacing dual-group membership in the intro.
Following that pattern, the intro should also surface why #9 is explicitly **not**
in the preload group — namely, that the design intentionally excludes it to protect
the RED-required judgment.

## Required fix

Add a companion sentence to the intro paragraph after the Consumer #6 BOTH callout:

> "Consumer #9 (`qrspi-plan-test-coverage-reviewer`) is intentionally excluded from
> the preload group: adding the full reviewer block would compromise its RED-required
> judgment on `task_type: code` tasks (per design.md G31 rationale)."

This mirrors the #6 disclosure pattern and pre-empts the reader question before they
reach the table row.

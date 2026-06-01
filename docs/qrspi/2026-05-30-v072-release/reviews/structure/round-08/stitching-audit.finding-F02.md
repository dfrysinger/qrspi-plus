# stitching-audit.finding-F02

**reviewer_tag:** stitching-audit
**round:** 8
**artifact:** structure
**section:** ## Hook-Point Locations → ### G31 prompt-prose `!cat` include sites
**severity:** high
**change_type:** self-contradiction

## Finding

The intro paragraph of the G31 Hook-Point subsection (structure.md L773-774) reads:

> "This is distinct from the `skills:` frontmatter preload used by agent files
> (Consumers #4-#8 per design.md G31 Distribution Table)."

The parenthetical "(Consumers #4-#8)" identifies a group that uses `skills:` preload and implicitly positions them as **absent** from this Hook-Point table. But the table directly below (L784) includes:

> `agents/qrspi-design-reviewer.md` | review-procedure body AFTER `skills:` preload triggers (Consumer #6): Addition D inline as refinement layered atop the shared reviewer-addition

Consumer #6 (`qrspi-design-reviewer.md`) is squarely within the #4-#8 range claimed to use only preload, yet it has a Hook-Point row for its Addition D inline block. design.md G31 Distribution Table (L2622) confirms the dual mechanism: Consumer #6 uses both `skills:` preload AND permanent inline Addition D.

## Impact

A reader of the intro alone would conclude that Consumer #6's Addition D is covered by the preload mechanism — that there's nothing to land inline in that agent's body. An implementer following the intro's implied exclusion of #4-#8 from the table would skip implementing Addition D. This is a direct instruction-execution gap: the intro and the table contradict each other, and the intro would "win" for a fast reader.

## Fix

Revise the intro to acknowledge the dual-mechanism case for Consumer #6:

> "This is distinct from the `skills:` frontmatter preload used by agent files (Consumers #4-#8 per design.md G31 Distribution Table). Consumer #6 (`qrspi-design-reviewer.md`) uses both the preload and an inline Addition D listed below; Consumers #4, #5, #7, #8 are preload-only and have no Hook-Point table entry."

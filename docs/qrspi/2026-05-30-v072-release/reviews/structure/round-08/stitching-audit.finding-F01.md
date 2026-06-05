# stitching-audit.finding-F01

**reviewer_tag:** stitching-audit
**round:** 8
**artifact:** structure
**section:** ## Hook-Point Locations → ### G31 prompt-prose `!cat` include sites
**severity:** medium
**change_type:** omission

## Finding

The intro paragraph of the G31 Hook-Point subsection (structure.md L772) states:

> "Additions A, C, and D are inline-permanent text in their consumer files."

This list is incomplete. **Addition B is also inline-permanent text.** The Hook-Point table row for Consumer #2 (L779) reads:

> `skills/plan/SKILL.md` | writer-subagent dispatch payloads (2 sites — Consumer #2): each site carries `!cat skills/_shared/prompt-prose-detection.md` + `!cat skills/_shared/prompt-prose-writer-addition.md` + **Addition B verbatim** (per design.md G31 Consumer #2)

design.md G31 Consumer #2 row (L2618) confirms: "permanent inline Addition B."

## Impact

An implementer reading only the intro text would conclude that B is *not* a permanent inline addition and may treat it as removable / replaceable prose rather than a locked verbatim block. The per-row wording is correct, but the intro assertion creates a false exception that contradicts it. The anchor-phrase checking design.md describes (L2704) relies on verbatim permanence being understood; a false categorization of B breaks that guarantee.

## Fix

Change the intro at structure.md L772 from:

> "Additions A, C, and D are inline-permanent text in their consumer files."

to:

> "Additions A, B, C, and D are inline-permanent text in their consumer files."

(B appears inline verbatim in the 2-site Consumer #2 dispatch payloads; its `!cat` siblings are shared-file includes, but B itself is a permanent inline block.)

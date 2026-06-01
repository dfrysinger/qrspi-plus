# stitching-audit.finding-F01

**reviewer_tag:** stitching-audit
**round:** 12
**artifact:** structure
**section:** ## Per-File Specifications
**severity:** must-fix
**kind:** stitching regression

## Finding

Check 6 fails: verbatim markdown payloads still contain 29 blockquote marker lines starting with `>` / `> `. Survivors are in four payload groups: `agents/qrspi-implementer.md` at structure.md L1606-L1610, `skills/plan/SKILL.md` at L1907, `skills/_shared/design-altitude-boundary.md` at L2125-L2132 and L2140-L2147, and `skills/_shared/multi-actor-flow-check.md` at L2239-L2245. R12 required zero such markers after the R11 blockquote-marker strip.

## Required fix

Strip the leading blockquote markers from those verbatim payload lines while preserving the underlying text and blank-line spacing. Re-run the verbatim-payload scan and confirm no line inside a markdown-fenced payload starts with `>` or `> `.

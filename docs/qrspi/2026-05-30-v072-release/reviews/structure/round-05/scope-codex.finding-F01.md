---
finding_id: R5-F01
severity: medium
change_type: scope
referenced_files:
  - structure.md (lines 209-213, §3 verifier-fanout invocation)
  - design.md (line 470, CD-4 §H verifier-fanout invocation form)
  - design.md (line 63, CD-1 reviewer-fanout invocation form)
  - structure.md (line 204, §3 reviewer-fanout invocation)
  - structure.md (line 279, §7 canonical --tier-override grammar)
---

## Finding

R4-F01 over-corrected: structure.md §3 verifier-fanout now reads `--tier-override qrspi-finding-verifier=<tier>` (a `tag=tier` pair), but design.md CD-4 §H authority specifies bare `[--tier-override <tier>]` for verifier-fanout. This creates an authority-level contract conflict.

## Evidence — design.md uses TWO distinct forms by mode

- **Reviewer-fanout (CD-1, design.md:63):** `[--tier-override tag1=high,tag2=medium,...]` — CSV of `tag=tier` pairs (multiple reviewer agents, each tier-overridable individually).
- **Verifier-fanout (CD-4 §H, design.md:470):** `[--tier-override <tier>]` — bare tier (the verifier is a SINGLETON agent `qrspi-finding-verifier`; no tag namespace needed).

Structure.md §3 R4 fix unified the two modes under §7's CSV grammar, which is incorrect: §7's CSV grammar exists for the reviewer-fanout case where multiple distinct reviewer tags can be tier-tuned independently. Verifier-fanout has only one agent so the `tag=` prefix is meaningless noise.

## Why R3 flagged this (and why the R3 fix was wrong)

R3's quality-claude finding (R3-F01 against §3 vs §7) was correct that the two structure sections disagreed, but the *reconciliation direction* was wrong. The fix should have been to clarify §7 that CSV grammar scopes to reviewer-fanout, while verifier-fanout uses the simpler `<tier>` form. Instead, R4 inflated §3 verifier-fanout to fit §7's grammar.

## Suggested fix

Two-part fix at structure-altitude (no implementation detail needed):

1. **Revert §3 verifier-fanout invocation form (line 212)** from `[--tier-override qrspi-finding-verifier=<tier>]` back to `[--tier-override <tier>]` to match design.md authority.
2. **Clarify §7 (line 279)** that the `<csv>` grammar applies to reviewer-fanout's multi-reviewer surface, and verifier-fanout uses a simpler bare-tier form because the verifier is a singleton agent. One sentence: "Note: this CSV grammar applies to reviewer-fanout. Verifier-fanout's `--tier-override` accepts a bare `<tier>` because the verifier is a singleton agent (`qrspi-finding-verifier`)."

## 3-check scope procedure

1. **Owns?** Yes — interface/CLI contract is structure-altitude (Structure owns interface contracts per skills/structure/owns-defers.md).
2. **Within structure altitude?** Yes — Interface §3 and §7 are structure-altitude surfaces.
3. **Fix altitude correct?** Yes — wording alignment between two structure-altitude sections + alignment with design.md authority; no Plan-altitude or implementation detail needed.

---
severity: medium
change_type: correctness
artifact: design
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/design.md:2259
  - docs/qrspi/2026-05-30-v072-release/design.md:2288
  - docs/qrspi/2026-05-30-v072-release/design.md:2305
  - docs/qrspi/2026-05-30-v072-release/design.md:587
  - docs/qrspi/2026-05-30-v072-release/design.md:707
---

# G28's CD-4 line-number references stale after R3 letter rename — readers navigating by line number reach wrong content

## Summary

The R3 CD-4 letter rename (A–G → J → [acceptance] → H → I rewritten to monotone A–J + acceptance moved to follow J per qc R3-F04) substituted the section-letter token `H.5 → I.5` everywhere it appeared in cross-references, but it did not refresh the *line numbers* that accompany those tokens. G28 carries the bulk of these stale references — five line citations into CD-4, four of which now point at the wrong content, and one which has drifted out of CD-4 entirely.

## The stale references in G28

All three citation sites in G28 use the same set of stale line numbers:

**Site 1 — G28 D4 (L2259):**

> CD-4's iron-rule preservation check (design.md L532, I.5) continues to hold trivially because the script's behavior is identical to v0.7.1.

**Site 2 — Cross-cutting note G28 ↔ CD-4 (L2288):**

> Future amendments to the kept-set logic MUST land in the script (per CD-4's amendment seam at design.md L642), NOT in orchestrator prose or dispositions overrides.

**Site 3 — References (L2305):**

> CD-4 (this file, L380-444 — verifier-fan-in pipeline; L400 context-cost iron rule; L417 threshold rule; L532 I.5 iron-rule preservation check; L642 amendment seam)

## Actual locations vs. cited locations

| Cited | Claimed content | Actual content at that line | Real location of claimed content |
|-------|-----------------|------------------------------|----------------------------------|
| L380 | "verifier-fan-in pipeline" header | inside Mermaid diagram body (`D->>FS: write per-tag PROMPT_FILEs + manifest entries`) | CD-4 header is at L352 |
| L400 | "context-cost iron rule" | inside Mermaid diagram Phase 3 body (`O->>S: verifier-fan-in.sh <round-dir>`) | Context-cost call-out is at L421 (choreography element #6) |
| L417 | "threshold rule" | choreography element #2 (Sequence) | Threshold rule is at L438 (§C step 3) |
| L532 | "I.5 iron-rule preservation check" | "**Tier 1 — mechanical fixes**" (inside §I.3) | I.5 is at L587 — 55 lines off |
| L642 | "amendment seam" | inside §I.7 platform directory / override chain prose | Amendment seam is at L707 |

The "L380-444" range purporting to cover the entire verifier-fan-in pipeline ends at L444, which is mid-Component E (`.verifier-fan-in-audit.json` schema example) — the pipeline section actually runs from L352 (header) past L709 (iron rule). So the cited *range* also under-shoots by ~270 lines.

## Why this matters

A reader following any of these line numbers reaches content that does not match what G28 claims is there. Concrete consequences:

1. **Plan task authoring against G28** — a Plan-time reader who Reads `design.md` at L532 looking for the iron-rule preservation check finds the tier-1 rescue list instead. The "iron rule still holds" claim G28 D4 makes (the core load-bearing rationale for "scripts/verifier-fan-in.sh unchanged") becomes unverifiable from G28 alone.
2. **Cross-cutting trace via References section** — the References block at L2305 is the audit trail for downstream skills consuming G28. Every CD-4 anchor in that audit trail is wrong. A future maintainer consulting "where is the amendment seam?" by following the L642 reference lands inside an unrelated platform-detection branch.
3. **The "L532, I.5" parenthetical is internally inconsistent on its own line** — it asserts that I.5 is at L532. The reader doesn't need to leave G28 D4 to notice the inconsistency once they look up either anchor.

## What R3 did and didn't do

R3 substituted the letter token (`H.5 → I.5`, `§H rescue tier → §I rescue tier`). The substitution was the right surface for the *named* anchor — the reader who follows "I.5" by searching the file (rather than jumping to a line number) reaches the correct content at L587. The line numbers were the unfortunate companion data that R3 did not refresh, and that subsequent insertions (CD-4 §I.7 rewrite for qc R3-F02, the new I.3 sub-paragraphs for qc R3-F01) drifted further.

## Recommendation

Two clean options:

**Option A — Delete the line numbers; keep the named anchors.** The named anchors (§I.5, §C, §E, amendment seam) are unambiguous within CD-4 and stable across future R5+ edits. The line numbers carry no information the named anchors don't already convey. Rewrite the three sites:

- **L2259:** "CD-4's iron-rule preservation check (CD-4 §I.5) continues to hold trivially..."
- **L2288:** "...per CD-4's amendment seam..." (drop "at design.md L642")
- **L2305:** "CD-4 (this file, § Verifier-Fan-In Pipeline — Mermaid diagram + choreography elements; §C threshold rule; §I.5 iron-rule preservation check; § Amendment seam — G19)"

**Option B — Refresh the line numbers.** Update all five references to point at the current locations (L352 for CD-4 header, L421 for context-cost, L438 for threshold rule, L587 for I.5, L707 for amendment seam). This works for this round but reintroduces the same rot risk on the next CD-4 edit.

Option A is more durable and matches the convention elsewhere in design.md (named-anchor references to external SKILL files use literal heading text, not line numbers, per G23 D2 acceptance criterion "phrasing matches the existing cross-link style…uses the literal heading text — not a line number — so the cross-link survives future re-numbering"). The same principle applies to internal references inside design.md.

## Scope note

This is one author's localized cross-reference rot in G28. A broader audit across the file (searching for any "design.md L<NNN>" or "this file, L<NNN>" pattern) may surface a small number of similar drifts; if so they should be fixed under the same Option A pattern. Not scoping that wider audit to this finding — flagging G28's specific cluster because R3 made these references concretely wrong rather than merely stale-by-aging.

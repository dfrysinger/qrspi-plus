---
finding_id: quality-claude-r03-F01
severity: low
change_type: clarity
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/phasing.md
artifact: phasing
---

# Slice 1.5 Surface enumerates "Structure" but no slice-1.5 goal edits Structure SKILL.md

## Where

`phasing.md` § "### Slice 1.5 — Skill prose & interactive dialog quality" — the Surface line:

> **Surface:** SKILL.md prose hardening across Goals, Design, Structure, Plan; Goals + Design interactive dialog quality + compaction-resilient incremental persistence; reviewer-authority discipline; scope-reviewer alignment with the detailed-solution boundary.

## What

The Surface line lists four target skills as receiving "SKILL.md prose hardening" in slice 1.5: Goals, Design, **Structure**, Plan. But none of the nine goals listed in slice 1.5 (G1, G2, G5, G10, G17, G30, G31, G33, G34) edit Structure SKILL.md prose:

- **G1** edits Design SKILL.md (Dialogue Conduct + Sub-Rules A/B + template).
- **G2** edits Plan SKILL.md (schema-migration task shape).
- **G5** edits Plan SKILL.md (idempotent post-approval split contract).
- **G10** edits reviewer-protocol SKILL.md (no-fabricated-authority anti-pattern).
- **G17** edits implementer-protocol SKILL.md and qrspi-test-writer agent (stale gitignore prose).
- **G30** edits Goals + Design SKILL.md (compaction-resilient persistence + dialogue conduct).
- **G31** edits reviewer agents + prompt-design-guide (prompt-prose reviewer wiring).
- **G33** edits Design SKILL.md (simple-language dialog rule, folded into G1's Dialogue Conduct).
- **G34** edits Design scope-reviewer + design owns-defers (scope-reviewer alignment).

The Structure SKILL.md prose work is owned by **slice 1.6** (G35), which gets its own dedicated slice precisely because the Structure-absorption shape is distinct. Mentioning "Structure" in 1.5's Surface creates ambiguity about whether 1.5 and 1.6 overlap on Structure SKILL.md, which they do not.

The Surface line is also **incomplete**: it omits implementer-protocol (touched by G17) and reviewer-protocol (touched by G10), both of which are edited by slice-1.5 goals.

This is consistent with the round-02 boundary-drift fix abstracting concrete file paths up to generic skill names without reconciling the abstracted list against the actual goal contents.

## Why it matters

Downstream consumers (Structure, Plan, Replan) read the slice Surface line to decide what edit surface each slice claims. The current text suggests slice 1.5 and slice 1.6 both touch Structure SKILL.md, which could lead a Plan task author to either (a) duplicate Structure SKILL.md edits across two parallel slices or (b) skip the Structure-absorption work assuming slice 1.5 covers it. The omission of implementer-protocol and reviewer-protocol from the surface enumeration also means scope-tagger / reviewers may not anticipate edits landing in those skill files when reviewing slice-1.5 work.

The roadmap.md slice 1.5 theme column avoids this trap by saying only "SKILL.md prose hardening + Goals/Design dialog quality" — the phasing.md slice prose drifted from that more accurate framing.

## Suggested fix

Either:

(a) Replace "Goals, Design, Structure, Plan" with the actual edited skills: "Goals, Design, Plan, reviewer-protocol, implementer-protocol" (and drop "Structure" — Structure SKILL.md prose is slice 1.6's responsibility).

(b) Drop the per-skill enumeration entirely and lean on the thematic framing already in the second clause: "SKILL.md prose hardening + interactive dialog quality across the authoring skills; reviewer-authority discipline; scope-reviewer alignment." — letting the per-goal entries downstream define the precise edit set.

Option (b) is closer to the round-02 stripping intent (no concrete file/skill paths in Surface prose). Choose at author discretion.

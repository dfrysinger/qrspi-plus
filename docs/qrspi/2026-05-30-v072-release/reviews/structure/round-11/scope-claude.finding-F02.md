---
finding_id: R11-F02
severity: low
change_type: scope
referenced_files: [docs/qrspi/2026-05-30-v072-release/structure.md:L15]
artifact: structure
round: 11
reviewer: scope-claude
---

The `## Prose Provenance Convention` preamble's `**Why per-file blocks.**` paragraph at L15 narrates the artifact's own revision history — explaining the prior shape that the per-file block format displaced — rather than documenting the current convention evergreen.

The literal text: *"Earlier revisions split this information across a §File Map row, a §Interfaces signature block, a §Hook-Point Locations row, and a verbatim-prose source in design.md that was cited only by topic. Plan and Implement consumers had to dereference four sections (three in structure.md, one in design.md) per file before authoring a task. The per-file block removes that dereference cost and removes the dual-citation drift risk where structure.md and design.md disagree on the locked prose."*

This is version-history narration that survives into the evergreen artifact. A consumer reading structure.md for v0.7.2 has no contact with "earlier revisions" — those drafts do not exist in the shipped state. The dereference-cost rationale is real but reads backwards: it justifies the convention by contrast against a prior state the consumer cannot see, rather than naming what the per-file block format DOES in the consumer's present (consolidate file-level reasoning into one block; pin the design→structure→plan→implement chain to a single anchor point per file).

The user's R11 scope-expansion frame explicitly authorizes the `## Prose Provenance Convention` H2 itself. This finding does not contest the H2's existence or its load-bearing role; it contests the past-tense framing of one paragraph inside it. The Evergreen-Output Rule (CD-2, shipping in v0.7.2 itself) names this exact antipattern — "we used to do X, now we do Y" prose that drafts the artifact's history into the artifact's content. Structure absorbing that rule mid-release while structure.md ships a small example of the antipattern is the load-bearing inconsistency.

Fix shape (one-paragraph rewrite, no structural change):

Replace L15 with a present-tense statement of what the per-file block format achieves for the consumer — e.g., *"Each per-file block is the single anchor point where an architect, Plan consumer, or Implement consumer reads everything that pertains to one target file: its action, slice, goal IDs, responsibility, interface signature, design.md-sourced verbatim prose (when locked), outline-only constraints (when deferred), test-coverage boundary, and `!cat` / `skills:` hook-point list. Consolidating these into one block removes per-file dereference cost across structure.md's prior sections and removes the dual-citation drift risk where structure.md and design.md could disagree on the locked prose."*

The rewrite preserves the load-bearing rationale (dereference cost; dual-citation drift) without anchoring it to a prior-revision contrast the consumer cannot verify.

Lower severity than F01 because: (1) this is a one-paragraph prose-quality slip in a preamble, not a contract-shape violation; (2) the surrounding paragraphs in the same H2 are already correctly framed in present tense (`**Verbatim vs outline.**`, `**Asymmetry is explicit, not implicit.**`, `**Interface signatures are inline.**`, `**Consumer hand-off.**`), so the drift is localized to one paragraph rather than systemic; (3) the consequences (consumer mildly confused by a backwards-pointing rationale) are nowhere near the consequences of F01 (Plan-altitude LOC estimates pre-committed at Structure altitude).

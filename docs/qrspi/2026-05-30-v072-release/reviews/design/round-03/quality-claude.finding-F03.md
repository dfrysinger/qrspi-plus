---
finding_id: R3-F03
severity: low
change_type: clarity
artifact: design
round: 3
reviewer: quality-claude
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/design.md:L3014-L3020
---

## Three orphan bullets at end of file with no parent heading

**Location:** `design.md` L3014–L3020 (after G35's closing `**Plain-language summary.**` paragraph, before EOF).

**Problem.** Three bullets dangle at the end of the file with no H2 heading, no introductory anchor prose, and no traceable owner:

```
- **Q5 under-counted consumer list** — research/summary.md Q5 (line 68) said splitter is not invoked by run-codex-review.sh; missed that implement/SKILL.md is the highest-density consumer (9 invocations + 2 splitter blocks).
- **Backward-loop flag mechanism may be dead code** — never observed in any session. The Pause Gate option 3 cascade may be undiscoverable in practice. Preserved in new architecture (cost is negligible) but worth observability check post-v0.7.2.
- **Design skill encourages "synthesize at end"** with no incremental persistence — risks losing 25+ goal-walkthrough decisions if compaction fires mid-Phase 1. This file is the workaround; the fix is a new design SKILL.md instruction to persist incrementally (could fold into G1's deliverables).
```

The bullets read as leftover scratchpad observations from earlier drafting — meta-notes about research-summary gaps, plugin-issue candidates, and a Design-skill improvement idea. Each one's content has (or should have) an owner elsewhere:

- The Q5 note duplicates content already in G3's solution (L1033) and CD-1's broader rename inventory — likely redundant.
- The backward-loop-dead-code note belongs in G4 / G6 as either a `Plugin issues flagged for v0.7.3 retro` bullet or an `Open Questions for v0.7.3+` entry (both established subsection patterns in the artifact).
- The "synthesize at end" note describes a Design SKILL.md improvement — exactly the surface G1's deliverables (L944–971) operate on, and it identifies a real gap not currently covered by any G1 deliverable (none of #1–#9 instruct incremental persistence). This one is *not* redundant; it surfaces an under-spec'd surface.

**Impact.** A reader navigating to G35 expects the file to end there; the orphan bullets either get treated as part of G35 (confusing, since they aren't about Structure SKILL absorption) or get skimmed past entirely. The third bullet flags a real Design SKILL.md gap that, left dangling, will be lost on the next compaction.

The CD-2 evergreen-output rule itself (L221–292 in this artifact) names "dialogue exhaust" and "session/drafting notes" as named antagonist patterns to strip — these three bullets fit that pattern by the artifact's own definition.

**Suggested fix.** Resolve each bullet to its proper home:

- Delete the Q5 bullet (already covered in G3 and CD-1).
- Move the backward-loop-dead-code observation into G4's or G6's `Pre-existing plugin issues to file` / `Open Questions for v0.7.3+` subsection (both goals already carry these subsection patterns).
- Either fold the "synthesize at end" observation into G1's deliverables (add a new deliverable #10 instructing incremental persistence to design.md under `status: draft` during the per-goal walkthrough) OR file it as an explicit Open Question for v0.7.3+ in G1's block, naming the observation and the candidate fix.

Then delete L3014–L3020 from the EOF region so the file ends cleanly at G35's closing paragraph.

---
status: approved
managed_by: phasing
source: v07-release-deferrals
---

# Future Research Summary

Research deferred from the v0.7 release alongside its owning goals.

## For G16 — Wave nesting in parallelization.md

The Q21 findings about current Branch Map and Execution Order presentation shape in `parallelization.md` are colocated in `research/summary.md` under the heading **Q13, Q14, Q21: Parallelize worktree checks, Branch Map vocabulary, and artifact shape**. The Q13/Q14 content serves the current-phase G8/G9 goals; the Q21 content (artifact shape, flat Branch Map table, separate narrative Execution Order section, single deliberate out-of-scope fixture under `tests/fixtures/`) is G16-relevant and stays colocated in `research/summary.md` for reference rather than being split out, because the collated section is the analytic unit that produced the findings and splitting would lose the cross-reference value the collator created.

The canonical `research/q21.md` corpus file remains in `research/` per the Phasing skill contract ("individual research/q*.md files are NOT split — they stay as full corpus"). When G16 is promoted in a future release, Phasing will pull the Q21 finding paragraph(s) forward from the collated summary.

### Q21 finding pointers (read from `research/summary.md` § Q13/Q14/Q21)

- Worked Example presents `parallelization.md` as frontmatter plus Execution Mode, Dependency Analysis, Execution Order, Branch Map, Stage Commits, and Mermaid sections.
- The only fixture under `tests/fixtures/` is a deliberate out-of-scope seed with a malformed Branch Map including concrete commits.
- Reviewer linting of artifact shape is split between quality checks in `qrspi-parallelize-reviewer.md` and scope/boundary checks in `qrspi-parallelize-scope-reviewer.md`.

These pointers are sufficient for a future G16 promotion. No corpus-file move required.

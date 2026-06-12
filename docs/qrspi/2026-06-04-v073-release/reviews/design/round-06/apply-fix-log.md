# R06 Apply-Fix Log

## Applied (1 finding — borderline scope, partial acknowledgement)

### scope-codex.R6-F01 (score 70) — G9 placement matrix prescribes file paths
**Fix applied** at G9 Pass 1 preamble (L505):
Added one-sentence note clarifying that the architectural decision is the four reuse tiers (universal / multi-skill-shared / skill-specific / on-demand-optional), and that specific file paths in the "Lives where" column are conventional locations Structure may refine. The tier identity is what Design fixes, not the literal path string.

This partially addresses the verifier's substance concern (sidecar score 70: G9 names specific file paths and ties acceptance to them, crossing into file-architecture). Full removal of paths would damage cross-skill vocabulary establishment (which is Design OWNS) and contradict scope-claude's R6 endorsement (scope-claude classified the same section as "naming cross-cutting architectural components, within Design OWNS").

The two scope reviewers disagree on this section; the fix acknowledges both viewpoints — Design owns the tier architecture (Pass 1 decision content), Structure owns exact path refinement.

## Dropped (3 findings — recurring quality hallucinations)

- quality-claude.R6-F01 (10) — Mermaid
- quality-codex.R6-F01 (10) — Mermaid
- quality-codex.R6-F02 (20) — Test Strategy

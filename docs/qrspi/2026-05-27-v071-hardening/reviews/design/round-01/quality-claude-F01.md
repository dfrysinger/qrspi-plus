---
artifact: design
reviewer: quality-claude
round: 1
finding_id: F01
severity: medium
check: approach-rationale-grounded-in-research
---

# F01 — DKR2 reasoning cites the wrong research file for the `.git/info/exclude` finding

## Location

`design.md` § **DKR2 -- Gitignore the scratch commit-message file (G2)** — Reasoning paragraph.

## Observation

The DKR2 Reasoning states:

> Per `research/q04-codebase.md`, the current safety relies on a per-clone `.git/info/exclude` entry — fresh clones and worktrees receive no protection.

`research/q04-codebase.md` is the question about **what paths and glob patterns the repo's `.gitignore` currently matches**. Its key findings enumerate four active entries (`.worktrees/`, `.vscode/`, `.DS_Store`, `**/.DS_Store`) and its caveats explicitly say "no `.gitattributes` or `.git/info/exclude` files were checked for additional ignore patterns." It documents no `.git/info/exclude` mechanism.

The `.git/info/exclude` / Invariant 3 finding is in **`research/q03-codebase.md`** (the question about the step-by-step commit procedure), which documents: "Invariant 3 (`.git/info/exclude` entry for the scratch path)" and explains that `git add -A` cannot stage the scratch file because of that per-clone exclude entry.

Notably, the **Trade-offs Considered** section of the same `design.md` (§ G2: Reorder the commit procedure) correctly cites `research/q03-codebase.md` for this same finding — making the DKR2 Reasoning a direct within-document citation inconsistency.

## Why it matters

An implementer following the DKR2 reasoning link to verify the claim would open q04 (gitignore file contents), find no mention of `.git/info/exclude`, and be unable to confirm the design's stated rationale. The research trail is broken.

## Recommended fix

In DKR2 Reasoning, change `research/q04-codebase.md` → `research/q03-codebase.md`:

> Per `research/q03-codebase.md`, the current safety relies on a per-clone `.git/info/exclude` entry — fresh clones and worktrees receive no protection.

(The Trade-offs G2 section already has the correct citation and does not need to change.)

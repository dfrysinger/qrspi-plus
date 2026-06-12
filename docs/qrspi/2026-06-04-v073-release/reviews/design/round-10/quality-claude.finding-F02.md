---
artifact: design
reviewer_tag: quality-claude
finding_id: quality-claude-F02
change_type: clarity
---

# G7 Solution still calls step 11 "the anchor-capture commit" — contradicts the corrected one-commit-per-round narrative

## Location

design.md L425 (G7 Solution paragraph).

## Finding

Round 10 updated G7's structural model (L431, L445) to align with research Q13/Q14: the per-round commit bundles everything, and `reviews/<step>/round-NN-commit.txt` is a file-write **after** the commit — NOT a separate commit. But line 425 still reads:

> Round-N's fix-commit SHA is already written to `reviews/<step>/round-NN-commit.txt` by step 11 (the anchor-capture commit).

The parenthetical "(the anchor-capture commit)" parses as identifying step 11 with an anchor-capture commit. Two problems:

1. Per research Q13/Q14 (and per L431/L445 in this same section), step 11 is the **per-round commit**, not an "anchor-capture commit." The anchor-capture step is a file-write that follows the commit; it has no commit of its own.
2. The phrasing implies the file-write produces a commit — which is exactly the misunderstanding the round-10 changes were meant to remove from the rest of the section.

The contradiction makes the same paragraph that introduces the anchor file simultaneously assert (a) "captured by a commit" and (b) "the file write is not its own commit" (L445).

## Expected fix

Replace `by step 11 (the anchor-capture commit)` with `by step 11 (the per-round commit's anchor-capture step — a file-write performed by main chat immediately after the per-round commit; see Q13/Q14)` — or, more tersely, drop the parenthetical entirely and let the rest of G7's prose carry the structural description:

> Round-N's fix-commit SHA is already written to `reviews/<step>/round-NN-commit.txt` by step 11. Step 12 reads that file directly when computing the narrow ref:

The cleanest fix is the deletion; the structure is explained correctly later in the section, so the parenthetical adds nothing but the contradiction.

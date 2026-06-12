---
artifact: design
reviewer_tag: quality-claude
finding_id: quality-claude-F02
change_type: clarity
---

# G7 brittleness rationale lists "anchor SHA file pickup" as a HEAD~1-shifting hazard — contradicts the section's own one-commit-per-round model

## Location

design.md L422 (G7 Outcome, brittleness item (1)). Cross-references L426 (G7 Solution — "anchor SHA file-write — not its own commit; per research Q13/Q14 each round produces exactly one commit") and L432 ("the anchor SHA file … is written by main chat after the commit and remains uncommitted until the NEXT round's per-round commit picks it up — confirmed in research Q13/Q14").

## Finding

Round 11 reframed G7's Outcome paragraph to name two specific brittleness modes the anchor-file lookup eliminates. Item (1) reads:

> (1) any unrelated commit landing between rounds (hotfix, bookkeeping, **anchor SHA file pickup**) shifts `HEAD~1` off the prior round's commit, producing a malformed diff;

The same round-11 diff also tightened the rest of G7 to commit explicitly to a one-commit-per-round structural model, citing research Q13/Q14:

- L426: "Round-N's per-round commit SHA is already written to `reviews/<step>/round-NN-commit.txt` by step 11 (the anchor SHA file-write — **not its own commit**; per research Q13/Q14 each round produces exactly one commit)."
- L432: "the anchor SHA file `reviews/<step>/round-NN-commit.txt` is written by main chat after the commit and **remains uncommitted until the NEXT round's per-round commit picks it up** — confirmed in research Q13/Q14".

Under that model, anchor SHA file pickup is **bundled into the next round's per-round commit** — it is *that* commit, not an additional commit between rounds. So it cannot shift `HEAD~1` off the prior round's commit. The HEAD~1 calculation from round N+1's POV resolves to round N's per-round commit regardless of whether the prior round's anchor file was uncommitted-on-disk and got picked up by N+1's per-round commit (that's the legitimate position, not a hazard).

The other two examples in the parenthetical hold up cleanly:

- **hotfix**: a legitimate cross-cutting commit that lands outside any review-round commit chain → shifts `HEAD~1`. Real hazard.
- **bookkeeping**: an out-of-band commit (e.g., main chat commits something it shouldn't per G5) → shifts `HEAD~1`. Real hazard.

The third example — "anchor SHA file pickup" — is the one that under the design's own model is **not** a separate commit. Listing it as a HEAD~1-shifting hazard contradicts L426 and L432.

This is also the v0.7.2 self-host shape from goals.md G7 ("Step 11 generates **two** commits per round (the fix commit, then the anchor-capture commit for `round-NN-commit.txt`)"). The round-11 rewrite correctly aligns the design with research Q13/Q14 (one commit per round) and away from the goals.md two-commit framing — but L422's parenthetical drags the goals.md two-commit framing back in via this single example. The reader is left unable to tell whether the design's model is one-commit (per L426/L432) or two-commit (per L422's example).

## Expected fix

Replace "anchor SHA file pickup" with an example that actually fits the design's stated model. Two options:

(a) **Drop the third example and let the open-ended phrasing carry the rest.** L422 becomes:

> (1) any unrelated commit landing between rounds (hotfix, bookkeeping, etc.) shifts `HEAD~1` off the prior round's commit, producing a malformed diff;

(b) **Replace with a HEAD~1-shifter that is a real commit under the current model.** Candidates: a fix-up commit added between fix and anchor-capture by an out-of-band actor, a merge-commit landing on the branch between rounds, a stage-commit from G6's surface that lands during a per-task review round. Pick one and substitute it for "anchor SHA file pickup".

Either fix removes the internal contradiction. (a) is the lower-risk fix because it doesn't introduce a new example that itself needs to be vetted against the rest of the model.

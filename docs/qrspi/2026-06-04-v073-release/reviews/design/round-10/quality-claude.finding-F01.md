---
artifact: design
reviewer_tag: quality-claude
finding_id: quality-claude-F01
change_type: correctness
---

# G7 Outcome's bug premise contradicts G7's newly-acknowledged one-commit-per-round shape

## Location

design.md L419-431 (G7 Outcome + Solution); cross-references goals.md G7 (multi-commit framing) and research/q13-q14-codebase.md (one-commit-per-round finding).

## Finding

Round 10 rewrote line 431 from "Keep the existing two-commit-per-round shape" to "Keep the existing one-commit-per-round shape ... confirmed in research Q13/Q14." That change correctly aligns with research Q13/Q14 (TL;DR: "Each apply-fix review round produces exactly one git commit. ... the total per-round commit count is always 1"). But the Outcome paragraph (L419-421) and the goal title (L419) were not updated to match, and the bug they describe cannot occur under the new structural model:

- **Goal title (L419):** "Narrow-round ref selection robust under multi-commit-per-round patterns" — explicitly frames the goal around multi-commit-per-round.
- **Outcome (L421):** "Silent empty-diff termination — where `git diff HEAD~1 -- <file>` produces zero lines because `HEAD~1` happens to point at the same round's fix commit instead of the prior round's — cannot recur."

Under one-commit-per-round (as L431 now establishes), `HEAD~1` from round N+1's POV IS the prior round's per-round commit by construction. There is no separate same-round fix commit for `HEAD~1` to land on. The failure mode the Outcome describes is structurally impossible under the shape L431 now asserts is real.

Cross-checking the citation: research Q14 further documents that the existing convergence rule (`skills/using-qrspi/SKILL.md:1026`, `scripts/round-prepare.sh:300–308`) already validates `HEAD~1 == prior round-NN-commit.txt SHA` and falls back to broaden on mismatch — so even if HEAD~1 did point somewhere unexpected, the existing mechanism prevents the silent-empty-diff outcome the Outcome claims would otherwise occur.

The mismatch leaves three readings, none of which the current prose disambiguates:

1. **The current shape really is one-commit-per-round** (matches Q13/Q14): then the bug as described in Outcome cannot recur today regardless of G7. G7 is defense-in-depth against future reintroduction of multi-commit patterns, OR against the orchestrator skipping the existing anchor-validation assertion under context pressure (the G9/G5 anti-pattern). The Outcome should be rewritten to describe the actual current failure window, not the v0.7.2-shape failure that no longer applies.
2. **The current shape is actually still multi-commit in some paths** (matches goals.md G7's live repro from v0.7.2 self-host, which shows three commits c2acbae/48da62c/d32fc50 in a chain): then L431's "one-commit-per-round ... confirmed in research Q13/Q14" claim is too strong — the artifact-level path may differ from what Q13/Q14 examined, or v0.7.2-self-host SKILL prose differed from current. Either qualify the claim or revert L431.
3. **The current per-round commit is one commit, but other unrelated commits can still land between rounds** (orchestrator bookkeeping commits, fix-up commits, anchor commits in other skills not yet migrated, etc.): then the Outcome should name that failure mode explicitly, not the same-round-fix-commit shape that doesn't apply.

Whichever reading is correct, the Outcome paragraph and the goal title need to be reconciled with L431. As written, the design tells the reader "the bug occurs because of multi-commit-per-round" in one paragraph and "the existing shape is one-commit-per-round (so the bug shape doesn't apply)" in the next.

## Expected fix

Either:

(a) Update Outcome (L419-421) and the goal title (L419) to reflect the actual failure mode under one-commit-per-round. Most plausibly: "`HEAD~1` is an implicit positional ref that breaks silently when ANY unrelated commit lands between rounds (orchestrator bookkeeping, intermediate process commits, etc.); the existing per-round-commit-anchor assertion in `skills/using-qrspi/SKILL.md:1026` is the safety net but is SKILL-prose the orchestrator can skip under context pressure (the G5/G9 anti-pattern). Reading the anchor file directly removes the implicit-ref failure window AND removes the orchestrator-skippable validation step." Then drop "multi-commit-per-round" from the goal title.

(b) If the structural model in L431 is wrong (i.e., multi-commit-per-round still exists in some path), revise L431 to scope the one-commit-per-round claim to the path Q13/Q14 actually examined, and keep the Outcome's multi-commit framing for the path(s) that still have it.

A two-line clarification at the top of G7 that explicitly reconciles "the bug premise" with "the structural model" would resolve this.

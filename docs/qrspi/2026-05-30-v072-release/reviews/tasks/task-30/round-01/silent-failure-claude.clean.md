# Silent Failure Hunter — Task 30 Round 1 — CLEAN

Reviewer: silent-failure-claude
Artifact: `skills/design/SKILL.md` (prompt-prose rewrite per T30 / design.md ## G1)
Diff: round-01.diff

## Verdict: CLEAN

No silent-failure findings. The diff is a prompt-prose rewrite; I adapted the
silent-failure rubric to the prose surface (STOP rules degrading to
log-and-continue, loud-failure requirements weakening, halt semantics
softening, deferral as silent-default).

## What I checked

1. **Removed STOP entries are ownership transfers, not downgrades.** The two
   deleted Red Flag — STOP bullets (`No test strategy section…`,
   `No Mermaid system diagram…`) and their matching rationalizations rows are
   removed because Design no longer owns the test-strategy or unified
   system-diagram artifacts (transfer to Structure per G35; per-goal Mermaid
   stays as optional inside each goal block under Sub-Rule C). They are
   deleted outright — not converted into warn/continue or "best effort"
   guidance. Clean transfer.

2. **Loud-failure posture is strengthened.** Sub-Rule C adds a required
   `Loud-failure paths` flow element with the anchor sentence
   `"Silent fallback" is never the answer — name the diagnostic.` Sub-Rule D
   forbids `TBD per vendor docs` deferrals and names the failure mode
   ("becomes a downstream blocker that resolves to either a guess (silently
   wrong) or a halt the user has to unblock — either outcome is a design
   defect"). Dialogue Conduct rule 7 treats implicit hand-offs as an open
   branch that must be closed before moving on. The unknown-branches rule
   requires `safe-default + verification procedure` instead of `TBD figure out
   later`. Net direction: more loud-failure surface, not less.

3. **Altitude tests use halt-and-back-off semantics.** Each sub-rule's
   altitude test ends with `If no → back off` or `If no → name the missing
   external answer, research it`. No log-and-continue branch.

4. **Decision-locking has no silent skip.** Rule 8 writes each decision into
   the goal block under `status: draft` as confirmed; rule 7 requires every
   branch decided, explicitly deferred with written reason, or split into a
   separate goal. No silent accumulation/skip path introduced.

5. **No silent paraphrase fallback introduced for prose-as-design.**
   Sub-Rule B explicitly rejects `"The rule should say X in spirit"` at any
   scale and requires verbatim authoring or intent + skeleton + anchor
   phrases — no degraded "approximate wording is fine" branch.

6. **No new empty/placeholder templates.** The per-goal block fields are
   required; no `{TBD}` defaulting introduced. The R6/R7 audit constraints
   from the task definition (no TODO/TBD, no decorative Mermaid, no stale
   line-number references) are observed in the new prose.

7. **No silent error-transformation.** No prose path converts a hard rule
   into a warn/continue; the `## Red Flags — STOP` framing is preserved and
   the surviving entries remain hard stops.

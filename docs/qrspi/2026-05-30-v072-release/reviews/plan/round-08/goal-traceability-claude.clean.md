# Plan goal-traceability review — round 08 (broaden vs main) — clean

**Reviewer:** claude (plan-goal-traceability-reviewer)
**Artifact:** plan.md
**Diff ref:** main (broaden round; no scope hint)
**Round-07 fix under review:** E1 — T25 added one Test Expectations bullet (plan.md L1414) elevating the existing DoD invariant at L1406 ("No stale `docs/prompt-design-guide.md` references remain in the repo") to an executable expectation.

## Verdict

No goal-traceability findings.

## Why clean

### Round-07 fix (L1414) verification

- **Forward trace (G31 → T25 → plan-authored criterion):** G31's "prompt-prose-coverage contract not yet enforceable" framing in goals.md ### G31 is the upstream problem; design.md ## G31 specifies the `git mv docs/prompt-design-guide.md → skills/_shared/prompt-design-rules.md` migration with deletion of the old path as a single-source-of-truth invariant; T25 owns the migration; the new L1414 bullet asserts the post-condition is build-enforced. Chain intact.
- **Backward trace (T25 → G31):** unchanged from round-07. T25 header at L1433 carries `Goal IDs: [G31]` only; the Overview's "Why" at L1384 cites `goals.md ### G31` and `design.md ## G31`; References at L1424 likewise.
- **DoD-to-test parity strengthening:** prior to this round, the L1406 DoD invariant lacked a paired Test Expectations bullet — the test expectations covered file existence, verbatim body match, and the 8 refresh-edit anchors, but the "no stale references" property was DoD-only. L1414 now closes that DoD-to-test asymmetry. The bullet explicitly tags itself "matches DoD invariant" to make the pairing audit-greppable.
- **No goal-coverage shift:** the bullet does not introduce new goal coverage (T25 still covers G31 only) and does not orphan any other goal (G31's other facets — Files 1-5 authoring, rule-refresh edits A-H, fast-path glob distinction — remain covered by other bullets in the same block). The strip-from-goals contract is honored: criterion authoring stays in plan.md.
- **Decomposition check:** G31's problem text in goals.md frames the migration as part of the prompt-prose coverage contract; deleting the old docs path and ensuring no stale references survive is a direct decomposition of "make the contract enforceable" (a live reference to a deleted source-of-truth file is precisely the kind of drift the contract aims to prevent).

### Surface outside the round-07 fix

No scope hint was provided (broaden round). I scanned the full diff for any other goal-trace regressions: none observed. The 38 tasks across 7 slices each carry `Goal IDs:` headers tracing to at least one approved goal, and the per-phase acceptance block at L25-L33 cross-references the cross-cutting fail-loud invariants for each major goal cluster (G3/G4/G6/G7/G8/G9/G11/G12/G13/G14/G15/G16/G18/G19/G20/G21/G22/G23/G27/G28/G31 surfaces all observable in the phase-acceptance bullets). Dropped findings (sec-codex.F01, scope-codex.F01, sf-codex.F01, tc-codex.F01) remain addressed and are not re-raised — E1 does not regress any of them.

## Dropped findings re-check

- **sec-codex.F01, scope-codex.F01, sf-codex.F01, tc-codex.F01** — not re-raised; round-07 E1 is additive at L1414 only and does not touch their respective fix surfaces.

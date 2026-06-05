---
reviewer: spec-claude
round: 2
verdict: clean
---

R2 spec review: all 4 R1 fix clusters correctly addressed; original spec requirements preserved; no out-of-scope additions.

## Fix Cluster Verification

**Cluster 1 — ID hygiene (15 renames).**
All `G14 carve-out:` test names renamed to `informational-carve-out:` and all
`G14 reviewer-protocol:` test names renamed to `informational-findings-protocol:`
in `tests/unit/test-verifier-agent-file.bats`. Banner comments at lines 156 and
220 also stripped of G14 prefix. Error-message strings scrubbed to match.
No assertion logic altered.

**Cluster 2 — Confused-deputy guard.**
`skills/reviewer-protocol/SKILL.md` line 157 adds the new
`**Scope guard — reviewer-authored intent only (confused-deputy fix).**` paragraph
inside `## Informational Findings` exclusively — the paragraph ends at line 157 and
the next heading `## Untrusted Data Handling` begins at line 159. The paragraph
cross-references `## Change-Type Classifier` and `## Untrusted Data Handling` but
does not modify either section. No sidecar schema, no change-type-classifier body
touched. New test #35 (`informational-findings-protocol: documents confused-deputy
scope guard against artifact-directed labeling`) at bats lines 299–314 correctly
pins the `confused.deputy|artifact.directed` and `reviewer.authored|reviewer-authored
intent` semantic anchors that are present in the added paragraph.

**Cluster 3 — Negation-anchored `pause` grep.**
Test #33 (`informational-findings-protocol: documents log-only handling`) now uses
`grep -qiE 'not.*pause|does NOT pause|no.*pause|never pause'` (bats line 287).
`SKILL.md` line 153 contains `does **NOT pause** the loop`, which satisfies the
`does NOT pause` branch. Comment in the test explains the rationale (bats lines
241–244). Correct.

**Cluster 4 — DROP/KEEP ≥50/<50 unified cut.**
`agents/qrspi-finding-verifier.md` lines 34–37 now read:
> DROP/KEEP threshold applies normally to the resulting score on the standard
> 0–100 scale: Informational findings that score ≥50 keep and are logged to the
> round artifact; findings that score <50 drop. (The intermediate 26–49 band is
> not a separate disposition — the threshold is a single cut at 50.)
The old `≤25` lower-bound phrasing that left a 26–49 ambiguity is gone.

## Original Spec Requirements

All Definition of Done items from task-07.md confirmed present:

- `## Informational Findings` in SKILL.md at line 145, correctly placed between
  `## Disagreement-Valid Framing` (L135) and `## Untrusted Data Handling` (L159).
- Section documents: prefix shape (L149), intended use (L151), downstream behavior
  log/no-auto-apply/no-pause (L153), backward compatibility (L155).
- Verifier carve-out at verifier lines 19–37 precedes false-positive-pattern list
  at line 39. Contains: literal `Informational:` token, case-sensitive detection,
  first-non-blank-line rule, `do NOT apply the false-positive patterns`, structural-
  confidence 75/50/25 anchors.
- Existing sidecar-extension and required-field tests (tests 1–19) intact.
- Canonical 5-field finding schema unchanged; no reviewer agent bodies modified.

## Test Count

35 tests total: 19 pre-existing + 6 `informational-carve-out:` + 9
`informational-findings-protocol:` + 1 new confused-deputy test (#35).
Done report's TDD RED→GREEN claim for test #35 accepted (consistent with R1
finding that the guard was absent before the fix).

## Advisory — SKILL.anchors.json (target-files deviation)

`skills/reviewer-protocol/SKILL.anchors.json` was modified (not in Target files
list). The change adjusts line-offset values for all sections that shifted when two
lines were inserted into SKILL.md. This is a necessary auxiliary update; omitting
it would leave the anchors file stale. No recommendation to rework; no retroactive
task-spec update required.

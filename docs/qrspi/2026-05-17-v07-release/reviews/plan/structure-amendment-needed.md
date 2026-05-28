# Structure.md amendment needed — surfaced by Plan round-1 review

## Context
Plan round-1 review finding `quality-claude.R1-F03` (medium, correctness) identified that `scripts/g4-section-anchor-manifest.json` — a load-bearing runtime artifact T34 creates and T35 reads — is missing from `structure.md`'s Slice 7 Mechanism B file map.

This is a structure.md defect, not a plan.md defect. structure.md is already approved; amendments to approved artifacts require a separate flow.

## Plan-side mitigation (applied)
Plan.md T34 description has been amended to explicitly self-disclose that `scripts/g4-section-anchor-manifest.json` is one of the four target files this task creates, with a parenthetical note referring back to this amendment record. This keeps plan.md self-consistent for implementer dispatch.

## Structure-side amendment (deferred)
The next time structure.md is amended (or as a one-off fix), the Slice 7 Mechanism B table should gain a row:

| File | Action | Responsibility |
|------|--------|----------------|
| `scripts/g4-section-anchor-manifest.json` | Create | Single registry enumerating the indexed artifact pairs (source path + colocated `.anchors.json` path per entry); consumed by `scripts/g4-section-anchor-refresh.sh` to know which artifacts to regenerate. Future Mechanism B expansions extend this manifest rather than discovering indexes ad-hoc. |

## Source finding
`docs/qrspi/2026-05-17-v07-release/reviews/plan/round-01/quality-claude.finding-F03.md`

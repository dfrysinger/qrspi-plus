---
severity: medium
change_type: correctness
location: plan.md § Overview sizing-notes paragraph (line 19) vs Task partition table rows for T03/T05/T11/T19/T31–T36 (lines 27, 30, 36, 45, 58–63) vs Task Specs bodies (lines 207, 261, 355, 494, 700, 721, 734, 747, 760, 776)
---

# F03 — Inconsistent canonical spelling of `sizing_exception` values across overview, partition table, and task spec bodies

## What

The closed exception set is spelled three different ways inside the plan, and no single declared form is used consistently end-to-end.

| Surface | Spelling used |
|---|---|
| Overview sizing-notes paragraph (line 19) | `schema migration, CI scaffolding, reusable primitives` (space-separated) |
| T05 / T11 / T19 partition-table cells (lines 30, 36, 45) | `schema-migration`, `ci-scaffolding` (hyphenated, lower-case) |
| T03 / T31 / T32 partition-table cells (lines 27, 58, 59) | `reusable primitives` (space-separated) |
| T33 / T34 / T35 / T36 partition-table cells (lines 60–63) | `reusable-primitives` (hyphenated) |
| T05 / T11 spec body (lines 261, 355) | `schema-migration` (hyphenated) |
| T03 spec body (line 207) | `reusable primitives` (space-separated) |
| T31 spec body (line 700) | `reusable-primitives` (hyphenated) — disagrees with T31's own table cell |
| T32 spec body (line 721) | `reusable-primitives` (hyphenated) — disagrees with T32's own table cell |
| T19 spec body (line 494) | `ci-scaffolding` (hyphenated) |
| T33–T36 spec bodies (lines 734, 747, 760, 776) | `reusable-primitives` (hyphenated) |

Two coupled problems:

1. **Cross-surface drift.** The overview prescribes the space-separated form; most task bodies use the hyphenated form. The Plan SKILL's Schema-Migration Task Shape rubric in turn requires the exact literal `schema-migration` (hyphenated) for the trio-gating, which the overview's `schema migration` (with space) does not satisfy. The overview is therefore wrong against the rubric, OR the rubric and the bodies are wrong against the overview — either way the document does not name a single source of truth.
2. **Within-task drift.** T31 and T32 disagree with themselves: the partition-table cell uses the space form (`reusable primitives`) and the spec body uses the hyphen form (`reusable-primitives`). A grep-based audit (or a structural lint) cannot match both spellings simultaneously without a disjunctive pattern, which is exactly the drift the closed exception set is meant to prevent.

## Why it matters

The `sizing_exception` value is consumed by:

- The Plan SKILL reviewer's schema-migration mandatory-trio gating (requires the exact literal `schema-migration`).
- Future structural lints over plan-spec frontmatter (any reviewer that needs to enumerate which exception each task carries).
- Human readers tracing which closed-set entry each oversized task is invoking.

When the plan itself spells the same exception three ways across overview / table / body, downstream consumers must either accept a permissive normalised match (defeating the closed-set discipline) or fail on benign drift inside the plan (defeating the plan-stability discipline). Neither outcome is what the Plan SKILL's closed exception set is for.

## Suggested change

Pick one canonical form (the hyphenated `schema-migration` / `ci-scaffolding` / `reusable-primitives` set, since that matches the Plan SKILL's existing rubric literal for `schema-migration`), then sweep the overview sizing-notes paragraph, every partition-table cell, and every spec-body declaration to that single form. The Apply-fix should also note in the overview which form is canonical so future plan rounds do not regress.

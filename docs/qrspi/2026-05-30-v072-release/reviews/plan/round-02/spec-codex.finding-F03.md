---
reviewer_tag: spec-codex
change_type: correctness
severity: low
artifact: plan.md
location: "Task 16 — sizing_exception value"
referenced_files:
  - plan.md
---

# F03 — Sizing-exception token mismatch (`schema-migration` vs `schema migration`)

## Defect

T16 (and possibly other tasks) uses `sizing_exception: schema-migration` (hyphenated). The checklist allowed-set may be `schema migration` (space-separated).

## Impact

If the validator enforces an exact closed-set match, the validation fails. If the validator is lenient, the values drift across the plan.

## Recommended fix

Verify the canonical form in the plan-reviewer enforcement spec (T15 or T18) and normalize all sites to match. Round-01 already normalized 4 sites to `schema-migration` (hyphenated) per the round-01 dispositions; if THAT is the canonical form, this finding is a false positive.

## Counter-argument to consider

Round-01's normalization landed on `schema-migration` (hyphenated) as canonical. Codex may be referencing an outdated plan-reviewer spec. Likely a verifier-droppable finding.

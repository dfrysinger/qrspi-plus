---
finding_id: R4-F02
severity: low
change_type: style
referenced_files: [tests/unit/test-verified-file-shape.bats, tests/acceptance/v07-phase1/test-phase1-acceptance.bats]
---

# AC3 unspecified-fallback assertion verbatim across unit and acceptance

`tests/unit/test-verified-file-shape.bats:182–185` and `tests/acceptance/v07-phase1/test-phase1-acceptance.bats:2002–2005` are functionally identical — same grep pattern against the same file, differing only in how the path is expressed. When the assertion needs updating (fallback spelling changes), both sites require identical edits and each is a silent landmine for divergence.

Overlap extends to AC1/AC2 equivalents; the acceptance AC2 uses an `awk` slice and is the more precise duplicate. Convergent with cs-claude.finding-F01 (same AC1–AC3 layering critique).

**Recommended remediation (backlog):** remove the lower-signal unit-suite duplicate, or promote the awk-scoped form to the unit suite and remove the unscoped acceptance version — make the layering intentional and distinct.

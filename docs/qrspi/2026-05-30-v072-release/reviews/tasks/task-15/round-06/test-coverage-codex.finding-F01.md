---
id: F01
reviewer: test-coverage-codex
round: 6
file: tests/integration/test-reference-gate-pause.bats
line: 493
severity: low
change_type: clarity
status: dismissed
---
Worked-example-A test does not assert exactly/at least THREE consumer path entries (only >=2 co-edit + >=1 no-change + rename framing).
ADJUDICATION: DISMISSED — reaffirms R5 decline. An exact-three-count assertion requires fragile whole-section parsing
(the co_edit_count grep already spans the whole section incl. inline disposition-vocab prose; an exact count worsens that fragility).
Framing + disposition pins give strong coverage without the brittleness.

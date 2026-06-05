---
reviewer_tag: goal-traceability-claude
round: 8
finding_id: R8-F01
severity: low
change_type: scope
referenced_files: [tests/acceptance/v07-phase1/test-phase1-acceptance.bats, scripts/run-codex-review.sh]
---

# F01 — First-party manifest entry shape lacks strict key-count pin (AC9 parity gap)

## Finding (DUPLICATE of test-coverage-claude R8-F03)

Same gap as test-coverage-claude.finding-F03: AC9 pins third-party entry at exactly 8 top-level + 4 nested keys with explicit defense-in-depth rationale. AC2 and AC5 verify first-party fields are *present* but do not pin total key count.

Expected first-party shape: exactly 5 top-level keys + exactly 5 nested dispatch_spec keys.

## Severity

LOW: T11 spec language says "containing" (not strict-shape bounding) — thoroughness gap beyond literal spec, not spec-fidelity failure. Particularly relevant as T20 regression-prevention concern when `emit_first_party_manifest_entry` migrates to `dispatch-agent.sh`.

## Suggested fix

See test-coverage-claude.finding-F03 — same suggested jq assertions.

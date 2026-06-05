# spec-claude clean — Task 19 round 6

No findings. All three round-05 gaps were addressed exactly as requested:

- GAP A.1 (additive assertion): `grep -q 'vendor=nonexistent-vendor-xyz'` added to the single-run
  unknown-vendor test, which already asserts non-zero + line_count==1 + tag + host=. The joint
  contract is now fully covered in one execution (diff line +49).

- GAP A.2 (assertion strengthening): weak-OR `grep -qE 'nonexistent-vendor-xyz|vendor='` tightened
  to precise `grep -q 'vendor=nonexistent-vendor-xyz'` in the adjacent naming test (diff line -57/+58).

- GAP B (new test): "unknown host default path jointly asserts single-line host=unknown vendor=none"
  added (diff lines +11–39). Asserts non-zero exit, line_count==1, `^\[second-reviewer-unavailable\]`,
  `host=unknown`, and `vendor=none` in one execution. Correct against frozen production: unsetting
  COPILOT_CLI + CLAUDE_PROJECT_DIR + CODEX_CLI causes detect_host → "unknown", lookup_default →
  "none", guard fires, emits exactly one diagnostic line, exits 1.

No production script changes. No structural refactors. All four reachable unavailable cases
(unknown host default, unknown vendor, explicit none, missing default is dead code in frozen
production) now have joint single-run assertions. TERMINAL pass: no material gaps remain.

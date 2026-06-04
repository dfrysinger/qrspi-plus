# Code Quality Review — Task 40, Round 1 (claude)

**Verdict:** Clean. No findings.

## Summary

The T40 implementation is well-structured and matches the spec's lint shape.

**Strengths observed:**

- **Single responsibility / decomposition**: Each of the two lint `@test` blocks
  owns exactly one rule (G21 body-guard, G26/BW02 minimum-version). Awk programs
  are small, single-pass, line-order-correct, with clear state-machine variables
  (`in_block`, `has_guard`, `flagged`).
- **Comments**: Header explains G21 / G26 design-lock rationale and cites
  `design.md` sections — orientation + WHY, not restatement. Per-test comments
  describe the parse strategy and diagnostic shape. Awk inline comments map
  patterns to spec language.
- **Structure compliance**: Files land at the spec'd paths
  (`tests/lint/test-bats-body-assertion-guard.bats`,
  `tests/unit/test-ci-workflow-shape.bats` additions,
  `tests/unit/test-using-qrspi-vocab.bats` retrofits). Self-exclusion via
  `! -name "test-bats-body-assertion-guard.bats"` matches the DoD.
- **Block parsing**: Opener `^@test ` and column-0 closer `^\}` match spec.
  `FNR == 1` correctly resets per-file state under multi-file awk invocation.
- **Diagnostics**: G21 emits `file:line: unguarded $body assertion: <line>`;
  BW02 emits `file:line: BW02: feature "run --separate-stderr" used without
  bats_require_minimum_version` — both satisfy "file:line + triggering feature"
  per spec.
- **YAGNI / scope discipline**: Workflow-shape pin reuses T39's existing
  `bats -r tests` invocation (anchored via grep) rather than adding new CI
  steps — correctly honoring the spec's "only if current CI/test entrypoints
  do not already execute" condition. No shellcheck rule, no pre-commit hook.
- **Self-consistent application**: `test-dispatch-sites.bats` receives a
  `bats_require_minimum_version 1.5.0` declaration, consistent with the BW02
  rule being introduced. The author applied the new rule to themselves.
- **Retrofit guards**: All four unguarded `[[ "$body" ... ]]` assertions in
  `test-using-qrspi-vocab.bats` (lines 126, 139, 154, 168) receive
  `[ -n "$body" ]` guards earlier in the same `@test` block with consistent
  `# G21 body-guard:` orientation comments.

**Items considered and judged non-blocking:**

- *Corpus-build duplication* (~6 lines repeated across the two `@test`s).
  Extracting would couple two independent rule walks that may diverge in
  exclusion sets; the current split keeps each rule self-contained and
  readable in isolation.
- *G21 lint is stricter than spec letter* (flags positive `==` `[[ "$body"`
  assertions too, where the spec narrows to negation). Over-guarding is safe —
  positive `==` assertions already fail loudly on empty `$body` — and the
  retrofit itself guards positives anyway. Internally consistent.
- *Pre-commit hook test only checks `.git/hooks/pre-commit`* despite mentioning
  `scripts/pre-commit*` in the comment. The mentioned alternative is
  speculative; `.git/hooks/` is the canonical surface. Adding the second check
  would be YAGNI.
- *QRSPI-internal IDs in `@test` names and comments* (`[T40/G21]`,
  `[G26/BW02]`). This is established project-wide convention in the BATS
  corpus (e.g., `[T19-shape]`, `Task 19 — G17` in the same file). Flagging
  here would create inconsistency without addressing the broader pattern;
  out of scope for T40.

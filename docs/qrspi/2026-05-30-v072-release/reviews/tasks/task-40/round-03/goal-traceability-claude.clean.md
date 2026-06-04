# Goal Traceability Review — Task 40, Round 3 — CLEAN

Round-3 diff: single-line regex extension in `tests/unit/test-ci-workflow-shape.bats:393`
adding `\.pre-commit-config|\.pre-commit-hooks` arms to the C1-enforcement path filter
(closes R2/F01 from test-coverage).

Trace verified end-to-end:

- goals.md ### G21 — CI-only enforcement, no pre-commit hook.
- tasks/task-40.md Scope/Out (line 33), DoD (line 43), Test expectations (line 53) —
  "no shellcheck rule and no pre-commit hook are added" / "confirm no pre-commit hook
  or shellcheck rule is introduced".
- Test: `tests/unit/test-ci-workflow-shape.bats` `[T40/G21] no tracked hook script
  wires body-guard or bats-body-assertion (C1 enforcement)` (lines 380–395).
- Implementation behavior (new regex arms): each arm — `.pre-commit-config*`,
  `.pre-commit-hooks*` — backward-traces to the same DoD bullet that the pre-existing
  arms (`scripts`, `.husky`, `.githooks`, `lefthook`) trace to. The pre-commit
  framework's canonical config filenames (`.pre-commit-config.yaml` consumer,
  `.pre-commit-hooks.yaml` provider) are exactly the surface the prior pattern
  missed; the extension closes the gap without expanding scope.

Forward trace, backward trace, gap analysis, and spec-to-test fidelity all intact.
No YAGNI signals. No findings.

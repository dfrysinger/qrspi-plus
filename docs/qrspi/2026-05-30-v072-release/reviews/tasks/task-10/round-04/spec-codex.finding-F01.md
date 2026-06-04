---
finding_id: R4-F01
reviewer_tag: spec-codex
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/tasks/task-10.md:51
  - tests/unit/test-verified-file-shape.bats:152
  - tests/unit/test-verified-file-shape.bats:168
  - tests/unit/test-verified-file-shape.bats:187
---

# spec-codex R4 F01: Fixture-backed defect_class unit coverage missing

## Spec hook

Task-10 L51: "Fixture-backed unit coverage in `tests/unit/test-verified-file-shape.bats` asserts verifier sidecars carry a non-empty `defect_class:` token matching lowercase kebab-case letters, digits, and hyphens, and accepts `unspecified` as the absence-of-signal value."

## Observation

The 8 new defect_class tests added to `test-verified-file-shape.bats` (lines 146-294) are all grep/doc-shape checks against the verifier-agent prose (`agents/qrspi-finding-verifier.md`) and against the success/failure sidecar TEMPLATES embedded in agent prose. They do not validate an emitted sidecar instance/token value as fixture data.

The existing fixture sidecars in `tests/fixtures/issue-109/round-*/round-NN/*.score.yml` carry pre-T10 frontmatter (`score:` + `reason:` only) and were not updated to include the new `defect_class:` field.

## Effect

No test creates a fixture sidecar with a real `defect_class:` value (e.g., `defect_class: real-defect`) and asserts the regex `^[a-z0-9][a-z0-9-]*$` accepts it, nor a fixture with `defect_class: unspecified` and asserts the fallback is accepted. The spec L51 explicit "fixture-backed" requirement is unfulfilled.

## Runtime risk

Bounded. The verifier-agent prose IS pinned by the existing grep tests, and the verifier emits sidecars by following that prose. Runtime divergence would require the verifier to emit a sidecar that doesn't match its own documented shape, which would be caught at fan-in time (verifier-fan-in.sh parse path) rather than silently propagating.

## Disposition

**ACCEPT-WITH-ISSUES, defer to backlog as PI-V072-T10-007.**

Rationale:
1. This is R4 verification pass after fix-cycle 3 (last fix budget per skill cap rule).
2. Skill explicitly mandates escalate-do-not-dispatch-cycle-4 when R4 has findings.
3. The fix is genuinely small (~15-20 LOC: 2 fixture sidecars + 2 fixture-backed bats tests) but exceeds the cap.
4. Runtime risk is bounded (agent prose pinned, fan-in parse catches divergence).
5. T11+ waves do not depend on this test fixture; the gap can be closed in a v0.7.2.x patch or v0.7.3 follow-up.

Filed as backlog item: `PI-V072-T10-007`.

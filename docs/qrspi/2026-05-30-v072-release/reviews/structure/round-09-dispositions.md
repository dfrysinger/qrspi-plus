# Structure R9 — Dispositions

## KEEP — apply fix

### scope-claude.F01 + scope-codex.F01 (corroborated, scope drift)
**Fix:** Reword the test row at L129 to drop the literal anchor phrase. Keep placement description (which IS Structure-owned: location pinning is the test row's architectural role). Add explicit hand-off: anchor text sourced from design.md G31 Addition C verbatim block — Plan/Implement author the assertion string.

Original (R8):
> Guard shared include usage for prompt-prose and design-boundary snippets; additionally pin the standalone Addition C anchor phrase (`"Scope: only \`task_type: code\` tasks."`) at the TOP of `agents/qrspi-plan-test-coverage-reviewer.md` so silent drift or misplacement of the scope guard is caught.

Replacement (R10):
> Guard shared include usage for prompt-prose and design-boundary snippets; additionally pin the standalone Addition C placement (TOP of `agents/qrspi-plan-test-coverage-reviewer.md` review-procedure section) so silent drift or misplacement of the scope guard is caught. Anchor text is sourced from design.md (G31 Addition C verbatim block) — Plan/Implement author the assertion string.

### stitching-audit.F01 (mermaid inconsistency, 80)
**Fix:** Update Mermaid S12 subgraph DM node at L517 from `scripts/dispatch-agent.sh` to `scripts/run-codex-review.sh` to match the file-map row at L37.

## DROP (below floor or altitude overstep)

### stitching-audit.F02 (28)
Coverage symmetry argument ignores existing indirect pinning for A, B, D. Plus widening would amplify the scope drift scope-reviewers flagged.

### stitching-audit.F03 (38)
Asymmetry exists but suggested remediation pulls design rationale into structure intro → altitude overstep; the table row already signals exclusion.

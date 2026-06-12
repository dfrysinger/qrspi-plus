---
verifier_status: passed
score: 75
actual_model: unknown
defect_class: spec-inconsistency
---

Verified against design.md G6:

- Step 2 capture procedure (L396): "resolves each task name to its current branch tip via `git rev-parse refs/heads/<task-NN>` and writes the resolved SHA set to a runtime sidecar". Only task tips are captured.
- Edge case (L405): "actual parents = {integration-base, task-tip}; expected = {task-tip} ... Choose the latter for symmetry — the validation always compares full parent set vs. full expected set." The chosen resolution requires the integration base to be in the expected set.

These two statements are internally inconsistent. An implementer following the capture procedure literally would produce expected = {task tips} while actual parents always include parent[0] = integration base from `--no-ff`. The comparison rule defined in step 3 ("equality" on the full parent set) would then halt every legitimate wave merge with `stage-commit-parent-mismatch`.

This is a real correctness issue introduced by R09's capture-procedure addition; the edge case was written assuming the chosen resolution would be reflected in the capture step. The proposed fixes (capture `git rev-parse HEAD` pre-merge, or compare `actual[1:]`) are both viable. Worth fixing before Plan consumes the spec since the inconsistency would either propagate into the implementation or force Plan to silently choose one interpretation.

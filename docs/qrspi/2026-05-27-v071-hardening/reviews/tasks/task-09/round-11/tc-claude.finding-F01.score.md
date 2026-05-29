# Verifier sidecar: tc-claude.finding-F01 (T9 round 11)

**Score: 35**
**Action: DROP**

## Reasoning

- Finding: test 9 comment claims to catch mutation `[|>]→[|]`. Reviewer correctly observes `in_scalar` is dead code, so the mutation is genuinely unobservable.
- Severity: low (reviewer self-labels "low-priority documentation fix" / "no blocking action required").
- Change type: clarity (test-comment accuracy).
- Hotfix B clarity threshold: 80. Score 35 < 80 → DROP.
- Test 9 still provides real behavioral coverage of the `>` code path end-to-end. Only the explanatory comment overstates the mechanism.
- Optional cleanup deferred to v0.7.2 polish backlog.

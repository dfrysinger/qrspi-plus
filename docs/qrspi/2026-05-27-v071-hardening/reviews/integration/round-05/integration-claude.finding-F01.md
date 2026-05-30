---
finding_id: R5-F01
severity: medium
change_type: security
referenced_files:
  - skills/using-qrspi/SKILL.md
  - tests/unit/test-using-qrspi-vocab.bats
artifact: integration
round: 5
reviewer: integration-claude
self_score: 70
materialized_by: orchestrator
materialization_reason: integration-claude reviewer agent ran under the system-prompt constraint "ONLY output channel is response text" — returned full finding body inline; orchestrator persists to disk per the inline-handling pattern.
---

## `validators:` trusted-model re-run path is the structural twin of the now-closed `trusted_path:` gap and remains uncovered

**Surface:**
- `skills/using-qrspi/SKILL.md:499` — `validators:` H4 body, `citation_density_floor` bullet describing the trusted-model re-run target.
- `skills/using-qrspi/SKILL.md:488` — the new fail-loud paragraph just added for `trusted_path:` (the contract pattern that should, by parity, also cover the validators: re-run).
- `tests/unit/test-using-qrspi-vocab.bats:136-159` — the two new pins are scoped to the `trusted_path:` H4 only; no parallel pin extracts the `validators:` H4 body.

### The cross-task interaction

`skills/using-qrspi/SKILL.md:499` (unchanged in fix-int-r4-01, predates round 05) reads:

> "When a dispatch's output falls below this floor, the validator triggers a trusted-model re-run: the same prompt is re-dispatched to the agent-bundled default model (bypassing `model_routing:`) and the re-run output replaces the original."

This describes a third dispatch path that resolves to **"agent-bundled default model (bypassing `model_routing:`)"** — structurally identical to the `trusted_path:` short-circuit that R4-F01 just identified and fix-int-r4-01 just closed. After T9 (which removed `model:` from all 41 agents), the "agent-bundled default model" is empty for every agent. The validator-triggered re-run therefore hits the same empty-step-4 condition that R4-F01 named for `trusted_path:`.

The three behaviorally distinct implementations enumerated in R4-F01 reproduce here:

| Implementation choice for validators: re-run target | G7b/#204 status |
|---|---|
| (a) Halt loudly, report empty agent-bundled default | Closed |
| (b) Silently fall back to `model_routing:` (despite the prose explicitly saying "bypassing `model_routing:`") | **Reopened** — silent fallback to model_routing |
| (c) Silently fall through to host CLI's default model | **Reopened** — the exact silent host-CLI re-routing G7b/#204 forbids |

The new L488 paragraph pins (a) for `trusted_path:`. The `validators:` H4 has no parallel sentence. A dispatcher implementer reading L488 + L499 together sees an asymmetric contract: trusted_path: must halt-and-report on empty step 4; validators: trusted-model re-run is unspecified.

The explicit "(bypassing `model_routing:`)" parenthetical at L499 makes (b) doubly wrong — it's both silent AND violates the documented bypass intent — but the prose neither forbids (b) nor specifies (a). Behaviors (b) and (c) reopen the G7b/#204 silent-fallback class through the validators: re-run path, one layer deeper than `model_routing:` and parallel to (not via) the `trusted_path:` path that R4-F01 just closed.

### Why this is not "introduced by the fix"

The `validators:` H4 wording predates fix-int-r4-01 and was present across rounds 01–04 in the merged T8+T9+T10 surface. The R4 security/integration reviewers (including security-claude, who filed R4-F01) had visibility into this H4 and did not flag it. fix-int-r4-01 correctly executes the scope set by its spec (trusted_path: only, no broadening — see the spec's explicit "Out of scope: Do NOT broaden R2's fail-loud paragraph in-place"). The fix author had no mandate to extend coverage to validators:.

This finding is therefore not a defect *introduced* by round 05; it is a **pre-existing R4 review-scope gap** made structurally visible by the closing fix's establishment of the halt-and-report pattern for the empty-step-4 condition. Closing one branch of an unstated invariant ("dispatch paths routing to agent-bundled default must halt loudly when step 4 is empty post-T9") while leaving its structural twin open is a load-bearing integration observation.

### Why severity is medium (not low)

Mirrors R4-F01's own calibration, which scored 70 (KEEP). The G7b/#204 silent-fallback class is the load-bearing class this hardening release exists to close (goals.md G7b). Reopening it through a structurally parallel path defeats the release's stated security goal in exactly the same way trusted_path: would have. The validators: re-run path is contingent on `citation_density_floor` triggering (rarer than every dispatch), which marginally caps exploitability versus the trusted_path: path (which fires on every match) — but the re-run, when it fires, has the same undefined-behavior surface as the trusted_path: branch did pre-fix.

### Why the new vocab pins do not catch this

The two new pins added in this round extract `_extract_h4 "$USING" '\`trusted_path:\` block'`. The `validators:` H4 has no parallel extractor call. A future edit that adds the literal anti-pattern wording inside the `validators:` H4 body would not RED-fail any pin.

### Suggested fix (mirrors fix-int-r4-01 structure, one H4 deeper)

Single-paragraph SKILL.md edit + one pin pair, identical pattern to fix-int-r4-01:

1. **At `skills/using-qrspi/SKILL.md:499`** (end of the `citation_density_floor` bullet, or as a new sub-bullet): append a sentence mirroring the L488 paragraph's contract:

   > "When the validator triggers the trusted-model re-run and the matched agent's frontmatter declares no `model:` field (the state established for all agents after the T9 sweep), the re-run has no concrete target. The dispatcher halts and reports the validator trigger plus the empty agent-bundled default. The dispatcher never falls back silently to `model_routing:` (which the re-run explicitly bypasses) and never passes the re-run through to the host CLI's silent re-routing — both fallbacks would reproduce the G7b/#204 silent-fallback class this hardening release exists to close, one layer deeper than the `model_routing:` and `trusted_path:` paths."

2. **In `tests/unit/test-using-qrspi-vocab.bats`** (append after L159): add two `@test` blocks mirroring the trusted_path: pair, but extracting `_extract_h4 "$USING" '\`validators:\` block'`. Same substring assertions.

The `_extract_h4` helper already accepts arbitrary H4 labels; no helper change needed.

### Verification trace

- **L488 (new):** halt-and-report contract for `trusted_path:` short-circuit when step 4 is empty post-T9. ✓ Closes R4-F01.
- **L499 (unchanged):** "re-dispatched to the agent-bundled default model (bypassing `model_routing:`)" — same target ("agent-bundled default", bypass intent identical to `trusted_path:`), no halt-and-report contract. ✗ Uncovered.
- **L510 (unchanged):** precedence chain prose, "routes directly to the agent-bundled default (step 4)" — does not contradict L488; not relevant to validators: gap.
- **vocab pins (new):** extract trusted_path: H4 only; no validators: H4 extractor. ✗ Future regression in validators: prose is undetectable by current pin set.

### Self-score (per Hotfix B threshold gate)

- **Dimension:** security (G7b/#204 silent-fallback class)
- **Calibration anchor:** R4-F01 verifier 70 (KEEP), same class, same structural pattern, one H4 over
- **Exploitability discount:** validators: re-run is contingent on citation_density_floor triggering; trusted_path: was unconditional on every match
- **Severity floor preservation:** fail-loud contract gap at a security boundary = medium minimum
- **Self-score: 70** (KEEP at the security threshold; expect independent verifier within ±5)

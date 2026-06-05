# Round-05 spec-codex findings — orchestrator adjudication (both DECLINED)

spec-claude: CLEAN. spec-codex raised F01 (HIGH) + F02 (MED). Both DECLINED with rationale.
This is an autopilot scope decision (user away); flagged for user attention on return.

## F01 (HIGH, shell-verdict) — DECLINED (defer to v0.7.3)
- Observation is factually correct: no runtime branch emits DETECTION_TYPE=shell-verdict.
- BUT the binding task acceptance contract is fully satisfied: all 11 Definition-of-Done bullets
  and all 9 Test-Expectation bullets in task-24.md are met; NONE require a shell-verdict runtime branch.
- design.md ### CD-4 → I.7 explicitly states shell-verdict is "example only; not currently set by any
  known host as of 2026-05-30" and the only acceptance fixture is a "synthetic future host (FOO_AUTO=1)".
  design I.7 Iron Law defers new host branches: "When a new host is added (Codex CLI in v0.7.3+...): add
  a new script branch following the same shape."
- The protocol IS implemented at the contract level: shell-verdict is in the stdout-contract header
  (script lines 7,9), in the DETECTION_TYPE enum, accepted by the output-shape tests (bats 293,497,506),
  and the orchestrator-side handling is documented in design I.7. Only the host-keyed runtime branch is
  (correctly) absent because no current host warrants it — adding a synthetic FOO_AUTO=1 branch now would
  be speculative/YAGNI production code for a non-existent host.
- Prior spec reviews — including spec-codex at round-04 — passed CLEAN on this identical code. Late-
  appearing reviewer stochasticity, not a regression.
- Decision: do NOT add a shell-verdict branch (production change, past fix-cap, against the user's
  "no substantive refactors" steer). Spec gate treated as satisfied for this task. SURFACE TO USER.

## F02 (MED, skills/ regression) — DECLINED (design-sanctioned precedent)
- A naive `grep -rl '## Auto Mode Active' skills/` would exit 0 (matches) and FAIL: the literal legitimately
  appears in skills/goals/SKILL.md:12 and skills/design/SKILL.md:12, which design I.7 explicitly cites as
  "documented precedent ... other plugin skills that already condition on the same signal."
- The encapsulation rule targets NEW consumer prose; the agents/ regression (round-05 finding A, implemented)
  covers the actionable surface. A whitelisted skills/ check is possible but low-value and brittle; declined.

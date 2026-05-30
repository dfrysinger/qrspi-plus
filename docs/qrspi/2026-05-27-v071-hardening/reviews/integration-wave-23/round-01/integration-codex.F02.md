---
finding_id: integration-codex.F02
severity: medium
change_type: correctness
referenced_files:
  - skills/using-qrspi/SKILL.md
  - scripts/run-codex-review.sh
  - tests/unit/test-host-detection.bats
artifact: integration-wave-23
round: 1
reviewer: integration-codex
---

# SKILL prose vs runtime divergence: COPILOT_CLI=1 → task-tool routing oversimplified

## Claim

T7's host-routing prose at `skills/using-qrspi/SKILL.md` (around L411-416 in the T7-modified block) simplifies the Copilot CLI host-detection rule to "`COPILOT_CLI=1` ⇒ task-tool dispatch." Actual runtime detection in `scripts/run-codex-review.sh` `detect_host` (lines 100-138) requires BOTH:

1. `COPILOT_CLI=1` in the environment, AND
2. `gh` resolves via `command -v` to a path under a trusted prefix (`/usr/*`, `/opt/*`, or `/Applications/*`).

Otherwise `detect_host` falls back to the `claude-code` branch (shell-pipeline). The trusted-gh-binary gate exists as a hardening against `gh` path forgery — `tests/unit/test-host-detection.bats:535-546` pins this behavior.

## Impact

In an environment where `COPILOT_CLI=1` is set but `gh` is on PATH from an untrusted location (e.g., user-local Homebrew under `/Users/<u>/...`, a CI runner with a custom install path, or a deliberately-shadowed `gh` higher on PATH), the SKILL prose tells the operator/reviewer to expect task-tool dispatch but `run-codex-review.sh` will execute shell-pipeline. This produces operator confusion at minimum and routing-mismatch surprise at worst — the symptom is "I'm on Copilot CLI, why did the shell-pipeline run?"

Severity is medium not high because the failure mode is degraded-clarity / mis-set-expectation, not security-relevant or correctness-of-output. The reviewer's verdict still lands because both routes ultimately dispatch the same reviewer agent prompt — but the operator's mental model of "which transport am I on" diverges from what `run-codex-review.sh` will choose.

## Suggested fix

Update `skills/using-qrspi/SKILL.md` host-routing prose to acknowledge the trusted-gh-binary gate. Two acceptable shapes:

**(a) Inline:** Change "`COPILOT_CLI=1`" to "`COPILOT_CLI=1` and `gh` resolves to a trusted system path (`/usr/*`, `/opt/*`, `/Applications/*`)".

**(b) Pointer:** Keep the simplified prose but add a one-line pointer: "(See `detect_host` in `scripts/run-codex-review.sh` for the full condition — `COPILOT_CLI=1` plus a trusted-gh-binary check.)"

(b) keeps the SKILL prose readable while preserving the audit trail; (a) is more self-contained at the cost of one extra clause.

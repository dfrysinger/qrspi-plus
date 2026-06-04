---
finding_id: R1-F02
reviewer_tag: security-codex
round: 1
task: 6
severity: medium
change_type: correctness
referenced_files:
  - agents/qrspi-finding-verifier.md
  - scripts/verifier-fan-in.sh
---

# F02 — `VERIFY_FAILED` sidecar value creates fan-in halt DoS path

## Location

- `agents/qrspi-finding-verifier.md:58–63` — allows writing `score: VERIFY_FAILED` in sidecar frontmatter as a failure-state encoding
- `scripts/verifier-fan-in.sh:258–260` — treats non-numeric `score:` as `score_unparseable`
- `scripts/verifier-fan-in.sh:302–310` — halts run with exit 1 on any `score_unparseable` sidecar

## Attack scenario

An attacker crafts a malicious finding or prompt-injection input that coerces the verifier into emitting `score: VERIFY_FAILED` for a single finding (e.g., via prompt injection in `referenced_files` content or finding body text). A single malformed sidecar then halts the entire round, blocking processing of all other findings — a one-finding kill switch.

## Threat model

The verifier is dispatched once per finding. Each verifier dispatch independently decides whether to emit a numeric score or a failure marker. The fan-in script treats any `score_unparseable` as a fatal global condition. This means one prompt-injection-induced verifier failure breaks the whole round.

## Scope note

T06's scope is to lock the sidecar extension and require `score:` integer 0–100. The `VERIFY_FAILED` carve-out predates T06; the fan-in halt behavior is in `scripts/verifier-fan-in.sh` which T06 does NOT own (T02 owned the fan-in script earlier). The fix surface spans the verifier-agent contract AND the fan-in script — a v0.7.3 candidate task.

## Suggested remediation

Two complementary fixes (either alone is insufficient):

1. **Verifier agent contract:** Keep `score:` strictly numeric `0..100` always. Put failure state in a separate field, e.g. `verifier_status: failed` with a `failure_reason:` body. Reject `VERIFY_FAILED` as a `score:` value.
2. **Fan-in behavior:** Treat per-finding verifier failure as a per-finding condition (skip that finding, log it, continue) instead of a global halt. Only halt the run when ≥ N findings fail (configurable threshold) or when the verifier process itself crashes.

## Severity rationale

Medium: requires prompt-injection capability to weaponize, but the impact is denial-of-service of the entire review round, which can stall a release at the worst moment. Same trust-boundary class as F01.

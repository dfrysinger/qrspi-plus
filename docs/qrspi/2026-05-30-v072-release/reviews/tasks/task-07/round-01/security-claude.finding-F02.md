---
reviewer_tag: security-claude
round: 1
finding_id: F02
severity: medium
change_type: correctness
referenced_files:
  - agents/qrspi-finding-verifier.md:L9-L36
  - skills/reviewer-protocol/SKILL.md:L145-L155
---

The verifier sidecar carries no Informational flag — the "no pause, no auto-apply" downstream behavioral contract has no enforcement mechanism in the output channel between the verifier and downstream routing components.

The verifier detects `Informational:` and changes scoring (finding-verifier.md:L9-L36), but the sidecar contains only `verifier_status: passed` and `score: <int>` (finding-verifier.md:L67-L84). There is no `is_informational: true` field. Any downstream component that needs to implement "do NOT auto-apply, do NOT pause" must independently re-detect `Informational:` from the original finding's `message` body — a second detection pass that is nowhere specified, contracted, or tested.

Concrete scenario: reviewer legitimately emits `change_type: intent` + `Informational:` prefix for real but non-blocking observation. Verifier scores 75. Fan-in keeps. Orchestrator has: kept finding, `change_type: intent`, score 75. If orchestrator routing reads frontmatter + score (≥50) without scanning message body for `Informational:`, it correctly routes as pause-gate intent finding. Loop pauses. User decides it's a real concern. Unintended mutation applied.

Reverse: malicious actor injects `Informational:` into message. Verifier scores on structural confidence. If orchestrator DOES scan, attacker succeeds. If orchestrator DOESN'T, "no pause" promise broken for legitimate uses. Either way, divergence between what verifier knows and what sidecar communicates creates inconsistency.

Root cause: sidecar extension lock contract pins sidecar schema to `verifier_status` + `score`. T07 correctly preserves that schema. But adding Informational carve-out without adding `is_informational:` field means detection is a verifier-internal detail that never propagates to downstream consumers.

Suggested mitigation: (a) add `is_informational: true` to success-path sidecar frontmatter when the prefix is detected and update sidecar contract + fan-in script, OR (b) document explicitly that downstream routing components MUST re-detect the `Informational:` prefix from the original finding file and add a bats test verifying the spec.

[Materialized from chat-only response by claude-sonnet-4.6. NOTE: Option (a) is OUT-OF-SCOPE per T07 spec "Out:" list (sidecar field changes are T06's). Option (b) is within scope.]

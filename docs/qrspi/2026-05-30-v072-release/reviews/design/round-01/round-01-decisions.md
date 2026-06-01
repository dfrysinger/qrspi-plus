# Round-01 fan-in decisions (post-verifier)

All 14 findings scored ≥60 (default keep threshold = 50). Disposition:

## Applied (commit 0f0eec0)

| Finding | Score | Disposition |
|---|---|---|
| quality-claude.F01 | 90 | APPLIED — CD-4 §I L636 change_type enum 'security' → 'scope, intent' |
| quality-codex.F02 | 88 | APPLIED — G27 D2 probe redefined as "second-reviewer-eligible vendor"; D4 halt diagnostic + L2128 acceptance updated |
| quality-claude.F02 | 78 | APPLIED — top-level Component Map (Mermaid) added before G1 |
| quality-codex.F04 | 75 | APPLIED — G20 deliverables renamed per CD-1/G6 inventory; G33 D2 inventory likewise updated |
| quality-claude.F03 | 75 | APPLIED — `## Test Strategy` H2 added (T1–T5 release taxonomy + cross-cutting invariants) |
| quality-codex.F01 | 75 | APPLIED (convergent with qc-F03) — Test Strategy section + G1 outcome paragraph split test-strategy (Design) from test-specification (Plan) |
| quality-codex.F03 | 72 | APPLIED — G27 D4 L2107/L2130 alias references removed to match D1 |

## Declined per user override (kept content; recorded for self-host signal)

| Finding | Score | User decision |
|---|---|---|
| scope-codex.F01 | 85 | KEEP — implementation-level surfaces at G1 L972-1006, G18 L1659-1693, G33 L2728-2760 retained; user wants design.md to carry the detail for self-host reasoning |
| scope-claude.F02 | 78 | KEEP — CD-4 §C 5-step verifier-fan-in algorithm retained |
| scope-claude.F01 | 78 | KEEP — G1 deliverables list retained (same area as scope-codex.F01) |
| scope-codex.F02 | 75 | KEEP — phasing/release assignments retained inline ("co-ships with X in v0.7.2", "v0.7.3+ follow-up") |
| scope-claude.F03 | 75 | KEEP — CD-4 §E JSON schema example retained |
| scope-codex.F03 | 60 | RESOLVED by Test Strategy addition (was convergent with qc-F03 / qcdx-F01) |
| quality-claude.F04 | 65 | KEEP — CD-4 §H rescue tier protocol retained; user explicitly requested rescue layer during dialogue (out-of-scope vs goals known and accepted) |

## Plugin-monitoring signal

Scope reviewers (claude + codex) fired correctly against the locked owns-defers
contract, but the user's self-host detail tolerance materially exceeded the
contract's altitude ceiling. Filed as PI-HKP-005 in session DB: candidate
hardening = either (a) tighten reviewer prompts to distinguish "implementation
detail Plan can author later" from "implementation detail the operator needs in
design.md for reasoning", or (b) add an `altitude_tolerance: <strict|relaxed>`
config field that loosens the scope-reviewer pass for self-host / experienced-
operator runs.

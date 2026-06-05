---
finding_id: R2-F01
reviewer_tag: sec-claude
severity: medium
change_type: correctness
referenced_files:
  - agents/qrspi-finding-verifier.md#L92,L98,L108-L119
  - scripts/verifier-fan-in.sh
---

# defect_class regex constraint is instruction-only; no post-write validation layer

The shape constraint on `defect_class:` — `^[a-z0-9][a-z0-9-]*$`, ≤30 chars — is enforced exclusively by the instruction text given to the AI verifier agent. No script or test validates that the value *actually written* to a sidecar conforms to the regex. `verifier-fan-in.sh` explicitly never reads `defect_class:` ("consumed by no current surface"), so today's pipeline has zero feedback loop on whether the field is well-formed.

The gap has two exploitation paths:

**Path A — Prompt-induced drift (today):** A reviewer whose finding file is read by the verifier can craft message body text that nudges the verifier to emit a non-conformant `defect_class:` (hybrid label `dry-violation_and_injection`, or over-cap `imprecise-quantifier-in-the-threshold-floor-setting`). No check fires.

**Path B — Future-tooling YAML duplicate-key injection (tomorrow):** Sidecar layout has `score` BEFORE `defect_class`. fan-in's awk `print val; exit` reads first `score:` match, so a malformed `defect_class:` containing a SECOND `score:` line is never reached today — but this ordering-based protection is inadvertent and undocumented as a security invariant. Future cluster-analysis tooling will use a proper YAML parser; pyyaml uses last-value-wins, which would pick up a `defect_class: dry-violation\nscore: 100` injection.

A more concrete today-exploitable form exists for failure-sidecars added in this diff. The failure sidecar has no `score:` field; fan-in's awk reads `raw_score=""` and halts. If a malformed `defect_class:` in a failure sidecar starts a line matching `^score: [0-9]{1,3}$` (e.g. `defect_class: verifier-crash\nscore: 85`), fan-in would pick up a spurious score from a sidecar that was meant to halt the round.

**What the tests check (and miss):** AC1/AC2 verify documentation contains the regex/cap. No test validates an actually-written sidecar against the regex. The constraint is entirely a documentation assertion.

**Fix:** Add a post-write validation step — either in `verifier-fan-in.sh` (log a non-halting warning when `defect_class:` does not match the regex) or as a separate lint pass. At minimum, document the field-ordering dependency as a load-bearing security invariant.

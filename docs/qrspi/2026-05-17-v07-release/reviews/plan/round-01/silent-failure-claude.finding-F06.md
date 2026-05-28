---
finding_id: R1-F06
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L354-L358]
artifact: plan
round: 1
reviewer: silent-failure-claude
---

T09's adapter contract document specifies that each adapter exits `0` on successful classification or exits `1` with a loud diagnostic on stderr "when the runner output is unrecognized." T10's test expectations include: "Unrecognized runner output causes each adapter to exit `1` with a diagnostic written to stderr (no silent default classification)."

However, neither T09 nor T10 specifies what happens at the RED-verification gate level in T11 when an adapter exits `1` for unrecognized runner output. The adapter contract says exit 1 with stderr diagnostic — but T11's description says "the orchestrator dispatches `qrspi-implementer` when the adapter returns `pass` or `assertion-failure` against the targeted change; it pauses with a load-bearing diagnostic on `infrastructure-failure` or on vacuous-RED." Adapter exit code `1` (unrecognized output) is not one of the three legal classification tokens (`pass`, `assertion-failure`, `infrastructure-failure`), and T11 does not specify how the orchestrator gate handles it.

The gap: if an adapter exits `1`, the orchestrator gate has received neither a valid classification token on stdout nor a valid exit code (the adapter contract says exit `0` on classification, exit `1` on unrecognized). T11's test expectations do not include a case for "what does the RED-verification gate do when the selected adapter exits non-zero (unrecognized runner output)?" The gate may silently interpret adapter exit `1` as an `infrastructure-failure` (reasonable but unspecified) or may proceed with implementer dispatch (silent failure to catch the unrecognized-output condition).

The fix is to add a test expectation in T11: "When the selected adapter exits `1` (unrecognized runner output), the RED-verification gate pauses with a load-bearing diagnostic distinguishing adapter-classification-failure from infrastructure-failure, and does not dispatch the implementer." This closes the gap between the adapter exit-code contract and the gate's consume-and-branch logic.

---
finding_id: R4-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-30-v072-release/goals.md:L76]
artifact: goals
round: 4
reviewer: scope-claude
---

**G29 "What we know so far" contains a Design-level advocacy passage that pre-disposes the trade-off decision before Design deliberation — boundary drift per Goals OWNS/DEFERS.**

The `owns-defers.md` rule is: *"Solution IDEAS may appear under 'What we know so far' framed as candidates Design should weigh — never as commitments."* The amended G29 violates this boundary in its "What we know so far" section, in the paragraph that precedes the candidate list:

> "The path-based variant is **strictly stronger** prompt-injection defense than the wrapped-body variant: artifact content materializes only inside the subagent's context via its Read tool, never touching the orchestrator's dispatch prompt or process memory. The `<<<UNTRUSTED-ARTIFACT-START>>>` framing is preserved by the reviewer's treatment of Read output as the wrapped body. The path-based form's protective semantics are at least equivalent to (and arguably stronger than) the wrapped-body form."

This paragraph does not describe the problem or provide neutral evidence. It performs a comparative security-properties analysis and concludes that the path-based form is categorically superior ("strictly stronger," "at least equivalent to (and arguably stronger than)"). That is Design-level trade-off resolution. It belongs in Design's trade-offs section — where the three candidates can be evaluated together with explicit rationale, risks, and a documented decision — not in Goals' problem context.

**Why this matters for downstream quality:** The "What we know so far" advocacy effectively pre-selects a direction before Design has deliberated. When Design receives G29, the path-based form already carries a "strictly stronger" label from Goals, creating institutional momentum against seriously evaluating the other two candidates (threshold rule, reviewer-side dual-parser). Design's trade-off section will be weakened if it must argue against a conclusion already embedded in the upstream artifact.

**Expected correction:** Truncate the "strictly stronger" advocacy paragraph or compress it to neutral evidence: e.g., "v0.7.2 self-host applied the path-based form for research R1+R2 (87 KB artifact) with no fidelity loss observed." The security-properties comparison ("materializes only inside the subagent's context," "never touching the orchestrator's dispatch prompt") is a Design-level claim and should move there. The three candidates that follow can then stand on equal footing for Design deliberation.

Note (not a separate finding): G29's title parenthetical "canonize `artifact_path`" names the preferred fix. This is consistent with `known-fix` type convention, but worth flagging as an observation: the title's directional label is mild pre-disposition reinforcing the advocacy paragraph. Resolving the advocacy paragraph (above) is the load-bearing fix; the title can stand if the paragraph is neutralized.

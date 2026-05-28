---
finding_id: R1-F04
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md, docs/qrspi/2026-05-17-v07-release/design.md]
artifact: plan
round: 1
reviewer: test-coverage-claude
---

T37's test expectations for the summary-shim detection BATS pin do not specify the detection pattern, making the expectations unfalsifiable.

The expectation states: "For each file the test asserts no dispatch-prompt construction substitutes a derived-summary artifact for the corresponding stable source artifact as the prompt's source-of-truth payload." And: "When a fixture introduces a summary-shim dispatch shape (e.g., a dispatch site that composes its prompt around an LLM-generated condensation of reviewer-protocol/SKILL.md...), the test fails with a diagnostic naming the offending file, the line range of the dispatch site, and the matched summary-shim shape."

However, the expectation does not specify WHAT PATTERN the test uses to identify a summary-shim dispatch shape. A test writer cannot write a deterministic regex scan without knowing what textual pattern in a skill/agent file constitutes a summary-shim dispatch site. The description gives an example (an LLM-generated condensation of reviewer-protocol/SKILL.md), but this is conceptual, not structural — what string, keyword, or pattern in the file indicates that a prompt is using a summary shim rather than a verbatim Read?

The test also must NOT flag verbatim Read sites or Mechanism B narrow Reads. But how does the test distinguish these at the text-search level? The expectation says "The test does NOT flag verbatim Read sites or Mechanism B index-driven narrow Reads against .anchors.json from T34" but doesn't specify the detection rule that separates "summary shim" from "verbatim Read."

Without a concrete detection pattern (e.g., a specific keyword, phrase structure, or variable name used in summary-shim dispatch constructions), this test expectation is vague and cannot produce a deterministic test. Add to T37's expectations: the specific regex or structural pattern the test uses to identify a summary-shim dispatch site, and the specific pattern(s) used to exclude verbatim Reads and Mechanism B reads from the scan.

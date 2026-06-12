---
finding_id: R1-F01
severity: medium
change_type: correctness
referenced_files:
  - /Users/dfrysinger/code/qrspi-plus-v0.7.2/docs/qrspi/2026-06-04-v073-release/design.md:L542-L556
  - /Users/dfrysinger/code/qrspi-plus-v0.7.2/docs/qrspi/2026-06-04-v073-release/design.md:L580-L583
artifact: design
round: 1
reviewer: quality-codex
---

The design asserts research-grounded rationale using shorthand references like “per Q1 research” and “Q4 established practice,” but does not cite concrete `research/q*.md` sources. That makes the research-traceability requirement non-auditable and weakens confidence that key architectural choices are grounded in verified findings rather than memory. Fix by adding explicit file-level citations (e.g., `research/q01-...md`) for each such claim, or by rewriting claims to clearly distinguish empirical self-host observations from research-backed conclusions.

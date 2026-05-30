---
id: quality-claude-001
artifact: questions
severity: HIGH
check: goal-leakage + objectivity
---

## Finding

**Q2** embeds the exact tool enumeration from G1's Candidate A/B/C list, leaking the design candidate set and pre-constraining the research.

### Offending text

> What POSIX-conformant shell methods **(using `tr`, `awk`, or `grep -E` with explicit hex escapes)** can detect the presence of control characters in a string…

### Goal-leakage dimension

G1 enumerates three candidates:
- Candidate A — `tr -d '[:cntrl:]'` followed by a length comparison
- Candidate B — `awk` with character-class matching
- Candidate C — `grep -E` with explicit hex escapes

The parenthetical in Q2 is a verbatim projection of those three choices. A researcher reading only Q2 can infer that the project is evaluating exactly those three tools and that some form of "pick one of these three" decision is in flight. The goal (fixing the `-P` PCRE dependency in `run-third-party-llm.sh`) becomes recoverable.

### Objectivity dimension

By naming `tr`, `awk`, and `grep -E` as the methods to research, the question forecloses discovery of other portable approaches (e.g., `od`-based pipelines, pure-bash `LC_ALL=C` parameter-expansion scanning, `sed` character classes). A web-research answer keyed to "which of these three" is narrower than a genuinely open-ended "what POSIX methods exist" inquiry, and may miss portability nuances relevant to deciding among the candidates.

### Suggested rewrite

> What POSIX-conformant shell methods exist for detecting the presence of control characters in a string, and what are their portability characteristics across macOS system tools (system `grep`, system `awk`, system `tr`) and their GNU/Alpine counterparts?

This framing is fully open, surfaces the same practical territory, and reveals nothing about the candidate set under evaluation.

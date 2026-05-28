---
finding_id: R3-F03
severity: high
change_type: clarity
referenced_files: [docs/qrspi/2026-05-17-v07-release/questions.md:L30]
artifact: questions
round: 3
reviewer: quality-claude
---

Q24's second clause is a hypothesis pre-assertion that telegraphs G18. The question asks "what dated or version-tagged file paths exist today that should be exempted from any prose-rot scan?" — the phrase "exempted from any prose-rot scan" presupposes that a prose-rot scan is the planned mechanism, which is precisely G18's lowest-cost candidate ("A BATS pin that scans `skills/**/SKILL.md` and `agents/qrspi-*.md` for release-version tokens"). The same clause also lifts G18's "release-version tokens or milestone references" wording in the first clause, compounding the leak. Rewrite to ask current-state without committing to a downstream mechanism — for example, "Which `skills/**/SKILL.md` and `agents/qrspi-*.md` files in the current `main` branch contain release-version strings or milestone references, and which dated or version-tagged file paths exist today that are intentionally release-bound?"

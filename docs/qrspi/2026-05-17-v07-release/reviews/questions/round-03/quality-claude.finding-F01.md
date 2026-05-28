---
finding_id: R3-F01
severity: high
change_type: clarity
referenced_files: [docs/qrspi/2026-05-17-v07-release/questions.md:L25]
artifact: questions
round: 3
reviewer: quality-claude
---

Q19 leaks G14 vocabulary verbatim. The question's second clause asks "what `REPO_ROOT`, empty-extract, and structural-anchor conventions do they share?" — that triplet (`REPO_ROOT` guards, empty-extract guards, structural exit anchors) is a direct lift from G14's "What we know so far" bullet describing the BATS pattern that was hand-rolled across T09/T14/T19 and that G14 wants to factor into a shared helper. A researcher reading Q19 in isolation can reconstruct the design intent: there is a known recurring BATS pattern with exactly these conventions and the work is to study it for consolidation. The first clause is acceptable current-state ("what awk/grep section-extraction patterns recur across …"), but the second clause should be neutralized — for example, "and what conventions, if any, do those tests share for path-rooting, empty-extract handling, and section-boundary handling?" — or dropped, with the recurring conventions left to be discovered by the research rather than enumerated by the question.

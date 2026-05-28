---
finding_id: R3-F06
severity: medium
change_type: clarity
referenced_files: [docs/qrspi/2026-05-17-v07-release/questions.md:L14]
artifact: questions
round: 3
reviewer: quality-claude
---

Q8 reuses G4's exact framing of the problem. The question asks "Which dispatch sites across `skills/` and `agents/` repeatedly include the same long stable files in prompt composition…" — "repeatedly include the same long stable files" mirrors G4's "repeatedly read the same long, stable artifacts" almost word-for-word. A researcher reading Q8 alone can infer that repeated reads of stable artifacts are a known cost amplifier and that the work targets reducing them. Reframe as a neutral inventory question — for example, "How is prompt composition currently assembled at dispatch sites across `skills/` and `agents/`, and what inputs are typically composed at each site?" — so the research surfaces the repeated-read pattern as a finding rather than restating it as the question's premise.

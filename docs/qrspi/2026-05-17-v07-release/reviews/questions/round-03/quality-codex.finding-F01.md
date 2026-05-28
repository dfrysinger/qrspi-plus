---
finding_id: R3-F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/questions.md:L7-L36]
artifact: questions
round: 3
reviewer: quality-codex
---

The question set fails the step's goal-leakage check: a researcher reading only these questions can infer the intended release work almost directly, because the list names the target surfaces and fixes rather than asking capability-level research questions. Examples include model-routing policy/schema work (`L7-L11`), the plan post-approval split (`L12-L13`), repeated long-file-read optimization (`L14-L15`), test-writer split investigation (`L16-L17`), fix-cycle ID hygiene (`L18,L35`), Parallelize reviewer false positives (`L19-L20,L27`), reference-gate / visual-fidelity work (`L21-L22,L36`), commit-message scratch staging (`L23`), the `u14-lint` false positive (`L24`), BATS helper extraction patterns (`L25`), Replan-vs-Goals boundary (`L26`), GitHub Actions CI (`L28`), and evergreen-prose rot detection (`L30-L31`). That is enough for the goal to be discernible from the question list alone, which undercuts blind research. Fix: rewrite the questions so they ask neutral investigations about current repo behavior, comparable framework patterns, and failure modes without naming the intended solution or issue target in the prompt itself.


---
finding_id: R7-F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-06-04-v073-release/design.md:L13-L21]
artifact: design
round: 7
reviewer: quality-codex
---

CD-1 is internally contradictory about `scripts/upstream-paths.sh` output format: it first specifies a "newline-separated absolute-path list," then later says the script "prints repo-relative paths … and step-relative artifact basenames." This ambiguity is load-bearing and can cause incompatible implementations. Resolve by choosing one output contract and using it consistently across Outcome/Solution/Edge-case text.


---
finding_id: R3-F04
severity: high
change_type: clarity
referenced_files: [docs/qrspi/2026-05-17-v07-release/questions.md:L31]
artifact: questions
round: 3
reviewer: quality-claude
---

Q25 lifts G18's signature phrase "release-version-token rot in evergreen contract files" almost verbatim. G18 frames the problem as "release-version tokens and milestone references can rot" in evergreen contract surfaces (`SKILL.md` files and QRSPI agent files). A researcher reading Q25 alone learns both the defect class to target and the noun phrase the goals already use to name it, which makes the goal directly recoverable from the question. Generalize the framing — for example, "What lint or CI patterns do other markdown-driven prompt or skill libraries use to detect or prevent version strings, milestone references, or other dated language from accumulating in files intended to be stable across releases?" — so the question describes the failure category in neutral terms rather than echoing G18's chosen label.

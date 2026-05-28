---
finding_id: R1-F03
severity: low
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/goals.md:L240]
artifact: goals
round: 1
reviewer: scope-claude
---

G13's "What we know so far" bullets enumerate specific function names that belong to Structure/Plan rather than Goals.

Per `skills/goals/owns-defers.md` DEFERS line 22: "Implementation logic, function signatures, assertion text → Structure / Plan / Implement." Per DEFERS line 19: "File / component / interface mapping → Structure."

Two bullets at L239–L240:
- "The source issue proposes `tests/unit/helpers/skill-markdown.bash`; Design should weigh exact helper boundaries and naming."
- "Candidate helpers include `extract_section_between`, `assert_grep_in_section`, and `repo_root_resolve`."

Naming a specific helper file (`tests/unit/helpers/skill-markdown.bash`) is file/component mapping; naming three specific function identifiers (`extract_section_between`, `assert_grep_in_section`, `repo_root_resolve`) is function-signature territory. Both belong downstream of Goals.

The bullets are framed with "Design should weigh exact helper boundaries and naming" and "Candidate helpers include," which puts them inside the OWNS line-12 candidate carve-out ("Solution candidates as possibilities") — that is what saves this from being a hard DEFERS violation. But the granularity is unusually deep for Goals: most other goals in this artifact frame candidates at the shape level (e.g. G1 "per-subagent default with per-task override fields"), while G13 names specific files and function identifiers.

Resolution: rewrite the two bullets to frame the candidate at the shape level — e.g. "A shared BATS helper library for skill-markdown section extraction and grep is a candidate Design should weigh, including which helper boundaries to expose." Drop the specific file path and the three function names; let Structure/Plan choose them.

Severity is low because the candidate framing already partially covers it; raising it primarily improves consistency with the rest of the goals artifact.

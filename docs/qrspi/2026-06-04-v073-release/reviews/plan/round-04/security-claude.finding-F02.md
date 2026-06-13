---
finding_id: R04-F02
severity: low
change_type: scope
referenced_files: ["docs/qrspi/2026-06-04-v073-release/plan.md"]
artifact: plan
round: 4
reviewer: security-claude
---

Informational: T37 (`measure-active-footprint.sh`) resolves `!cat` references transitively from SKILL.md files without any stated requirement that target paths be restricted to within the repository or the `skills/_shared/` directory. The test expectations cover unresolvable references (`footprint-snippet-unresolvable:`) and circular references (`footprint-snippet-cycle:`), but a path-traversal target such as `!cat ../../secrets` or `!cat /etc/passwd` is neither unresolvable (the file exists) nor circular — it would be resolved silently, and its contents would appear verbatim in the emitted `g9-footprint-report.md`.

SKILL.md files are authored in a trusted pipeline context, making this a low-probability risk. However, the same script handles untrusted user-supplied content (skill trims, snippet bodies, future contributors' SKILL.md additions), and a path restriction test expectation would provide defense-in-depth. Suggested addition to T37 test expectations: "A `!cat` reference whose resolved path is outside the repository root (or outside `skills/`) surfaces the `footprint-snippet-unresolvable:` named diagnostic and exits non-zero — targets are not silently followed outside the skills tree."

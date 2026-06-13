---
finding_id: R05-F02
severity: low
change_type: scope
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md:L1316-L1325
artifact: plan
round: 5
reviewer: security-claude
---

Informational: T37 (`measure-active-footprint.sh`) specifies cycle detection and unresolvable-reference detection for `!cat` resolution, but adds no test expectation requiring that resolved paths stay within the repository root. A skill file containing `!cat /etc/passwd` or a traversal like `!cat ../../../../outside-repo` would be attempted by the script without error — the file would either be read silently (if it exists) or surface only the generic `footprint-snippet-unresolvable:` diagnostic (if it is unreadable), not a dedicated path-boundary diagnostic.

**Attack surface.** Skill files are contributor-authored content committed to the repo. Any contributor with write access could introduce a `!cat` reference pointing outside `skills/` or outside the repo root. The script would resolve it during footprint measurement and could silently ingest sensitive content into the token count (which is then written into `g9-footprint-report.md`). The data surface is not transmitted externally — it stays in a local file — but the script would read and tokenise content it was not intended to handle.

**Scope of the proposal.** Adding a test expectation of the form: "A skill body containing a `!cat` reference whose resolved path escapes the repository root (e.g., an absolute path or a `../` traversal escaping the repo) surfaces the `footprint-path-traversal:` named diagnostic and a non-zero exit, and the out-of-bounds path is not read." This is a new deliverable requirement (one new named diagnostic, one additional guard in the resolution loop, one new test case), hence `change_type: scope`.

**Confidence note.** The threat requires a contributor to write a malicious `!cat` reference into a skill file, which requires commit access and a PR review bypass. The script runs locally at measurement time, not in a CI execution context with secret access. This is rated low severity on that basis. If the footprint script is ever run in a CI environment with access to sensitive paths, the risk class would increase.

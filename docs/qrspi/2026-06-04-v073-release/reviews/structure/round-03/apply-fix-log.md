# Structure R03 — apply-fix log

2 findings, 1 substantive (both pointing at the same gap):

- **scope-codex F01 + quality-codex F01 (high/correctness)** — Structure under-committed on G5 per-phase phase-base anchor paths. Both Claude reviewers said clean but explicitly noted the same gap the Codex reviewers filed. Adjudicated in favor of concrete commitment.

Applied:
- Named concrete paths: `reviews/integration/phase-base.txt` and `reviews/test/phase-base.txt` (single-line `integration_base_sha=<SHA>`).
- File Map: G5 OBC row updated with per-phase path map; integrate/test SKILL rows extended with phase-start phase-base.txt write responsibility.
- Interfaces block: per-phase phase-base source enumerated explicitly with format spec.
- Architectural Diagram: added PB_INT and PB_TEST nodes, three distinct OBC→anchor edges (implement/integration/test), PHASES→PB_INT/PB_TEST write edges.

Defers kept narrow: WHEN/WHERE in the SKILL each phase writes phase-base.txt remains Plan's task-carving call.

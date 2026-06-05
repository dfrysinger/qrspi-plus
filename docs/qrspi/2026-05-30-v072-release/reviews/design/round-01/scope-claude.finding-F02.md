---
finding_id: R1-F02
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-30-v072-release/design.md:L414-L419]
artifact: design
round: 1
reviewer: scope-claude
---

The CD-4 section ("Verifier-Fan-In Pipeline"), component C at lines 414–419 describes `scripts/verifier-fan-in.sh` via a 5-step numbered algorithm that specifies the script's internal iteration structure and branching logic: glob findings, for-each finding → assert `change_type:` present → assert value in enum → glob paired sidecar → read `score:` → apply threshold, with halt branches at each assertion. This is procedural pseudocode with explicit control-flow detail ("for each finding: Reads frontmatter → asserts… (halt if missing) → asserts… (halt if out-of-enum) → globs… (halt if missing or wrong extension) → reads… (halt if unparseable)"), which the Design DEFERS rule assigns to Plan/Implement.

The Design-appropriate treatment is to name the script, its invocation signature, its inputs (finding files + score sidecars), its output (a `kept-findings.txt` file and an audit JSON), and its behavioral contract (filter by change_type threshold; exit non-zero with diagnostic on any structural defect). That contract is fully captured in the surrounding prose (components A, B, D, E, F) — the step-by-step walk through the script's internal loop is redundant with those components and crosses the design/plan boundary.

To resolve: collapse the five-step numbered list at lines 414–419 into 1–2 prose sentences summarising the script's single-invocation contract: what it reads, what it writes, and its two exit outcomes (all-clean vs. halt). Move the per-step enumeration of assertion conditions to the Plan task spec for the script.

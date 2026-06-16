This section is the **single source of truth** for goals.md scope boundaries. It is the locked rule set the scope-reviewer dispatch loads at review time (Read by the `qrspi-goals-scope-reviewer` agent at runtime per its rules-loading procedure). Findings cite this list directly.

### Goals OWNS

- **Project purpose.** One- or two-sentence framing of what is being built and the problem space.
- **Environmental constraints.** Tech stack, compatibility, performance budgets, deployment, timeline — the real-world conditions any solution must respect.
- **Per-goal entries.** Each goal carries:
  - a stable **goal ID** (e.g. `G1`, `G2`, …) that downstream artifacts (questions, research, design, structure, plan, roadmap, future-*) reference,
  - a **`type` field** with allowed values `known-fix | exploratory` (see "Goal Type Field" below),
  - exactly three subsections — **Problem**, **Why we care**, **What we know so far** — and no others.
- **Optional `Cross-Cutting Notes` section.** Top-level only when relationships between goals genuinely cross-cut. Omit when not needed.
- **Solution candidates as possibilities.** Solution IDEAS may appear under "What we know so far" framed as candidates Design should weigh — never as commitments.

### Goals DEFERS

- **Out-of-scope decisions** → eliminated. What isn't a goal isn't in scope. Project-level scope clarifications (if any) belong to Design's Approach where solution scope is decided.
- **Detailed solution definitions** → Design.
- **Acceptance criteria** → Design's per-goal `Acceptance` blocks + Plan's per-task expectations. Goals does NOT enumerate per-goal acceptance criteria.
- **File / component / interface mapping** → Structure.
- **Task specs, LOC estimates, dependencies** → Plan.
- **Phasing decisions, vertical slice authoring, roadmap** → Phasing.
- **Implementation logic, function signatures, assertion text** → Structure / Plan / Implement.

### Permitted Incidental References

The DEFERS list is about *ownership* of decisions, not *mention* of the deferred surface. The following incidental references are PERMITTED and MUST NOT be flagged as boundary violations by the scope-reviewer:

- **User-locked decisions made during Goals dialogue.** When the user explicitly locks a direction during the Goals interactive dialogue, the artifact MAY record that lock under "What we know so far" using a provenance marker such as `Decision locked during this Goals dialogue:` or `User-locked during Goals dialogue:`. Provenance trumps the candidate-framing rule — the user is the authority, and recording the lock truthfully is more important than re-framing it as a candidate. The lock applies only to the goal's framing, not to Design's downstream decisions about how to implement it.
- **Acceptance candidates framed as candidates.** Sentences that surface possible acceptance approaches using candidate verbs (`could include`, `Design should weigh`, `candidate acceptance approach:`) are PERMITTED. Sentences that bind acceptance with imperative verbs (`Acceptance must include`, `Acceptance must measure`) are NOT — those still violate the rule.
- **Cross-goal sequencing intent in Cross-Cutting Notes.** Goals OWNS goal relationships; ordering hints between goals (e.g. "G8 lands last because trimming files G1-G7 edit creates merge churn") are part of expressing those relationships and are PERMITTED in `## Cross-Cutting Notes`. The actual phase boundaries and roadmap are still Phasing's call — Goals records the *coupling rationale*, not the phase decision.
- **One-sentence mechanism sketches in candidate-fix bullets.** A single sentence describing a candidate fix's mechanism (e.g. "validate actual merge-parent SHAs against named task-tip SHA set; halt on mismatch") is PERMITTED. Multi-line shell pseudocode with specific variable names, command flags, or assertion text is NOT — that level of specificity belongs to Structure / Plan / Implement.

The scope-reviewer evaluates the deferred surface against these carve-outs FIRST before flagging a boundary finding. A scope finding is only valid when the artifact crosses the boundary in a way the carve-outs do not permit.

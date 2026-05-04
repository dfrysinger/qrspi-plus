This section is the **single source of truth** for the scope-reviewer dispatch (`{ARTIFACT_TYPE}=goals`). Findings cite this list directly.

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
- **Acceptance criteria** → Design's Test Strategy + Plan's per-task expectations. Goals does NOT enumerate per-goal acceptance criteria.
- **File / component / interface mapping** → Structure.
- **Task specs, LOC estimates, dependencies** → Plan.
- **Phasing decisions, vertical slice authoring, roadmap** → Phasing.
- **Implementation logic, function signatures, assertion text** → Structure / Plan / Implement.

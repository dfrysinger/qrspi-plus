# Design — `design.md` template (conformance contract)

The synthesis subagent produces `design.md` per the template below. **Per-section template guidance is embedded inline as HTML comments below.** Each section block carries a one-line guidance comment and a conformance reminder so future `design.md` content can be linted for boundary-drift signals (the scope-reviewer's boundary-drift sub-check looks for downstream-stage jargon — DDL keywords, full TypeScript signatures, literal `expect(...)` assertions, phase-split language — leaking into `design.md`; `design.md` owns approach/rationale/trade-offs and per-goal solution definitions, not Plan/Implement-layer surfaces or Phasing-layer slice authoring).

**Conformance applies to every section.** Claim-before-evidence (lead each subsection with its decision sentence; supporting detail follows). Paragraph density: ≤150 words / ≤8 lines per paragraph; if longer, split. Scannability: bullets in any section longer than ~12 lines. No-brevity prohibition: do NOT add "be concise", "brief summary", "≤ N lines" framing.

````markdown
---
status: draft
---

# Design: {Project/Feature Name}

<!-- Lead with one claim sentence describing the architecture's organizing axis (e.g., "Event-sourced write side, projection-based read side"); do NOT restate goals.md. -->

## Approach

<!-- Per-section guidance: one claim sentence first ("Chosen approach: {X}"), then 1–2 short paragraphs of rationale grounded in research findings. Claim-before-evidence; length-target ≤8 lines per paragraph. NO DDL, NO full function signatures, NO assertion text — those are DEFERS. -->

{Chosen approach and rationale}

## Key Decisions

<!-- Per-section guidance: bulleted list of major decisions, each with one-line decision + one-line reasoning. Decisions are at the architecture-boundary level (data-flow, transport, persistence model, security posture) — NOT line-by-line logic, NOT column-level DDL. Bullets for scannability; lead each bullet with the decision noun. -->

{Decisions made during discussion with reasoning}

## Trade-offs Considered

<!-- Per-section guidance: the 2–3 rejected alternatives, each with what it traded off and why it lost. Claim-before-evidence — lead each subsection with the alternative name; rationale follows. Keep at the approach level — do NOT enumerate per-column trade-offs (DEFERS). -->

{Alternatives that were rejected and why}

````

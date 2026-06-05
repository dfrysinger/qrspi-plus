---
status: draft
question_ids: [11]
research_type: codebase
---

# Q11: Design skill structure, reviewer checks, and artifact depth comparison

## Summary

**TL;DR:** `skills/design/SKILL.md` prescribes five required top-level sections (Approach, Key Decisions, Trade-offs Considered, Test Strategy, System Diagram) with specific per-section content rules. The two reviewer agents split responsibilities: `qrspi-design-reviewer` checks artifact quality (goal coverage, trade-off documentation, diagram presence, research-citation accuracy, YAGNI, test-strategy completeness), while `qrspi-design-scope-reviewer` checks boundary compliance against the Design OWNS / Design DEFERS rule set. The actual v0.7.1 design artifact at `docs/qrspi/2026-05-27-v071-hardening/design.md` closely matches the template structure (183 lines, all 5 canonical sections present) but required three review rounds to converge — with findings spanning mis-citations, missing trade-off entries, scope drift into per-line procedures and test-file layout, and an incomplete host-detection branch.

**Key findings:**
- The SKILL.md template mandates exactly five canonical section headings: `## Approach`, `## Key Decisions`, `## Trade-offs Considered`, `## Test Strategy`, `## System Diagram`; renaming any heading is prohibited.
- Per-section content rules are precise: Approach requires a one-claim-sentence lead with ≤150 words/≤8 lines per paragraph; Key Decisions requires one-line decision + one-line reasoning per bullet; Trade-offs requires a named rejected alternative per subsection; Test Strategy is type/layer/framework only (no assertion text, no per-file layout); System Diagram requires a Mermaid diagram with a one-sentence organizing-axis claim.
- `qrspi-design-reviewer` checks eight quality dimensions: goal coverage, trade-offs stated, no internal contradictions, appropriate test strategy, YAGNI, research-grounded rationale, diagram present/readable, no phasing content.
- `qrspi-design-scope-reviewer` runs a 3-check procedure against `skills/design/owns-defers.md`: (1) boundary-drift detection, (2) scope completeness vs. OWNS list, (3) lexical boundary-drift signal scan.
- The v0.7.1 design artifact (`design.md`, 183 lines) has all five canonical sections with 11 named Key Decisions, 7 Trade-offs subsections, per-goal test coverage, and a Mermaid flowchart — exceeding minimum template guidance in section count.
- Three review rounds were required: round 1 produced 3 quality findings + 4 scope findings; round 2 produced 2 quality findings + 0 scope findings; round 3 was clean.

**Surprises:** The quality reviewer (not the scope reviewer) is explicitly the only reviewer permitted to Read source files at runtime — specifically `research/q*.md` for citation verification. The scope reviewer has no Read permission beyond loading `owns-defers.md`. This asymmetry is architecturally intentional and documented as an invariant.

**Caveats:** Only the v0.7.1 hardening cycle design artifact was examined for depth comparison. The `future-design.md` file in the same directory was not examined (out of scope per the question). Codex reviewer findings from round 1 were also read (they converged with Claude findings), but rounds 2–3 for Codex were clean and not enumerated individually.

## Full findings

### SKILL.md — Required Structure for Design Decisions

**Source:** `skills/design/SKILL.md` (28.1 KB); per-section template at lines 83–123; OWNS/DEFERS contract in `skills/design/owns-defers.md`.

#### Canonical Section Headings (required, exact names)

The SKILL.md output format block (lines 83–123) specifies five canonical section headings that must not be renamed:

| Section | Heading | Template guidance |
|---------|---------|-------------------|
| 1 | `## Approach` | One claim sentence first ("Chosen approach: {X}"), then 1–2 short rationale paragraphs grounded in research. No DDL, no full function signatures. |
| 2 | `## Key Decisions` | Bulleted list; each bullet = one-line decision + one-line reasoning at architecture-boundary level (data-flow, transport, persistence model, security posture). Not column-level DDL, not line-by-line logic. |
| 3 | `## Trade-offs Considered` | 2–3 rejected alternatives, each with its name as a subsection lead and explicit rejection rationale. Approach-level only — not per-column trade-offs. |
| 4 | `## Test Strategy` | Design-level only: test types (unit / integration / E2E), layers covered, frameworks chosen. Bullets for type/layer/framework triples. No assertion text, no per-test-file layout. |
| 5 | `## System Diagram` | Mermaid diagram. Lead with one-sentence claim of organizing axis. No file/module-layout detail. |

**Source references:**
- Heading mandate: `skills/design/SKILL.md:81` — "Required-section heading match: the headings below … are the canonical set; do not silently rename."
- Per-section HTML comments: `skills/design/SKILL.md:90–122`

#### Conformance Rules Applying to Every Section

From `skills/design/SKILL.md:81`:
- **Claim-before-evidence**: lead each subsection with its decision sentence; supporting detail follows.
- **Paragraph density**: ≤150 words / ≤8 lines per paragraph; longer paragraphs must be split.
- **Scannability**: bullets required in any section longer than ~12 lines.
- **No-brevity prohibition**: the artifact must NOT add "be concise," "brief summary," or "≤ N lines" framing; soft length targets live in SKILL.md, not the artifact.

#### Narrative Depth

The SKILL.md provides soft-length target guidance at lines 20–21: "Soft length target: 200–400 lines for this SKILL.md." The `design.md` artifact itself has no mandatory minimum word/line count — narrative depth is governed by the paragraph-density cap (≤8 lines, ≤150 words per paragraph) and the section completeness requirements. The `## Red Flags` block at lines 276–285 explicitly flags "No test strategy section, or test strategy is just 'add tests'" and "No Mermaid system diagram, or diagram is just boxes without relationships" as stop conditions.

#### Precondition Checks (additional structural gates)

SKILL.md lines 125–144 define two structural precondition checks that run before reviewer dispatch:

1. **Visual-fidelity binding** (when `config.md` carries `visual_fidelity_required: true`): `## Test Strategy` must contain a `### Visual-Fidelity Binding` subsection naming at least one concrete wireframe artifact (Figma URL or embedded PNG path). A subsection with empty, whitespace-only, comment-only, or placeholder body fails the gate identically to absence.

2. **Reference-gate checklist** (when design introduces a reviewer dependent on an external reference artifact): `design.md` must record the lift-verbatim-vs-re-derive decision, naming the reference artifact path/URL.

---

### Design OWNS / DEFERS Contract

**Source:** `skills/design/owns-defers.md`

#### OWNS (what design.md must cover)

- **Approach selection** — which architectural approach was chosen, stated with one claim sentence.
- **Technical trade-offs with rationale** — the 2–3 alternatives weighed, cost/complexity/latency/blast-radius comparison, why the chosen approach won.
- **Test strategy at the design level** — test types, layers, frameworks; behavior-level only.
- **Key architectural decisions** — major decisions with reasoning grounded in goals and research; data-flow boundaries, persistence model, transport choice, security posture.
- **System diagram (high-level boxes/flow)** — Mermaid diagram of major components, their relationships, data flow at architecture level; not file/module layout.

#### DEFERS (what design.md must not contain)

- Full DDL (CREATE TABLE, column types, NOT NULL clauses) → Plan / Implement
- CHECK constraints spelled out → Plan / Implement
- RLS matrices (per-role per-table policy text) → Plan / Implement
- Column commentary (COMMENT ON statements) → Plan / Implement
- Full function signatures with parameter types and return types → Structure / Plan / Implement
- Full assertion text (literal `expect(...).toEqual(...)` lines) → Implement (TDD)
- Line-by-line logic (procedural pseudocode, control-flow detail) → Plan / Implement
- Vertical slice authoring (Iron Law 1) → `qrspi:phasing`
- Phase boundaries and replan gates (Phase 1 PoC guideline) → `qrspi:phasing`
- `roadmap.md` (goal-to-phase assignment table) → `qrspi:phasing`

---

### Reviewer Agent Checks

#### `qrspi-design-reviewer` (quality checks)

**Source:** `agents/qrspi-design-reviewer.md:28–36`

Eight design-specific quality checks:

1. **Goal coverage** — design addresses all goals' problem statements (traces against goals' Problem / Why we care / What we know so far subsections; verifiability criteria are authored downstream in `plan.md`).
2. **Trade-offs clearly stated** — every major architectural decision documents alternatives considered and why this approach was chosen; rationale grounded in research findings.
3. **No internal contradictions** — component descriptions, data-flow explanations, and interface definitions are mutually consistent.
4. **Test strategy appropriate at design level** — names test types (unit, integration, contract, e2e) and explains what's being tested at each level.
5. **YAGNI** — no unnecessary components, layers, or abstractions beyond what the goals require; no speculative generalization.
6. **Approach rationale grounded in research** — architectural choices trace back to concrete research findings; citations to `research/q*.md` are accurate (verified with the Citation-verification Read exception).
7. **System diagram present and readable** — Mermaid diagram is present and describes component relationships at a level useful to an implementer.
8. **Phasing/slice decomposition not present** — phasing and slice authoring are out of scope; do not flag as quality issues (handled by scope reviewer).

**Citation-verification Read exception** (`agents/qrspi-design-reviewer.md:23`): the quality reviewer is the **only** reviewer permitted to Read files at runtime; scope is bounded to `research/q*.md` files, and only when verifying a specific cited file (not exploratorily).

#### `qrspi-design-scope-reviewer` (scope/boundary checks)

**Source:** `agents/qrspi-design-scope-reviewer.md:13–24`

Three-check scope procedure, operating solely against `skills/design/owns-defers.md` (no companion artifacts):

1. **Boundary-drift detection** — does any content cross into territory the OWNS/DEFERS rule defers to a later artifact?
2. **Scope compliance per OWNS** — does the artifact cover everything it owns, or is anything missing?
3. **Lexical boundary-drift signal** — heuristic scan for patterns indicating drift (e.g., file paths or task specs in a design doc).

The scope-reviewer loads `skills/design/owns-defers.md` at runtime via a `Read` call (Step 1 of its procedure). It takes **no companion artifacts** — scope/boundary checks are evaluated against the OWNS/DEFERS rule alone, not against goals.md or research/summary.md.

---

### Comparison: Template Prose vs. Actual v0.7.1 Design Artifact

**Source:** `docs/qrspi/2026-05-27-v071-hardening/design.md` (183 lines, `status: approved`)

#### Section-Level Structural Comparison

| Template Section | Present in v0.7.1 design.md | Notes |
|---|---|---|
| `## Approach` | ✓ (lines 7–15) | Leads with one organizing-axis sentence; uses 3-bucket summary; no DDL |
| `## Key Decisions` | ✓ (lines 17–85) | 11 named DKR subsections (DKR1–DKR11), each with **Decision** and **Reasoning** boldface structure |
| `## Trade-offs Considered` | ✓ (lines 87–127) | 7 subsections (G1, G2, G3, G4, G5, G6, G7b); one goal's trades omitted initially (see review findings) |
| `## Test Strategy` | ✓ (lines 129–147) | Per-goal test coverage; BATS framework named; assertion text/file layout deferred |
| `## System Diagram` | ✓ (lines 149–183) | Mermaid `flowchart TD`; organizing-axis claim sentence present; 5 subgraph groupings |

The artifact does not silently rename any canonical heading and does not include any frontmatter-listed precondition flags (`visual_fidelity_required` is absent/false in config.md for this run).

#### Depth Characterization

- **Key Decisions**: Each DKR entry averages ~5–6 lines (one `**Decision:**` sentence, one `**Reasoning:**` sentence + 1–2 supporting sentences). DKR1 and DKR6 are longest (~6 lines each). DKR8 is shortest (2 sentences). Decisions reference specific research files (e.g., `research/q02-web.md`, `research/q05-codebase.md`) in every Reasoning paragraph.
- **Trade-offs**: Each rejected alternative is ~2–4 lines: alternative name (rejected), one sentence of why it was considered, one sentence of why it was rejected.
- **Test Strategy**: ~19 lines total; one 2–3 line paragraph per goal (G1–G7b); names BATS as framework; explicitly defers assertion text and per-test-file layout.
- **System Diagram**: 33 lines of Mermaid; 5 named subgraphs; all major DKR components represented; organizing-axis sentence precedes the code fence.

#### Review Round Findings Summary

The v0.7.1 design required three review rounds to converge:

**Round 1** (quality-claude: 3 findings; scope-claude: 4 findings; quality-codex: 1 finding; scope-codex: 1 finding):
- `quality-claude-F01` / `quality-codex-F01` (severity: medium) — DKR2 reasoning cited `research/q04-codebase.md` for a finding that lives in `research/q03-codebase.md`; broken research traceability.
- `quality-claude-F02` (severity: low) — `## Trade-offs Considered` had no entry for G5; only goal with a named Key Decision (DKR5) absent from trade-offs.
- `quality-claude-F03` (severity: medium) — DKR6 introduced a three-way host-detection result (Copilot CLI / Codex CLI / Claude Code) but DKR7 specified dispatch transport for only two of the three states; internal contradiction; system diagram node `H_CODEX` had no outbound edges.
- `scope-claude-F01` (severity: medium) — DKR8 Reasoning enumerated exact file line ranges that its own Decision block deferred to Plan; DEFERS violation ("Line-by-line logic → Plan / Implement").
- `scope-claude-F02` (severity: medium) — DKR5 Reasoning embedded a per-line treatment priority procedure (ordered steps for rewrite/delete/inline-marker); DEFERS violation (plan-level task spec).
- `scope-claude-F03` (severity: low) — DKR4 Reasoning contained an implementation directive ("parallelize-reviewer agent's linting must be updated to walk Wave sub-sections"); should be an impact consequence statement.
- `scope-claude-F04` / `scope-codex-F01` (severity: low/medium) — Test Strategy G2 specified shell-command-level test procedure (`git add -A`, `git status --porcelain`); Test Strategy section named specific BATS test files (`tests/unit/test-run-third-party-llm.bats` etc.); both are DEFERS violations ("Full assertion text → Implement (TDD)"; "per-test-file layout → Implement").

**Round 2** (quality-claude: 2 findings; scope-claude: 0; quality-codex: 0; scope-codex: 0):
- `quality-claude-F01` (severity: medium) — DKR7 cited `research/q11-codebase.md` for the `gpt-5.3-codex` model name; Q11 contains zero occurrences of that model name; correct sources are `goals.md` G6 and `research/q12-web.md`.
- `quality-claude-F02` (severity: low) — DKR9 stated specific concrete model IDs (`claude-opus-4.7`) without citation; the Q12-documented value was `claude-opus-4.6`; Copilot CLI IDs left as "equivalent concrete IDs" without specification.

**Round 3**: All four reviewer tags clean (zero findings).

#### Deviations from Template Minimum

The template minimum is five sections with the prescribed content per section. The v0.7.1 artifact exceeds the minimum in Key Decisions (11 subsections where the template shows `{Decisions made during discussion with reasoning}` with no minimum count) and Trade-offs (7 subsections, one per named goal, where the template guidance says "2–3 rejected alternatives").

The Trade-offs section had a gap at round 1 (G5 missing), which was flagged as a quality finding (`F02`), confirming that reviewers enforce the "every major architectural decision documents what alternatives were considered" rule against the actual OWNS contract rather than the template's example count of "2–3."

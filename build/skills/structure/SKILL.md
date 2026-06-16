---
name: structure
description: Use when design.md is approved and the QRSPI pipeline needs file/component mapping — maps vertical slices to specific files, interfaces, and component boundaries
---

# Structure (QRSPI Step 6)

**PRECONDITION:** Invoke `qrspi:using-qrspi` skill to ensure global pipeline rules are in context. (Idempotent on session re-entry. Subagents are exempt — SUBAGENT-STOP in using-qrspi handles that.)

**Announce at start:** "I'm using the QRSPI Structure skill to map the design to files and interfaces."

## Overview

Map the design's vertical slices to specific files, components, and interfaces. Define what gets created vs modified, show how slices map to the stack, and produce a detailed architectural diagram. This is the bridge between abstract design and concrete implementation.

Structure authors: the unified system architecture diagram(s) for the release (Mermaid or equivalent — stitching the components named across design.md's per-solution and cross-cutting-CD blocks into a single architectural overview); file maps and module-boundary contracts; cross-solution component interactions; unified test architecture (the `## Test Architecture` section in structure.md); and per-type stitching of per-solution acceptance criteria from design.md.

<!-- Soft length target: 300–500 lines for this SKILL.md. The marker is a guidance signal — long enough to carry per-section template guidance + worked examples + iron laws, short enough to keep the prompt scannable in a single context window. -->

## Structure OWNS / Structure DEFERS

**Analogy.** structure.md is the **C-header file** / **system manifest** for the project: it declares what gets built, where each unit lives, and how the units connect at their interfaces — but it does NOT contain the bodies. Implementation text (the `.c` file equivalent) is owned downstream by Plan and Implement; architecture decisions (the spec the manifest realizes) are owned upstream by Design; phase boundaries and slice authoring (which units belong to *this* manifest at all) are owned by Phasing.

The OWNS/DEFERS contract below is the locked rule set the scope-reviewer dispatch loads at review time (Read by the `qrspi-structure-scope-reviewer` agent at runtime per its rules-loading procedure). Boundary-drift detection runs against the DEFERS list; scope-compliance runs against the OWNS list.

## Structure Altitude Boundary

### Structure OWNS

Structure OWNS:
- Unified system architecture diagram(s) for the release (Mermaid or equivalent) — stitches the components named across design.md's per-solution + cross-cutting-CD blocks into a single architectural overview
- File map: which file holds which component, directory layout, module boundaries
- Module-boundary contracts: which module exports what to which other module (the structural commitments Plan's task carving consumes)
- Cross-solution component interaction specification: how the components named in design.md's per-solution blocks interact at the system-architecture level (distinct from design.md's per-solution end-to-end flows, which are inter-actor-only inside one solution)
- Unified test architecture: a top-level `## Test Architecture` section in structure.md that names the test taxonomy for the release (e.g., unit, integration, end-to-end, smoke, contract — exact taxonomy varies by release), names the coverage boundary of each type, and enumerates the cross-cutting test invariants (drawn from CDs and goals in design.md) along with which test type owns each invariant
- Per-type stitching of per-solution acceptance criteria: for each type in the test taxonomy, enumerate which per-solution `Acceptance` subsections from design.md (per goal + per CD) feed into that test type — naming the design.md source by goal/CD identifier

### Structure DEFERS

Structure DEFERS:
- Per-solution choice rationale or alternatives weighed (Design's job — Structure consumes the locked solution, does not re-litigate it)
- Per-task assertions / unit-test code (Plan/Implement's job — Structure names the test taxonomy and per-type coverage boundary; Plan authors the per-task `Test Expectations` against the taxonomy; Implement writes the test code)
- Per-solution end-to-end flows or per-solution sequence diagrams (Design's job — Structure shows components at the architectural level, not per-solution choreography)
- External-system contracts or vendor research (Design's job — Structure consumes the cited answers, does not re-research; Design is the last research-bearing phase)
- Detailed solution descriptions or per-solution decision rationale (Design's job — Structure stitches the locked solutions into a unified architecture; Design defines them)

A finding citing structure.md prose that asserts any DEFERS item — for example, embedding a literal compaction-callout sentence rather than just the placement site, or specifying per-task LOC inside a structure entry — is a boundary-drift finding emitted by the scope-reviewer with `change_type: scope` (per the schema in `skills/reviewer-protocol/SKILL.md`).

## Artifact Gating

**Required inputs:**
- `goals.md` with `status: approved`
- `research/summary.md` with `status: approved`
- `design.md` with `status: approved`
- `phasing.md` with `status: approved`

If any artifact is missing or not approved, refuse to run and tell the user which artifact is needed.

Read `config.md` from the artifact directory to determine whether Codex reviews are enabled.

### Config Validation

Apply the **Config Validation Procedure** in `using-qrspi/SKILL.md`. Structure validates `second_reviewer`.

<HARD-GATE>
Do NOT produce structure.md without approved goals.md, research/summary.md, design.md, AND phasing.md.
Do NOT proceed to Plan without user approval of the structure.
</HARD-GATE>

## Execution Model

**Subagent per round** (iterative with human feedback). Each round is a fresh subagent with declared inputs + any feedback from prior rounds.

## Phase-Scoped Content Rules (consumer guidance)

> **Consumer guidance, not authoritative source.** The authoritative source for phasing decisions, vertical slice authoring, roadmap maintenance, and current-phase scoping is the **Phasing** skill (`skills/phasing/SKILL.md`). Structure consumes phasing decisions from `phasing.md` (and pruned `design.md`); it does not own them. The text below restates the consumer-side expectations Structure honors when reading those upstream artifacts.

When generating `structure.md`, Structure honors the phase scope set by Phasing: structure.md reflects ONLY current-phase file maps and interfaces (per `phasing.md` + the pruned `design.md`). Entries are tagged with goal IDs. File maps for goals not in the current phase (per `roadmap.md`, which Phasing authors) do not appear in `structure.md`. Structure verifies every goal ID in the file map exists in the current-phase `goals.md`; cross-phase scoping decisions and any change to the phase boundary itself are Phasing's responsibility — Structure refers the user back to Phasing if a scope shift is needed rather than re-authoring the phase split.

## Multi-Actor Flow Check

## Multi-Actor Flow Check

Before authoring any deliverable that operationalizes a design decision involving two or more actors — where "actor" means anything that performs an operation and hands off to another: scripts, subagents, orchestrators, tools, services, protocol participants, object-call participants, workflow steps, queue producers/consumers, function callers/callees — verify that the design specifies all six choreography elements:

1. **Actor inventory** — every participant named, with its role.
2. **Sequence of operations** — ordered list of who-does-what; parallelism boundaries explicit.
3. **Per-step inputs and outputs** — what each actor receives and produces at each step; where outputs are written (stdout, file path, return value, manifest entry, message).
4. **Consumer identification** — for every output, who reads it next. Outputs with no named consumer must be removed or the consumer surfaced.
5. **Loud-failure paths** — what happens when each step fails; where the failure surfaces; which actor catches it. Silent fallback is never the answer.
6. **Context-cost call-out** — for any flow that crosses a context boundary (orchestrator/subagent, process, network), explicitly state what crosses vs. what stays on disk or in the other context.

If any element is missing for an in-scope decision, **STOP** authoring against this decision and surface a concrete diagnostic to the user. Do NOT guess the missing hand-off and continue.

Diagnostic template:

> Design decision **X** enumerates actors **A, B, C** but does not specify **[missing element — e.g., "what happens if B produces no output", "how A invokes B", "who reads C's output"]**.
>
> Stopping before guessing.
>
> Recommended path: trigger the **Backward Loops** procedure (see `using-qrspi/SKILL.md` § Backward Loops) to re-open Design via its per-decision dialogue, lock the missing element, re-review + re-approve `design.md`, then cascade forward — every dependent artifact from Design onward (Phasing if phase boundaries are affected, Structure, Plan, Parallelize if task dependencies are affected) re-runs against the updated design.
>
> Alternative: provide explicit guidance to accept the gap with a documented assumption recorded against this decision in the deliverable. The assumption becomes the de-facto contract — name what you are choosing for the missing element.

**Iron law:** silently inventing a missing hand-off is a contract violation that ships half-finished features which only surface at Test or in production. Guessing-instead-of-stopping is a process failure and must be reported even if the deliverable otherwise looks complete.

## Process

### Structure Subagent

**Inputs:**
- `goals.md`
- `research/summary.md`
- `design.md`
- `phasing.md` (current-phase scope source — Phasing-owned)
- Any prior feedback files

**Task:** Map the design to concrete files and interfaces.

1. Map each vertical slice from `design.md` to specific files and components
2. For each slice, show which layers of the stack it touches and what files are involved
3. Define interfaces between components (function/class signatures, not implementations)
4. Identify create vs modify for each file
5. Detailed Mermaid architectural diagram: file/module layout, API endpoints, data flow, interface boundaries
6. If CI setup noted in Design, define pipeline structure (workflow file, test commands, lint config) and project convention files (CLAUDE.md, linting config, etc.) for greenfield projects

**Output format for `structure.md`:**

## Evergreen-Output Rule

Any artifact in the QRSPI run directory governed by `status: draft → approved` frontmatter promotion (goals, design, structure, phasing, plan, parallelization, roadmap, future-goals, and any future artifact adopting this lifecycle) describes the **current state** of decisions. The reader is a downstream agent or future maintainer.

*(Excludes by design: `SKILL.md` files — skills carry rule rationale legitimately; `feedback/*.md` — the designated home for dialogue exhaust; `reviews/**/*.md` — finding rationale; `config.md` — non-narrative.)*

**Litmus test (apply to every paragraph before write).** Two filters, in order:

1. Is the subject the **decision** (the thing being designed / planned / scoped)? → keep.
2. Is the subject the **document itself** — its drafts, its history, the dialogue that produced it, "us"? → cut.

A sentence that only makes sense as a delta from a prior state is **dialogue exhaust** — strip it.

**Permitted substantive content** (do NOT confuse with dialogue exhaust):

- Chosen approach and its rationale (inline)
- Rejected alternatives and tradeoffs, where the artifact template asks for them (e.g., design.md's `## Trade-offs Considered` — substantive content about the decision space, not about the document's history)
- Rationale embedded inline as one parenthetical when a downstream reader needs it

**Named antagonist patterns — strip on sight, substitute as shown:**

| Antagonist pattern | Recognize by | Replace with |
|---|---|---|
| Session / drafting notes | "Rule X drafting note," "this collapsed from 3 to 1 because…" | Nothing — delete. If a fact matters, embed inline in the decision. |
| Version-history narration | "earlier draft said X," "previously," "originally," "pre-cleanup" | Nothing — git history holds versions. |
| Inside baseball | text addressed to "us" / "the author," meta-explanation of the document's own structure ("this section is split into A and B because…") | The decision the structure expresses — without the structural explanation. |
| Compaction-loss recovery notes | "this nuance was almost lost during…" | Nothing — if the nuance is needed, the rule itself carries it. |
| Failure-modes-prevented lists | bullets that justify why a rule exists rather than state what to do | Strengthen the rule's wording; delete the justification list. |

Decision-process history (drafts, review rounds, feedback applied, compaction recovery) lives in feedback files, review findings, PR descriptions, and git history — never in the artifact.

> **Per-section template guidance is embedded inline as HTML comments below.** Each section block carries a one-line guidance comment and a conformance reminder so future structure.md content can be linted for boundary-drift signals (the scope-reviewer's boundary-drift sub-check looks for skill-implementation jargon — specific tool names, hook syntax, subagent dispatch verbs — leaking into earlier-stage artifacts; structure.md owns file paths and interfaces, not Plan/Implement-layer language).
>
> **Conformance applies to every section of structure.md.** Claim-before-evidence (lead each subsection with its decision sentence; supporting detail follows). Paragraph density: ≤150 words / ≤8 lines per paragraph; if longer, split. Scannability: bullets in any section longer than ~12 lines. Required-section heading match: the headings below (`## File Map`, `## Interfaces`, `## Architectural Diagram`, `## CI Pipeline`) are the canonical set; do not silently rename. No-brevity prohibition: do NOT add "be concise", "brief summary", "≤ N lines" framing; the soft length target is set in this SKILL.md, not in the artifact.

````markdown
---
status: draft
---

# Structure: {Project/Feature Name}

<!-- Lead with one claim sentence describing the project scope; do NOT restate Design's architecture. -->

## File Map

<!-- Per-section guidance: one row per file. Action ∈ {Create, Modify}. Responsibility is a one-line behavior summary at the boundary level — NOT line-by-line logic, NOT LOC estimates, NOT commit ranges (those belong to Plan). Bullets/tables for scannability; concrete paths only — no directory placeholders. -->

### Slice 1: {name}
| File | Action | Responsibility | Goal IDs |
|------|--------|---------------|----------|
| `path/to/file.ts` | Create | {what it does at the boundary} | {G1, G2} |
| `path/to/existing.ts` | Modify | {what changes at the boundary} | {G1} |

### Slice 2: {name}
...

## Interfaces

<!-- Per-section guidance: explicit signatures with concrete types. NO `any`, NO `object`, NO `TBD`. Plan reads these to define task boundaries. Claim-before-evidence — lead with the interface's purpose sentence, then the signature block. -->

### {Component A} → {Component B}
```typescript
// path/to/interface.ts
interface FooService {
  bar(input: BarInput): Promise<BarOutput>;
}
```

## Architectural Diagram

<!-- Per-section guidance: Mermaid diagram of file/module relationships, API endpoints, data flow, interface boundaries. Diagram is written into structure.md (NOT pasted into terminal). Lead with a one-sentence claim describing the diagram's organizing axis (e.g., "Modules grouped by slice; arrows are runtime data flow, not import direction") so a scanning reader does not have to infer the convention. -->

{Detailed Mermaid diagram}

## CI Pipeline (if needed)

<!-- Per-section guidance: workflow file structure, test commands, lint config. Present only if Design noted CI setup. Bullets for the command list; one paragraph maximum for rationale. -->

{Workflow file structure, test commands, lint config}

## UI Reference Affordances (required when any task carries lift_source:; omit otherwise)

<!-- Per-section guidance: record once per release; do NOT derive per-task. Three affordances required:
     1. Sibling reference repo — path, pinned commit, or scratch directory where the coded prototype lives.
     2. Lift-codemod transformation — token import codemod or mechanical lift recipe that translates source tokens into the target's design-system vocabulary.
     3. Image-asset pipeline — where reference PNG/SVG/PDF artifacts live and how they reach the target tree.
     Consumer contract: T28's visual-fidelity reviewer Reads this section to ground lift-verbatim-vs-re-derive judgments. -->

### Sibling Reference Repo
{Path to the sibling repo, scratch directory, or pinned upstream commit that serves as the coded-prototype source for lift tasks}

### Lift-Codemod Transformation
{Token import codemod or mechanical recipe (e.g., `sed -i 's/OldComponent/NewComponent/g'`) that translates source tokens to the target design-system vocabulary}

### Image-Asset Pipeline
{Location of reference PNG/SVG/PDF artifacts and the step that copies or links them into the target tree}
````

### Review Round

**Compaction checkpoint: pre-fanout.** Quality + scope reviewer fan-out reads `structure.md` + `goals.md` + `research/summary.md` + `design.md` + `phasing.md` + the agent-embedded reviewer protocol; saturated context produces shallow findings. See using-qrspi `## Compaction Checkpoints` for the iron-rule contract.

Call `TaskCreate({ subject: "Recommend /compact (pre-fanout) — structure", description: "pre-fanout: parallel reviewer dispatch reads structure.md + 4 prior artifacts. User decides whether to /compact." })`.

Apply the **Standard Review Loop** from `using-qrspi/SKILL.md`. Two parallel reviewer dispatches per artifact per round (quality + scope). Structure-specific reviewer instructions:

**Dispatch the round through dispatch-agent's high-level entry.** Run `scripts/dispatch-agent.sh --step structure --round ${ROUND} --artifact-dir <ABS_ARTIFACT_DIR>` (plus the per-skill `--output-dir`/`--artifact`/`--agents` flags below). High-level mode invokes `scripts/review-prep.sh` to emit `<ABS_ARTIFACT_DIR>/reviews/structure/round-${ROUND}.diff` and threads `diff_file_path:` into each reviewer prompt; the orchestrator runs no `git diff` Bash redirect of its own. When the artifact directory is not inside a git repository, review-prep skips diff emission and `diff_file_path:` is omitted. When using-qrspi step 12 narrows the base ref, pass `--base-ref "$(cat reviews/structure/round-$((ROUND-1))-commit.txt)"` so review-prep narrows against the prior round's per-round commit SHA (using-qrspi step 12 owns the SHA-format validation and the `anchor-file-missing:`/`sha-format-invalid:` halt directions before the SHA reaches `git diff`). Scope-tag narrowing (when active) reaches reviewers as `scope_hint:` wrapped between `<<<UNTRUSTED-SCOPE-HINT-START id=scope_hint>>>` / `<<<UNTRUSTED-SCOPE-HINT-END id=scope_hint>>>` markers per the reviewer-protocol Reviewer Dispatch Contract.

The round's reviewers dispatch through the universal dispatch chain (`scripts/dispatch-agent.sh` → Task fan-out → `scripts/await-round.sh`). Set the per-skill dispatch parameters below, then include the shared reviewer-dispatch prose. Include the `*-codex` peer tags in `REVIEW_AGENTS` only when `second_reviewer: true`; otherwise list only the `*-claude` tags.

```sh
REVIEW_STEP="structure"
REVIEW_ROUND="${ROUND}"                                  # current review round (NN)
REVIEW_OUTPUT_DIR="<ABS_ARTIFACT_DIR>/reviews/structure/round-${ROUND}/"
REVIEW_ARTIFACT="structure.md"
REVIEW_AGENTS="quality-claude=qrspi-structure-reviewer,scope-claude=qrspi-structure-scope-reviewer,quality-codex=qrspi-structure-reviewer,scope-codex=qrspi-structure-scope-reviewer"
```

# Reviewer Dispatch (shared)

With `$REVIEW_STEP`, `$REVIEW_ROUND`, `$REVIEW_OUTPUT_DIR`, `$REVIEW_ARTIFACT`, and `$REVIEW_AGENTS` set by the per-skill preamble above, run:

```sh
scripts/dispatch-agent.sh --step "$REVIEW_STEP" --round "$REVIEW_ROUND" \
  --output-dir "$REVIEW_OUTPUT_DIR" --artifact "$REVIEW_ARTIFACT" \
  --agents "$REVIEW_AGENTS"
```

`dispatch-agent` emits M lines on stdout (one per first-party reviewer; zero lines for a third-party-only batch). Each line has the form:

```
MODE=first_party TAG=<tag> SUBAGENT_TYPE=<agent-name> MODEL=<resolved-model> PROMPT_FILE=<absolute-path>
```

**For every emitted spec line, invoke the Task tool with these arguments (parse the line as space-separated `KEY=VALUE` pairs; values contain no spaces):**

- `subagent_type` = the `SUBAGENT_TYPE` value, verbatim
- `model` = the `MODEL` value, verbatim
- `prompt` = the literal string `"DISPATCH_FILE=<PROMPT_FILE-value>"` — a single-line env-var-style reference; the prompt argument has no other content

**Invoke all M Task tool calls in parallel in one orchestrator response** (one Task call per spec line). The reviewer agent body's first instruction is to `Read` its `DISPATCH_FILE` — do not pre-Read the file yourself; the dispatch context belongs in the subagent's window, not the orchestrator's.

**Iron law (orchestrator-side dispatch contract):** invoke the Task tool exactly once per emitted spec line, with `SUBAGENT_TYPE`, `MODEL`, and `PROMPT_FILE` copied verbatim. Skipping a line, deduplicating across lines, modifying any value, or substituting a different subagent_type is a contract violation. The dispatch manifest (`$REVIEW_OUTPUT_DIR/.dispatch-manifest.json`) records expected dispatches; the apply-fix step's "expected tag produced no output" diagnostic catches missed or mis-routed Task invocations.

**Capture each Task return value to disk before draining.** After each Task call returns, write the subagent's reply text (the full Task return string) to `$REVIEW_OUTPUT_DIR/.dispatch/<TAG>.raw` using the `create` tool, where `<TAG>` is the `TAG` value from the corresponding spec line. This is mandatory regardless of whether the subagent appeared to write per-finding files itself. Rationale: when a subagent cannot use the Write tool (read-only sandbox; missing `allowed-tools` entry; tool denial at runtime) it emits findings via the `<<<FINDING-BOUNDARY>>>` stdout contract instead. `await-round.sh` recovers those findings via a universal stdout-fallback that reads `.dispatch/<TAG>.raw` and pipes it through `third-party-finding-splitter.sh`; without the captured `.raw` file the fallback has nothing to work with and the round looks (incorrectly) clean.

After all Task tool calls return AND all `.raw` captures are written (Task tool is synchronous; first-party subagents with working Write tools have already written their per-finding files by this point), drain any third-party background dispatches and finalize the round:

```sh
scripts/await-round.sh --round-dir "$REVIEW_OUTPUT_DIR"
```

`await-round` is no-op-safe — first-party-only rounds still call it; it returns immediately after reading the manifest. It writes a small `$REVIEW_OUTPUT_DIR/.round-complete.json` summary and (for third-party dispatches OR any entry that produced no per-finding files but has a `.dispatch/<TAG>.raw` capture) materializes per-finding files via `third-party-finding-splitter.sh`. It does NOT echo captured subagent payloads (CD-1 #4 output-bound contract).

Then read `$REVIEW_OUTPUT_DIR/.round-complete.json` and the per-finding files as needed for apply-fix. The raw per-reviewer prompt content (assembled by dispatch-agent into `PROMPT_FILE`) never enters the orchestrator's context — only the small spec lines + the small `DISPATCH_FILE` references passed to Task.

### Human Gate

Present `structure.md` to the user — "hammer on it" review point alongside Design. **Always state the review status** when presenting: either "Reviews passed clean in round N" or "Reviews found issues in round N which were fixed but not re-verified."

When presenting Mermaid diagrams (dependency graphs, architectural diagrams, parallelization plans), write the diagram to the artifact file (e.g., `structure.md` for architecture diagrams, `parallelization.md` for dependency graphs) and direct the user to open the file. Do not paste raw Mermaid syntax into terminal output — it renders as unreadable text in the terminal. Tell the user: "The architecture diagram is in `structure.md` — open it to view the rendered diagram."

On approval, if reviews have not passed clean, note this and ask if they'd like a review loop before finalizing.

**`lift_source:` gate (before writing `status: approved`):** Before marking `structure.md` approved, scan the current release's task specs for any task carrying `lift_source:` in its frontmatter. If any such task exists and `structure.md` does NOT contain a `## UI Reference Affordances` section, REFUSE to write `status: approved` and emit a named refusal:

> `structure: approval refused — plan contains a task with lift_source: but structure.md is missing the ## UI Reference Affordances section. Add the section (sibling reference repo, lift-codemod transformation, image-asset pipeline) before approving.`

This refusal is non-negotiable. The Structure skill cannot mark `structure.md` approved while a `lift_source:` task exists without the affordances section that T28's visual-fidelity reviewer requires.

Then write `status: approved` in frontmatter.

On rejection, write the user's feedback and the rejected artifact snapshot to `feedback/structure-round-{NN}.md` (using the standard feedback file format from `using-qrspi`), then launch a new subagent with original inputs + **all** prior feedback files (not just the latest round). After re-generation, the review cycle restarts.

### Artifact

`structure.md` — file-level and function-level breakdown organized by vertical slice, with interface definitions, Mermaid architectural diagram, CI pipeline structure if needed

### Terminal State

If the artifact directory is inside a git repository, commit the approved `structure.md` and the `reviews/structure/` directory (per-round per-reviewer files; see `using-qrspi` → "Commit after approval (when applicable)").

**Compaction checkpoint: pre-handoff.** Structure approved; the next skill (typically Plan) reads `structure.md` + every prior approved artifact + reviewer findings on a fresh context. See using-qrspi `## Compaction Checkpoints` for the iron-rule contract.

Call `TaskCreate({ subject: "Recommend /compact (pre-handoff) — structure", description: "pre-handoff: next skill reads structure.md + prior artifacts + reviewer findings. User decides whether to /compact." })`.

**REQUIRED:** Invoke the next skill in the `config.md` route after `structure`.

## Test Architecture

Author the unified `## Test Architecture` section in structure.md after Design approval. Design authors per-solution `Acceptance` subsections per goal/CD block; Structure stitches them into a release-level test architecture. This is new authoring behavior for Structure — do not re-open Design rationale or add Plan/Implement-level assertions.

**Procedure (run after Design approval):**

1. Enumerate every per-solution `Acceptance` subsection in design.md — one per goal block and one per CD block. Record each by goal/CD identifier (e.g., G1, G5, CD-4).
2. Name the test taxonomy for the release (e.g., unit, integration, end-to-end, smoke, contract — exact taxonomy varies by release). Group the acceptance criteria from step 1 by test type per the named taxonomy, citing the design.md source identifier for each entry.
3. Enumerate cross-cutting test invariants drawn from CD blocks and cross-cutting goals in design.md. For each invariant, name the test type that owns each invariant.
4. Author the result as a top-level `## Test Architecture` section in structure.md: named-taxonomy-first (T1, T2, …), one paragraph per type naming the coverage boundary and which design.md `Acceptance` subsections feed into it, and a final `### Cross-cutting invariants` subsection listing the invariants from step 3 with their owning test type.

Structure's role in this section: name the test taxonomy, enumerate cross-cutting test invariants, and name the test type that owns each invariant. Structure does not author per-task test expectations or assertion code — those belong to Plan and Implement respectively.

## Section-Anchor Index

The Section-Anchor Index is the G4 scope-tagger narrowing contract — narrow, byte-identical reads of named H2 / H3 sections inside large SKILL.md artifacts. scope-tagger narrowing ships unconditionally and is consumed by skill authors who need a stable section slice (e.g., a reviewer that wants the `## Dispatch Contract` section of `skills/reviewer-protocol/SKILL.md` without rescanning the file for headings every dispatch).

- **Colocation convention.** Every indexed source artifact ships its index file colocated next to the source — `skills/<name>/SKILL.anchors.json` sits next to `skills/<name>/SKILL.md`. Future indexed artifacts MUST follow this convention so consumers can resolve the index path mechanically from the source path (`<source>.anchors.json`).
- **Manifest as the single registry.** The file `tools/g4-section-anchor-manifest.json` is the single registry that gates which artifacts receive a maintained index. The refresh script (`tools/g4-section-anchor-refresh.sh`) only regenerates the indexes named in the manifest; an artifact that wants an index MUST be added to the manifest. Indexes for artifacts NOT in the manifest are not maintained and MUST NOT be relied on by consumers — they can drift silently from their source.
- **Refresh ownership (regenerator output, not hand-authored).** Index files are the output of the refresh script. Hand-editing an index file is a contract violation — the next refresh-script invocation will overwrite hand edits without warning. To extend an index, edit the source artifact (add or rename a heading) and re-run the refresh script; the index will reflect the source's current state.
- **Consumer contract (index lookup + `Read(offset, limit)`).** An agent that wants section X of artifact Y consults `Y.anchors.json`, looks up the `{line_start, line_end}` range for the heading text matching X, then issues `Read(offset=line_start, limit=line_end - line_start + 1)` to retrieve the slice verbatim. Consumers MUST NOT re-scan the source for headings (that defeats the entire scope-tagger narrowing contract — re-scans cost the same as the original read). The byte-identical slice the index resolves to is the load-bearing property: a section's content is identical across consumers because everyone reads through the same `{line_start, line_end}` range.
- **Duplicate-heading-text invariant.** A source artifact MUST NOT contain two H2 or H3 headings whose text is identical — duplicates make `{heading_text → range}` lookups ambiguous and the refresh script exits non-zero with a loud diagnostic naming the offending artifact, the duplicate text, and the colliding line numbers. Resolution: rename one of the duplicate headings to disambiguate.

Pin for the consumer contract: T36's `test-section-anchor-refresh.bats` asserts that the regenerated index reflects the source's current heading layout after a source heading is added, removed, or renamed.

## Red Flags — STOP

- A file mentioned in the design has no entry in the file map
- An interface definition doesn't match between caller and callee
- A file is marked "Modify" but doesn't exist in the codebase
- A file is marked "Create" but already exists in the codebase
- Slices in the file map don't match slices in the design
- Missing Mermaid architectural diagram
- CI pipeline structure is needed (greenfield or no existing CI) but not defined
- Interfaces use placeholder types ("any", "object", "TBD")
- Pasting Mermaid diagram syntax directly into terminal output (user cannot read it)
- Plan contains a task with `lift_source:` but `structure.md` lacks `## UI Reference Affordances` — do NOT approve; emit the named refusal (see Human Gate above)

## Common Rationalizations — STOP

| Rationalization | Reality |
|----------------|---------|
| "The interfaces are obvious from the file names" | Write them explicitly. The Plan skill uses interfaces to define task boundaries. |
| "I'll figure out the exact files during implementation" | Structure IS the file decision. Deferring to implementation means the plan will be wrong. |
| "This file is too small to list" | If it's in the design, it's in the structure. Every file needs an entry. |
| "The existing codebase doesn't have clear interfaces" | Then define them. Structure is the opportunity to introduce clarity. |
| "CI can be set up later" | CI is Task 1 of Phase 1 (per Design). It blocks everything else. |

## Worked Example

**Good file map entry:**

> ### Slice 1: Client rate check
> | File | Action | Responsibility |
> |------|--------|---------------|
> | `src/middleware/rate-limiter.ts` | Create | Express middleware that checks Redis for client rate, returns 429 if exceeded |
> | `src/services/redis-client.ts` | Modify | Add rate limit increment/check methods to existing Redis wrapper |
> | `src/types/rate-limit.ts` | Create | RateLimitConfig, RateLimitResult interfaces |
> | `tests/middleware/rate-limiter.test.ts` | Create | Unit tests for rate limiting middleware |

**Bad file map entry (vague):**

> ### Rate Limiting
> | File | Action | Responsibility |
> |------|--------|---------------|
> | `src/middleware/` | Create | Rate limiting stuff |
> | Various | Modify | Update as needed |

The bad example uses directory paths instead of files, and "various" is not an action plan.

## Iron Laws — Final Reminder

The two override-critical rules for Structure, restated at end:

1. **Every file in the design has an entry; every entry has a real path.** No directory placeholders, no "various", no "TBD". Structure IS the file decision — Plan reads from it directly to write task specs.

2. **Interfaces are explicit, with concrete types.** No `any`, no `object`, no placeholder types. Plan uses interface signatures to define task boundaries; vague interfaces produce vague tasks.

Behavioral directives D1-D4 apply — see `using-qrspi/SKILL.md` → "BEHAVIORAL-DIRECTIVES".

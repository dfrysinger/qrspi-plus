# QRSPI Canonical Reference

Consolidated reference for the QRSPI methodology as articulated in Dex Horthy's QRSPI talk and related HumanLayer material, plus the extensions qrspi-plus layers on top. Supersedes `qrspi-reference.md` (condensed table) and `qrspi-deep-dive.md` (SBS per-step notes) — both of those files are retained in git history but are no longer maintained.

## Sources at a glance

| Source | Location | Primary vs Derived |
|---|---|---|
| Slide deck — Dex's SBS talk | `docs/slides/qrspi-deck.pdf` (156 pages, pages 291-446 of the SBS 2026 conference deck) | Primary |
| ACE-FCA essay — "Getting AI to Work in Complex Codebases" | `docs/upstream/ace-fca.md` (mirrored) | Primary (principles) |
| Alex Lavaee "From RPI to QRSPI" | linked from `docs/upstream/README.md` | Derived |
| Heavybit "What's Missing to Make AI Agents Mainstream?" | linked from `docs/upstream/README.md` | Derived (Dex interview) |
| Dev Interrupted "Dex Horthy on Ralph, RPI, and escaping the Dumb Zone" | linked from `docs/upstream/README.md` | Derived (podcast teaser) |
| YouTube talks | linked from `docs/upstream/README.md` | Primary (video form of the deck) |

## Background: why RPI broke down

The original **RPI** (Research → Plan → Implement) used a single `/create_plan` mega-prompt that had grown to **85+ instructions**, internally attempting design decisions, structure outlines, and detailed planning all at once. In practice design and structure steps were accidentally skipped (they were buried sub-steps), plans were low quality, and engineers were reviewing ~2000 lines of code instead of catching problems earlier.

QRSPI fixes this by **extracting every hidden sub-step into an explicit phase** with its own prompt, inputs, outputs, and human review gate. Each phase runs in a fresh sub-agent context and produces a compact artifact that compacts before feeding the next phase, keeping context utilization in the **40-60% band** (the deck's "smart zone"; ACE-FCA's equivalent framing). Frontier LLMs can follow ~150-200 instructions with good consistency (cited from arxiv 2507.11538, deck slide ~58), so the per-stage instruction budget drops from 85+ in the monolith to an aggregate **38** across the split (deck slide ~95); Heavybit characterizes this as "<40 instructions per step."

## Stage inventory

Sources disagree on the total count. The difference is which stages get enumerated, not what the pipeline does:

| Stage | Deck (Dex SBS) | Lavaee | Heavybit | qrspi-plus |
|---|---|---|---|---|
| **Goals** | — | — | — | ✅ (new step) |
| **Questions** | ✅ | ✅ | ✅ | ✅ |
| **Research** | ✅ | ✅ | ✅ | ✅ |
| **Design** | ✅ | ✅ | ✅ | ✅ |
| **Structure** | ✅ | ✅ | ✅ | ✅ |
| **Plan** | ✅ | ✅ | ✅ | ✅ |
| **Worktree** | ✅ | ✅ | ✅ | ✅ |
| **Implement** | ✅ | ✅ | ✅ | ✅ |
| **Integrate** | — | — | — | ✅ (new step) |
| **Test** | — | — | — | ✅ (new step) |
| **Replan** | — | — | — | ✅ (new step) |
| **PR** | ✅ | ✅ | (handoff, not numbered) | (PR created by Test) |
| Total stages | **8** | **8** | **7** | **9 (+ Replan)** |

The QRSPI acronym (deck slide ~152) highlights five steps in blue — **Q**uestions, **R**esearch, **S**tructure, **P**lan, **I**mplement — even though the pipeline has 8 steps total. Design, Worktree, and PR are present but not in the acronym.

Naming: the framework is called **QRSPI** by most sources. Lavaee also mentions **CRISPY** as an alternative name ("the replacement is a framework Horthy calls CRISPY (technically QRSPI)"); the other sources do not use CRISPY.

## Per-step reference

Per-artifact size and scope guidance is drawn primarily from deck slide ~107's size table, with per-step detail from surrounding slides. Size targets are Dex's own numbers from the SBS talk; reviewer expectations and "what's deferred" are paraphrased from the per-step slide groups.

### 1. Goals (qrspi-plus only)

Not a step in Dex's pipeline. qrspi-plus adds Goals as an explicit intent-capture step: purpose, constraints, testable acceptance criteria, out-of-scope exclusions. Also selects pipeline mode (quick fix vs full) and writes `config.md`.

**Artifact:** `goals.md`. Size: Purpose ~1-2 sentences; criteria/constraints as short lists.

### 2. Questions (Q in QRSPI)

A "skilled engineer" agent analyzes the ticket to detangle intent from codebase zones and generate targeted research questions — query planning before code is read. The questions artifact carries codebase-zone instructions forward while the ticket itself is hidden from the researcher.

**Artifact:** `questions.md`. Size: not specified in the deck. In qrspi-plus, each question is tagged `[codebase]`, `[web]`, or `[hybrid]` to dispatch the right specialist.

**Deferred:** the original ticket (hidden from Research to prevent confirmation bias).

### 3. Research (R in QRSPI)

Codebase/web exploration driven by the questions. Facts only — no opinions, no implementation planning, no recommendations. "Research == Compression of Truth" (deck slide ~36). Produced at 40% context used. Sub-agents feed the researcher: codebase-locator, codebase-analyzer, codebase-pattern-finder.

**Artifact:** `research.md` (qrspi-plus: `research/summary.md` + per-question `research/q*.md`). Size: **300-1000 lines** (deck slide ~28).

**Deferred:** opinions, recommendations, implementation planning, the ticket itself.

### 4. Design (in QRSPI pipeline, not in the acronym)

Interactive design discussion with questions between agent and human. Agent proposes options, asks clarifying questions, iterates until both share the same "design concept" (Matt Pocock). The conversation is the artifact.

**Artifact:** `design.md`. Size: **~200-400 lines** (deck slide ~107). Contents seen in the deck's riptide-daemon example (slides ~109-116):
- Summary of change request
- Current State (bulleted facts with file references, types)
- Desired End State (bulleted behaviors and resolved decisions)
- Patterns to Follow (existing code patterns with file paths and snippets)
- Resolved Design Questions (Decision / schema / Rationale)
- Design Questions (open options A/B/C with pros and cons)

**Deferred:** file maps, signatures, full implementation task plans.

### 5. Structure (S in QRSPI)

How do we get there? Maps design into a phase-by-phase skeleton. "If the plan is the full implementation, the outline is C header files" (deck slide ~128): signatures, new types, high-level phases. Structure also assigns horizontal-vs-vertical phase shapes with explicit LoC budgets.

**Artifact:** `structure.md`. Size: **~300-500 lines** (deck slide ~107). Contents:
- Per-phase blocks: phase title, one-paragraph summary, File Changes list, Validation block (typecheck/test commands + manual-validation steps)
- Horizontal slicing (e.g., db → services → api → frontend) or vertical slicing (stub → wire → mock end-to-end)

**Deferred:** full file diffs and code snippets (to Plan).

### 6. Plan (P in QRSPI)

Tactical document for the implementer agent. Full diffs, signatures, before/after code blocks, file/line targets, sub-section headings. "You spot check it — save the deep review for the actual code" (deck slide ~138).

**Artifact:** `plan.md` (+ per-task specs in qrspi-plus). Size: **~1000-2000 lines** (deck slide ~107). Size rule of thumb: "A 1000-line plan has as many surprises as 1000 lines of code" — so plans retain full detail, but human review is spot-check rather than deep line-by-line.

**Deferred:** the code itself (to Implement).

### 7. Worktree (in QRSPI pipeline, not in the acronym)

Sets up an isolated git worktree on a feature branch. qrspi-plus extends this to dependency-graph analysis, parallel/sequential/hybrid execution modes, baseline test verification, and subagent permission pre-configuration.

**Artifact (qrspi-plus only):** `parallelization.md`.

### 8. Implement (I in QRSPI)

Executes the plan in the worktree. qrspi-plus adds a TDD iron law (no production code without a failing test first), 8 specialized reviewers split across correctness (always-run: spec, code quality, silent failures, security) and thoroughness (deep-mode only: goal traceability, test coverage, type design, simplification), and configurable review depth per phase.

### 9. PR / Test / Integrate / Replan (qrspi-plus extensions)

Dex's original QRSPI ends Implement → PR for human review. qrspi-plus splits the PR-phase into explicit steps: Integrate (merge + cross-task + security review + CI gate), Test (acceptance testing against `goals.md` + PR creation), and Replan (between-phase replanning with severity-classified amendments).

## How the framework enforces its guarantees

From ACE-FCA (the principles essay behind QRSPI):

- **Stateless LLMs.** "LLMs are stateless functions. The only thing that affects the quality of your output (without training/tuning models themselves) is the quality of the inputs." Context window is the only lever.
- **Optimize for Correctness / Completeness / Size / Trajectory** (in that order).
- **Failure modes ranked worst-to-least-bad**: Incorrect Information → Missing Information → Too much Noise.
- **40-60% utilization band** of the ~170k working context budget. The deck's "smart zone / dumb zone" terminology is the same framing.
- **Sub-agent isolation = fresh context window** via Claude Code's `Task()` tool. "Subagents are not about playing house and anthropomorphizing roles. Subagents are about context control." The boundary is **contextual**, not security/process.
- **Compaction is the unifying technique.** Artifacts (`research.md`, `plan.md`, `progress.md`) are the form compaction takes. Each phase produces a compact artifact that survives context resets.

## Core philosophy (distilled)

- **Do not outsource the thinking.** QRSPI gives the agent every opportunity to show you what it's thinking at each stage, with human review gates between phases. You review ~200 lines of alignment artifacts instead of ~2000 lines of code.
- **Context engineering is the only lever.** Each phase runs in a fresh subagent with only declared inputs.

## Key principles

- **Separate what we need to know from finding the answers** (Questions → Research split).
- **Hide the ticket from researchers.** Research stays objective; prevents confirmation bias.
- **Vertical slices, not horizontal layers.** Each feature goes end-to-end.
- **One line of plan ≈ one line of code.** Plans are long and detailed; review them as spot-checks.
- **Hammer on goals, design, and structure.** These are the high-leverage review points.
- **Single pipeline for all work.** Fix tasks route through the same Worktree → Implement pipeline.

## User review effort guide (qrspi-plus artifacts)

| Artifact | Review effort |
|---|---|
| `goals.md` | **Hammer on this** — wrong goals = everything downstream is wrong |
| `questions.md` | Thorough — missing questions = blind spots |
| `research/summary.md` | Read and verify — wrong facts = wrong design |
| `design.md` | **Hammer on this** — approach, slicing, phasing |
| `structure.md` | **Hammer on this** — file layout, interfaces |
| `plan.md` + task specs | Spot-check — review subagent validates detail |
| Code | **Thorough review** — reinvest time saved from spot-checking plan |

## What qrspi-plus adds beyond the base framework

**New pipeline steps**

| Step | What it adds | Base QRSPI equivalent |
|---|---|---|
| **Goals** | Explicit intent capture with testable acceptance criteria, pipeline mode selection (quick fix vs full), `config.md` creation, goal specificity enforcement | Base QRSPI uses a ticket/issue as input; Goals formalizes this as a reviewable artifact |
| **Integrate** | Cross-task integration review + security integration review after merging worktrees, CI pipeline gate with fix-task routing, phase learnings capture | Not in base — Implement goes straight to PR |
| **Test** | Acceptance testing against original goals, per-failure quick/full classification, `goals.md` checkbox updates, code review checkpoint, phase routing (PR on final phase, Replan on intermediate) | Not in base — PR review was the verification step |
| **Replan** | Between-phase replanning with severity classification (minor/major/scope-unknown), fire-and-forget backward loops to Goals, Design, or Structure, three-tier amendment classification, phase snapshot and promotion | Not in base — single-phase execution only |

**Extended existing steps**

| Step | What qrspi-plus adds |
|---|---|
| **Design** | Vertical-slice enforcement, phase definitions with replan gates, test strategy, Mermaid system diagrams, phase-scoped content rules, roadmap maintenance |
| **Structure** | Interface definitions (function/class signatures), create vs modify tracking, CI pipeline structure for greenfield projects, phase-scoped file maps |
| **Plan** | Sub-subagent dispatch for large plans, merge/split lifecycle, quick-fix single-task mode, `pipeline` field on task files, 5 specialized reviewer templates (architectural plan review) |
| **Worktree** | Dependency graph analysis, parallel/sequential/hybrid execution modes, baseline test verification with auto-fix, batch gate after all tasks, subagent permission pre-configuration |
| **Implement** | TDD iron law, 8 specialized reviewers in correctness/thoroughness tiers, configurable review depth per phase, aggressive commenting requirements, verbatim review result persistence |

**Infrastructure additions**

- 13 specialized reviewers (4 implementation correctness + 4 implementation thoroughness + 5 plan-level)
- 5 canonical review patterns (Inner Loop / Outer Loop / Deterministic / Artifact Synthesis / Architectural Plan)
- Route-based routing via `config.md`
- Quick fix mode (shortened pipeline)
- Fix-task routing loops (integration, CI, test → through the same pipeline)
- Artifact gating (structural enforcement of prerequisites)
- Phase-scoped artifacts + `future-*.md` + `phases/phase-NN/` archives
- Amendment classification (clarifying / additive / architectural)
- Hook-based enforcement (PreToolUse + PostToolUse + SessionStart)
- Behavioral directives D1/D2/D3 across all skills

See the top-level `README.md` for the full infrastructure-additions table, pipeline diagrams, and configuration reference.

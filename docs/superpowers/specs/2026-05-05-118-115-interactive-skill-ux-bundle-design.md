# Interactive-Skill UX Bundle: #118 Per-Goal Design + Auto-Mode + #115 Per-Researcher Dispatch Refinements

**Status:** Design
**Issues:** [#118](https://github.com/dfrysinger/qrspi-plus/issues/118), [#115](https://github.com/dfrysinger/qrspi-plus/issues/115)
**Milestone:** v0.5
**Date:** 2026-05-05

## 1. Bundle Rationale

Both issues refine **interactive-skill prompt language** — collaborative-skill UX (#118) and per-researcher dispatch prompts (#115). Each issue is itself a 2-pack of small refinements, so the spec totals four discrete prose-edits to three SKILL.md files.

The two issues are independent (different SKILLs, different concerns) but share the shape: adjust prompt prose at specific dispatch/preamble sites, no schema change. Bundling avoids two near-identical small PRs.

Per the qrspi-plus prose-handling preference: skip full reviewer suite, decide test handling per change, no TDD ceremony.

## 2. #118: Per-Goal Design + Auto-Mode Detection

### 2.1 Refinement A — Per-goal Design brainstorming

**Problem.** v0.4-bundle had 13 goals (G1-G13). `design/SKILL.md` § Interactive Design Discussion currently prescribes "Propose 2-3 design approaches with trade-offs, lead with recommendation" without sequencing per-goal. Opening the floor to a 13-goal design dump produces shallow buy-in. Goal-by-goal Q&A produces deeper alignment.

**Site.** `skills/design/SKILL.md:45` — `### Interactive Design Discussion`.

**Fix shape.** Replace the current step-1 prescription with a per-goal loop:

> 1. **For each goal in `goals.md`, in order:**
>    1. Surface the relevant research findings from `research/summary.md` (and on-demand from `research/q*.md` if a decision depends on details).
>    2. Propose 2–3 candidate approaches; lead with recommendation; explain trade-offs.
>    3. Open Q&A — user asks back, you ask back, until the goal's design is settled.
>    4. Move to the next goal. Do **not** dump multiple goals' designs in one turn.

Existing steps 2–5 (test strategy, mermaid diagram, key decisions, amendment handling) remain — they're cross-cutting concerns finalized after per-goal discussion settles. Renumber them as the post-loop second phase.

**Add Red Flag entry** to the Red Flags section (at end of design/SKILL.md):

> Batch-presenting designs for multiple goals in one turn — pace the discussion goal-by-goal.

### 2.2 Refinement B — Auto-mode detection in Goals + Design

**Problem.** Goals and Design are collaborative interactive skills. Auto-mode rules ("minimize interruptions, prefer action over planning") subvert the collaboration — the agent is told to skip the turn-by-turn dialogue these skills depend on.

**Sites.**
- `skills/goals/SKILL.md:10` — preamble after `**Announce at start:**`
- `skills/design/SKILL.md:10` — preamble after `**Announce at start:**`

**Fix shape.** Add a new bullet immediately after the announce line in both SKILLs:

> **If auto-mode is detected** (presence of `## Auto Mode Active` system-reminder in current context), surface to the user before the first interactive step: "This skill is collaborative — turn-by-turn dialogue produces better {Goals/Design} quality than autonomous execution. Recommend exiting auto-mode (`Esc` → off) for this phase. I'll proceed in either mode if you prefer."
>
> Do not force the user out of auto-mode; respect their choice. Surface the recommendation explicitly at start.

The recommendation is a one-time surface at skill start, not repeated mid-skill.

## 3. #115: Per-Researcher Dispatch Refinements

### 3.1 Refinement A — Direct-write is the unambiguous default (G13)

**Problem.** During the 2026-04-29 v0.4-bundle Research stage, ~200KB of per-question research was routed back through main chat as text-return then re-emitted via `Write` — likely defensive over-fencing against the F-8 binary subagent worktree wall. User observed: "very slow and context heavy."

**Status (verified by reading current research/SKILL.md).** The SKILL already prescribes direct writes for `research/q*.md` (line 52: "Each subagent writes its own report directly to `{ABS_RESEARCH_DIR}/q{NN}-{type}.md` using the `Write` tool. The orchestrator passes the absolute path into the subagent prompt; subagents do NOT return findings as text."). The defect was at the dispatch-prompt-shape level, not the SKILL design.

**Site.** `skills/research/SKILL.md` § Per-Researcher Subagent → Dispatch parameters list (around line 60–66).

**Fix shape.** Tighten the dispatch parameters subsection by adding an explicit short paragraph immediately after the parameters list:

> **Direct-write contract (unambiguous default).** Per-researcher subagents write their `q*.md` report directly to `output_path` via the `Write` tool. They do **not** return report content as text. Text-return is not used anywhere in the research pipeline — the collation subagent also direct-writes (to the `research/_collated.md` staging filename, which the orchestrator then renames to `research/summary.md`). The staging-filename pattern exists precisely to avoid text-return through main chat. If the orchestrator ever omits `output_path` from a per-researcher dispatch, that is a dispatch defect — fix the orchestrator, do not fall back to text-return.

This pins the contract in dispatch-side prose so future re-templating cannot regress to defensive text-return.

### 3.2 Refinement B — Summary block authored last, placed first

**Problem.** Per-question `research/q*.md` files carry a structured summary block (TL;DR / key findings / surprises / caveats per #95 / G10) at the **top**. Researcher subagents reading the file template top-down may be tempted to write the summary block first — generating it from intent rather than completed findings.

**Site.** `skills/research/SKILL.md` § Per-Researcher Subagent — wherever the per-question report template (or pointer to it in the agent body `agents/qrspi-research-specialist.md`) is referenced.

**Fix shape.** Add an explicit instruction line in the dispatch parameters area (or just below §3.1's direct-write paragraph):

> **Summary-last authoring order.** The per-question report template places the structured summary block (TL;DR / key findings / surprises / caveats) at the **top** of the file — that is the consumer-facing reading order. Authoring order is the inverse: investigate first, draft the full report body, then author the summary block **last**, then place it at the top of the file. Do not generate the summary from intent before the body is complete.

Pair with a one-line reminder comment in the report-template scaffold (in `agents/qrspi-research-specialist.md` — verify exact site during implementation).

## 4. Test Handling

Per qrspi-plus prose-handling memory: decide test handling per change.

| Refinement | Test surface | Decision |
|---|---|---|
| §2.1 per-goal Design loop | Reviewer prose-grep against `For each goal in goals.md` literal in design/SKILL.md | **Skip.** Mechanical content; dialogue ordering is verified at runtime by user, not by static check. |
| §2.2 auto-mode detection (Goals + Design) | Static grep for `Auto Mode Active` literal in both SKILLs | **Add minimal grep guard.** Two-assertion bats test: each SKILL's preamble contains the auto-mode detection paragraph. Cheap to write, catches regression. |
| §3.1 direct-write contract pin | Static grep for "Direct-write contract" header in research/SKILL.md dispatch section | **Add minimal grep guard.** One assertion: research/SKILL.md contains the header literal. Cheap; catches accidental deletion in future edits. |
| §3.2 summary-last instruction | Static grep for "Summary-last" header | **Same as §3.1** — add to the same bats file. |

**Single new bats file:** `tests/unit/test-interactive-skill-prompts.bats` — 3 assertions total (auto-mode in goals, auto-mode in design, direct-write + summary-last in research).

## 5. Sequence

Single PR. Two commits (group by issue):

1. **`docs(research): #115 per-researcher dispatch prompt refinements`** — direct-write contract paragraph + summary-last instruction in research/SKILL.md, plus the research-specialist agent-body reminder line.
2. **`docs(goals,design): #118 per-goal Design + auto-mode detection`** — per-goal loop in design/SKILL.md, auto-mode preamble in goals/SKILL.md + design/SKILL.md, Red Flag entry in design/SKILL.md, plus the new bats guard file (covers both issues).

The bats file lands in commit 2 because that commit is the larger surface change; if landed in commit 1 the auto-mode assertions would fail until commit 2 lands.

Test plan:
- `bats tests/unit/test-interactive-skill-prompts.bats` — 3 assertions pass.
- `bats tests/unit/` — full suite green.
- Manual scan: open design/SKILL.md and verify the per-goal loop reads naturally with surrounding context.

## 6. Backwards Compatibility

Pure prose. No agent file, schema, or routing impact.

The per-goal Design loop changes the **shape** of the discussion the orchestrator runs at runtime; existing in-flight design conversations do not exist as persisted state, so there's no migration. New conversations use the new shape.

The auto-mode detection adds a new soft surface — if no `## Auto Mode Active` system-reminder is present, the detection paragraph instructs no action and the skill proceeds normally.

## 7. Out of Scope

- **Auto-mode detection in non-interactive skills** (Questions, Research, Phasing, Structure, Plan, Parallelize, Implement, Integrate, Test). Those run as subagent pipelines; auto-mode is appropriate. Explicitly not extended in this PR.
- **File layout changes for `research/q*.md`** — summary block stays at the top (it's the right consumer-facing layout). Only the authoring-order instruction changes.
- **Collation subagent's text-return pattern** — still required for `summary.md` per the CC 2.1.x guardrail. §3.1 explicitly preserves this exception.

## 8. Closes

- Closes #118
- Closes #115

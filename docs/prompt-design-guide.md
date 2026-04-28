# QRSPI Prompt Design Guide

**Status:** Active rule set for skill prompt authoring and review.
**Last applied:** 2026-04-25 (Phase 4 refactor + task-sizing amendment).

This document is the canonical rule set for designing and reviewing the prompt content of QRSPI skill files (`SKILL.md`, reviewer templates, hook prompts). It exists so future skill changes — and future skill rewrites when we learn more — apply a consistent, evidence-backed standard rather than re-deriving it each time.

When to use this guide:
- Authoring a new skill or skill section
- Reviewing a skill change (this is the rule set the reviewer template enforces)
- Auditing existing skills for drift (run periodically; the existing pipeline accumulates noise over time)

---

## The seven rules

Every rule has a short statement, an explicit test, and a precedence note where it interacts with other rules.

### R1 — Cut prose the orchestrator doesn't act on

The skill prompt is read by an orchestrator LLM that acts on instructions: what to do, when, in what order, what to avoid. It does NOT act on prose written for human maintainers. Verbosity bias loses up to 60% adherence when prompts grow without adding signal (IFEval++ / LIFBench).

**Test:** If removing the line would change zero orchestration behavior, cut it.

**Cut these categories:**
- Meta-prose about the document ("canonical statement of X", "this section defines Y")
- Cross-skill ownership metadata ("other skills reference back", "owned by skill Z")
- Discoverability hints not load-bearing for the current step ("see also...")
- Historical reasons for a rule (distinct from R2's failure-mode rationale, which IS load-bearing)
- Hook-enforceable rules the orchestrator doesn't need to restate
- Code patterns the agent can discover from existing project files
- Stale code snippets — use file-path or section-heading references instead, never line numbers (they rot)
- Explanatory padding around imperative rules
- Mermaid diagrams that duplicate Process Steps (see R6)

**Keep:**
- Rationale where the failure mode is non-obvious (model would rationalize past — see R2)
- Examples for failure modes you have actually observed (see R4)
- Iron Law / canonical contracts (these ARE the spine)

**Precedence:** R2 > R1, R4 > R1. A `Why:` line preserved by R2 is NOT R1-cuttable padding. An example preserved by R4 is NOT R1-cuttable padding. If a finding cites R1 against content that R2 or R4 explicitly protects, decline the finding.

### R2 — Hot-path imperative, edge-case rationale

Use `"Do X. Do not do Y."` for hot-path rules. Add a one-line `Why:` only where the rule has a non-obvious failure mode that the model would otherwise rationalize past.

**Keep rationale example:** "When reviewers say 'out of scope,' do not extend. Why: new material attracts new review findings — R7-R10 of the Phase 4 refactor found bugs only in scope I had self-induced."

**Drop rationale example:** "Use `git -C /absolute/path ...`, not `cd path && git ...`" — failure mode is obvious to anyone who's used git.

### R3 — Load-bearing rules at the END

Anthropic measured ~30% improvement when critical instructions sit at the end of long context. The "lost in the middle" effect (Liu et al. 2024) is flatter on Opus 4.6 / GPT-5 but not gone, and instruction-following degrades with length faster than retrieval does (LIFBench).

- Repeat the most override-critical rules (Iron Laws) at start AND end of each skill.
- Place Red Flags / Common Rationalizations sections toward the end.
- Use the start position for hard gates (`<HARD-GATE>` blocks) so primacy enforces them.
- Use the end position for restatements so recency reinforces them.

### R4 — Cap examples at 2; contrastive only for observed failure modes

The 2025 Few-Shot Dilemma research shows that past 2-3 examples, frontier models *degrade* on instruction tasks (format mimicry causes copy-paste behavior).

- 0 examples for well-named tasks
- 1-2 examples when output shape is unusual
- Contrastive (good/bad) pairs only for failure modes you've actually observed
- Stop adding examples once two consecutive additions don't move the needle

### R5 — `references/` only when reads are genuinely optional

For Claude Code: spine + references saves zero tokens if the spine always instructs the read. Move content to `references/X.md` only when:

- (a) Most invocations of the skill won't need it (recovery procedures, rare error paths)
- (b) It's for human review, not LLM execution
- (c) A subagent reads it and returns a summary (subagent isolation = real savings)

HumanLayer explicitly warns against over-sharding: *"Do not shard into separate files that require the agent to make tool calls to discover, unless the extra context is incredibly verbose."*

### R6 — Drop Mermaid from skill prompts

Mermaid in skill files duplicates Process Steps below it, renders unreliably (`{slug}` curly-brace collisions with decision-shape syntax — observed bug), serves human readers but not the orchestrator-LLM, and is pure verbosity-bias cost. Drop from all SKILL.md files. Keep at most one in `using-qrspi/SKILL.md` for human pipeline overview navigation.

### R7 — Lexical anchoring with trigger tokens

Use exact terms that appear in trigger output, frontmatter, or hook output. Mitigates NoLiMa-style mid-context degradation when a rule must live mid-skill.

**Better:** *"When `state.json` shows `current_step: implement` and `phase_start_commit` is set..."*
**Worse:** *"When the state machine indicates the implement phase is active and the phase boundary has been recorded..."*

---

## Cross-cutting prompt-engineering principles

These come from the Phase 2 prompt-best-practices research and apply across all skills:

- **Aim for the minimal set that fully specifies behavior.** "Minimal" does NOT mean "short" — Anthropic's own substantive prompts run 200-450 lines.
- **XML tags structure distinct content types.** Use `<HARD-GATE>`, `<BEHAVIORAL-DIRECTIVES>`, etc. — Claude was specifically trained to treat XML tag boundaries as semantic separators.
- **Provide rationale alongside prohibitions.** "Never use ellipses" is weaker than "Never use ellipses — the TTS engine cannot pronounce them." The model generalizes from the explanation.
- **Reduce aggressive MUST/CRITICAL language for Claude 4.x.** Opus 4.5+/4.6 are more responsive to system prompts than older models; aggressive phrasing causes overtriggering.
- **Positive framing outperforms negative framing.** Reframe rules as positive obligations ("Always encourage a review after changes") rather than prohibitions ("Do not skip the review") where possible.
- **Wrap examples in `<example>` tags.** Untagged examples can be misinterpreted as directives.

---

## The finding-type gate

Reviewers (both Claude and Codex) are evaluated against this gate. The gate exists because earlier review rounds (Phase 4 R7-R10) accumulated self-induced detail-bloat — reviewers proposed elaborations that I implemented, which then attracted new findings on the elaborations.

### Blocking findings (fix before round closes clean)

| Category | Definition |
|---|---|
| **architectural** | Structural defect: misplaced rule, broken cross-reference, ambiguous orchestration step, contradicts an existing rule in same skill or in `using-qrspi` |
| **factual** | Claim contradicts the codebase, the frontmatter schema, the source research, or itself |
| **contradiction** | Internal contradiction (e.g., new Red Flag conflicts with new Common Rationalization, new Iron Law conflicts with the section it summarizes, two restatements use inconsistent vocabulary) |
| **rule-violation** | R1-R7 misapplied OR a pattern the rule explicitly says to cut/keep was missed. Reviewer must cite the rule ID and the line/section. |

### Declined findings (note in summary, do NOT fix)

| Category | Why declined |
|---|---|
| **detail-suggestion** | "Add more detail," "could be clearer," "consider expanding" — these grow length without adding signal (R1) |
| **example-suggestion** | "Add an example for case Z" — reviewers cannot generate the observed-failure evidence R4 requires |
| **scope-extension** | Suggestions to extend into adjacent material the reviewer themselves marked pre-existing or out-of-scope |

### Loop convergence

A round is "clean" when both reviewers find no blocking findings. Declined detail-suggestions do NOT block convergence. Hard cap: **5 rounds**. Even with the gate, hard-cap to limit residual churn risk. If round 5 still has blocking findings, present them to the user along with what was fixed and let the user decide whether to ship or iterate.

---

## The review workflow

For any skill change — including small amendments — apply this workflow:

1. **Draft** the change against the seven rules. Write a self-review pass before dispatching reviewers.
2. **Round 1: Dispatch both reviewers in parallel.** Claude (via the Agent tool) and Codex (via codex-companion). Both receive the same prompt: the diff, the rule set, the gate, and the specific things to check. Run in parallel — neither blocks the other.
3. **Apply the gate** to all returned findings. Fix blocking findings; note declined findings in a summary.
4. **Round N+1: Dispatch both reviewers again** against the updated artifact. Continue until a round closes clean (no blocking findings from either reviewer) or 5 rounds have run.
5. **Present to user.** Always state the review status: "Reviews passed clean in round N" OR "Reviews found issues in round N which were fixed but not re-verified" OR "Hit 5-round cap — N blocking findings remain, here they are."

Codex catches more findings than Claude. The Phase 4 task-sizing review demonstrated this clearly: 8 blocking findings caught across 5 rounds, 6 of 8 from Codex. Both reviewers are required.

---

## How to write a reviewer prompt

A reviewer prompt has six parts:

1. **What is being reviewed** (file paths + diff path + concise change description)
2. **Why the change exists** (the motivating problem; the empirical grounding if numerical claims are involved)
3. **The rule set to apply** (R1-R7, the cross-cutting principles, link to this guide)
4. **The finding-type gate** (blocking categories + declined categories)
5. **Specific things to check** (concrete checks that derive from this particular change — e.g., "is the closed exception set stated identically in all 6 locations?")
6. **Output format** (terse, blocking findings first, declined findings noted, status line)

Reviewer prompts should not duplicate the rule definitions — point to this guide. Past reviewer prompts (`/tmp/plan-sizing-review-prompt*.md` from the 2026-04-25 task-sizing amendment) are the canonical templates.

---

## Source research

The seven rules are derived from:

- **HumanLayer canonical sources** (Dex Horthy QRSPI talks, ACE-FCA essay, 12-factor agents repo) — for prompt structure, sharding, and the "<40 instructions per step" framing
- **Anthropic prompt-engineering documentation** (effective context engineering for AI agents, multishot prompting, long-context prompting) — for XML tag usage, rationale-with-prohibitions, lost-in-the-middle, end-of-context placement
- **OpenAI Codex harness engineering** (AGENTS.md guidance, "give Codex a map" post) — for ~100-line target, "imperative phrasing > prose," structural enforcement over instructional discipline
- **2024-2025 prompt-engineering research** (Liu et al. 2024 "Lost in the Middle"; IFEval++; LIFBench; NoLiMa; the 2025 Few-Shot Dilemma paper) — for verbosity bias, instruction-following degradation, lexical anchoring, the example cap

Two working documents in this repo carry the original derivation if you need to re-derive or update the rules:
- Phase 4 refactor design doc (in the project repo: `general2/docs/superpowers/specs/2026-04-25-qrspi-skill-refactor-design.md`)
- Phase 2 prompt-best-practices research (in the project repo: `general2/docs/qrspi/2026-04-06-phase4-hooks/phases/phase-02/research/prompt-best-practices.md`)

---

## When to re-run this guide against the codebase

The QRSPI skill prompts will accumulate drift over time as features get added. Schedule a periodic audit:

- After every major Phase ships
- When a new Claude or Codex model lands (rules may need recalibration)
- When you notice a skill is failing to follow its own instructions
- Before any significant pipeline restructuring

The audit pass: for each skill file, ask "does it still satisfy R1-R7? Are there new patterns from real usage that should become rules?" If new evidence emerges, update this guide first, then re-apply across the skills.

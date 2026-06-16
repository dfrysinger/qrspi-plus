# QRSPI Prompt Design Rules

**Status:** Active rule set for skill prompt authoring and review.
**Last applied:** 2026-06-02 (rules-file relocation + eight updates A-H). <!-- evergreen-exempt -->

This document is the canonical rule set for designing and reviewing the prompt content of QRSPI skill files (`SKILL.md`, reviewer templates, hook prompts). It exists so future skill changes — and future skill rewrites when we learn more — apply a consistent, evidence-backed standard rather than re-deriving it each time.

When to use this guide:
- Authoring a new skill or skill section
- Reviewing a skill change (this is the rule set the reviewer template enforces)
- Auditing existing skills for drift (run periodically; the existing pipeline accumulates noise over time)

---

## The eight rules

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

**Named antagonist patterns (CD-2).** Six categories of prose that fail the R1 test and must be cut from any LLM-consumable artifact (substitute pattern in parentheses):

- **Dialogue exhaust** — back-and-forth negotiation text, prior-round findings, "we agreed that…" summaries. (Substitute: the locked decision itself, stated as present-tense fact.)
- **Session/drafting notes** — "I initially wrote X but then realized Y," "as a first pass…," "TODO: revisit." (Substitute: the final decision only; if genuinely undecided, mark with `status: draft` on the artifact, not inline.)
- **Version-history narration** — "in v0.7.1 this was different," "previously the rule said…." (Substitute: the current rule, verbatim; history lives in git log, not prompt prose.) <!-- evergreen-exempt -->
- **Inside baseball** — references to internal process mechanics that the LLM consumer has no action to take on. (Substitute: cut; if action is required, state the action directly.)
- **Compaction-loss recovery notes** — "if you resumed after /compact, re-read…," "context may have been lost." (Substitute: compaction-resilient design per the cross-cutting principle below — instruct incremental persistence and a recovery diagnostic in the SKILL.md itself, not inline in the artifact.)
- **Failure-modes-prevented lists** — "this design prevents X, Y, Z failures." (Substitute: cut; the design's correctness is evaluated by reviewers, not narrated by the author.)

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

Anthropic measured ~30% improvement when critical instructions sit at the end of long context. The "lost in the middle" effect (Liu et al. 2024) is flatter on Opus 4.6 / GPT-5 but not gone, and instruction-following degrades with length faster than retrieval does (LIFBench). May 2026 status: confirmed on Opus 4.7-high and GPT-5.5 (end-of-context placement still yields measurable improvement; the magnitude is reduced at shorter context lengths but the ordering principle holds). GPT-5.3-Codex: confirmed (instruction-following at end of context window measurably stronger than mid-context). Sonnet 4.6: confirmed (consistent with Opus 4.6 pattern).

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

For agent platforms that pre-load skill text (Claude Code, Codex CLI, Copilot CLI, and equivalent hosts): spine + references saves zero tokens if the spine always instructs the read. Move content to `references/X.md` only when:

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

### R8 — Prose density: short declarative sentences, full behavioral precision

Tighten every sentence to its shortest declarative form that still carries full behavioral precision and any load-bearing rationale. Length without signal degrades adherence. Length with signal is the spec.

**Reviewer test:** Could this sentence be shorter without losing behavioral precision OR load-bearing rationale?

If the answer is yes, tighten. If the answer is no, leave the sentence alone.

**Tightening patterns.**

| Pattern in current prose | Tightened form | Why it works |
|---|---|---|
| "It is important to note that the orchestrator must read the artifact." | "Read the artifact." | Imperative voice; meta-emphasis cut. |
| "In order to validate the diff, run the lint script." | "Run the lint script to validate the diff." | Subordinate-clause flip removes "in order to". |
| "The reason this matters is that downstream consumers grep for the literal token." | "Downstream consumers grep for the literal token." | Filler opener removed; the fact carries the rationale. |
| "There are several cases in which the dispatch may halt." | "Dispatch halts when:" followed by a bulleted list. | Existential opener replaced by a direct list. |
| "We will now describe the procedure for handling failures." | Cut entirely; the procedure that follows speaks for itself. | Meta-announcement of the next paragraph adds zero signal. |
| "This section provides guidance on how to author the rubric." | "Author the rubric as follows:" | Meta-prose about the document body collapsed into the imperative. |

### What NOT to tighten

The following categories carry behavioral or audit weight that paraphrase destroys. Leave them at their current wording even when a shorter form exists:

- **Load-bearing repetition.** A phrase intentionally restated for emphasis or clarity across sections. The repetition IS the signal; collapsing it removes the emphasis the author put there on purpose.
- **Verbatim test-pinned strings.** Anchor phrases that `tests/**/*.bats` files match literally via `grep -F`, `grep -qxF`, or equivalent. Any string reachable from a bats test as a literal match is a contract — tightening it turns the test red.
- **Iron-law clauses.** Sentences whose verbatim form is the load-bearing assertion (e.g., contracts, named invariants, "MUST"/"NEVER" rules). The exact wording is the spec; paraphrase weakens the assertion.
- **Anchor phrases preserved verbatim across edits.** Paraphrase breaks the audit handle, even when shorter wording exists.
- **Verbatim contracts, named diagnostic strings, and exact frontmatter field values.** These are audit handles, not prose.
- **One-line `Why:` rationale where the failure mode is non-obvious.** Tighten only the surrounding sentence; keep the rationale.
- **Examples whose specificity carries the failure mode being illustrated.** Tightening removes the evidence.
- **Imperative-voice rules already stated as "Do X. Do not do Y."** These are already at the floor.
- **Lists whose items each name a distinct behavior.** Merging items hides the named behaviors.

Rule of thumb: before tightening any sentence, `grep -rF "<the sentence>" tests/` — if anything matches, the sentence is test-pinned and you must leave it alone.

**Guardrail — minimal does NOT mean short.** R8 tightens each sentence. R8 does not delete required behavior. The cross-cutting principles below state that the goal is the minimal set that fully specifies behavior, and that substantive prompts run two-hundred-plus lines. R8 is bounded by behavioral coverage. Shorten sentences. Preserve every load-bearing instruction, contract, anchor phrase, named diagnostic, and rationale the artifact requires.

---

## Cross-cutting prompt-engineering principles

These come from the Phase 2 prompt-best-practices research and apply across all skills:

- **Aim for the minimal set that fully specifies behavior.** "Minimal" does NOT mean "short" — Anthropic's own substantive prompts run 200-450 lines.
- **XML tags structure distinct content types.** Use `<HARD-GATE>`, `<BEHAVIORAL-DIRECTIVES>`, etc. — Claude was specifically trained to treat XML tag boundaries as semantic separators.
- **Provide rationale alongside prohibitions.** "Never use ellipses" is weaker than "Never use ellipses — the TTS engine cannot pronounce them." The model generalizes from the explanation.
- **Reduce aggressive MUST/CRITICAL language for Claude 4.x.** Opus 4.5+/4.6 are more responsive to system prompts than older models; aggressive phrasing causes overtriggering.
- **Negation works in modern LLMs (Claude 4+, GPT-4+) when paired with (1) a positive substitute, (2) a named antagonist label, and (3) a decision rule.** Bare "do not X" without a substitute is the GPT-3-era anti-pattern — it leaves the model without a replacement behavior and degrades under paraphrase. The Iron Laws, Red Flags, and Common Rationalizations sections in QRSPI skills demonstrate the paired pattern in practice (named antagonist + substitute + "if you find yourself doing X, do Y instead").
- **Wrap examples in `<example>` tags.** Untagged examples can be misinterpreted as directives.
- **Evergreen Litmus Test — before writing any paragraph in an artifact governed by `status: draft → approved`, apply the two-question filter:** (1) does this paragraph read true if every prior draft were deleted? (2) is the subject the WHAT being designed, or the dialogue that produced it? If either filter fails, the paragraph is dialogue exhaust — strip it. (Source: CD-2 Evergreen-Output Rule.)
- **Anchor phrases — verbatim audit handles.** When a phrase must be preserved verbatim across edits (e.g., a verbatim Sub-Rule B prose-design block, the locked text in CD-2's Evergreen-Output Rule), call it an "anchor phrase" in the surrounding prose. Anchor phrases are the audit handles reviewers and authors use to detect silent drift.
- **Compaction-resilient prompt design — when an orchestrator-driven skill spans enough decisions to risk mid-phase `/compact` firing (Goals, Design at scale), the SKILL.md prose must (1) instruct incremental persistence to the final artifact under `status: draft`, (2) instruct a recovery diagnostic on resume, and (3) instruct the orchestrator to re-read the in-progress artifact to enumerate locked decisions before continuing.** Presence ≡ locked; no placeholder bodies.

---

## The finding-type gate

Reviewers (both Claude and Codex) are evaluated against this gate. The gate exists because earlier review rounds (Phase 4 R7-R10) accumulated self-induced detail-bloat — reviewers proposed elaborations that I implemented, which then attracted new findings on the elaborations.

### Blocking findings (fix before round closes clean)

| Category | Definition |
|---|---|
| **architectural** | Structural defect: misplaced rule, broken cross-reference, ambiguous orchestration step, contradicts an existing rule in same skill or in `using-qrspi` |
| **factual** | Claim contradicts the codebase, the frontmatter schema, the source research, or itself |
| **contradiction** | Internal contradiction (e.g., new Red Flag conflicts with new Common Rationalization, new Iron Law conflicts with the section it summarizes, two restatements use inconsistent vocabulary) |
| **rule-violation** | R1-R8 misapplied OR a pattern the rule explicitly says to cut/keep was missed. Reviewer must cite the rule ID and the line/section. |

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
3. **The rule set to apply** (R1-R8, the cross-cutting principles, link to this guide)
4. **The finding-type gate** (blocking categories + declined categories)
5. **Specific things to check** (concrete checks that derive from this particular change — e.g., "is the closed exception set stated identically in all 6 locations?")
6. **Output format** (terse, blocking findings first, declined findings noted, status line)

Reviewer prompts should not duplicate the rule definitions — point to this guide.

---

## Source research

The rules are derived from:

- **HumanLayer canonical sources** (Dex Horthy QRSPI talks, ACE-FCA essay, 12-factor agents repo) — for prompt structure, sharding, and the "<40 instructions per step" framing
- **Anthropic prompt-engineering documentation** (effective context engineering for AI agents, multishot prompting, long-context prompting) — for XML tag usage, rationale-with-prohibitions, lost-in-the-middle, end-of-context placement
- **OpenAI Codex harness engineering** (AGENTS.md guidance, "give Codex a map" post) — for ~100-line target, "imperative phrasing > prose," structural enforcement over instructional discipline
- **2024-2025 prompt-engineering research** (Liu et al. 2024 "Lost in the Middle"; IFEval++; LIFBench; NoLiMa; the 2025 Few-Shot Dilemma paper) — for verbosity bias, instruction-following degradation, lexical anchoring, the example cap

The load-bearing derivations for the rules are inlined in this file (each rule carries its source citation inline). For broader research context, the v0.7.2 release research summary at `docs/qrspi/2026-05-30-v072-release/research/summary.md` covers Q1-Q5 (prompt-prose detection, rules applicability across host platforms, model-era calibration, content-semantic vs. path heuristics, and vendor-neutrality findings). No external `general2/...` paths — those working documents predated this repo's self-contained structure and are not accessible at plugin install time. <!-- evergreen-exempt -->

---

## When to re-run this guide against the codebase

The QRSPI skill prompts will accumulate drift over time as features get added. Schedule a periodic audit:

- After every major Phase ships
- When a new Claude or Codex model lands (rules may need recalibration)
- When you notice a skill is failing to follow its own instructions
- Before any significant pipeline restructuring

The audit pass: for each skill file, ask "does it still satisfy R1-R8? Are there new patterns from real usage that should become rules?" If new evidence emerges, update this guide first, then re-apply across the skills.

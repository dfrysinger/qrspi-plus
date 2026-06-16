---
status: draft
audience: v0.7.4 Goals round (prompt-corpus quality cluster)
captured: 2026-06-14
author: autopilot main agent + 4 parallel adversarial reviewers (Opus 4.7 high)
---

# QRSPI v0.7.3 Prompt Corpus Audit — stack-ranked improvement backlog

End-to-end adversarial audit of every prompt file under `skills/` and
`agents/` against `skills/_shared/prompt-design-rules.md` (R1–R8 + the
cross-cutting principles + the finding-type gate), driven by four parallel
Opus 4.7-high reviewers each owning a coherent slice.

Per-slice findings live in:

- `slice1-heavyweight.md` — using-qrspi / implement / plan / integrate / test (5 spines, 18 findings)
- `slice2-pipeline.md` — goals / questions / research / research-isolation / design / structure / phasing / parallelize / replan (9 spines, 21 findings)
- `slice3-shared.md` — reviewer-protocol / implementer-protocol / prompt-prose-* / all `_shared/*` (30 files, 18 findings)
- `slice4-agents.md` — all 42 agents under `agents/` (22 findings)

Total raw findings: 79. After dedup and clustering: 13 stack-ranked
improvement items (item #0 added in the §1a measurement re-audit), of
which 4 are **blocker-class** (silent correctness defects active today
in the shipped v0.7.3 prompts) and 1 is **architectural-high** (the
runtime-token win @dfrysinger originally aimed at in v0.7.3 — see §1a).

---

## 1. Size delta — v0.7.2 → v0.7.3

The v0.7.3 trim succeeded on the per-spine axis (R8 + R5 sharding) but
shifted bulk into `references/` files. Net char count down 2.6%; net file
count up 72%.

**Total prompt corpus:**

| Metric | v0.7.2 | v0.7.3 | Δ |
|---|---:|---:|---|
| Files | 91 | 157 | +72% |
| Lines | 13,150 | 13,494 | +2.6% |
| Chars | 1,244,733 | 1,212,387 | −2.6% |

**SKILL.md trims (sorted by largest cut):**

| file | v0.7.2 lines | v0.7.3 lines | Δ % |
|---|---:|---:|---:|
| skills/implement/SKILL.md | 1,451 | 513 | −65% |
| skills/using-qrspi/SKILL.md | 1,262 | 622 | −51% |
| skills/plan/SKILL.md | 726 | 446 | −39% |
| skills/goals/SKILL.md | 499 | 301 | −40% |
| skills/design/SKILL.md | 469 | 308 | −34% |
| skills/replan/SKILL.md | 429 | 310 | −28% |
| skills/parallelize/SKILL.md | 429 | 328 | −24% |
| skills/test/SKILL.md | 377 | 309 | −18% |
| skills/phasing/SKILL.md | 305 | 285 | −7% |
| skills/integrate/SKILL.md | 319 | 307 | −4% |
| skills/questions/SKILL.md | 184 | 184 | 0% |
| skills/research/SKILL.md | 252 | 252 | 0% |
| skills/structure/SKILL.md | 283 | 283 | 0% |
| skills/research-isolation/SKILL.md | 77 | 77 | 0% |
| skills/reviewer-protocol/SKILL.md | 287 | 287 | 0% |
| skills/implementer-protocol/SKILL.md | 270 | 288 | +7% |
| skills/prompt-prose-{reviewer,writer}/SKILL.md | 17 | 17 | 0% |

**Observation.** The six untouched skills (questions / research /
structure / research-isolation / reviewer-protocol / two prompt-prose
SKILLs) are likely the largest remaining R8 headroom — they predate the
v0.7.3 trim discipline.

**Agent files:** essentially unchanged in v0.7.3 (Δ +1 to +9 lines per
file). Bulk of v0.7.3 work was on skill spines; the 42 agent prompts
under `agents/` were not part of the trim pass and carry significant
drift accumulated since v0.7.1 (see items #4 / #5 below).

### 1a. The trim numbers above are mostly illusion (`!cat` build-inlining defeats the G9 load-on-demand intent)

The percentages in §1 measure **source** SKILL.md line counts. They
are not what reaches the agent — and more importantly, the
`references/` split was **architecturally meant** to deliver runtime
load-on-demand savings, not editing-time source reduction.

`tools/build-plugin.mjs:117-118` and
`scripts/resolve-skill-includes.sh:48-66` both implement the
`!cat <relpath>` directive: at plugin build time (and at test-extract
time), every `!cat references/foo.md` line in a SKILL.md is replaced
inline with the contents of `references/foo.md`. The split into
`references/` files therefore delivers **no runtime token savings** —
the content reaches the agent on every session load.

**This contradicts the explicit G9 design intent.** v0.7.3 design.md
named two mechanisms with different intended semantics
(`docs/qrspi/2026-06-04-v073-release/design.md:517-519`):

| Tier | Intended mechanism | Intended cost |
|---|---|---|
| Multi-skill load-bearing boilerplate (`_shared/`) | `!cat`-inlined | paid every load — correct |
| Optional / worked-examples / rare-path content (`references/`) | **Read on-demand** | **"zero active cost when not needed"** — MISIMPLEMENTED |

What shipped: both wired through `!cat`. Concrete proof:
`using-qrspi/SKILL.md` has **28** `!cat skills/using-qrspi/references/...`
directives and **zero** prose pointers asking the agent to Read a
`references/` file on demand. Same pattern in `implement/`, `plan/`,
`design/`. The runtime-cost-bearing mechanism was applied to the
"zero active cost" tier.

Source vs `resolve-skill-includes.sh`-expanded line counts:

| skill | source | expanded | "trim" reality |
|---|---:|---:|---|
| implement/SKILL.md | 513 | **1,175** | source −65% but expanded prompt still 1,175 lines |
| using-qrspi/SKILL.md | 622 | **1,086** | source −51% but expanded prompt still 1,086 lines |
| plan/SKILL.md | 446 | **618** | source −39% but expanded +172 lines via !cat |
| design/SKILL.md | 308 | **412** | source −34% but expanded +104 lines via !cat |
| parallelize/SKILL.md | 328 | **435** | +107 expanded |
| goals/SKILL.md | 301 | **398** | +97 expanded |

**G9 outcome target vs delivered.** Design.md:508 set the target:
"Total active-context skill footprint per typical session drops from
~80-95K tokens to ~15-30K tokens." Actual landing is estimated
~50-65K — real progress from the prose-density (R8) pass and
script-mechanic deletion, but the single biggest lever
(load-on-demand `references/`) was never pulled.

**What v0.7.3 DID actually deliver on G9:**

- ✅ Centralized 5 `_shared/` snippets with real reuse (genuine R5 win)
- ✅ R8 prose-density rule + density pass on heavy spines (genuine
  ~15-20% runtime trim on expanded counts)
- ✅ Script-mechanic restatement deletion (real footprint win)
- ❌ Load-on-demand `references/` (zero delivery; the files exist but
  inline at build time)

The remaining ~70% of G9's runtime delivery is the work captured in
new backlog item **#0** below — **not "new architectural work to
consider," but "finish the G9 outcome that shipped misimplemented."**

### 1c. The G9 gate test was rigged — it under-measured shipped footprint

The acceptance test `tests/acceptance/v07-phase1-test-phase/test-g9-footprint.bats`
that the v0.7.3 release passed at "29,626 tokens, 374-token margin
under the 30,000 gate" measures something **different** from what
ships. The measurement script
`scripts/measure-active-footprint.sh:155` resolves `!cat` directives
only for `_shared/` paths:

```python
CAT_RE = re.compile(r'^!cat[ \t]+(skills/_shared/[^\s]+\.md)[ \t]*$')
```

Compare to `tools/build-plugin.mjs:117-118` and
`scripts/resolve-skill-includes.sh:48` which both resolve **any**
`!cat <relpath>` — including `references/`. So the build pipeline
inlines `references/` content into the shipped SKILL.md, but the gate
test pretends it doesn't. The 29,626-token number is the source-file
view; the actual shipped active-context footprint is materially
larger by the sum of every `references/*.md` file `!cat`-ed into an
active skill.

**Implication.** The "G9 gate met" claim was a measurement artifact,
not a real win. The runtime context that ships to the host agent
exceeds the 30K target by an unmeasured margin (rough estimate: heavy
spines like implement and using-qrspi alone contribute ~2× the source
line count once references are expanded, so the real shipped footprint
is plausibly closer to ~50-65K vs the 29,626 reported).

**v0.7.4 fix.** Either (a) fix item #0 (convert `references/` to
Read-on-demand so the source view becomes the runtime view), or (b)
fix the measurement script to expand `references/` `!cat` lines too
and re-run the gate honestly. (a) is the right fix; (b) is the
honesty backstop if (a) gets deferred. Both should land — the lint
should match the build.

---

### 1d. Are the 61 `references/*.md` files justified?

Today, **as `!cat`-inlined files**, no — each `references/*.md` has
exactly **1 consumer** (its parent SKILL.md) and contributes the same
runtime tokens as inline prose would. The split is paying file-system
indirection cost at edit time and measurement-clarity cost
(source-line trim numbers mislead) for no runtime token savings and
no reuse benefit. The only durable benefit is **R5 editing
ergonomics** (one concern per file, sub-rules editable in isolation),
which is real but is a much smaller win than the §1a numbers implied.

**As Read-on-demand files** (item #0's fix), the split becomes
properly justified — the runtime cost falls to "zero active cost
when not needed" per design intent, and the editing-ergonomics win
stays. The files are correct; the loading mechanism is wrong. Fix
the loading mechanism, not the files.

---

## 2. Existing prompt-related GitHub issues collated

128 open issues match the prompt-audit keyword sweep. The 39 most
directly applicable, grouped by theme:

**Shared-asset adoption / drift (covered by this audit):**
- #277 — Two divergent plugin manifest files
- #278 — `_shared/codex/launch-await-pattern.md` has zero consumers (✅ verified by slice 3 F04)
- #279 — `_shared/precondition-block.md` adopted by 1 of 12+ consumers (✅ verified by slice 3 F05)
- #310 — Skill body bloat + stale dispatch-script references

**Verifier / Cite Check infrastructure:**
- #270 — Stronger Cite Check infrastructure
- #281 — Verifier rubric: scoring-axis-of-truth undocumented
- #282 — Verifier rubric: no "cited content deleted" carve-out
- #293 — Verifier sporadic 0-turn empty-response flake → auto-retry
- #305 — Finding-verifier false-negatives ID-hygiene findings by grounding rubric in CONTRIBUTING.md instead of implementer-protocol/SKILL.md
- #307 — Verifier malformed `defect_class` tokens lack 'unspecified' fallback

**Reviewer / agent contract drift:**
- #283 — Copilot CLI subagents refuse /tmp file ops
- #287 — Narrow contract breaks under 2-commit-per-round (`HEAD~1` resolves wrong) (✅ verified by slice 4 F02; root cause now mapped)
- #288 — Codex reviewer dispatches return chat-only despite frontmatter tools: Read, Write
- #291 — `qrspi-finding-verifier` hard-codes `CLAUDE.md` (Claude-leak in host-agnostic agent) (✅ verified by slice 4 F03)
- #294 — Codex reviewers never honor per-finding disk-write contract on Copilot CLI task-tool transport
- #295 — Apply-fix per-round SHA anchor pattern self-referential
- #296 — Apply-fix protocol step 4 verifier upstream-artifact list missing 'plan' step
- #297 — Canonize `artifact_path` as primary reviewer-dispatch input for large artifacts
- #306 — Release-wide `[Tnn]` task-ID marker leak; ID-hygiene ban not enforced

**Goals / Design / Phasing / Structure (scope, altitude, vocab):**
- #267 — Automated sweep-aware test discovery
- #269 — G18 follow-up: scope-completeness reviewer + automated gate-time grep
- #274 — Goals premise validation against existing Research
- #275 — QRSPI goal-lifecycle disposition vocabulary (3 "moot" flavors)
- #276 — Goals/Design canonical-helper drift sweep
- #285 — Design SKILL.md lacks incremental persistence
- #286 — Phasing skill: collapse slice-within-phase + relax Phase 1 PoC
- #289 — Phasing skill prompts altitude-incorrect acceptance criteria
- #290 — Structure skill: explicitly name "gaps between solutions"
- #292 — Plan SKILL: enhanced task-spec shape
- #298 — Plan-author over-scopes absorbed/moot goal IDs

**Misc:**
- #271 — Reviewer-model calibration mitigation
- #272 — Path-based artifact passing for Codex-as-third-party
- #301 — Test-phase reviewer-fan-out opt-in
- #303 — OBC HARD-RULE observable beyond Implement
- #304 — Doc backlog: platform-directory-pattern + token-cost-principles
- #309 — `extract_section` helper uses predictable /tmp path
- #315 — Capture run artifact-dir once at run start
- #316 — Standardize CLI flag style across scripts

**Retrospective from v0.7.3 Implement (`implement-retrospective.md`):**
A–H opportunities filed against using-qrspi / implement / plan /
integrate / replan, targeting Implement-phase autonomy guardrails
against defensive budget-thinking. Sequenced for v0.7.4 as goal cluster
G-RETRO. Orthogonal to this audit (this audit covers prompt-content
quality; the retrospective covers main-agent behavioral guardrails) —
both should run in v0.7.4 in parallel.

---

## 3. Stack-ranked improvement backlog

Items ranked by **(blast radius × correctness severity ÷ fix cost)**.
Each item names: the canonical evidence pointer into the per-slice
reports, the existing GH issue(s) it would close, the proposed fix
shape, and the rationale for the rank position.

---

### #0 — TOP PRIORITY (architectural) — Finish v0.7.3 G9: relocate misplaced content + delete-first the "optional"

**Slices:** cross-cutting (surfaced by the §1a measurement re-audit)
**Existing issues:** related: #297, #310
**Severity:** highest non-defect work in v0.7.4 — the headline v0.7.3 G9 outcome that shipped misimplemented

**The mis-shipped intent.** Per §1a / design.md:517-519, v0.7.3
intended `references/*.md` to be **Read on-demand** ("zero active
cost when not needed"). Implementation `!cat`-inlined all 61 files
at build time. Source-line trims (implement −65%, etc.) are mostly
illusion. G9 design target: 80-95K → 15-30K active context; estimated
actual landing ~50-65K. The remaining ~70% of G9's runtime delivery
is a content-relocation sweep — **no script changes needed**.

**Mechanism hierarchy (cleanest → last resort).**

| # | Mechanism | When to use |
|---|---|---|
| 1 | **Inline in agent file body** | Subagent-only content unique to one subagent |
| 2 | **`skills: [topic]` frontmatter** | Subagent-only content reused across ≥2 subagents. Dispatcher already auto-bundles (`dispatch-agent.sh:1226-1262`). |
| 3 | **`!cat <path>` in host SKILL.md** | Content the host loads every session |
| 4 | **Prose "Read on demand" pointer in host SKILL.md** | Host-side optional content that **survived the skepticism test** below |
| 5 | **Delete** | First-resort treatment for anything claimed as "optional" |

**Do NOT use:** `!cat` in agent files. Two reasons: (a) Claude Code
may not support `!cat` in agent files at runtime (the build pipeline
expands it, but the runtime loader's behavior is unverified for
agent files specifically); (b) the `skills: [topic]` mechanism is
strictly cleaner for any content meriting its own file. If content
is unique to one agent, inline it; if shared, use `skills:`.

**Skepticism principle for "optional" content.** When classifying a
block as "optional / rare-path / worked-example," **first try
deleting it outright**, not converting it to a prose-on-demand
pointer. If the next 2-3 production runs of the affected pipeline
step show no degradation, the deletion stands. If a run degrades,
either restore the block inline (it wasn't optional) or convert to a
load-on-demand pointer (it was optional but truly load-bearing). The
default for "optional" should be **delete first, prove necessity to
restore**. This prevents the corpus from accumulating prose that
nobody actually needed but everyone was too cautious to drop.

**Concrete task set for v0.7.4.**

**0.1 — Host SKILL.md `!cat` sweep.** For every `!cat <path>` in a
host SKILL.md (~30 directives across the heavy spines), classify:

- **host-only** → keep `!cat`-ed.
- **subagent-only, used by 1 agent** → delete `!cat` line; **inline**
  the content into that agent file's body.
- **subagent-only, used by ≥2 agents** → delete `!cat` line; promote
  to `skills/<topic>/SKILL.md`; add `<topic>` to the relevant agents'
  `skills:` frontmatter.
- **both host and subagent** → promote to `skills/_shared/<topic>.md`;
  `!cat` from host SKILL.md AND name in the subagent's `skills:`
  frontmatter (or `!cat` in the agent file — choose the path Claude
  Code's runtime actually supports for agent files; verify before
  shipping).
- **"optional" / rare-path / worked-examples** → **delete first.**
  Only restore as inline content or load-on-demand pointer if a
  subsequent run actually degrades.

**0.2 — Agent-file duplication sweep (the bigger win nobody has
measured yet).** Audit the 42 agent files for repeated prose:

- The 7 `*-scope-reviewer.md` agents share a 4-step procedure (read
  owns-defers → load artifact → 3-check → write findings) plus
  Diff-File Read Pattern and Scope Hint paragraphs. Factor into a
  new `skills/scope-reviewer-protocol/SKILL.md`; each scope-reviewer
  agent declares `skills: [reviewer-protocol, scope-reviewer-protocol]`
  and shrinks to ~10 lines of per-artifact specifics.
- The 10 quality-reviewer agents (`qrspi-X-reviewer.md`, ~50-145
  lines) likely have similar shared skeletons. Investigate and
  factor.
- The Diff-File Read Pattern and Scope Hint paragraphs probably
  appear (verbatim or near) in 20+ agents. Audit and consider
  pulling into `reviewer-protocol/SKILL.md` (which is already bundled
  into every reviewer dispatch — zero new mechanism).

**0.3 — Fix the G9 footprint test.**
`scripts/measure-active-footprint.sh:155` only expands `_shared/`
`!cat` directives. Update the regex to expand any `!cat <path>` (or
better: invoke the same `resolve-skill-includes.sh` the build pipeline
uses, so the test and build cannot disagree). Re-run the G9 gate
honestly against the post-relocation corpus.

**0.4 — Re-measure and document.** Update §1a's table with delivered
expanded line counts post-sweep. The G9 outcome (80-95K → 15-30K)
becomes the v0.7.4 success criterion.

**Why this is THE v0.7.4 priority.** Every other backlog item adds
prose. This one is the only item that materially reduces the host
context window, and it's the one we already paid for in v0.7.3
without actually delivering. The blocker items #1-#4 should still
hotfix first (correctness > perf), but #0 is the strategic
centerpiece of v0.7.4 — without it, v0.7.4 ships another release of
prose churn without solving the original footprint problem.

---

### #1 — BLOCKER — Sweep `codex_reviews:` → `second_reviewer:` across 11 consumer skills

**Slices:** 1.F01 + 1.F05 + 1.F15 + 1.F19, 2.F01 + 2.F08
**Existing issues:** none filed (this is a fresh find — surprising; the orchestrator-side rename clearly missed the consumer-side sweep)
**Severity:** blocker
**Blast radius:** every QRSPI run after v0.7.3 that sets `second_reviewer: true` in config.md

**Problem.** `skills/using-qrspi/SKILL.md` line 112 declares
`codex_reviews:` removed — "a stray `codex_reviews:` field in
config.md is a hard validation error, never silently aliased." But
**11 places across 11 files** still read the field by its old name:

| file | line(s) |
|---|---|
| skills/using-qrspi/SKILL.md | 411 (Apply-fix step 2 schema-violation guard — the gate itself reads the dead field) |
| skills/implement/SKILL.md | 71, 411 |
| skills/plan/SKILL.md | 34, 219, 228 |
| skills/integrate/SKILL.md | 62-68, 118 |
| skills/test/SKILL.md | 55, 112 |
| skills/questions/SKILL.md | 25 |
| skills/research/SKILL.md | 23 |
| skills/design/SKILL.md | 169 |
| skills/structure/SKILL.md | 34-38 |
| skills/phasing/SKILL.md | 29-31 |
| skills/replan/SKILL.md | 42-44, 111-131 |

A run that follows using-qrspi's hard-reject literally aborts on first
contact with a `codex_reviews:` value. Simultaneously, all 11
consumers read that same field name and find nothing → silent
degradation of the second-reviewer dispatch path. Either side wins,
the user loses.

**Fix.** Single sweep: `grep -rln 'codex_reviews' skills/ | xargs sed
-i'' 's/codex_reviews/second_reviewer/g'`, then read-back validation
that no `codex_reviews` token remains in any spine. The vocabulary
question of whether dispatch tag suffixes (`quality-codex`,
`spec-codex`) should also be vendor-neutralized is a separate item —
see #6 below. This item is just the config-field rename completion.

**Why rank #1.** Touches every run. Single-line edits across 11 files.
The orchestrator's own apply-fix gate is broken today. This is the
cheapest correctness fix in the backlog.

---

### #2 — BLOCKER — Resolve the `## Test Strategy` / `## Test Architecture` H2 collision (3-way contradiction)

**Slices:** 2.F02 + 2.F03 + 2.F07 + 2.F14
**Existing issues:** related to #275 (vocabulary drift) and #270 (Cite Check infra)
**Severity:** blocker (guaranteed infinite loop on visual-fidelity runs)

**Problem.** Three artifacts disagree on which skill owns the unified
test-strategy section:

- `skills/design/SKILL.md:231` (visual-fidelity precondition): "`## Test Strategy` contains a `### Visual-Fidelity Binding` subsection."
- `skills/_shared/design-altitude-boundary.md:10`: "design.md does NOT carry a top-level Test Strategy section..."
- `skills/_shared/design-altitude-boundary.md:22` (DEFERS): "Unified Test Strategy / Test Architecture section ... (Structure's job)"
- `skills/design/references/design-md-template.md:1-34`: authors NO `## Test Strategy` H2
- `skills/phasing/SKILL.md:136`: reads `design.md ## Test Strategy` for wireframe artifact names
- `skills/structure/SKILL.md:16, 205`: Structure OWNS `## Test Architecture`
- `skills/phasing/owns-defers.md:16`: Phasing DEFERS "test strategy" → owned by **Design** (wrong; per altitude-boundary it belongs to Structure)

A run with `visual_fidelity_required: true` hits the Design
precondition → halts because `## Test Strategy` is missing from the
template → loops back to re-synthesis → re-reads the OWNS/DEFERS that
forbids the section → loop indefinitely.

**Fix.** Pick ONE home. Recommended: retire the phrase "Test Strategy"
entirely; use `## Test Architecture` (Structure-owned) + per-goal
`Acceptance` blocks (Design-owned) + a `### Visual-Fidelity Binding`
subsection located in whichever owns visual binding. Then update all
four contracts (design-altitude-boundary, design template, phasing
precondition, structure heading set) to agree.

**Why rank #2.** Hard infinite-loop on a non-edge-case
(visual-fidelity runs). Touches design + phasing + structure +
`_shared/design-altitude-boundary.md`. Larger surgical surface than #1
but still well-bounded.

---

### #3 — BLOCKER — Hard-coded rule-range references (`R1-R7`) silently drop new rules; replace with rangeless framing

**Slice:** 3.F02
**Existing issues:** none (fresh find)
**Severity:** blocker (R8 invisible to every prompt-prose review since R8 was authored) — **but** the right fix is structural, not a number bump

**Problem.** `prompt-design-rules.md:15` titled "## The eight rules"
defines R1…R8 (R8 = Prose density). Every consumer that instructs an
agent which rules to apply says "R1-R7" — frozen at the count that was
canonical when the snippet was written:

- `skills/_shared/prompt-prose-reviewer-addition.md:3`
- `skills/_shared/prompt-prose-writer-addition.md:1`
- `skills/_shared/prompt-prose-test-expectations-clause.md:3`
- `skills/prompt-prose-reviewer/SKILL.md:2` (frontmatter description)
- `skills/prompt-prose-writer/SKILL.md:2` (frontmatter description)

Bumping "R1-R7" → "R1-R8" fixes today's drift but recreates the same
defect class on the next rule addition (R9 lands → five files silently
drop it again). The brittleness is the enumeration itself, not the
number.

**Fix (structural, not numeric).** Replace every hard-coded rule range
with rangeless framing — "apply all rules in
`skills/_shared/prompt-design-rules.md`" (or "every R-rule defined
in…"). One source of truth (the rules file's own headings), no
consumer-side count to drift. Do the same scrub inside the rules file
itself (lines 165, 201, 232 currently say "R1-R8"). Drop the proposed
`test-prompt-design-rule-range.bats` lint — it would re-encode the
same brittleness in test form. If a lint is wanted, it should assert
the *absence* of `R[0-9]+-R[0-9]+` hard ranges in consumer snippets,
not pin the upper bound.

**Why rank #3.** Silent correctness defect on the rule that just
delivered the v0.7.3 trim. The structural fix is the same cost as the
numeric fix (still ~6 edits) but durably closes the defect class.

**Adjacent cleanup.** `tests/lint/test-prompt-design-rules-r8.bats`
encodes the same brittleness: line 13 pins the literal substring
`R1-R8` in the rules file's finding-type-gate row. After the
rangeless-framing scrub, that assertion needs to be loosened (or
replaced with "the gate row references the rule-set as a whole, not
a hard count").

---

### #4 — BLOCKER — Reviewer-protocol claims "exactly two emission paths"; dispatcher uses only the third; first/third-party emission files are dead

**Slice:** 3.F01 (root); closes #283, #288, #294
**Existing issues:** #283, #288, #294 (all three are downstream symptoms)
**Severity:** blocker (architectural contract drift; ships every release as misleading docs)

**Problem.** `skills/reviewer-protocol/SKILL.md:12-13`: *"The two
files are siblings: every reviewer dispatch follows exactly one of
them; **there is no third path.**"* Three files exist:

1. `first-party-emission.md` (74 lines) — host with Write tool
2. `third-party-emission.md` (80 lines) — Codex read-only sandbox
3. `stdout-fallback-emission.md` (51 lines) — host where Write is denied

`scripts/dispatch-agent.sh:819,961,1223,1411` appends ONLY
`stdout-fallback-emission.md` to every reviewer prompt
unconditionally
(`EMISSION_OVERRIDE_ABS="$REPO_ROOT/skills/reviewer-protocol/stdout-fallback-emission.md"`).
`grep -rn "first-party-emission\|third-party-emission" scripts/
tools/` returns zero hits. The two named-as-canonical emission siblings
have zero script consumers. The "no third path" claim is false.

This is the **root** of the #283/#288/#294 cluster: every downstream
symptom (Codex returning chat-only; Copilot CLI subagent refusing /tmp
ops) is the dispatcher honoring a single fallback contract while the
SKILL.md describes a two-path model that the dispatcher does not
implement.

**Fix.** Two viable shapes:
- (a) **Unify.** Delete first/third-party-emission siblings. Fold
  content into a single `emission.md` describing the unified wire
  format. Rewrite SKILL.md to acknowledge the single emission path
  with a runtime host-capability branch. Update dispatcher
  `EMISSION_OVERRIDE_ABS` to point at the unified file.
- (b) **Make the dispatcher pick.** Use `detect_host` /
  `lookup_host_vendor_path` (already present in dispatch-agent.sh:951)
  to select the appropriate sibling per dispatch.

Recommend (a). Three files for one behavior is unnecessary; the
explicit single-path is honest about what ships.

**Why rank #4.** Single architectural fix closes a 3-issue cluster
that has been open for months. Touches one SKILL + three referenced
files + one dispatch script. Net file count drops.

---

### #5 — HIGH — Centralize 3 cross-cutting agent blocks (closes 88 maintenance points + closes #287)

**Slice:** 4.F01 + 4.F02 + 4.F13 + 4.F15 + 4.F16
**Existing issues:** #287 (root cause via F02), #279 + #278 (shared-snippet under-adoption family)
**Severity:** high (one stale-prose carrier across 32 agents = same hazard, 32 surfaces)

**Problem.** Cross-agent grep counts:

| Duplicated block | Files | Lines duplicated |
|---|---:|---:|
| `## Diff-File Read Pattern` | 31 | ~155 |
| `## Scope Hint` | 31 | ~93 |
| `DISPATCH_FILE=<path>` preamble | 34 | ~34 |
| 3-check scope procedure | 7 | ~84 |
| `reviewer_tag — claude or codex` bullet (stale; should be `<family>-<host>`) | 16 | 16 |

Two stale-prose hazards living in those duplications:

- **`HEAD~1` stale reference (32 agents)** — `skills/reviewer-protocol/SKILL.md:46` was updated to "the SHA read from `reviews/{step}/round-(NN-1)-commit.txt`"; the 32 agent bodies still say "`<base-branch>` by default; `HEAD~1` only when the convergence rule narrows." Issue #287 names this directly.
- **`reviewer_tag — claude or codex` bullet (16 agents)** — Expected-Reviewer Matrix entries are `<family>-<host>` (e.g., `spec-claude`, `security-codex`); 16 agent bodies say the tag is just `claude` or `codex`. The reviewer would emit filenames that don't match what `verifier-fan-in.sh` and `await-round.sh` expect.

**Fix.** Three new shared snippets:

1. `skills/_shared/reviewer-diff-and-scope.md` — verbatim
   diff-file-read-pattern + scope-hint blocks, anchored on the SHA
   contract (no `HEAD~1`). `!cat` from each of the 31 reviewer
   agents. Closes #287 with one edit instead of 31.
2. `skills/_shared/scope-3-check.md` — the 3-check scope procedure
   (with the fail-closed-on-malformed-OWNS/DEFERS clause from slice 4
   F14 lifted in). `!cat` from each of the 7 scope-reviewer agents.
3. `skills/_shared/dispatch-file-preamble.md` — the
   `DISPATCH_FILE=<path>` preamble. `!cat` from each of the 34
   dispatch-file-consuming agents.

Plus: rewrite the `reviewer_tag` bullet to the correct
`<family>-<host>` form in those same 16 agents, ideally also via the
new `reviewer-diff-and-scope.md` snippet.

**Why rank #5.** Single centralization pass cuts 88 maintenance
points + closes #287 + bakes in correct contracts for future protocol
edits. The cost is one careful diff per agent (40 edits) which can
itself be a sweep task per the Plan Sweep Task Contract.

---

### #6 — HIGH — Delete 7 dead `_shared/` snippets + fix the footprint test that masks the deletion

**Slices:** 1.F03 + 1.F04 + 1.F13, 3.F03 + 3.F04 + 3.F14 + 3.F16 + 3.F17
**Existing issues:** closes #278, #279 (decentralize side); related to #310
**Severity:** high (false SSoT claims + drift hazard + ships dead documentation as canonical)

**Problem.** 8 of 22 `skills/_shared/*.md` files are unreferenced or
superseded by content actually loaded from `skills/using-qrspi/references/`.
The footprint test
(`tests/acceptance/v07-phase1-test-phase/test-g9-footprint.bats:46-55`)
asserts file existence for six of these, masking that nothing
`!cat`-includes them. Several claim "single source of truth" framing
in their first paragraph while diverging from the actually-loaded
version on load-bearing content (e.g., `_shared/compaction-checkpoint.md`
carries a `## Iron Rule` section that the actually-loaded
`using-qrspi/references/compaction-checkpoints-detail.md` omits).

| File | `!cat` consumers | Notes |
|---|---:|---|
| `_shared/compaction-checkpoint.md` | 0 | superseded by `using-qrspi/references/compaction-checkpoints-detail.md` |
| `_shared/config-validation.md` | 0 | superseded by `config-validation-procedure.md` + inline tables in using-qrspi |
| `_shared/feedback-format.md` | 0 | superseded by `using-qrspi/references/feedback-file-format.md`; "+" vs "plus" drift |
| `_shared/pause-gate.md` | 0 | superseded by `using-qrspi/references/review-loop-pause-gate.md`; H2/H3 heading drift breaks anchors |
| `_shared/review-loop.md` | 0 | also still says `HEAD~1` (slice 1 F02) — actively misleading if anyone re-adopts it |
| `_shared/reviewer-dispatch.md` | 0 | near-verbatim duplicate of `-prose.md` variant (which has 13 consumers) |
| `_shared/codex/launch-await-pattern.md` | 0 | confirms #278 |
| `_shared/precondition-block.md` | 1 (goals only) | one-line snippet; R5 sharding test failure |

**Fix.** Tier 1 (pure deletes, no consumer to update):

```
git rm skills/_shared/{compaction-checkpoint,config-validation,feedback-format,pause-gate,review-loop,reviewer-dispatch}.md
git rm -r skills/_shared/codex/
# decide on precondition-block.md: delete (1 consumer = below R5 floor) OR add !cat to the other 11 orchestrator skills (close #279 by adoption instead)
```

Update `tests/acceptance/v07-phase1-test-phase/test-g9-footprint.bats:46-55`
to drop the deleted-file existence assertions and add a STRONGER lint:
for each file in `skills/_shared/`, require at least one `!cat
skills/_shared/<basename>` match across `skills/` + `agents/`, OR an
explicit allow-list of files that are intentionally read-by-Read
(like `prompt-design-rules.md`).

Estimated `_shared/` reduction: 22 → ~12 files.

**Why rank #6.** Eliminates 7 documented-as-canonical-but-actually-dead
files. The footprint-test fix prevents recurrence. Closes #278 by
deletion; closes #279 by deliberate decision (delete vs adopt).

---

### #7 — HIGH — Trim the 6 untouched skills + 2 agent outliers (residual R8/R1 from pre-trim era)

**Slices:** 1.F07 + 1.F08 + 1.F16 + 1.F17, 2.F10 + 2.F13 + 2.F18 + 2.F21, 4.F06 + 4.F17 + 4.F18
**Existing issues:** related to #310 (skill body bloat)
**Severity:** high (consolidated R8 footprint; closes ~200 lines of estimated cuttable prose)

**Problem.** Six SKILL.md files were not part of the v0.7.3 trim pass
(see size-delta table in §1 above): `questions`, `research`,
`research-isolation`, `structure`, `reviewer-protocol`,
`prompt-prose-{reviewer,writer}`. Concrete R1/R8 hits found in the
audit:

- **`skills/parallelize/SKILL.md:196-197`** (slice 2 F04) — same sentence twice back-to-back, second copy carries an orphan `4.` numeric marker from a deleted parent list. Pure dead code.
- **`skills/parallelize/SKILL.md:223 vs 326`** (slice 2 F05) — Red Flag says "the four symbolic values"; Iron Law summary names five (or six with the suffix grammar). Three locations disagree on the count.
- **`skills/parallelize/SKILL.md:113-128`** (slice 2 F21) — JavaScript-ecosystem hard-codes (eslint, tsconfig, vitest, `.next/`, `dist/`) in vendor-neutral skill. R1 violation.
- **`skills/research/SKILL.md:52, 95, 104`** (slice 2 F13) — three "Claude Code 2.1.x subagent-guardrail blocklist" host-version pins in a vendor-neutral skill.
- **`skills/research/SKILL.md:60, 99`** (slice 2 F12) — hard-coded `model: "sonnet"` literal in dispatch (should reference `config.md.model_routing`).
- **`skills/parallelize/references/worked-examples.md`** (slice 2 F10) — inlines the Good example that SKILL.md already authors verbatim. R5 misapplication.
- **`skills/goals/SKILL.md:102-118`** (slice 2 F17) — Dialogue Conduct list skips number 5 (jumps 4 → 6).
- **`skills/using-qrspi/SKILL.md:50-52, 62-66, 600-604`** (slice 1 F07) — pre-`!cat` paragraphs hand-summarize content the include is about to deliver.
- **`skills/plan/SKILL.md:207-215 vs 235`** (slice 1 F16) — Plan reviewer agent table duplicates the REVIEW_AGENTS literal 30 lines below.
- **`skills/using-qrspi/SKILL.md` + 3 spines** (slice 1 F17) — Test-step opt-out stated 4 times across 2 files.
- **`agents/qrspi-test-writer.md`** (slice 4 F17) — 299-line outlier with production-code-prohibition stated 5 times. Estimated cut: −50 to −75 lines.
- **`agents/qrspi-visual-fidelity-reviewer.md`** (slice 4 F06 + F18) — 347-line outlier; the per-finding YAML schema is duplicated verbatim from `reviewer-protocol/first-party-emission.md` (which the agent already preloads via `skills:`). Estimated cut: −50 to −80 lines.

**Fix.** A v0.7.3-style trim pass on the six untouched skills + the
two agent outliers, applying the same Pass 1 / Pass 2 / Pass 3
discipline used in v0.7.3.

**Why rank #7.** Largest remaining R8 surface in the corpus.
High-confidence cuts (estimated ~300 lines net). Two of the offenders
(`research`, `parallelize`) contain factual contradictions in
addition to R8 fat.

---

### #8 — MEDIUM — Document the `phase:` config field + add 4th carve-out to no-silent-defaults

**Slice:** 1.F06 + 1.F18
**Existing issues:** none (fresh find)
**Severity:** medium (silent runtime-backfill of an undocumented field)

**Problem.** `skills/implement/SKILL.md:96-98` writes `phase: NN` back
to `config.md` as part of the smoke check. The field is not in
`skills/using-qrspi/SKILL.md`'s canonical schema (lines 82-121), not
in its validation table (lines 325-336), not in field-specific menus
(lines 259-292), and not in the "exactly three carve-outs" enumeration
at lines 304-310. using-qrspi states "These three are the only
carve-outs from the no-silent-defaults rule above" — provably false.

**Fix.** Add `phase:` to the canonical schema with its semantics
("set by Implement at smoke-check time; integer ≥ 1; informational
ordinal"). Add validation-table row naming Implement as the only
validator. Update the carve-outs section to read "These four are the
only carve-outs" and document the scan-derive procedure.

**Why rank #8.** Medium severity (silent today, not actively broken).
Cheap fix (two paragraph adds in one file). Closes a latent failure
mode.

---

### #9 — MEDIUM — Vocabulary boundary fixes for Goals / Phasing / Structure ownership

**Slices:** 2.F06 + 2.F15 + 2.F20
**Existing issues:** related to #276 (helper drift), #275 (goal-lifecycle vocab), #289 (phasing altitude)
**Severity:** medium (factual contradictions across the ownership boundary)

**Problem.** Three boundary contradictions:

- **`skills/goals/SKILL.md:51`** (slice 2 F06) — Goals' Next-Phase Restart prose says Replan populates only `goals.md` from `future-goals.md`; actual contract (replan/SKILL.md:161-162) populates **four** drafts from four future-*.md files.
- **`skills/phasing/SKILL.md:130`** (slice 2 F15) — Phasing flips `status: approved` on four upstream artifacts it does not own. Goals SKILL line 142-143 explicitly forbids hand-edits to its frontmatter by other skills.
- **`skills/phasing/owns-defers.md`** (slice 2 F20) — phasing template requires `## Orphan IDs` + `## Goal-ID Consistency` H2s; phasing OWNS list enumerates neither. Scope-reviewer can flag the very sections the fail-closed condition requires.

**Fix.** Three discrete edits; see per-slice F-findings for proposed
fix shapes.

**Why rank #9.** Cross-skill ownership boundaries are load-bearing
for the QRSPI scope-reviewer contract. Each individually small; as a
cluster they validate the boundary mechanism.

---

### #10 — MEDIUM — Verifier rubric host-coupling + missing `skills:` preload (#291 + #305)

**Slices:** 4.F03 + 4.F19 + 4.F21
**Existing issues:** closes #291; addresses #305 directly
**Severity:** medium (Claude-leak in host-agnostic agent; verifier rubric drift)

**Problem.** `agents/qrspi-finding-verifier.md` references `CLAUDE.md`
4 times (lines 15, 17×2, 54, 55) as the authority for stylistic
judgments and silenced-finding tests. The agent is supposed to be
host-agnostic (Haiku today, Codex tomorrow; runs in both Claude Code
and Copilot CLI sessions). A Codex verifier looking for `CLAUDE.md`
finds nothing.

Additionally:
- verifier has no `skills:` preload, relies on `<upstream_paths>` to
  pick up `implementer-protocol/SKILL.md` § Hygiene contract at runtime
- `qrspi-test-writer` + `qrspi-plan-apply-fix` similarly missing
  `skills:` preloads they need (test-writer commits and writes
  `@test "..."` strings the implementer-protocol hygiene scan binds;
  apply-fix lifts finding-ID prose that the ID-hygiene contract
  forbids)

**Fix.** Substitute "the host-instructions file (`CLAUDE.md` on
Claude Code; `AGENTS.md` on Codex CLI; `copilot-instructions.md` on
Copilot CLI)" at each of the 4 occurrences. Add `skills:
[implementer-protocol]` to verifier + plan-apply-fix; add `skills:
[implementer-protocol, prompt-prose-writer]` to test-writer.

**Why rank #10.** Closes two open issues. Cheap edits. The
implementer-protocol preload addition has the side effect of bringing
test-writer's commit prose under the same hygiene scan that catches
`[Tnn]` leaks (closes part of #306).

---

### #11 — MEDIUM — Apply-fix protocol gaps (#295 + #296)

**Slices:** 1 (apply-fix protocol section in using-qrspi), 4.F08
**Existing issues:** #295, #296
**Severity:** medium

**Problem.** Two separately-filed issues against the apply-fix
protocol surface: #295 (per-round SHA anchor pattern self-referential
and adds an extra commit per round) and #296 (per-step verifier
upstream-artifact list missing the 'plan' step entry). The audit
confirms `agents/qrspi-plan-apply-fix.md` has no `prior_round_anchor`
parameter and no explicit "worktree state assumption" — it operates
purely off finding files, which works for the current per-finding
flow but degrades under recovery/replay.

**Fix.** Add a `## Worktree state assumption` block to
`agents/qrspi-plan-apply-fix.md` declaring the prior-round anchor
contract. Add `prior_round_anchor` to Step 2's input list. Re-thread
the apply-fix per-step verifier upstream-artifact list to include the
'plan' step (per #296's filed fix shape).

**Why rank #11.** Closes 2 open issues. Touches one agent + the
apply-fix protocol section in using-qrspi.

---

### #12 — LOW — Frontmatter normalization + meta-prose / inside-baseball cleanup

**Slices:** 3.F06 + 3.F07 + 3.F08 + 3.F10 + 3.F11 + 3.F12 + 3.F15 + 3.F18, 4.F09 + 4.F10 + 4.F11 + 4.F12 + 4.F20 + 4.F22
**Existing issues:** none specifically; tangentially #277, #310
**Severity:** low (cosmetic but cumulative)

**Problem.** Grab-bag of low-severity items worth batching into one
sweep:

- 2 agents use `tools: [Read, Write]` (YAML flow); 40 use `tools: Read, Write` (bare list) — normalize to bare-list
- 5 agents use `description: "..."` (quoted); 37 use bare — normalize to bare
- `qrspi-research-collator` has `Bash` in tools/allowed-tools but never invokes bash — drop
- `skills/_shared/tsc-probe-helper.md` has `name:/description:` frontmatter that on a host with skills-autodiscovery would register it as a stand-alone skill — strip
- `skills/implementer-protocol/notifications.md` same shape — strip
- Both protocol SKILLs carry "This file is **designed to grow**" meta-prose (slice 3 F07)
- `skills/reviewer-protocol/SKILL.md:49` cites `#109` as behavior justification without `<!-- evergreen-exempt -->` (the protocol's own hygiene rule forbids this — slice 3 F08)
- `skills/_shared/prompt-design-rules.md:4` "Last applied: 2026-06-02" + the file's lines 6-12 framing prose violate the file's own R1 (slice 3 F10 + F11)
- `skills/_shared/prompt-design-rules.md:62` pins R3 calibration to specific model versions ("Opus 4.7-high", "GPT-5.5") that rot — neutralize and move dated evidence to docs
- `skills/_shared/verifier-dispatch-prose.md:1-9` HTML-comment header cites internal section IDs ("design.md CD-4 §H L494") — strip
- Add `prompt-prose-reviewer` skill preload to ~10 reviewers whose review surface can include prompt prose (slice 4 F12) — currently only Design has it
- Hoist `qrspi-implementer.md:10-46` "Orchestrator-Only Scripts" allowlist into `implementer-protocol/SKILL.md` so lightweight + test-writer inherit (slice 4 F22)
- Add stdout-fallback-emission `skills:` preload to every reviewer agent so the override-when-Write-fails path is in context (slice 4 F20; addresses #288/#294 belt-and-suspenders alongside #4 above)

**Fix.** One sweep PR per group; ~30 edits across 25 files.

**Why rank #12.** Each low-severity individually. Batched, the sweep
removes ~6 distinct latent footguns and tightens the prose-density
audit handle for future enforcement.

---

## 4. Cluster summary + recommended v0.7.4 goal structure

The 13 items above (item #0 + items #1–#12) fall into 4 clusters.
**Priority shift from earlier draft:** item #0 (G9 finish) is reframed
as the v0.7.4 centerpiece, not a parallel-track perf item — without
it, v0.7.4 ships another release of prose churn without solving the
original footprint problem the v0.7.3 release was named after.

### G-HOTFIX — v0.7.3.1 hotfix release (items #1, #2, #3, #4)

Four blockers currently shipping as silent correctness defects.
Should ship as v0.7.3.1 hotfix immediately, ahead of v0.7.4 proper.
~12 file edits + 1 deletion sweep + 1 lint test. Correctness > perf;
this clears the deck before v0.7.4 begins.

**Estimated effort.** 2-3 hours implement, 1 hour review cycle.

### G-AUDIT-CORE (v0.7.4 G1) — Finish G9: content relocation + delete-first sweep (item #0)

The strategic centerpiece of v0.7.4. Three sub-passes:

- **0.1** Host SKILL.md `!cat` sweep — classify each `!cat` as
  host-only / subagent-only-1-agent (inline) / subagent-only-multi
  (promote to SKILL.md + `skills:` frontmatter) / both (`_shared/`) /
  optional (**delete-first** under the skepticism principle).
- **0.2** Agent-file duplication sweep — factor the scope-reviewer
  4-step skeleton + Diff-File Read Pattern + Scope Hint paragraphs
  into shared SKILL.md spines reachable via `skills:` frontmatter.
- **0.3** Fix `scripts/measure-active-footprint.sh` to expand any
  `!cat` (not just `_shared/`); rerun G9 gate honestly.
- **0.4** Re-measure expanded SKILL.md line counts; G9 design target
  (80-95K → 15-30K) becomes the v0.7.4 success criterion.

**No script changes required** beyond the footprint-test fix. The
mechanisms (`skills:` frontmatter, `_shared/`, inline agent content)
all already exist.

**Estimated effort.** 4-6 hours classification + relocation across
~5 heavy spines and 42 agents, 2-3 hours measurement and CHANGELOG,
2-3 hours dual-review-till-clean per relocated skill cluster.

### G-AUDIT-CENTRALIZATION (v0.7.4 G2) — Cross-cutting agent centralization (items #5, #6)

Two high-severity items addressing the shared-snippet architecture.
Creates 3 new `_shared/` snippets, deletes 7 dead ones, mass-edits
~40 agents. Closes #287, #278, #279. Compounds with G-AUDIT-CORE
(centralization is the natural follow-on to relocation).

**Estimated effort.** 4-6 hours implement (mostly mechanical sweep),
2 hours review.

### G-AUDIT-BOUNDARIES (v0.7.4 G3) — Untouched-skills trim + boundary fixes (items #7, #8, #9, #10, #11, #12)

Six medium/low items addressing residual R8/R1 from the six skills
not touched in the v0.7.3 trim, plus accumulated small bugs. Closes
#291, #295, #296, partial #306. Can run in parallel with the other
two clusters once G-HOTFIX lands.

**Estimated effort.** 8-12 hours implement, 3-4 hours review.

### Orthogonal — G-RETRO (already filed in implement-retrospective.md)

Implement-phase autonomy guardrails (A-H opportunities). Runs in
parallel with G-AUDIT clusters. Different surface (main-agent
behavioral guardrails vs prompt-content quality), no merge conflicts
expected.

### Suggested sequencing

```
v0.7.3.1 hotfix:   G-HOTFIX                            (~1 day)
v0.7.4 G1:         G-AUDIT-CORE  (#0)                  (~2-3 days)
v0.7.4 G2:         G-AUDIT-CENTRALIZATION  (#5, #6)    (~1 day, parallel with G3)
v0.7.4 G3:         G-AUDIT-BOUNDARIES  (#7–#12)        (~2 days, parallel with G2)
v0.7.4 G4:         G-RETRO  (A–H)                       (parallel throughout)
```

---

## 5. Acknowledgements — what's working

From the per-slice "Acknowledgements" sections, worth preserving and
not regressing:

- The Iron Law / `<HARD-GATE>` placement at start AND end of major
  spines (R3 application) is consistently correct across plan,
  implement, integrate, test, using-qrspi.
- `<SUBAGENT-STOP>` directive at top of `using-qrspi/SKILL.md` is the
  right cross-cutting subagent exemption mechanism; correctly cited
  from every spine's PRECONDITION line.
- The reviewer-protocol `skills:` preload mechanism (33 agents
  declare it correctly; the host preloads the body at activation) is
  well-designed. The under-adoption findings sit on top of an
  architecture that works.
- The implementer-protocol cross-cutting hygiene contract is well-
  factored: 3 implementer agents inherit Commit Before Reporting,
  ID-hygiene contract, BLOCKED escape hatch from one place.
- The Path A / Path B untrusted-data delimiter contract
  (`reviewer-protocol/SKILL.md:171-202`) is consistently invoked
  across every reviewer body with identical START/END wrapper tokens.
- The verifier change-type score thresholds (style/clarity ≥80,
  correctness ≥70) are stated consistently in 4 places with an R2
  `Why:` line on the asymmetric correctness floor — good R2
  application.
- Plan's Sweep Task Contract carries the rerunnable `grep -rn -- 'pat'
  tests/` shape with explicit `--` argument-separator rationale —
  strong R2 + good R7 lexical anchoring.
- The v0.7.3 trim was real and effective: implement −65%, using-qrspi
  −51%, plan −39%, goals −40%, design −34%. The R8 + R5 sharding
  discipline shipped; the residual work in this report is what
  remained after a single trim pass.
- `skills/research-isolation/SKILL.md` (77 lines) is exemplary R8
  work: every sentence load-bearing, structural carve-out for the
  trusted region is precise, canonical token list is the spec.
- Replan's Severity Classification table is the strongest single
  artifact in slice 2 — every row operational, loop-back target
  named, examples concrete enough to act on.
- `qrspi-visual-fidelity-reviewer`'s `reviewer_tag:
  visual-fidelity-claude` is the only agent body that gets the
  family-host tag form right; it's the model the 16 other reviewers
  (item #5) should adopt.

---

## 6. Methodology + audit reproducibility

**Reviewer slate.** 4 parallel `general-purpose` agents, all
`claude-opus-4.7-high`, each owning a non-overlapping slice of the
prompt corpus. Adversarial framing ("assume the prompts ARE buggy
until proven otherwise"). Each received the full
`prompt-design-rules.md` as the rule set + the curated list of
existing-issue context to avoid re-discovery.

**Audit duration.** Slice 1: 397s. Slice 2: 450s. Slice 3: 510s.
Slice 4: 651s. Total wall: 651s (parallel). Total cost: 4× Opus 4.7
high.

**Finding-type gate applied.** Every reviewer applied the blocking
vs declined categories from `prompt-design-rules.md:158-176`.
Combined declined-section across the 4 slices: 14 detail-suggestions /
example-suggestions / scope-extensions (NOT included in the 79 raw
findings count; all were correctly excluded per the gate).

**Reproducibility.** To re-run this audit on a future release:

1. Update size-delta computation: `git ls-tree -r --name-only <tag>` per
   skills/agents — see the Python snippet that generated
   `size-delta.md`.
2. Refresh prompt-related GitHub issue list:
   `gh issue list -R dfrysinger/qrspi-plus --limit 200 --state open
   --search "..."` — keyword list at the top of §2 above.
3. Dispatch the same 4-slice reviewer set with the same per-slice
   prompts (this file's §3 maps each finding back to its slice for
   prompt-template reuse).
4. Re-cluster + re-rank per the (blast radius × correctness severity
   ÷ fix cost) rubric in §3.

Recommended cadence per the existing rules-file guidance
(`prompt-design-rules.md:225-228`):

- After every major Phase ships ← this audit was triggered by v0.7.3
  shipping
- When a new Claude or Codex model lands (rules may need recalibration)
- When a skill is observed failing to follow its own instructions
- Before any significant pipeline restructuring

---
round: 09
artifact: design
status: fixing
---

# Round 09 dispositions

## Findings inventory

- quality-claude: 5 findings (medium=2, low=3)
- scope-claude: 0 findings (clean — 8th consecutive)
- quality-codex: 1 finding (medium=1)
- scope-codex: 0 findings (clean — 6th consecutive)

Total: 6 findings. No HIGH. All accept.

Trend: 10 → 3 → 5 → 4 → 2 → 4 → 3 → 4 → 6. Count went up but severity weight is similar to previous rounds. Scope topology stable clean.

## Per-finding dispositions

### R9-F01 quality-claude (medium) — accept. G14 dependents list misclassifies G12

The canonical G14 dependent set established in round 3 was `{G8, G9, G11, G12, G15, G18}`. But G12's BATS pin inspects working-tree state and `.git/info/exclude` — it does NOT extract markdown sections, so it doesn't consume G14's helper. Misclassification creates a false dependency.

**Fix:** Remove G12 from G14's canonical dependent set. New set: `{G8, G9, G11, G15, G18}`. Update three locations:
- G14 "Dependency note" subsection
- G14 "What research found" markdown-inspection list
- Decision 7's bulleted dependent list

### R9-F02 quality-claude (medium) — accept. G7 `id_hygiene_exempt:` contradicts advisory framing

G7 is framed as "Advisory, not blocking" with explicit rejection of blocking pre-commit hooks. But the per-task frontmatter `id_hygiene_exempt: [<paths>]` field is itself a blocking-check escape hatch — exempt lists only make sense for blocking checks. If G7 is purely advisory, no exempt mechanism is needed; the implementer reports any hits in DONE and reviewers see them.

**Fix:** Resolution is to remove `id_hygiene_exempt:` entirely. G7 stays advisory; carve-outs are path-shaped (`docs/qrspi/**`, reviewer agent files, opt-in via inline comments where needed, like `<!-- id-hygiene-exempt -->` matching G18's pattern). Two locations to edit:
- G7 "Path-shaped carve-outs" subsection (around design.md line 342): remove the `id_hygiene_exempt: [<paths>]` per-task frontmatter mention. Keep `docs/qrspi/**` and reviewer-agent-file carve-outs. Add an inline carve-out option matching G18's `<!-- evergreen-exempt -->` pattern: `<!-- id-hygiene-exempt -->` on a line skips that line.
- Decision 10's enumeration: remove the `id_hygiene_exempt: [<paths>]` bullet.

### R9-F03 quality-claude (low) — accept. G3 N=2 boundary untested

G3's small-plan carve-out is `<= 2 tasks` but tests cover only N=1 and N=3+. The N=2 case is the load-bearing boundary.

**Fix:** Add an explicit N=2 boundary test bullet to G3's "Test strategy at the design level":
- Boundary test (N=2): a plan with exactly two tasks does the split in main chat (within the carve-out) and produces two `tasks/task-NN.md` files.

### R9-F04 quality-claude (low) — accept. G10 reference_artifact conditional requirement

Decision 10 says all new task-spec fields are additive-with-safe-default. But `reference_artifact:` is conditionally required: when `reference_gate: true`, the workflow needs `reference_artifact:` to know what to show the user.

**Fix:** Update Decision 10 to note the conditional requirement: `reference_artifact:` is required iff `reference_gate: true`; when `reference_gate:` is absent or false, `reference_artifact:` is absent. Similarly note in G10's Recommendation that the two fields go together.

### R9-F05 quality-claude (low) — accept. G6 pre-implementer gate mechanism unspecified

The gate's distinction between "assertion failure" and "infrastructure failure" (syntax error, import error, fixture setup) is real but the design doesn't say HOW the orchestrator distinguishes them across test frameworks (BATS, Vitest, Jest, pytest). Plan would have to invent a mechanism.

**Fix:** Add a one-paragraph clarification to G6's gate section. Mechanism: the orchestrator uses framework-specific exit-code semantics and stdout/stderr parsing via a small per-framework adapter. Each adapter maps the test runner's failure output to either "assertion failure" or "infrastructure failure". Initial adapter set: BATS, Vitest, Jest, pytest. The adapter implementation lives in the orchestrator code (Plan/Implement own the per-framework adapter code); Design owns the mechanism contract (per-framework adapters return a classified failure type; orchestrator pauses on any infrastructure-class result).

Add a design-level test bullet:
- Per-framework adapter test: each supported test framework (BATS, Vitest, Jest, pytest) has an adapter that returns `assertion-failure`, `infrastructure-failure`, or `pass` for a representative failing/passing run.

### R9-F01 quality-codex (medium) — accept. G15 "What research found" still mentions "criteria"

G15's "What research found" subsection still says Replan promotes goals "that already have IDs and criteria" — contradicts the round-7 fix that removed acceptance criteria from goals.md's contract. Need to scrub the lingering "criteria" wording.

**Fix:** Edit G15's "What research found" paragraph to say "Replan promotes existing Formal goals that already have IDs, types, and the required Goals problem-framing subsections (Problem / Why we care / What we know so far)" — drop the "criteria" wording. Reviewer-visible consistency with the round-7 fix.

## Fix dispatch plan

Single fix subagent. 6 accepts.

## Convergence assessment after round 9

After round 9:
- 9 review rounds × 4 reviewers = 36 reviewer dispatches.
- 33 prior findings + 6 new = 39 total. After this round's fixes, 39 closed.
- Scope clean for 8 consecutive rounds (scope-claude) / 6 consecutive (scope-codex).
- HIGH count: 0 in rounds 6, 8, 9 (mostly 0). Quality reviewers continuing to find medium/low refinements.

If round 10 produces ≤ 2 small findings OR scope still clean and only LOW findings, declare convergence and surface to user for human gate.
If round 10 finds new HIGH or scope drift: keep looping.

## Status

draft → fixing → (post-fix) → re-review round 10.

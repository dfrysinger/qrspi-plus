# Slice 3 audit: cross-cutting + _shared

## Summary

- **Files audited:** 30
  - `skills/reviewer-protocol/SKILL.md` (287 lines)
  - `skills/reviewer-protocol/first-party-emission.md` (74)
  - `skills/reviewer-protocol/third-party-emission.md` (80)
  - `skills/reviewer-protocol/stdout-fallback-emission.md` (51) — NOT in user's brief but discovered as a third sibling
  - `skills/implementer-protocol/SKILL.md` (288)
  - `skills/implementer-protocol/notifications.md` (165)
  - `skills/prompt-prose-reviewer/SKILL.md` (17)
  - `skills/prompt-prose-writer/SKILL.md` (17)
  - 22 `skills/_shared/*.md` files (incl. `codex/launch-await-pattern.md`)
- **Total findings:** 18 (12 P0/P1 contract & dead-code, 6 P2 hygiene)

### `_shared` consumer counts (verified by grep)

Two columns: **`!cat` consumers** = files that actually inline the snippet via the build-time include. **Prose-mention consumers** = SKILL/agent files that name the path in passing but do NOT pull it in. The second column is the relevant signal for "is anything actually using this?". `!cat = 0` means the snippet is dead-include weight.

| Snippet | `!cat` consumers | All consumers (incl. prose / tests) | Verdict |
|---|---:|---|---|
| `compaction-checkpoint.md` | **0** | 1 (existence test only) | **DEAD** — content duplicated in `using-qrspi/references/compaction-checkpoints-detail.md` |
| `config-validation-procedure.md` | **0** | 3: `skills/implement/SKILL.md`, `skills/using-qrspi/SKILL.md`, `tests/unit/test-config-model-routing.bats` | prose-link only, not `!cat`'d |
| `config-validation.md` | **0** | 1 (existence test only) | **DEAD** — superseded by `config-validation-procedure.md` and inline tables in `using-qrspi/SKILL.md` |
| `design-altitude-boundary.md` | **2** | 3: `skills/design/owns-defers.md`, `agents/qrspi-design-scope-reviewer.md`, lint test | OK |
| `evergreen-output-rule.md` | **9** | 11 (9 SKILLs + `using-qrspi/references/artifact-quality.md` + reviewer-protocol prose ref) | OK — high-value snippet |
| `feedback-format.md` | **0** | 1 (existence test only) | **DEAD** — content duplicated (and divergent) in `using-qrspi/references/feedback-file-format.md` |
| `multi-actor-flow-check.md` | **4** | 4: `skills/{implement,parallelize,plan,structure}/SKILL.md` | OK |
| `pause-gate.md` | **0** | 2 (existence test + 1 prose mention in `using-qrspi/SKILL.md`) | **DEAD** — content duplicated (and divergent) in `using-qrspi/references/review-loop-pause-gate.md` |
| `precondition-block.md` | **1** | 1: `skills/goals/SKILL.md` | Underused — see #279 (1 of 12 orchestrator-facing skills) |
| `prompt-design-rules.md` | **0** | 4 prose refs + 3 tests | Loaded via Read, not `!cat` — but is the authoritative rules file |
| `prompt-prose-detection.md` | **4** | 4: `skills/{design,plan,prompt-prose-reviewer,prompt-prose-writer}/SKILL.md` | OK |
| `prompt-prose-reviewer-addition.md` | **1** | 1: `skills/prompt-prose-reviewer/SKILL.md` | OK (single-purpose) |
| `prompt-prose-test-expectations-clause.md` | **1** | 1: `skills/plan/SKILL.md` | OK (single-purpose) |
| `prompt-prose-writer-addition.md` | **3** | 3: `skills/{design,plan,prompt-prose-writer}/SKILL.md` | OK |
| `review-loop.md` | **0** | 2 (existence test + 1 prose mention in `using-qrspi/SKILL.md`) | **DEAD** — content duplicated (and divergent) in `using-qrspi/references/review-loop-pause-gate.md` |
| `reviewer-dispatch-prose.md` | **13** | 14 (13 skills + self-ref from `verifier-dispatch-prose.md`) | OK — heavy reuse |
| `reviewer-dispatch.md` | **0** | 1 (existence test only) | **DEAD** — near-verbatim duplicate of `reviewer-dispatch-prose.md` (the actually-used variant) |
| `structure-altitude-boundary.md` | **2** | 3: `skills/structure/owns-defers.md`, `agents/qrspi-structure-scope-reviewer.md`, lint test | OK |
| `tsc-probe-helper.md` | **0** | 1 (unit test asserting helper template exists) | **DEAD as `_shared` snippet** — it's actually a vendored TS-helper doc, mis-filed under `skills/_shared/` |
| `verifier-dispatch-prose.md` | **1** | 1: `skills/implement/SKILL.md` | OK |
| `verifier-filter-rule.md` | **1** | 1: `skills/implement/SKILL.md` | OK |
| `codex/launch-await-pattern.md` | **0** (only self-reference) | 0 | **DEAD** — confirms #278 |

**Net dead-snippet count: 8 of 22** = 36% of `skills/_shared/` is unreferenced or superseded.

---

## Findings

### F01 — `skills/reviewer-protocol/` ships three emission files; SKILL.md asserts exactly two; the dispatcher uses only the third [P0 contract drift]

The canonical body in `skills/reviewer-protocol/SKILL.md:12-13` states the architecture is binary:

> "The two files are siblings: every reviewer dispatch follows exactly one of them; **there is no third path.**"

But three emission files exist in the same directory:

1. `first-party-emission.md` (74 lines) — host with Write tool
2. `third-party-emission.md` (80 lines) — Codex read-only sandbox
3. `stdout-fallback-emission.md` (51 lines) — host where Write is denied / unavailable

And `scripts/dispatch-agent.sh:819, 961, 1223, 1411` shows that ONLY the third file is appended to every reviewer prompt — UNCONDITIONALLY, for every dispatch, both first- and third-party (`EMISSION_OVERRIDE_ABS="$REPO_ROOT/skills/reviewer-protocol/stdout-fallback-emission.md"`).

Net effect:

- **`first-party-emission.md` and `third-party-emission.md` are read by ZERO scripts.** `grep -rn "first-party-emission\|third-party-emission" scripts/ tools/` returns no hits. They are cross-referenced from the SKILL.md and from each other and the bats tests — that is their only life.
- The reviewer subagents never see `first-party-emission.md` or `third-party-emission.md` in their dispatch payload; they see the SKILL.md body PLUS `stdout-fallback-emission.md`.
- The "no third path" claim is false.
- The wire format in `stdout-fallback-emission.md` (line 19, `<<<FINDING-BOUNDARY>>>` + `NO_FINDINGS`) is identical to `third-party-emission.md:17`; they differ only in framing ("when to use this fallback" vs "you are running in a read-only sandbox"). 205 lines of overlapping content for a single behavior.

Recommendation: Either (a) delete `first-party-emission.md` and `third-party-emission.md`, fold their content into `stdout-fallback-emission.md`, and rewrite SKILL.md to acknowledge the single emission path with a runtime branch on Write-tool capability; or (b) make the dispatcher actually pick which of the two siblings to append based on host detection (`detect_host` / `lookup_host_vendor_path` already exist in dispatch-agent.sh:951). The current state — three files for a one-file behavior, with the SKILL.md describing a model the dispatcher does not implement — is the worst of every option.

Tightly coupled to #294, #288, #283 (host-availability inconsistencies in reviewer dispatch). This finding is the root of that cluster.

`change_type: correctness`

---

### F02 — `prompt-design-rules.md` defines R1–R8 (eight rules); every consumer file says "R1-R7", silently dropping R8 [P0 rule-set / consumer mismatch]

`skills/_shared/prompt-design-rules.md:15` has the heading `## The eight rules` and the file defines R1, R2, R3, R4, R5, R6, R7, **R8** ("Prose density: short declarative sentences, full behavioral precision", line 99).

Every consumer that tells an agent which rules to apply says "R1-R7":

- `skills/_shared/prompt-prose-reviewer-addition.md:3` — "apply R1-R7 + cross-cutting principles + finding-type gate"
- `skills/_shared/prompt-prose-writer-addition.md:1` — "apply R1-R7 + cross-cutting principles BEFORE drafting"
- `skills/_shared/prompt-prose-test-expectations-clause.md:3` — "Implementer applies R1-R7 + cross-cutting principles"
- `skills/prompt-prose-reviewer/SKILL.md:2` (frontmatter `description:`) — "applies R1-R7"
- `skills/prompt-prose-writer/SKILL.md:2` (frontmatter `description:`) — "applies R1-R7 before drafting"

Meanwhile, the *rules file itself* references R1–R8 in three places:
- line 165 (finding-type-gate table): "**rule-violation** | R1-R8 misapplied"
- line 201: "The rule set to apply (R1-R8, the cross-cutting principles, link to this guide)"
- line 232: "does it still satisfy R1-R8?"

Effect: every prompt-prose reviewer dispatched into the field is told to skip R8 (the prose-density rule), even though the canonical rule set requires it AND the finding-type gate scores R8 misapplication as a blocking rule-violation. R8 was added after the consumer-side prose was written; the consumers were never updated.

Fix: replace every "R1-R7" with "R1-R8" in the four consumer snippets and the two SKILL.md descriptions. (Six edits in five files.)

`change_type: correctness`

---

### F03 — Four `_shared` snippets are dead duplicates of `using-qrspi/references/*.md` content; existence pinned by a footprint test that nobody actually consumes [P0 SSoT violation, cascade-divergence risk]

`tests/acceptance/v07-phase1-test-phase/test-g9-footprint.bats:46-55` asserts existence of six `_shared` snippets:

```bash
for snippet in reviewer-dispatch.md review-loop.md config-validation.md \
               compaction-checkpoint.md pause-gate.md feedback-format.md; do
  [ -f "$SHARED/$snippet" ] || { echo "missing required _shared snippet: $snippet" >&2; false; }
done
```

Of these six, **four are `!cat`-included by zero skills** (`reviewer-dispatch.md`, `compaction-checkpoint.md`, `feedback-format.md`, `pause-gate.md`) and **two more (`review-loop.md`, `config-validation.md`) are prose-mentioned but also not `!cat`-included.** The canonical content for each is duplicated in `skills/using-qrspi/references/` (the file that IS `!cat`-included from `using-qrspi/SKILL.md`).

Concrete divergence proof (these are not byte-identical sibling files):

- `_shared/feedback-format.md` (29 lines, frame: "Single source of truth for the user-rejection feedback file") vs `using-qrspi/references/feedback-file-format.md` (18 lines, frame: "When a user rejects an artifact, the feedback is captured in..."). Different headings, different framing prose, identical YAML schema. Vocab match for the schema; vocab drift for everything around it.
- `_shared/compaction-checkpoint.md` (47 lines, with formal `## Iron Rule` / `## Auto-mode interaction` / `## TaskCreate at named checkpoints` sections) vs `using-qrspi/references/compaction-checkpoints-detail.md` (26 lines, prose-flattened with bold-label paragraphs instead of headings, **omits the `## Iron Rule` section entirely**). The shared snippet's framing claim ("Single source of truth for the compaction checkpoint contract") is false — the references file is the actually-loaded version, and it omits the load-bearing Iron Rule heading.
- `_shared/review-loop.md` (59 lines, formal `## Round-directory precondition` / `## Round body` / `## Fix-altitude rule`) vs `using-qrspi/references/review-loop-pause-gate.md` (45 lines, focused on the Pause Gate; the precondition + diff-emission-contract content lives inline in `using-qrspi/SKILL.md:352-365` instead). Two different splits of the same content.
- `_shared/reviewer-dispatch.md` (59 lines) vs `_shared/reviewer-dispatch-prose.md` (37 lines) — near-verbatim siblings; only `-prose.md` has 13 `!cat` consumers; the un-`-prose` variant is dead.

The footprint test gives the false impression that these snippets are load-bearing. They are not. Each is a stale draft of content that subsequently moved to `using-qrspi/references/` and was not deleted.

Fix: delete the four dead `_shared` snippets and `reviewer-dispatch.md` (5 files total). Update the footprint test to assert existence only for the snippets with ≥1 `!cat` consumer. Keep the references-side versions as the SSoT.

`change_type: correctness`

---

### F04 — `skills/_shared/codex/launch-await-pattern.md` has zero consumers (verifies #278) [P1 dead snippet]

`skills/_shared/codex/launch-await-pattern.md` is referenced only by itself (HTML comment at end: `<!-- Embedded via: !cat skills/_shared/codex/launch-await-pattern.md -->`).

`grep -rln "launch-await-pattern" skills/ agents/ scripts/ tools/ tests/` → only the file itself.

The companion-dispatch flow it describes is fully implemented in `scripts/codex-companion-bg.sh` and in the per-skill prose; no skill or agent file pulls this snippet in. Confirms #278; recommend delete + remove the empty `codex/` subdir.

`change_type: correctness`

---

### F05 — `_shared/precondition-block.md` adopted by 1 of 12 candidate orchestrator skills (verifies #279) [P1 underutilization]

Verified: only `skills/goals/SKILL.md` `!cat`-includes `precondition-block.md`. The other 11 orchestrator-facing pipeline skills (`questions`, `research`, `design`, `phasing`, `structure`, `plan`, `parallelize`, `implement`, `integrate`, `test`, `replan`) do not, even though every one of them would benefit from the same idempotent `qrspi:using-qrspi` precondition.

Two ways to resolve:
- (a) Add the `!cat skills/_shared/precondition-block.md` line to all 11 orchestrator skills (close the gap; SSoT wins).
- (b) Accept that the actual mechanism is the SUBAGENT-STOP rule + the description-tag invocation pattern, and delete `precondition-block.md` as a single-consumer micro-snippet (decentralize per slice-3's centralization-inverse principle).

The snippet body is one line; option (b) is cleaner.

`change_type: scope`

---

### F06 — `_shared/tsc-probe-helper.md` is mis-filed; it's a TypeScript helper README, not a shared prompt-prose snippet [P2 categorization]

`skills/_shared/tsc-probe-helper.md` carries a `name:` + `description:` frontmatter block (the only `_shared` file that does — every other snippet is body-only) and reads as project-level developer documentation for the `templates/tsc-probe.ts` helper. It is not consumed by any SKILL.md or agent (zero `!cat` references); its only reference is one unit test.

Two issues:
1. It's not a `_shared` snippet at all — it's a TS-helper reference doc that should live in `docs/qrspi/` or `templates/README.md`.
2. The `name:` + `description:` frontmatter makes it look like a stand-alone skill — if a host with skills-autodiscovery sees `skills/_shared/tsc-probe-helper.md`, the frontmatter may register it as a skill named `tsc-probe-helper` that nothing dispatches to.

Fix: move the file out of `_shared/` (suggested location: `templates/README.md` or `docs/qrspi/tsc-probe-pattern.md`) and strip the frontmatter.

`change_type: correctness`

---

### F07 — `reviewer-protocol/SKILL.md` and `implementer-protocol/SKILL.md` both contain "This file is designed to grow" meta-prose — R1 violation per the rule set they're a peer to [P1 self-contradiction with own rules]

`skills/reviewer-protocol/SKILL.md:15`:
> "This file is **designed to grow**. Future reviewer-shared content that is transport-neutral ... is added as **additional sections** to this same file rather than as new files. ... The path is stable across edits so the `skills:` preload field and the dispatch pipeline never need to change."

`skills/implementer-protocol/SKILL.md:12`:
> "This file is **designed to grow**. Future implementer-shared content (allowed-files contract, additional dispatch fields, etc.) is added as **additional sections** to this same file rather than as new files. The path is stable across edits so the `skills:` preload field never needs to change."

Both are exactly the "Meta-prose about the document" pattern that R1 (the rules file these documents are subject to) explicitly cuts:

> R1, prompt-design-rules.md:27 — "**Cut these categories:** Meta-prose about the document ('canonical statement of X', 'this section defines Y')"

The orchestrator LLM gains nothing actionable from "this file is designed to grow"; it's instruction for human maintainers about authoring discipline. Strip both paragraphs.

`change_type: clarity`

---

### F08 — `reviewer-protocol/SKILL.md` references PR/issue `#109` as behavior justification — evergreen-markdown rule violation per `implementer-protocol/SKILL.md:133` [P1 self-contradiction with sibling protocol]

`skills/reviewer-protocol/SKILL.md:49`:
> "consumes a per-round `scope_set` derived by the `qrspi-scope-tagger` Haiku subagent (using-qrspi step 6 (scope-tagger dispatch)) AFTER the verifier filter from **#109**."

`skills/implementer-protocol/SKILL.md:133` explicitly enumerates this as a forbidden token in any added line of an edited `.md` file:

> | PR or issue reference as behavior justification | `(see\|per\|fixes\|closes)\s+#\d+` used to justify current behavior | `per #42`, `see #172` | `<!-- evergreen-exempt -->` |

The reviewer-protocol body uses "from #109" without `<!-- evergreen-exempt -->`. If the implementer-protocol's own hygiene scan were applied to the reviewer-protocol body it would flag this line. The two protocol files are siblings and should be consistent.

Fix: either delete "from #109" (the sentence reads fine without it: "...AFTER the verifier filter") or add `<!-- evergreen-exempt -->` if the issue ref is genuinely load-bearing for audit. The former is cleaner.

`change_type: correctness`

---

### F09 — Neither protocol SKILL.md has a `<HARD-GATE>` block at the start; R3 (prompt-design-rules.md:66) requires it [P1 R3 misapplication]

R3 in `prompt-design-rules.md:60-67`:
> "Load-bearing rules at the END... — Repeat the most override-critical rules (Iron Laws) at start AND end of each skill. — Use the start position for hard gates (`<HARD-GATE>` blocks) so primacy enforces them."

`grep "HARD-GATE" skills/reviewer-protocol/ skills/implementer-protocol/` returns:
- `skills/reviewer-protocol/SKILL.md:256` (one mention inside the Anti-Fabrication Rule body, referencing "consumer skill's HARD-GATE" — does not constitute a HARD-GATE block IN this skill)
- `skills/reviewer-protocol/first-party-emission.md:70` (one mention saying "tags failing the regex are a HARD-GATE refusal" — same: a reference, not a HARD-GATE block)
- No matches in `implementer-protocol/`.

Both protocol skills carry IRON-RULE / Iron-law blocks at the *end* of their emission siblings (e.g., `first-party-emission.md:74`, `third-party-emission.md:78`) — R3-end is partially honored. But R3-start (HARD-GATE at the top to enforce override-critical rules by primacy) is unimplemented in either protocol.

The reviewer-protocol IRON RULE for one-finding-per-file (`first-party-emission.md:11`, `third-party-emission.md:11`) is genuinely override-critical (combining findings breaks the verifier change-type partition). It belongs at the start of the SKILL.md and at the end, per R3's "start AND end" prescription. Today it lives only at the start AND end of the *emission* siblings — neither of which is preloaded into reviewer dispatches at the canonical position (see F01 for why the emission siblings aren't shipped at all).

Fix: lift the one-finding-per-file IRON RULE into `reviewer-protocol/SKILL.md` itself, wrap it in a `<HARD-GATE>` block at the top, and restate it at the bottom.

`change_type: correctness`

---

### F10 — `prompt-design-rules.md` "Last applied" date is 12 days stale and is exactly the "Session/drafting notes" antagonist pattern the rules file itself enumerates [P2 self-contradiction]

`prompt-design-rules.md:4`:
> "**Last applied:** 2026-06-02 (rules-file relocation + eight updates A-H). <!-- evergreen-exempt -->"

Current date is 2026-06-14. The `<!-- evergreen-exempt -->` marker is correctly applied (per the implementer-protocol carve-out convention). But the rules-file's own R1 cuts:

> "Session/drafting notes — 'I initially wrote X but then realized Y,' 'as a first pass…,' 'TODO: revisit.' (Substitute: the final decision only)"

And in `evergreen-output-rule.md:21`:
> "| Session / drafting notes | 'Rule X drafting note,' 'this collapsed from 3 to 1 because…' | Nothing — delete. |"

"Last applied: 2026-06-02 (rules-file relocation + eight updates A-H)" is a session/drafting note. The eight-updates parenthetical references private letters (A-H) that the file does not enumerate — a reader has zero way to act on it. The substitute per the rule is: delete the line; if the rule version matters, git log is authoritative.

`change_type: style`

---

### F11 — `prompt-design-rules.md:6-12` is meta-prose about the document — R1 violation in the rules file itself [P2 self-contradiction]

> Line 6: "This document is the canonical rule set for designing and reviewing the prompt content of QRSPI skill files..."
> Lines 8-11: "When to use this guide:"

R1 explicitly cuts: "Meta-prose about the document ('canonical statement of X', 'this section defines Y')". Either the rules file gets an exemption (state it explicitly with a footnote — "This file is human-maintainer-facing as well as agent-facing, hence the framing prose") or the framing prose goes. Currently the file violates its own R1 without acknowledging the exemption.

`change_type: clarity`

---

### F12 — `prompt-design-rules.md:62` — model-era calibration claim references models that may be obsolete and pins specific behavior to specific models [P2 stale rule-set claim]

R3 body, line 62:
> "May 2026 status: confirmed on Opus 4.7-high and GPT-5.5 (end-of-context placement still yields measurable improvement; the magnitude is reduced at shorter context lengths but the ordering principle holds). GPT-5.3-Codex: confirmed... Sonnet 4.6: confirmed (consistent with Opus 4.6 pattern)."

Concerns:
- Pinning calibration to specific models (Opus 4.7-high, GPT-5.5, Sonnet 4.6) means each new model release silently invalidates the claim. The rules file's own audit pass instruction (`prompt-design-rules.md:226-229`) acknowledges this: "When a new Claude or Codex model lands (rules may need recalibration)."
- The dated phrase "May 2026 status" is itself the version-history narration antagonist from `evergreen-output-rule.md:25` ("previously," "originally").
- The line is marked nowhere with `<!-- evergreen-exempt -->`.

Fix: replace the model-specific paragraph with a model-neutral statement ("end-of-context placement remains measurably better than mid-context across frontier-class models; magnitudes vary by model and context length") and let the audit-cadence section handle recalibration. Move the dated model-specific evidence to `docs/qrspi/` if it needs to be preserved.

`change_type: style`

---

### F13 — `prompt-prose-reviewer/SKILL.md` and `prompt-prose-writer/SKILL.md` are 17-line wrappers around `_shared` snippets that include 3- and 6-line additions — consolidation candidates [P2 micro-skill bloat]

Both 17-line SKILLs (`skills/prompt-prose-{reviewer,writer}/SKILL.md`) are nothing but:
- A description frontmatter
- An `!cat` of `_shared/prompt-prose-detection.md`
- An `!cat` of a 3-line (writer) or 6-line (reviewer) `*-addition.md`
- A 3-line guard comment

The "additions" are 3 and 6 lines respectively. The detection snippet is shared. Four files for what is effectively two unique paragraphs (reviewer-side application + writer-side application).

Consolidation paths to consider:
- **(a) Fold writer-side and reviewer-side additions into a single `_shared/prompt-prose-application.md` snippet** that consumers `!cat` directly. Delete the two micro-SKILLs and the `*-addition.md` micro-snippets. Consumers (the reviewer agents and `skills/{design,plan}/SKILL.md`) already know whether they are reviewing or authoring; they can `!cat` the same snippet and the addition body can be conditional prose.
- **(b) Or, keep the two micro-SKILLs but inline the addition content into them.** This drops the `_shared/prompt-prose-*-addition.md` micro-snippets (3 files: reviewer-addition.md, writer-addition.md, test-expectations-clause.md — the last is single-consumer per the consumer-count table). The cost is duplicating the detection snippet body across the two SKILLs.

Net: 5 files of `_shared/prompt-prose-*` content + 2 micro-SKILLs = 7 files for what is conceptually three paragraphs (detection, writer-side, reviewer-side, plus a single-consumer test-expectations clause). This is the "sprawling library of micro-skills" that the user's own copilot instructions warn against ("a sprawling library of micro-skills is worse than a small library of class-level umbrella skills").

`change_type: scope`

---

### F14 — `reviewer-dispatch.md` and `reviewer-dispatch-prose.md` are near-verbatim siblings; only one has consumers [P0 dead-file]

The two files differ mainly in section-heading structure and intro prose; the dispatch body is structurally identical. `reviewer-dispatch-prose.md` has 13 `!cat` consumers; `reviewer-dispatch.md` has 0. The latter is preserved only by the footprint test (see F03).

Recommend delete `reviewer-dispatch.md` and remove it from the footprint test's existence assertion list.

`change_type: correctness`

---

### F15 — `verifier-dispatch-prose.md:1-9` carries a 9-line HTML-comment header citing internal section IDs ("design.md CD-4 §H L494", "CD-1 §11"); these are routing/traceability metadata that should be in commit log / git blame, not skill-prose [P2 evergreen violation]

```
<!-- skills/_shared/verifier-dispatch-prose.md
     Shared verifier-dispatch snippet, `!cat`-included into:
       - skills/using-qrspi/SKILL.md   (artifact-level Apply-fix protocol)
       - skills/implement/SKILL.md     (task-level Apply-fix protocol)
     Source of truth: design.md CD-4 §H + structure.md Slice 1.1.
     Mirrors skills/_shared/reviewer-dispatch-prose.md (CD-1 §11). The two
     snippets are deliberately separate because each names a different
     `dispatch-agent.sh` mode flag at the call site (the load-bearing
     difference) — see design.md CD-4 §H rationale (L494). -->
```

This is the "Inside baseball" antagonist pattern from `evergreen-output-rule.md:26`:
> "text addressed to 'us' / 'the author,' meta-explanation of the document's own structure"

It also pins to a line number ("L494") which R1, prompt-design-rules.md:32 explicitly cuts ("Stale code snippets — use file-path or section-heading references instead, never line numbers (they rot)").

Fix: strip the HTML-comment block. The snippet itself reads fine without it.

`change_type: style`

---

### F16 — `feedback-format.md` (`_shared`) and `feedback-file-format.md` (`using-qrspi/references/`) drift: schema identical, framing prose divergent, neither cross-references the other [P1 SSoT divergence]

Specific diff:

| `_shared/feedback-format.md` | `using-qrspi/references/feedback-file-format.md` |
|---|---|
| Title: "# Feedback File Format (shared)" | (no title) |
| Frame: "Single source of truth..." | Frame: "When a user rejects an artifact, the feedback is captured in..." |
| Footer: "The new subagent receives the original inputs plus this feedback file." | Footer: "The new subagent receives the original inputs + this feedback file." |
| 29 lines | 18 lines |

The YAML body in the middle (`step:`, `round:`, `rejected_artifact:` + the `## User Feedback` and `## Previous Artifact` sections) is identical. The `_shared` file frames itself as the SSoT but is referenced by zero `!cat` consumers; the references-side file is the actually-loaded one. Either:
- Delete `_shared/feedback-format.md` and merge any unique framing into `references/feedback-file-format.md`. (Recommended — matches the actual data flow.)
- Or convert `references/feedback-file-format.md` to a one-line `!cat skills/_shared/feedback-format.md` include and let the `_shared` file actually be the SSoT it claims to be.

Subset of F03 but called out separately because the wording-level drift ("plus" vs "+", different opener) is the kind of silent divergence that compounds.

`change_type: correctness`

---

### F17 — `_shared/pause-gate.md` claims SSoT for the Review-Loop Pause Gate but is bypassed by `using-qrspi`; the contents differ on the load-bearing `## Iron Rule` / heading taxonomy [P1 SSoT divergence with load-bearing content drift]

Same pattern as F16 but more severe: `_shared/pause-gate.md` (47 lines, with formal `## BATCH-WITH-OVERRIDES UI contract` / `## 3-option menu` / `## Pending-findings file` headings + a "Write timing: fail-closed precondition" paragraph) vs `using-qrspi/references/review-loop-pause-gate.md` (45 lines, with `### BATCH-WITH-OVERRIDES UI contract` / `### 3-option menu` + the "Write timing" paragraph and "Pending-findings file" section absent — the latter is folded into prose differently).

The references-side file is the one actually `!cat`-loaded into using-qrspi/SKILL.md:592. The `_shared` version's framing claim ("Single source of truth for the Review-Loop Pause Gate UI") is materially false; it diverges from the actually-loaded version on a structural taxonomy (H2 vs H3 headings break anchor-based references).

Same fix shape as F16.

`change_type: correctness`

---

### F18 — `notifications.md` (implementer-protocol sibling) defines a separate `notifications:` capability via frontmatter — competes with the parent SKILL.md frontmatter [P2 frontmatter pollution]

`skills/implementer-protocol/notifications.md:1-4`:
```
---
name: notifications
description: Sibling-notification protocol — how cross-task contract changes surface to dependent tasks
---
```

This is a sibling-file under `skills/implementer-protocol/` (an existing skill's directory), but it carries `name: notifications` frontmatter that on a host with broad skills-autodiscovery would register it as a competing skill named `notifications`. The other sibling under `implementer-protocol/` (`SKILL.md`) is the canonical skill entry.

Same risk as F06 — the host may try to dispatch to `notifications` as if it were a top-level skill. Compare to e.g. `skills/reviewer-protocol/first-party-emission.md` which has NO frontmatter at all (correct sibling-file shape).

Fix: strip the `name:` + `description:` frontmatter. The sibling file is consumed via the `[notifications.md](notifications.md)` markdown link in `implementer-protocol/SKILL.md:29` — it does not need or want its own skill identity.

`change_type: correctness`

---

## Cross-file patterns

1. **"Single source of truth" framing is a tell.** Five `_shared` snippets claim to be the SSoT for something (`compaction-checkpoint.md`, `config-validation.md`, `feedback-format.md`, `pause-gate.md`, `review-loop.md`). Four of those five are actually superseded by a `using-qrspi/references/*.md` file that is the real SSoT (F03, F16, F17). Pattern: when a snippet's first paragraph asserts SSoT status, audit whether anything actually `!cat`s it.

2. **The SKILL.md-references vs `_shared` split is doing double duty for the same content.** `using-qrspi/SKILL.md` `!cat`-includes its own `references/*.md` files for content that is conceptually cross-cutting (pause gate, review loop, compaction). The `_shared/` directory ALSO has files for those same concerns. Decision: pick one home and migrate. The `references/` home wins by usage; the `_shared/` home wins by name-purity. Either way, eliminate the duplication.

3. **Frontmatter on sibling files is a foot-gun.** `tsc-probe-helper.md` and `notifications.md` are both sibling files (not entry SKILL.md files for a skill directory) but carry `name:`/`description:` frontmatter, which on hosts with broad skill-discovery would make them appear as standalone skills. The convention in `reviewer-protocol/first-party-emission.md` and `reviewer-protocol/third-party-emission.md` (no frontmatter) is correct. F06 and F18 should be fixed for consistency.

4. **"R1-R7" vs "R1-R8" drift (F02) is the canonical example of `_shared`-snippet rule-set drift.** The rule set grew an R8; the consumers were never updated. Without a lint test that asserts "every reference to the prompt-design rules names the current rule range," every future rule addition will be silently dropped by every consumer. Recommend a `tests/lint/test-prompt-design-rule-range.bats` that greps for `R1-R[0-9]` across `_shared` + `prompt-prose-*` and pins the upper bound.

5. **Footprint test asserts existence, not consumption (F03 root cause).** `tests/acceptance/v07-phase1-test-phase/test-g9-footprint.bats` checks that six `_shared` snippets EXIST but does not check that anything CONSUMES them. A test that asserts existence-of-include-target is half a contract; the other half is "and the target is included somewhere." Recommend a stronger lint: for each file in `skills/_shared/`, require at least one `!cat skills/_shared/<basename>` match across `skills/` + `agents/` OR an explicit allow-list of files that are intentionally read-by-Read (like `prompt-design-rules.md`).

---

## Centralization opportunities (INVERSE — consolidation + decentralization of micro-snippets)

Net direction for slice 3 is to **shrink** `_shared/`, not grow it. Concrete moves, ordered by safety:

**Tier 1 — pure deletes (no consumers to update):**
- DELETE `skills/_shared/reviewer-dispatch.md` (superseded by `-prose` variant; F14)
- DELETE `skills/_shared/compaction-checkpoint.md` (superseded by `using-qrspi/references/compaction-checkpoints-detail.md`; F03)
- DELETE `skills/_shared/feedback-format.md` (superseded by `using-qrspi/references/feedback-file-format.md`; F03, F16)
- DELETE `skills/_shared/pause-gate.md` (superseded by `using-qrspi/references/review-loop-pause-gate.md`; F03, F17)
- DELETE `skills/_shared/review-loop.md` (superseded by `using-qrspi/references/review-loop-pause-gate.md` + inlined content in `using-qrspi/SKILL.md`; F03)
- DELETE `skills/_shared/config-validation.md` (superseded by `config-validation-procedure.md` and the inline tables in `using-qrspi/SKILL.md`; F03)
- DELETE `skills/_shared/codex/launch-await-pattern.md` + remove `skills/_shared/codex/` directory (F04, verifies #278)
- UPDATE `tests/acceptance/v07-phase1-test-phase/test-g9-footprint.bats:46-55` to drop the six deleted-file existence assertions.

**Tier 2 — merge / re-home:**
- MERGE `first-party-emission.md` + `third-party-emission.md` + `stdout-fallback-emission.md` into a single `skills/reviewer-protocol/emission.md` describing the unified wire format with a one-paragraph host-capability branch. Update `reviewer-protocol/SKILL.md` to acknowledge the unified model (drop the "no third path" claim). Update `scripts/dispatch-agent.sh` to point `EMISSION_OVERRIDE_ABS` at the unified file. (F01)
- MERGE `prompt-prose-reviewer-addition.md` + `prompt-prose-writer-addition.md` + `prompt-prose-test-expectations-clause.md` into a single `_shared/prompt-prose-application.md`. Inline `prompt-prose-detection.md` into the same file (it's a 30-line snippet that always travels with the application prose). Delete `skills/prompt-prose-reviewer/SKILL.md` and `skills/prompt-prose-writer/SKILL.md` — fold their guards into the merged snippet. (F13)
- RE-HOME `skills/_shared/tsc-probe-helper.md` → `templates/README.md` or `docs/qrspi/tsc-probe-pattern.md`. Strip the SKILL-style frontmatter. (F06)
- STRIP `name:`/`description:` frontmatter from `skills/implementer-protocol/notifications.md` (sibling files should not look like standalone skills). (F18)

**Tier 3 — restructure:**
- DECIDE on `_shared/precondition-block.md` (F05): either add the `!cat` line to all 11 missing orchestrator skills (close the gap) OR delete the one-line single-consumer snippet (decentralize). The decision belongs to the maintainer; my recommendation is delete (1-line snippets fail the R5 sharding test by definition).
- Fix the `R1-R7` → `R1-R8` drift in all five consumer files (F02). Add the lint test described in cross-file pattern 4.

Estimated `_shared/` reduction after Tier 1+2: from 22 files to ~12 files, with no functional regression and one outright contract bug closed (F01).

---

## Acknowledgements

- **#278 (codex/launch-await-pattern.md zero consumers):** confirmed. See F04.
- **#279 (precondition-block.md adopted by 1 of 12+ consumers):** confirmed exactly. See F05.
- **#310 (skill body bloat + stale dispatch-script references):** related — F07 (designed-to-grow meta), F08 (#109 ref), F15 (verifier-dispatch-prose header comment), F12 (model-era pinning). The reviewer-protocol and implementer-protocol bodies carry their own version of this pattern.
- **#283, #288, #294 (Codex/Copilot-CLI tool-availability inconsistencies in reviewer dispatch):** the *root* of this cluster is F01 — the protocol SKILL.md asserts a two-path emission model that the dispatcher does not implement. Once F01 is fixed (unified emission contract with explicit host-capability branch), the consumer-side inconsistencies have a single rule to follow.
- **#297 (artifact_path as primary reviewer-dispatch input for large artifacts):** outside slice 3's surface — the dispatch-contract section names `artifact_body` as the wrapped-input primary, not a path. No finding in this slice; flagged for slice that owns dispatch sites.
- **#270, #269, #267 (review-infra follow-ups):** consistent with the F03 / F14 / F01 cleanup direction. F14 (delete `reviewer-dispatch.md`) is the cheapest example.
- **#321 (closed — verifier sidecar `.score.yml` vs `.score.md`):** verified resolved — every reference in this slice (`reviewer-protocol/SKILL.md:61`, `verifier-dispatch-prose.md:49,67`, `verifier-filter-rule.md:3`) uses `<reviewer-tag>.finding-F<NN>.score.md` consistently. No drift remains in slice-3 files.
- **#305, #307, #277:** outside this slice (CLAUDE.md / plugin-manifest / defect_class tokens) — no finding in slice 3.

---

## Declined

- **Long sentences in `reviewer-protocol/SKILL.md:47` (scope_hint bullet, ~600 words).** Long but every clause carries behavioral signal (the empty-value equivalence, the Codex-vs-Claude asymmetry rationale, the wrapper-contract pin). R8's "What NOT to tighten" carve-out for "Lists whose items each name a distinct behavior" and "Verbatim contracts, named diagnostic strings" applies. Not a finding.
- **`R5 / spine-vs-references` concern for `using-qrspi/SKILL.md` `!cat`-including `references/*.md`.** Could read as a violation of R5's "spine + references saves zero tokens if the spine always instructs the read", but the actual mechanism is build-time `!cat` inlining — no runtime tool call by the agent. R5's concern is about agents making tool calls to discover content; that does not apply here. Not a finding.
- **Mermaid in `_shared/design-altitude-boundary.md:9, 21`.** The mentions are about Mermaid diagrams *inside design.md as an artifact*, not Mermaid *in this skill prose*. R6 cuts Mermaid from skill prose — design.md is an artifact, not skill prose. Not a finding.
- **`evergreen-output-rule.md` carve-out list (`feedback/*.md`, `reviews/**/*.md`).** The carve-out treats reviewer findings as exempt from the evergreen rule — which is correct (a finding is by nature an observation about a prior state). Consistent with the implementer-protocol's `reviews/**` carve-out (`implementer-protocol/SKILL.md:149`). Not a finding.
- **`prompt-design-rules.md:219` mentions `v0.7.2` with `<!-- evergreen-exempt -->`.** Correctly carved out. Not a finding.
- **`implementer-protocol/SKILL.md:131-133` examples carry `v0.7`, `v1.2`, `in v0.7`, `per #42`, `see #172` literals.** Inside a code-block table whose subject IS the forbidden-token regex shape — the examples ARE the test surface. The table itself carries `<!-- evergreen-exempt -->` on each line. Correctly carved out. Not a finding.

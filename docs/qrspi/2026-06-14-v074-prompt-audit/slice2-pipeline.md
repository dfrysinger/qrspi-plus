# Slice 2 audit: pipeline-step skills

> **Output-path note.** The dispatch asked for `/tmp/v073-audit/slice2-pipeline.md`, but
> `/tmp` writes are blocked by the runtime sandbox in this session. The report is written
> to `.audit-output/slice2-pipeline.md` inside the repo root instead. Move/copy as needed.

## Summary

- Files audited: 14 (9 SKILL.md + 3 owns-defers.md + 6 references/*.md, plus cross-checks against `_shared/design-altitude-boundary.md` and `using-qrspi/SKILL.md`)
- Total findings: 21 (blocker: 4, high: 9, medium: 8)
- Cross-file redundancies found: 4
- Stale references found: 8

The two highest-priority findings are F01 (cross-pipeline `codex_reviews:` zombie field — orchestrator says it's a hard validation error, six skills still validate it) and F02 (`## Test Strategy` section is required by Design's visual-fidelity gate and by Phasing's precondition assertion, but Design's own DEFERS list forbids it and Design's template doesn't author it). Both are architectural defects, not nits.

## Findings

### F01 — `codex_reviews:` is removed by using-qrspi but six slice-2 skills still validate it
- file: skills/questions/SKILL.md ; skills/research/SKILL.md ; skills/design/SKILL.md ; skills/structure/SKILL.md ; skills/phasing/SKILL.md ; skills/replan/SKILL.md
- line_range: questions [25,25], research [23,23], design [169,169], structure [34,38], phasing [29,31], replan [42,44]
- severity: blocker
- rule_violated: architectural (contradicts `using-qrspi/SKILL.md` — the orchestrator)
- evidence: questions L25 — `"Read config.md from the artifact directory to determine whether Codex reviews are enabled. If config.md doesn't exist, default to codex_reviews: false."`; structure L38 — `"Structure validates codex_reviews."`; phasing L31 — `"Phasing validates codex_reviews (expected true or false)"`; replan L44 — `"Replan validates codex_reviews."`; design L169 — `"Design validates codex_reviews."`; cross-check using-qrspi L112 — `"codex_reviews: removed — legacy name for second_reviewer. A stray codex_reviews: field in config.md is a hard validation error, never silently aliased."`
- problem: The orchestrator (`using-qrspi`) says `codex_reviews:` is removed AND that a stray instance in `config.md` is a hard validation error with no aliasing. Six slice-2 skills still instruct the orchestrator to validate the legacy field. A run where the user follows Goals (which writes `second_reviewer:`) hits Phasing/Design/Structure/Replan and gets told to validate a field that does not exist — at best a no-op, at worst a halt menu loop. Questions and Research also default `codex_reviews: false` when `config.md` is missing, which now contradicts the rename diagnostic.
- proposed_fix: Replace every `codex_reviews` reference in slice-2 skills with `second_reviewer`. For Questions/Research the "Read config.md to determine whether Codex reviews are enabled" sentence should read "Read config.md to determine whether second-reviewer dispatch is enabled" with default `second_reviewer: false`. Drop the legacy term entirely.
- links_to_existing_issue: none (this is fresh; not in the prior-context issue list)

### F02 — `## Test Strategy` section is required by Design's visual-fidelity gate, forbidden by Design's own DEFERS, and absent from the Design template
- file: skills/design/SKILL.md ; skills/_shared/design-altitude-boundary.md ; skills/design/references/design-md-template.md ; skills/phasing/SKILL.md ; skills/phasing/references/visual-fidelity-precondition.md
- line_range: design SKILL [229,234] and [269,269]; design-altitude-boundary [10,10] and [22,22]; design-md-template [1,34]; phasing SKILL [136,136]; phasing visual-fidelity-precondition [5,12]
- severity: blocker
- rule_violated: contradiction (internal: same skill OWNS contract forbids a section the skill's own precondition requires)
- evidence: design SKILL L231 — `"## Test Strategy contains a ### Visual-Fidelity Binding subsection."`; design-altitude-boundary L10 — `"design.md does NOT carry a top-level Test Strategy section stitching acceptance criteria across goals (Structure's job)."`; design-altitude-boundary L22 (DEFERS) — `"Unified Test Strategy / Test Architecture section that stitches per-solution acceptance criteria … (Structure's job…)"`; phasing SKILL L136 — `"Every UI-producing phase must cite at least one wireframe artifact (named in design.md ## Test Strategy's visual-fidelity binding subsection)"`; design-md-template authors only `## Approach`, `## Key Decisions`, `## Trade-offs Considered` — no `## Test Strategy`
- problem: When a run carries `visual_fidelity_required: true`, the Design precondition asserts `## Test Strategy` exists. But Design's locked OWNS/DEFERS contract (the artifact the scope-reviewer dispatches against) explicitly DEFERS the entire `## Test Strategy / Test Architecture` H2 to Structure. The Design template does not author the section either. So the synthesis subagent will (a) follow the template and not author `## Test Strategy`, (b) get halted by the precondition, (c) loop back to re-synthesis, (d) re-read the OWNS/DEFERS contract that forbids the section, (e) loop indefinitely. Phasing's precondition compounds the bug by reading the same forbidden section from design.md to discover legal wireframe artifact names.
- proposed_fix: Pick one home for the visual-fidelity binding and synchronize the three contracts. Two viable resolutions: (A) carve a narrow `## Test Strategy` exception into design-altitude-boundary.md (e.g., "Design DEFERS the unified Test Strategy/Architecture section, **except** for a `### Visual-Fidelity Binding` subsection naming wireframe artifacts when `visual_fidelity_required: true`"), add the section to design-md-template.md as a conditional block, and keep phasing's reference. (B) Move visual-fidelity binding to Structure's `## Test Architecture` (which already exists per Structure SKILL L205) and rewrite Design's precondition + Phasing's reference to target Structure. (A) is the smaller change; (B) is more consistent with the existing ownership boundary. Either way the three files must agree.
- links_to_existing_issue: adjacent to #270 (Cite Check infra) but not the same — this is a structural contradiction, not a citation gap

### F03 — Structure's "canonical heading set" omits the two H2s Structure is required to author
- file: skills/structure/SKILL.md
- line_range: [83,85], [133,149], [205,216]
- severity: high
- rule_violated: contradiction (internal: canonical heading set vs. authoring instructions)
- evidence: L85 — `"Required-section heading match: the headings below (## File Map, ## Interfaces, ## Architectural Diagram, ## CI Pipeline) are the canonical set; do not silently rename."`; L133 — `"## UI Reference Affordances (required when any task carries lift_source:; omit otherwise)"`; L205 — `"## Test Architecture"`; L207 — `"Author the unified ## Test Architecture section in structure.md after Design approval."`
- problem: The conformance reminder pins four canonical H2s and says "do not silently rename." But the same SKILL.md later mandates two additional H2s (`## UI Reference Affordances`, `## Test Architecture`) that are not in the canonical list. A subagent reading the template + conformance reminder linearly will treat the two extra headings as drift to be stripped; a scope-reviewer applying the conformance reminder will flag them as boundary violations. The lift-source gate (L181-186) then refuses approval when `## UI Reference Affordances` is missing — guaranteeing a stuck round when the upstream rule said the section must not exist.
- proposed_fix: Extend the canonical set on L85 to six headings: `## File Map`, `## Interfaces`, `## Architectural Diagram`, `## CI Pipeline`, `## Test Architecture` (always required), `## UI Reference Affordances` (conditional on `lift_source:` tasks). Update the template (L87-149) to author `## Test Architecture` as a top-level block matching the procedure at L209-214.
- links_to_existing_issue: none directly; tangentially related to #269 (scope-completeness reviewer)

### F04 — Parallelize's review-loop step is duplicated verbatim, with the second copy mis-numbered "4."
- file: skills/parallelize/SKILL.md
- line_range: [196,197]
- severity: high
- rule_violated: rule-violation (R1 — content the orchestrator doesn't act on) and factual (broken numbering)
- evidence: L196 — `"Apply fixes; loop until clean (default) or present at user request. Findings tagged change_type: scope or change_type: intent … pause the loop … style / clarity / correctness findings auto-apply."`; L197 — `"4. Apply fixes; loop until clean (default) or present at user request. Findings tagged change_type: scope or change_type: intent … pause the loop … style / clarity / correctness findings auto-apply."`
- problem: The same sentence appears twice back-to-back. The second instance carries an orphan list marker `4.` even though there is no enclosing 1/2/3 list — it's a leftover from a prior numbered procedure. Duplicated load-bearing instructions either confuse the orchestrator on intent (which copy wins?) or get treated as emphasis. Either way, R1 fails.
- proposed_fix: Delete L197 entirely. Drop the orphan numeric marker.
- links_to_existing_issue: none

### F05 — Parallelize Red-Flag says "the four symbolic values" but the Branch Model defines five (or six with the suffix grammar)
- file: skills/parallelize/SKILL.md
- line_range: [81,87], [223,223], [326,326]
- severity: high
- rule_violated: contradiction (within file)
- evidence: L81-87 enumerate five symbolic-base names: `feature branch tip`, `task-NN tip`, `stage-after-W{N}`, `stage-after-W{N}{suffix}`, `task-00 tip`; L223 (Red Flag) — `"A Base column entry is something other than the four symbolic values defined in the Branch Model (no commit hashes, no improvised names)"`; L326 (Iron Law final reminder) lists FIVE — `"feature branch tip, task-NN tip, stage-after-W{N}, stage-after-W{N}{suffix} (e.g., stage-after-W2a), task-00 tip"`
- problem: A reviewer auditing parallelization.md against the Red Flag will incorrectly flag the legitimate fifth value (`task-00 tip`) or the suffixed-stage form. Three locations in one file disagree on the count.
- proposed_fix: L223 should read "something other than the five symbolic values" (or "six counting the suffixed stage form"). The cleanest fix is to drop the count and reference the enumeration: `"A Base column entry is not one of the symbolic values listed in the Branch Model § Symbolic base vocabulary (no commit hashes, no improvised names)."`
- links_to_existing_issue: none

### F06 — Goals' Next-Phase Restart description misses `questions.md` and the three other future-* files
- file: skills/goals/SKILL.md
- line_range: [51,51]
- severity: high
- rule_violated: factual (contradicts replan/SKILL.md and phasing/SKILL.md)
- evidence: goals L51 — `"Replan auto-populates the draft goals.md from roadmap.md + future-goals.md: Replan reads roadmap.md for the next phase's goal IDs, extracts matching entries from future-goals.md, and writes them as the new draft goals.md (status: draft). artifact_promote_next_phase has reset goals/research/design frontmatter to draft and deleted phase-scoped files (structure.md, plan.md, tasks/)."`; replan L161-162 — `"Extract from future-* artifacts — for each of future-goals.md, future-questions.md, future-research-summary.md, future-design.md … Write next-phase drafts — write four next-phase artifact drafts in the artifact directory: goals.md, questions.md, research/summary.md, design.md."`
- problem: Goals' restart-mode prose says Replan only populates `goals.md` from `future-goals.md`. The actual Replan contract populates four drafts from four future-* files. Goals' description also omits `questions.md` from the list of artifacts whose frontmatter Replan reset to `draft` — a four-artifact reset described as a three-artifact reset, plus a one-file populate described where there are four. A Goals run resuming in Next-Phase Restart Mode will read a stale spec and may halt under its own fail-closed preconditions ("4. The draft contains ≥1 goal whose ID matches…" L65) without ever knowing why the other three drafts also exist.
- proposed_fix: Rewrite L51: `"Replan auto-populates four next-phase drafts (goals.md, questions.md, research/summary.md, design.md) from the four future-*.md artifacts (future-goals.md, future-questions.md, future-research-summary.md, future-design.md) per the goal-ID set in roadmap.md. artifact_promote_next_phase has reset goals/questions/research/design frontmatter to draft and deleted phase-scoped files (structure.md, plan.md, tasks/). The phases/phase-NN/ snapshot exists; config.md carries the original route and pipeline."`
- links_to_existing_issue: none

### F07 — Phasing's DEFERS routes "test strategy" to Design; Design DEFERS it to Structure; Structure OWNS it — three-way disagreement
- file: skills/phasing/owns-defers.md ; skills/_shared/design-altitude-boundary.md ; skills/structure/SKILL.md
- line_range: phasing/owns-defers [16,16]; design-altitude-boundary [10,10] and [22,22]; structure SKILL [16,16]
- severity: high
- rule_violated: contradiction (cross-file boundary-ownership disagreement)
- evidence: phasing/owns-defers L16 (Phasing DEFERS) — `"Architecture, key decisions, system diagram, test strategy → owned by Design."`; design-altitude-boundary L10 — `"design.md does NOT carry a top-level Test Strategy section stitching acceptance criteria across goals (Structure's job)."`; design-altitude-boundary L22 — `"Unified Test Strategy / Test Architecture section that stitches per-solution acceptance criteria from individual goal/CD blocks into a release-wide test plan … (Structure's job…)"`; structure SKILL L16 — `"Structure authors: … unified test architecture (the ## Test Architecture section in structure.md); and per-type stitching of per-solution acceptance criteria from design.md."`
- problem: Phasing scope-reviewer thinks any "test strategy" content in phasing.md must point to Design; Design scope-reviewer thinks any unified test strategy in design.md must point to Structure; Structure thinks it owns it. A reviewer chain that pivots through `phasing.md → design.md → structure.md` will keep bouncing the same finding. Also see F02 — this is the upstream of the visual-fidelity collision.
- proposed_fix: Settle the boundary in one place (proposal: per-solution Acceptance lives in Design's per-goal blocks; unified `## Test Architecture` lives in Structure; "Test Strategy" as a phrase is retired). Then rewrite phasing/owns-defers L16 to route "test strategy" to Structure (not Design), and align design-altitude-boundary + structure SKILL on the term `## Test Architecture` (not `## Test Strategy`).
- links_to_existing_issue: #276 (helper drift — same family of vocabulary drift) and F02 (Test Strategy collision)

### F08 — Replan companion-prep prose says "both Claude dispatches" but the dispatch fans out to four reviewers when `second_reviewer: true`
- file: skills/replan/SKILL.md
- line_range: [111,121], [123,123], [125,131]
- severity: medium
- rule_violated: factual (contradicts the per-skill REVIEW_AGENTS line in the same section)
- evidence: L111 — `"Companion preparation. Construct the wrapped companion bodies once and reuse the analyzer's response payload across both Claude dispatches:"`; L123 — `"The two reviewers — qrspi-replan-reviewer (quality) and qrspi-replan-scope-reviewer (scope) — run in parallel reviewer dispatches once the analyzer has returned"`; L130 — `REVIEW_AGENTS="quality-claude=qrspi-replan-reviewer,scope-claude=qrspi-replan-scope-reviewer,quality-codex=qrspi-replan-reviewer,scope-codex=qrspi-replan-scope-reviewer"`
- problem: "Both Claude dispatches" and "two reviewers" describe the no-second-reviewer case; the REVIEW_AGENTS line below dispatches four when `second_reviewer: true`. The companion-prep prose tells the orchestrator to reuse the payload twice; the dispatch tells it to reuse four times. A literal reader could plumb the payload into the two Claude tags and forget the two Codex tags.
- proposed_fix: Rewrite L111 — `"Construct the wrapped companion bodies once and reuse the analyzer's response payload across all reviewer dispatches in REVIEW_AGENTS below (two Claude dispatches, plus two Codex dispatches when second_reviewer: true)."` Rewrite L123 to use "the reviewer pair" wording, not "the two reviewers".
- links_to_existing_issue: none

### F09 — Replan references a "3-round convergence in Pattern 1/2" with no Pattern 1 or Pattern 2 defined anywhere in the skill
- file: skills/replan/SKILL.md
- line_range: [135,135]
- severity: medium
- rule_violated: factual (broken cross-reference) / R1 (orphan inside-baseball)
- evidence: L135 — `"- Fix issues, ask user 1) Present 2) Loop until clean (recommended), loop or present (max 10 rounds — this is the standard using-qrspi review loop cap, distinct from the 3-round convergence in Pattern 1/2)."`
- problem: "Pattern 1/2" is not defined in replan/SKILL.md or using-qrspi/SKILL.md (verified via grep; the only "Pattern" mentions in slice-2 are unrelated). The parenthetical is dialogue-exhaust drift from an earlier authoring round where the skill named numbered patterns explicitly. R1 says cut content the orchestrator can't act on; an orphan reference to a non-existent pattern is the canonical case.
- proposed_fix: Drop the parenthetical entirely. The "max 10 rounds" claim already names its source (`using-qrspi review loop cap`).
- links_to_existing_issue: none

### F10 — Parallelize references/worked-examples.md duplicates the Good example inline in SKILL.md (R5 misapplication)
- file: skills/parallelize/SKILL.md ; skills/parallelize/references/worked-examples.md
- line_range: SKILL [247,295]; references/worked-examples [1,49]
- severity: medium
- rule_violated: rule-violation (R5)
- evidence: SKILL L249-295 carries the full Good worked example (Execution Mode/Rationale/Dependency Analysis table/Branch Map/Stage Commits). worked-examples.md L1-49 carries an identical Good example (same Hybrid mode, same task names, same Wave assignments, same Stage Commits table) before its Multi-Stage Suffix and Reference-Gate sections.
- problem: R5 — `references/` only when reads are genuinely optional. The Good example is inlined in the spine; the same content is repeated in references/. No tokens are saved; the references/ file's R5 claim ("Two additional examples … live at …" L245) is only true for the two new examples, not the first one.
- proposed_fix: Drop the duplicated Good example from worked-examples.md (start the file at the Multi-Stage Suffix example). The references/ file then contains only the two truly-additional examples; the inline Good example is sufficient.
- links_to_existing_issue: none

### F11 — Phasing has no compaction-resilient incremental-persistence contract despite a multi-decision interactive discussion
- file: skills/phasing/SKILL.md
- line_range: [54,63]
- severity: medium
- rule_violated: rule-violation (cross-cutting "Compaction-resilient prompt design" principle)
- evidence: L58-63 — `"Interactive Phasing Discussion: 1. Read goals.md, questions.md, research/summary.md, design.md and present a proposed slice decomposition … 2. Discuss with the user: which slices belong in Phase 1 … 3. Collect amendment items from the user: any new slices introduced here must receive their own goal IDs in roadmap.md … 4. Once the slice set and phase grouping settle, hand off to the synthesis subagent."` Phasing has NO "Incremental Persistence" or "Resume after compaction" section, in contrast to goals/SKILL.md L120-145 and design/SKILL.md L125-153.
- problem: The cross-cutting Compaction-resilient design principle says: "when an orchestrator-driven skill spans enough decisions to risk mid-phase `/compact` firing (Goals, Design at scale), the SKILL.md prose must (1) instruct incremental persistence to the final artifact under `status: draft`, (2) instruct a recovery diagnostic on resume, and (3) instruct the orchestrator to re-read the in-progress artifact to enumerate locked decisions before continuing." Phasing's discussion is the second-largest interactive surface in the pipeline (10 artifacts to keep coherent, including 4 prunes and 4 future-* files). The atomic single-emission subagent at L77-89 means any compaction during steps 1-3 loses the entire discussion. Issue #285 already filed a parallel concern for Design's incremental persistence; Phasing is the structurally analogous gap.
- proposed_fix: Add an `### Incremental Persistence (Direct-to-Artifact Drafting)` section after `### Interactive Phasing Discussion` that mirrors the Design pattern: write each settled slice and each settled phase boundary into phasing.md `## Slices` / `## Phases` under `status: draft` as it locks; on resume, read the draft to enumerate locked decisions; finalize-pass flips to `status: approved`. The four prunings and four future-* files remain atomic — only the discussion's slice/phase decisions need incremental persistence.
- links_to_existing_issue: #285 (same family — Design incremental persistence)

### F12 — Research hard-codes `model: "sonnet"` for both specialist and collator dispatches
- file: skills/research/SKILL.md
- line_range: [60,60], [99,99]
- severity: medium
- rule_violated: factual (potentially contradicts model-routing config; at minimum violates "trust config" R1 cut)
- evidence: L60 — `Agent({ subagent_type: "qrspi-research-specialist", model: "sonnet" })`; L99 — `Agent({ subagent_type: "qrspi-research-collator", model: "sonnet" })`. Compare research/SKILL.md L77-83 — `"the role's trusted_path: route from config.md's model_routing: table, OR the trusted-tier default from the routing matrix in skills/implement/SKILL.md § G5 Initial Routing Matrix"` (the citation-density-rerun path uses a config-driven model selection).
- problem: The same skill describes a config-driven model-routing path for the rerun, but the initial dispatch hard-codes `sonnet`. If config carries a different default, the initial dispatch ignores it; if the user opts into Opus for research-heavy runs, the dispatch silently downgrades. Hard-coding a model in the prompt is also the kind of stale reference R1 calls out — model identifiers rot faster than skill bodies.
- proposed_fix: Replace the literal `model: "sonnet"` with the routing-table reference: `model: <the role's specialist-tier route from config.md's model_routing: table>`. Or drop the `model:` key entirely from the dispatch shape and let the runtime apply the role default; cite the routing matrix path instead.
- links_to_existing_issue: #271 (reviewer-model calibration) — adjacent; this is dispatch-model calibration

### F13 — Research's "Claude Code 2.1.x subagent-guardrail blocklist" is a host-version-pinned claim that R1 says to cut or relocate
- file: skills/research/SKILL.md
- line_range: [52,52], [95,95], [104,104]
- severity: medium
- rule_violated: rule-violation (R1 — version-history narration / inside baseball about host runtime)
- evidence: L52 — `"The q*.md filename pattern is intentionally outside the Claude Code 2.1.x subagent-guardrail blocklist (filenames whose stem starts (case-insensitive) with report, summary, findings, or analysis), so direct write succeeds."`; L95 — `"summary.md matches the Claude Code 2.1.x subagent-guardrail blocklist … the subagent cannot Write to it directly."`; L104 — `"the Claude Code 2.1.x subagent-guardrail blocks summary.md direct write"`
- problem: Three sentences pin behavior to "Claude Code 2.1.x". The skill must work on Copilot CLI and Codex CLI too (vendor neutrality per the v0.7.2 research summary). Either the blocklist exists in all hosts (in which case the version pin is misleading) or it doesn't (in which case the staging-rename contract is wrong on those hosts). The R1 named-antagonist "Version-history narration" pattern applies: "in v0.7.1 this was different" / "Claude Code 2.1.x does X" is the same shape — host-version narration the orchestrator can't act on. Verified-host carve-outs of this kind belong in design-time external-knowledge sub-rule D evidence, not the spine.
- proposed_fix: Either (a) cut the version pin and state the rule unconditionally — `"The q*.md filename pattern is outside the host subagent-guardrail blocklist (filenames whose stem starts with report, summary, findings, or analysis), so direct write succeeds."` — and add a one-line evergreen-exempt host-evidence comment, OR (b) move the host-evidence detail to `skills/research/references/host-guardrail-evidence.md` (R5 valid: it's recovery context most invocations don't need) and reference from the spine.
- links_to_existing_issue: none

### F14 — Design template (the conformance contract) doesn't author per-goal blocks, yet the SKILL teaches them
- file: skills/design/SKILL.md ; skills/design/references/design-md-template.md
- line_range: design SKILL [24,32], [125,150]; template [1,34]
- severity: high
- rule_violated: contradiction (template omits the per-goal block shape the SKILL prose mandates)
- evidence: design SKILL L26-30 — per-goal block template fields (Outcome / Solution / Why this approach / Dependencies + edge cases / Acceptance); L147-148 finalize-pass — `"Validate that every goal in goals.md has a corresponding per-goal block in design.md with all five fields populated"`. Template L7-33 authors only `# Design: {Project/Feature Name}` + `## Approach` + `## Key Decisions` + `## Trade-offs Considered`; no `## Goals` H2, no `### G1 — ...` per-goal block, no five-field per-goal subsection guidance.
- problem: The template — explicitly labeled "conformance contract" (L1, L3, L5) — does not show the per-goal block shape that the SKILL prose (and the OWNS list at design-altitude-boundary L7) requires. A synthesis subagent reading "the conformance template" will faithfully produce a three-section file; the finalize-pass will then fail every goal under L147's validation. Compounded by F02: the precondition asserts a `## Test Strategy` H2 that is also missing from the template.
- proposed_fix: Extend design-md-template.md to author `## Cross-Goal Decisions` (optional, top), `## Goals` (H2 wrapper), per-goal `### G{N} — {name}` blocks with the five-field shape (Outcome / Solution / Why this approach / Dependencies + edge cases / Acceptance), and — paired with F02's resolution — the `## Test Strategy` (or relocated) section. The HTML-comment per-section guidance pattern used for Approach/Key Decisions/Trade-offs extends cleanly to per-goal blocks.
- links_to_existing_issue: none

### F15 — Phasing finalize-flip is described in the "Human Gate" but the four pruned artifacts' status flip is silently scope-creeping into Phasing
- file: skills/phasing/SKILL.md
- line_range: [130,130]
- severity: medium
- rule_violated: architectural (ownership of frontmatter status flips)
- evidence: L130 — `"Only after that assertion passes do you write status: approved in the frontmatter of phasing.md, roadmap.md, the four pruned artifacts, and the four future-*.md artifacts."`
- problem: Phasing flips `status: approved` on the four upstream artifacts (goals.md, questions.md, research/summary.md, design.md). But Goals/Questions/Research/Design each own their own approval frontmatter (per their respective Iron Rules and Human Gates — e.g., goals SKILL L142-143 — `"Flip frontmatter status: draft to status: approved. Only the finalize pass writes approved; hand-edits mid-phase are forbidden."`). Phasing is doing a hand-edit-by-another-skill on artifacts it does not own. The pruning operation legitimately rewrites bodies, but flipping their `status:` to `approved` is the upstream skill's job — and the artifacts were already `approved` before Phasing ran (Phasing's inputs require all four `approved`).
- proposed_fix: Drop the four pruned artifacts and four future-*.md artifacts from the `status: approved` write on L130. Either (a) leave them as-is — they came in `approved`, Phasing rewrites bodies, they stay `approved`; or (b) reset them to `draft` post-prune and have the user re-approve via a quick gate. Phasing should only write `status: approved` to artifacts it OWNS — `phasing.md` and `roadmap.md`. Concretely: the current behavior conflicts with goals SKILL's forbidden-hand-edits clause.
- links_to_existing_issue: none

### F16 — Research's `qrspi-research-collator` Pre-Flight pattern table lists `defect_summary` for collator but the carve-out tokens in research-isolation/SKILL.md miss the collator-specific channel
- file: skills/research-isolation/SKILL.md ; skills/research/SKILL.md
- line_range: research-isolation [26,26], [69,76]; research [97,97], [105,105]
- severity: low
- rule_violated: factual (vocabulary completeness — minor)
- evidence: research-isolation L26 — `"Sanitization bypass — when a sanitized re-dispatch channel exists (defect_summary for specialist; defect_summary for collator), it is supposed to carry defect-only bullet points."` (good — names both); but L33 (collator-specific) says: `"Canonical token: questions-compendium-leakage — emit this verbatim in the refusal prefix so the orchestrator's pattern→repair table matches."` The orchestrator pattern→repair table in research/SKILL.md L120 says: `"sanitization-bypass ⇒ the orchestrator-authored defect_summary still carried goal/intent prose."` — singular, doesn't disambiguate specialist vs. collator defect_summary. A reviewer seeing `RESEARCH-ISOLATION-VIOLATION: sanitization-bypass:` from the collator can't tell from the canonical token which channel leaked.
- problem: Borderline; both channels emit the same `sanitization-bypass` token and the repair procedure is the same ("re-author the defect_summary"). It's not a bug, but it's a weak audit handle when both agents can produce the same token from different inputs.
- proposed_fix: Optional — add a per-agent suffix to the token (`sanitization-bypass-specialist` / `sanitization-bypass-collator`) to make the repair faster. Or leave it; this is below the finding-type-gate severity floor for many reviewers. **Flagging as low**, may be declined.
- links_to_existing_issue: none

### F17 — Goals' Dialogue Conduct list skips number 5 (jumps 4 → 6)
- file: skills/goals/SKILL.md
- line_range: [102,118]
- severity: low
- rule_violated: factual (numbering)
- evidence: L106 — `"1. Open with questions."`; L108 — `"2. One question at a time"`; L110 — `"3. Ground first, ask second."`; L112 — `"4. When the user asks for your call, provide one."`; L114 — `"6. Sharpen fuzzy language."`; L116 — `"7. Walk every branch of the decision tree"`; L118 — `"8. Lock decisions as they settle."`
- problem: Number 5 was removed in a trim, but 6/7/8 weren't renumbered. Anchor "Rule 8" appears in L120 (`"Per Rule 8, write each locked goal directly to goals.md"`) and on this current numbering it correctly points to "Lock decisions". A reviewer or future editor counting items will be confused. Minor but easy to fix.
- proposed_fix: Renumber 6 → 5, 7 → 6, 8 → 7. Update the L120 reference to "Per Rule 7" (and any other cross-references to Rule 8 in the file — verified only one).
- links_to_existing_issue: none

### F18 — Goals' Common Rationalizations row includes "Let me just start the research first" which is dialogue exhaust from a prior pipeline shape
- file: skills/goals/SKILL.md
- line_range: [281,281]
- severity: low
- rule_violated: rule-violation (R1 — dialogue exhaust / inside-baseball that the orchestrator doesn't act on)
- evidence: L281 — `| "Let me just start the research first" | Research without approved goals means you don't know what you're looking for. |`
- problem: The user-facing orchestrator that runs Goals is not the same orchestrator that would dispatch Research — Research is a separate skill behind a HARD-GATE on Goals' approved status (questions/SKILL.md L28 — `"Do NOT generate questions without an approved goals.md."`, and research/SKILL.md L26 — `"Do NOT pass goals.md to ANY research subagent"`). The Goals skill cannot start Research; the rationalization is one the human user could voice, but Goals' orchestrator-reading-the-skill cannot act on it. Compare with the surrounding rationalizations, which are all things the Goals orchestrator might be tempted to do (drop subsections, mark known-fix instead of exploratory).
- proposed_fix: Cut the row, or restate as the goal-internal failure mode: `| "I can populate Problem from the goal title without re-asking" | The goal title is not the Problem. Re-enter dialogue to capture the Problem frame."` (i.e., a rationalization Goals' orchestrator could actually voice).
- links_to_existing_issue: none

### F19 — Questions skill announces "Codex reviews" in config-read prose despite the verifier-gate using `second_reviewer`
- file: skills/questions/SKILL.md
- line_range: [25,25]
- severity: medium
- rule_violated: vocabulary drift + factual (already covered by F01 but worth a separate fix-site reminder for the legacy reading)
- evidence: L25 — `"Read config.md from the artifact directory to determine whether Codex reviews are enabled. If config.md doesn't exist, default to codex_reviews: false."`
- problem: Same vocabulary as F01, but Questions is in a special situation: it's the first downstream skill that reads `config.md` after Goals writes it. If Goals wrote `second_reviewer:` (per its current YAML on L173-184) and Questions then reads `codex_reviews`, the per-skill validation that follows in Questions' Review Round prose (`REVIEW_AGENTS="..."` including codex tags conditionally) will never see a value and silently default to false. Bug surface is largest here because Questions is the first crossing.
- proposed_fix: Already covered by F01's blanket fix; flagging the Questions-specific impact (silent degradation of the second-reviewer dispatch on the very next step after Goals).
- links_to_existing_issue: none (subset of F01)

### F20 — Phasing's `phasing.md` template includes a `## Orphan IDs` section the OWNS list does not name
- file: skills/phasing/SKILL.md ; skills/phasing/owns-defers.md
- line_range: SKILL [199,206], [236,236]; owns-defers [6,10]
- severity: low
- rule_violated: contradiction (template names a section the OWNS list doesn't enumerate)
- evidence: SKILL L201 — `"### Goal-ID Consistency"`, L203 — `"### Orphan IDs"`, L236 fail-closed — `"Reviewers MUST reject any phasing.md emission that omits the ## Orphan IDs section (even when the section content reads 'No orphan IDs.' — the section header itself is required so reviewers can confirm the validation procedure ran)."`. phasing/owns-defers.md L4-10 (OWNS) names "Vertical-slice authoring", "Phase boundaries", "roadmap.md authoring", "Current-phase pruning", "Future-* artifact maintenance", "Goal-ID consistency validation" — but does NOT enumerate `## Orphan IDs` (or `## Goal-ID Consistency`) as owned headings in `phasing.md`.
- problem: The scope-reviewer dispatches against the OWNS/DEFERS list. If `## Orphan IDs` and `## Goal-ID Consistency` are not in OWNS, the scope-reviewer can flag them as boundary drift; the reviewer-protocol fail-closed condition on `## Orphan IDs` then collides with the OWNS-list rejection.
- proposed_fix: Add a bullet to phasing/owns-defers.md OWNS: `"phasing.md required sections: ## Slices, ## Phases, ## Goal-ID Consistency, ## Orphan IDs (always emitted, content 'No orphan IDs.' when none)."` This pins the headings the scope-reviewer must accept.
- links_to_existing_issue: none

### F21 — Parallelize Worktree-Aware Setup Validation embeds JavaScript-ecosystem-specific tools as load-bearing names without abstraction
- file: skills/parallelize/SKILL.md
- line_range: [113,128]
- severity: low
- rule_violated: rule-violation (R1 — code patterns the agent can discover from project files)
- evidence: L119-122 — `"1. eslint — config (eslint.config.js, .eslintrc*, package.json eslintConfig) ignores .worktrees/** … 2. tsconfig — tsconfig.json exclude array contains .worktrees/** … 3. vitest / jest — test config's exclude (or testPathIgnorePatterns) contains .worktrees/** … 4. framework build dir under worktrees — verify recursive globs (.next/** not just .next/) …"`
- problem: This validation hard-codes ESLint, tsconfig, vitest/jest, `.next/`, `dist/`, `build/` — JavaScript/TypeScript-only patterns. QRSPI is meant to be vendor-and-stack neutral (v0.7.2 research summary). Non-JS projects (Python, Go, Rust) get advisory output that talks past them; the orchestrator following the script will halt-or-skip without producing useful guidance. R1 also says "Code patterns the agent can discover from existing project files" — discovering which build tooling is in use is the agent's job, not a hardcoded enum.
- proposed_fix: Replace the per-tool enumeration with a tool-discovery instruction: `"Discover the project's lint/typecheck/test config files (per language ecosystem; e.g., eslint/tsconfig/vitest for JS, ruff/mypy/pytest for Python). For each discovered config, confirm .worktrees/** is excluded and that any framework build directory (.next/**, dist/**, build/**, __pycache__/**, target/**, …) is also excluded under that pattern."` Or move the JS-specific enumeration to `references/worktree-validation-js.md` and call it out only when JS configs are detected.
- links_to_existing_issue: none

---

## Cross-file patterns

1. **`codex_reviews:` zombie field (F01, F19).** Six slice-2 skills carry validation for a field the orchestrator explicitly removed. Fix in a single sweep — replace every `codex_reviews` with `second_reviewer`. Audit slice 1 (plan/implement/integrate/test) for the same pattern; the trim notes show those skills WERE trimmed in v0.7.3 so this may already be fixed there.

2. **"Test Strategy" / "Test Architecture" vocabulary drift (F02, F03, F07, F14).** Four findings, three skills, one shared `_shared` rule file all disagree on whether `## Test Strategy` is a Design H2, a Structure H2, a Structure DEFERS, or a thing that doesn't exist. The cluster needs a single coordinated rename + ownership decision. Strong recommendation: retire "Test Strategy" entirely; use `## Test Architecture` (Structure-owned) + per-goal `Acceptance` (Design-owned) + a `### Visual-Fidelity Binding` subsection in whichever owner makes sense once F02 is decided. Aligns with the spirit of issue #275 (vocabulary drift on the "moot" flavors) — same family of fix.

3. **Stale numbering, broken cross-references, dialogue-exhaust references (F04, F05, F09, F17).** Four nits, all evidence of trim-without-renumber. A pre-commit `grep -n '^[0-9]\+\.' SKILL.md` sanity pass would catch most of these.

4. **Compaction-resilience asymmetry (F11).** Goals and Design have incremental-persistence contracts (per the cross-cutting principle); Phasing does not, despite being structurally analogous (multi-decision interactive surface, 10 atomic artifacts). Plan and Structure are likely in the same boat — worth checking in slice 1 audit.

## Centralization opportunities

1. **Compaction-checkpoint TaskCreate calls.** Every slice-2 skill carries 2 (some 3) `TaskCreate({ subject: "Recommend /compact …" })` calls with near-identical prose. These could collapse to a shared `!cat skills/_shared/compaction-checkpoint.md` partial parameterized by step name. (That file already exists per the directory listing — verify it's not already meant to be the source of truth and just under-used.)

2. **Dispatch-agent high-level-entry prose.** The 5-7-line block beginning `"Dispatch the round through dispatch-agent's high-level entry. Run scripts/dispatch-agent.sh --step <step> --round ${ROUND} …"` is repeated verbatim in 6 slice-2 skills (goals/questions/research/design/phasing/structure/parallelize/replan), each with only the `--step <name>` token differing. This is ~700 lines of duplicated prose across slice 2 alone. Strong R5 candidate to extract to `_shared/dispatch-agent-prose.md` and substitute `${REVIEW_STEP}` once at the per-skill site.

3. **Quick-Fix Auto-Approve Branch verifier-gate prose.** Identical 6-bullet block in questions/SKILL.md L107-121 and research/SKILL.md L174-188 — same conditions, same audit-log requirements, same fail-loud guarantees. Extract to `_shared/quick-fix-auto-approve-branch.md`.

4. **"On approval, if reviews have not passed clean…" Human Gate prose.** Repeated nearly verbatim across goals/questions/research/design/structure/phasing/parallelize/replan Human Gate sections. Already a candidate.

## Acknowledgements

- The v0.7.3 trim is real and effective on Goals (499→301) and Design (469→308). The interactive sections in both are now tight and the Iron-Law-at-end pattern is consistently applied.
- Parallelize's symbolic-vs-concrete separation (lines 18-20) is genuinely well-written and load-bearing; the rationale paragraph survives R1 because the alternative (the half-static / half-runtime artifact described) is a non-obvious failure mode worth narrating.
- The research-isolation Pre-Flight skill (77 lines) is exemplary R8 work — every sentence load-bearing, structural carve-out for the trusted region is precise, canonical token list is the spec.
- Replan's Severity Classification table (L55-69) is the strongest single artifact in slice 2 — every row is operational, the loop-back target is named, the examples are concrete enough to act on.

## Declined (detail-suggestion / example-suggestion / scope-extension noted but NOT findings)

- **Goals/Design "If auto-mode is detected" announcement prose** — could be terser, but the user-facing wording is intentional and load-bearing for the host-CLI behavior detection. R8 leave-alone.
- **Phasing Iron Law 1 + Phase 1 PoC Guideline restated at end (L281-283)** — appears redundant with L43-52 but R3 explicitly mandates end-of-context restatement of Iron Laws. Decline as scope-extension.
- **Research worked-example "Bad finding" (L237-242)** — could carry a third bad example, but R4 caps at 2; the existing one carries the failure mode evidence. Decline as example-suggestion.
- **Structure CI Pipeline section** — only authored when CI is in play; some reviewers might call this conditional inconsistent with the canonical-heading rule, but the conditional is explicit ("if needed"). Borderline; on the "leave alone" side of R8.
- **Design "Read on demand" research/q*.md permission prose (L167)** — long sentence carrying anti-prophylactic discipline; load-bearing. Decline.
- **Replan Boundary with Goals section (L255-298)** — could be moved to `references/boundary-with-goals.md` (already exists per file listing). Mild R5 opportunity but the spine version is the actively-enforced contract; moving it risks behavioral drift. Decline as scope-extension.
- **Parallelize "Why This Skill Is Separate From Implement" section (L18-20)** — historical narration that R1 would normally cut, but the alternative (half-static / half-runtime artifact) is a non-obvious failure mode and the rationale is load-bearing for understanding why "stage commits don't exist yet" in the Iron Law. R2 carve-out applies; decline.

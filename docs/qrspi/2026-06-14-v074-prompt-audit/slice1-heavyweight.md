# Slice 1 audit: heavyweight orchestrators

## Summary
- Files audited: 5 SKILL.md spines + ~30 referenced snippets across using-qrspi/, implement/, plan/, integrate/, test/, and skills/_shared/
- Total findings: 18 (blocker: 3, high: 9, medium: 6)
- Cross-file redundancies found: 5
- Stale references found: 11 (10 `codex_reviews` call-sites + 1 `HEAD~1` rule)

## Findings

### F01 — `codex_reviews` declared "removed" but still wired as the live trigger across the slice
- file: skills/using-qrspi/SKILL.md, skills/plan/SKILL.md, skills/integrate/SKILL.md, skills/test/SKILL.md, skills/implement/SKILL.md
- line_range: using-qrspi [112, 112] + [271, 273] + [411, 411]; plan [34, 38] + [219, 219] + [228, 228]; integrate [62, 68] + [118, 118]; test [55, 55] + [112, 112]; implement [71, 71] + [411, 411]
- severity: blocker
- rule_violated: contradiction (and stale-ref + factual)
- evidence: using-qrspi line 112: `` - `codex_reviews`: **removed** — legacy name for `second_reviewer`. A stray `codex_reviews:` field in `config.md` is a hard validation error, never silently aliased. `` — yet using-qrspi line 411 itself reads: `Evaluate the Expected-Reviewer Matrix for the current step against `config.md.codex_reviews`.` and implement line 71 reads: `Implement validates `route`, `codex_reviews`, and (after Phase-Level Configuration) `review_depth` and `review_mode`.`
- problem: The canonical config schema in using-qrspi (lines 86, 111, 121, 133, 267-273, 300, 330) names `second_reviewer:` as the live field and demands a hard rejection on any stray `codex_reviews:`. Every other skill in the slice still names `codex_reviews:` as the field they validate, the gate they read at dispatch time, and the boolean that controls Codex peer-tag inclusion in `REVIEW_AGENTS`. This is the single highest-severity finding in the slice: the rename was applied to the schema but not to the consumers. A fresh run that follows using-qrspi's hard-reject rule literally will abort the run on contact with a `codex_reviews:` value in config.md, while plan/integrate/test/implement orchestrators will simultaneously try to read `config.md.codex_reviews` and find nothing. The Apply-fix Per-expected-tag schema-violation guard (using-qrspi line 411) is the most damaging instance: the entire reviewer-output validation gate keys on a field whose name the same file says is no longer valid.
- proposed_fix: Sweep `codex_reviews` → `second_reviewer` across plan/integrate/test/implement and using-qrspi line 411. This is exactly the "sweep task" shape plan/SKILL.md § Sweep Task Contract describes (a public-symbol rename across consumer files). The schema's hard-reject of legacy `codex_reviews:` then becomes consistent with consumers reading `second_reviewer:`.
- links_to_existing_issue: none (this is the kind of cross-file consumer adoption gap #279/#278/#277 describe but it is not specifically tracked)

### F02 — Shared `review-loop.md` snippet contradicts the spine's anchor-file contract by naming `HEAD~1`
- file: skills/_shared/review-loop.md
- line_range: [23, 23]
- severity: blocker
- rule_violated: contradiction / stale-ref
- evidence: `round NN+1 uses `<ref>=HEAD~1` only when the convergence comparison fires "narrow" against round NN, and falls back to `<ref>=<base-branch>` otherwise`
- problem: using-qrspi/SKILL.md line 508 explicitly says: `halt non-zero with the named `anchor-file-missing:` diagnostic (e.g. `anchor-file-missing: reviews/{step}/round-(NN-1)-commit.txt — cannot narrow round NN+1; no silent fallback to HEAD~1`). Do NOT fall back silently to `HEAD~1` or base-branch.` integrate/SKILL.md line 150 says `No `HEAD~1` shorthand — the anchor file is the source of truth.` implement/SKILL.md line 434 says `No `HEAD~1` shorthand is used and no silent fallback to base-branch fires on a missing/malformed anchor file`. And using-qrspi line 473 spells out the design intent: `the per-round commit IS the anchor, not a candidate to be cross-checked against `HEAD~1`.` The shared snippet — which is a candidate single-source-of-truth for the standard review loop — names the exact ref form the spine repeatedly forbids. A spine that drifts back to reading `_shared/review-loop.md` (or an agent that grabs it as the cheap canonical) will re-introduce the silent-fallback class the v0.7.3 anchor-file work exists to close.
- proposed_fix: Replace `<ref>=HEAD~1` in `_shared/review-loop.md` line 23 with `<ref>=<sha-from-anchor-file>` and back-reference the anchor-file lookup contract. Alternatively, delete `_shared/review-loop.md` entirely if it has been superseded by the inlined section in using-qrspi/SKILL.md § Standard Review Loop (see F03 — two competing SoTs).
- links_to_existing_issue: none

### F03 — Three pairs of shared snippet vs inlined SKILL.md content compete as sources of truth
- file: skills/_shared/config-validation.md (vs using-qrspi/SKILL.md § Config Validation Procedure); skills/_shared/review-loop.md (vs using-qrspi/SKILL.md § Standard Review Loop); skills/_shared/compaction-checkpoint.md (vs using-qrspi/references/compaction-checkpoints-detail.md)
- line_range: using-qrspi [242, 348] (Config Validation Procedure), [352, 585] (Standard Review Loop + Apply-fix protocol + Diff handling), [598, 604] (Compaction Checkpoints); _shared/config-validation.md [1, 122]; _shared/review-loop.md [1, 60]; _shared/compaction-checkpoint.md [1, 47]
- severity: blocker
- rule_violated: contradiction / R5 misapplication
- evidence: `_shared/config-validation.md` line 1: `# Config Validation Procedure (shared)\n\nSingle source of truth for `config.md` field validation across every skill that reads route or pipeline behavior.` — yet using-qrspi/SKILL.md line 242 opens its own `## Config Validation Procedure` and proceeds to inline a 100+ line near-duplicate of the shared snippet. Plan/Integrate/Test/Implement all link to `using-qrspi/SKILL.md § Config Validation Procedure` (the inlined section), not to `_shared/config-validation.md`. Compare `_shared/config-validation.md` line 49 (question_budget four named failure-modes, each with its own multi-line menu) against using-qrspi line 288 (single collapsed menu shape covering the same four failure-modes) — the rule sets are not byte-identical.
- problem: Three load-bearing contracts each have two living copies. The shared snippet is labeled "single source of truth" but is not referenced by any of the five SKILL.md files in this slice (Apple-grep `grep -r config-validation.md skills/`). The inlined version in using-qrspi is what consumers cite. When the rule changes, an editor will update one copy and not the other; F02 (`HEAD~1` in `_shared/review-loop.md`) is the concrete instance of this hazard already firing.
- proposed_fix: Pick one home per contract and delete the other. Recommended: keep the inlined sections in using-qrspi/SKILL.md (consumers cite them, R3 places them at the spine's end where they belong) and delete `_shared/config-validation.md`, `_shared/review-loop.md`, and `_shared/compaction-checkpoint.md`. Or: collapse the using-qrspi sections to a one-line `!cat skills/_shared/<name>.md` include each (the using-qrspi spine already uses `!cat` for ~30 includes — pattern is established) and fix the snippets to be byte-canonical. Either way, eliminate the dual-SoT.
- links_to_existing_issue: none (related class to #310 implement bloat / stale dispatch refs)

### F04 — Two near-duplicate reviewer-dispatch shared snippets; only one is included by spines
- file: skills/_shared/reviewer-dispatch.md vs skills/_shared/reviewer-dispatch-prose.md
- line_range: reviewer-dispatch.md [1, 59]; reviewer-dispatch-prose.md [1, 37]
- severity: high
- rule_violated: contradiction / R5 misapplication
- evidence: `reviewer-dispatch.md` line 1: `# Reviewer Dispatch (shared)\n\nVerbatim reviewer-dispatch incantation. Single source of truth for orchestrator-side reviewer fan-out across every skill that runs a Review Round.` reviewer-dispatch-prose.md line 1: `# Reviewer Dispatch (shared)\n\nWith `$REVIEW_STEP`, `$REVIEW_ROUND`...` Both define the dispatch incantation, the Task-tool fan-out rule, the iron-law-orchestrator-side-dispatch-contract, the `.raw` capture rule, and the `await-round.sh` finalization. Plan line 238, integrate line 128, test line 122, implement line 396 each `!cat` ONLY `reviewer-dispatch-prose.md`. `reviewer-dispatch.md` is referenced by zero spines in this slice.
- problem: Two "single source of truth" labels in `_shared/` for the same contract. The longer one (`reviewer-dispatch.md`) appears to be the original, the shorter one (`-prose.md`) the trimmed include. Same drift hazard as F03. The "single source of truth" claim in the unreferenced file is provably false.
- proposed_fix: Delete `skills/_shared/reviewer-dispatch.md`; promote `reviewer-dispatch-prose.md` as the sole shared snippet, optionally renaming to `reviewer-dispatch.md` once the original is gone.
- links_to_existing_issue: none

### F05 — Apply-fix protocol step 2 (in using-qrspi) reads `config.md.codex_reviews`, contradicting its own file
- file: skills/using-qrspi/SKILL.md
- line_range: [411, 411]
- severity: blocker
- rule_violated: contradiction
- evidence: `Evaluate the Expected-Reviewer Matrix for the current step against `config.md.codex_reviews`. For each expected tag, assert step 1 (per-reviewer output enumeration) produced at least one of (`<tag>.finding-*.md`, `<tag>.clean.md`).`
- problem: This is a self-contradiction inside one file. using-qrspi line 112 declares `codex_reviews:` removed and a "hard validation error, never silently aliased." Line 411 then makes the entire Apply-fix per-expected-tag schema-violation guard pivot on reading that same removed field. A run cannot satisfy both rules: either the field is rejected at validation (line 272) and the gate has nothing to read, or the field is read at the gate (line 411) and the rejection rule is a fiction. This is technically an instance of F01 but called out separately because it is INSIDE the file that authoritatively kills the field.
- proposed_fix: Change line 411 to `against `config.md.second_reviewer``. Trivial single-token edit.
- links_to_existing_issue: none

### F06 — `phase:` is a load-bearing config.md field consumed by Implement but undeclared in using-qrspi's canonical schema and validation table
- file: skills/implement/SKILL.md vs skills/using-qrspi/SKILL.md
- line_range: implement [96, 98]; using-qrspi schema [82, 121] and validation table [325, 342]
- severity: high
- rule_violated: factual / stale-ref
- evidence: implement line 96: `Probe `.smoke-probe-NN` (NN = `config.md` `phase:`). Before the leftover-probe check, branch on the `phase:` field state:` and line 97: `Write `phase: NN` back to `config.md` (preserving all other fields), then re-read `config.md` and confirm round-trip. On write failure or read-back mismatch, halt: "Implement smoke check failed: could not backfill missing phase field to config.md — check write permissions"`. using-qrspi/SKILL.md canonical config schema (lines 82-121) enumerates `created`, `pipeline`, `second_reviewer`, `route`, `review_depth`, `review_mode`, `verifier_enabled`, `scope_tagger_enabled`, `visual_fidelity_required`, `question_budget` — no `phase:`. Validation table (lines 325-336) does not list `phase:`. Field-specific menus (lines 259-292) have no `phase:` entry.
- problem: Implement runtime-backfills a config field that the schema does not document. A user reading using-qrspi's "Full format:" YAML block and validation table will not know `phase:` exists. On a re-run after Phase 1 ships, `config.md` carries `phase: 1` (written by Implement smoke check) — but no validation procedure tells Goals/Plan/etc. how to handle a malformed `phase:` value, nor does the schema say it is a valid top-level key. This is the same shape as the `codex_reviews` undocumented-runtime-field class, only for a field that IS used rather than one declared dead.
- proposed_fix: Add `phase:` to using-qrspi's canonical schema (line 105 region) with its semantics ("set by Implement at smoke-check time; integer ≥ 1; informational ordinal"). Add a row to the validation table (line 336 region) naming Implement as the only validator. Optionally cross-link to implement/SKILL.md § Implement-Entry Smoke Check for the backfill semantics.
- links_to_existing_issue: none

### F07 — using-qrspi pre-`!cat` paragraph sandwiches duplicate-content with included references
- file: skills/using-qrspi/SKILL.md
- line_range: [50, 52], [62, 66], [600, 604]
- severity: medium
- rule_violated: R1 (and R8 — could tighten)
- evidence: line 50: `Pipeline state is derived from artifact frontmatter; the only piece of derived state worth persisting is `phase_start_commit` (lives in `plan.md` frontmatter, scoped by Replan and Test).` followed immediately on line 52 by `!cat skills/using-qrspi/references/state-and-pipeline-ordering.md`. Same pattern lines 62-66 (`Users can enter mid-pipeline when required input artifacts already exist with `status: approved`; mid-pipeline resume also detects `replan-pending.md` to resume Replan when set.` then `!cat .../mid-pipeline-entry.md`). Same pattern lines 600-602: `**Iron Rule.** Pause and recommend `/compact` to the user before continuing. The user can decline; do not skip the recommendation.` then `!cat .../compaction-checkpoints-detail.md` — and the iron rule is ALSO in `_shared/compaction-checkpoint.md` line 5-7.
- problem: The sandwich-prose around an `!cat` include either (a) duplicates the included content (the iron-rule case) or (b) hand-summarizes content the include is about to deliver in full (the state-and-pipeline-ordering case). Per R1, sentences that produce zero orchestration behavior delta should be cut. The orchestrator reads the included content immediately; the intro paragraph is meta-commentary about what's coming. R8 alternative: tighten to a one-line lexical anchor pointing at the included file rather than restating a contract.
- proposed_fix: Cut the intro paragraphs; let the section heading + `!cat` line stand alone. The iron-rule restatement at line 600-602 is the strongest cut candidate — it duplicates the `_shared/compaction-checkpoint.md` line 7 verbatim while the include's own line 5 already starts with `## Iron Rule`.
- links_to_existing_issue: none

### F08 — Plan re-states `route` / `pipeline` precedence already pinned in using-qrspi
- file: skills/plan/SKILL.md
- line_range: [22, 22], [34, 34]
- severity: medium
- rule_violated: R1 (redundancy across the slice)
- evidence: line 22: `Read `config.md` to determine pipeline mode. If `config.md` doesn't exist or has no `route` field, refuse to proceed and tell the user to re-run Goals. The `route` field is authoritative; `pipeline` is informational (see using-qrspi Config File).` line 34: `If any required artifact is missing or not approved, refuse to run and name the missing artifact. Read `config.md` to determine whether Codex reviews are enabled.`
- problem: Both sentences restate a rule using-qrspi already pins (the route/pipeline authority is in using-qrspi line 87-105; the "missing field → re-run Goals" menu is in using-qrspi line 246-292). The cross-reference `(see using-qrspi Config File)` already points the reader there, but the prose re-pins the rule first. The "Read config.md to determine whether Codex reviews are enabled" trailing sentence is also a stale-`codex_reviews` instance (F01).
- proposed_fix: Cut the prose restatements; rely on the cross-reference. plan.md is the artifact-author skill, not the config-contract skill; it doesn't need to re-author the contract.
- links_to_existing_issue: none

### F09 — `plan/SKILL.md` references `skills/plan/owns-defers.md` but the established refs convention puts subordinate content in `skills/plan/references/`
- file: skills/plan/SKILL.md
- line_range: [18, 18], [114, 114], [427, 427]
- severity: medium
- rule_violated: architectural (inconsistent layout)
- evidence: line 18: `!cat skills/plan/owns-defers.md` line 114: `skills/plan/owns-defers.md` (the layer-depth clamp — without it, sub-subagents drift into Implement/Structure scope...` line 427: `Fix upstream: sub-subagent inputs must include `skills/plan/owns-defers.md`.`
- problem: Every other plan-spine include uses `skills/plan/references/X.md` (`!cat skills/plan/references/common-rationalizations.md`, etc.). Three load-bearing files now live directly in `skills/plan/`: `owns-defers.md`, `post-approval-split-contract.md`, `smoke-spec.md`. The path inconsistency is a navigation hazard — readers (and reviewers searching for "everything plan owns") will glob `skills/plan/references/` and miss the OWNS/DEFERS contract. The OWNS/DEFERS file is the most-cited (sub-subagents must load it; reviewers cite it). Verified via `ls skills/plan/`.
- proposed_fix: Move `skills/plan/owns-defers.md`, `skills/plan/post-approval-split-contract.md`, and `skills/plan/smoke-spec.md` under `skills/plan/references/`; update the three `!cat` / link sites in plan/SKILL.md. Or: codify the alt-layout in using-qrspi's workspace-layout reference so the path discrepancy stops looking like an error.
- links_to_existing_issue: none

### F10 — implement § Subagent Permissions softens an iron-law gate to a "recommended" CLI flag
- file: skills/implement/SKILL.md
- line_range: [126, 128]
- severity: high
- rule_violated: iron-law erosion (R3 / cross-cutting)
- evidence: line 128: `**Recommended:** run sessions with `--dangerously-skip-permissions` enabled so per-tool approval prompts do not stall subagents.`
- problem: Implement's HARD-GATE at line 74 forbids dispatching tasks that touch overlapping files and requires per-task reviewer dispatch — both rely on subagents running tools without interactive stalls. The "Recommended:" softening leaves the failure mode ("a per-tool prompt stalls a parallel subagent fan-out mid-wave; the wave never completes; the round-counter is wrong because reviewer fan-in is partial") as user-discretion. Either this is load-bearing for the wave-dispatch contract (make it MUST) or the wave-dispatch contract has a recovery path for tool-permission stalls (state it). Currently neither: it's a soft suggestion attached to a hard-gate-protected dispatch shape. Per the cross-cutting "reduce aggressive MUST/CRITICAL language" rule, this is not the right place to invoke MUST blindly — but the softness in a per-tool-permission context is the wrong direction.
- proposed_fix: Either (a) tighten to: `Sessions must run with `--dangerously-skip-permissions` enabled. Per-tool approval prompts stall subagents inside a parallel wave; the round-counter cannot be advanced from a stalled wave.` or (b) document the recovery path for a stalled subagent dispatch (kill + re-dispatch; how it interacts with `SendMessage` persistence).
- links_to_existing_issue: none

### F11 — implement/SKILL.md uses both `Agent({...})` and `Task({...})` vocabulary for the same dispatch primitive
- file: skills/implement/SKILL.md vs skills/_shared/reviewer-dispatch-prose.md
- line_range: implement [19, 19] + [288, 290] + [292, 292] + [338, 338]; reviewer-dispatch-prose.md [17, 22]
- severity: high
- rule_violated: contradiction (vocabulary drift; R7 anchor)
- evidence: implement line 19: `Main chat dispatches `Agent({ subagent_type: "qrspi-implementer" })` per task` implement line 288: ``Agent({ subagent_type: "<implementer_subagent>" })`` implement line 292: `First fix cycle is a fresh `Agent({...})` dispatch; subsequent cycles re-enter via `SendMessage`` reviewer-dispatch-prose.md line 17: `For every emitted spec line, invoke the **Task tool** with these arguments`. implement line 407 (Between rounds — required sequence) line 5: `parse stdout for `MODE=first_party` spec lines. For each, invoke Task exactly once with `subagent_type`/`model` copied verbatim`.
- problem: The implementer dispatch incantation in implement/SKILL.md uses `Agent({ subagent_type: ... })`. The reviewer dispatch incantation (in the shared snippet implement includes) uses `Task` tool with `subagent_type` parameter. The "Between rounds" sub-step uses Task as well. Anchor-token drift per R7: a reviewer or agent doing literal token-match against a trigger like "Task tool" will not find the implementer-dispatch site, and vice versa. If `Agent({...})` and `Task({subagent_type:...})` are two literal API names for the SAME primitive (which seems to be the case — both pass `subagent_type` and a prompt), the slice should pick one and pin it. If they are different primitives, the implementer-dispatch site MUST explain why it diverges from the rest of the dispatch chain.
- proposed_fix: Audit which is the actual API in the host CLIs (Copilot CLI / Claude Code) and pick one canonical name. Sweep the slice to that name. The "Between rounds" sequence at implement line 407 already uses `Task`, which suggests that is the live name.
- links_to_existing_issue: none

### F12 — Plan apply-fix override delegates to an agent at a path that may not exist at plugin-install time
- file: skills/plan/SKILL.md
- line_range: [244, 244], [428, 428]
- severity: high
- rule_violated: stale-ref / factual
- evidence: line 244: `the orchestrator dispatches `agents/qrspi-plan-apply-fix.md`. The full dispatch invocation (sh block with all `--field` / `--companion` arguments) and the override rationale ... live in `references/apply-fix-dispatch.md`. Read that reference whenever running a Plan apply-fix pass; the dispatch resolves `--model` via the Tier Resolution Chain against the agent's `tier: high` frontmatter` line 428: `The plan fix-pass is dispatched without `agents/qrspi-plan-apply-fix.md` (e.g., freehand `general-purpose`).` Apply-fix is described as the Plan override of using-qrspi's Apply-fix protocol step 8.
- problem: This audit cannot verify `agents/qrspi-plan-apply-fix.md` exists from the skills/ tree alone — but the citation is load-bearing for the Plan apply-fix safety claim (without that agent body's Step 3 upstream-contract pre-flight, freehand fixes can reverse design-approved contract directions per line 428). If the agent file is missing or renamed, the entire Plan apply-fix protocol falls back to the using-qrspi base behavior silently — there is no validation step that asserts the agent file exists at dispatch time. Same hazard surface as the OBC script-absent diagnostic in implement/integrate (which IS guarded — line 480: `if `scripts/orchestration-boundary-check.sh` is absent or not executable...`).
- proposed_fix: (a) Verify `agents/qrspi-plan-apply-fix.md` exists in the v0.7.3 release; if missing, restore or remove the override. (b) Add an "agent-file-absent" precondition diagnostic at dispatch time mirroring the OBC script-absent pattern.
- links_to_existing_issue: none

### F13 — `_shared/review-loop.md` exists, claims canonical, but is not `!cat`-included by any spine in this slice
- file: skills/_shared/review-loop.md vs skills/using-qrspi/SKILL.md
- line_range: review-loop.md [1, 60]; using-qrspi [350, 585]
- severity: high
- rule_violated: R5 misapplication / architectural
- evidence: `_shared/review-loop.md` line 3: `Single source of truth for the autonomous review loop. Every skill that runs reviewers `!cat`-resolves this snippet`. Verified via `grep -rn "review-loop.md" skills/` — zero `!cat` includes of `_shared/review-loop.md` in the slice. using-qrspi/SKILL.md § Standard Review Loop (lines 350-585) inlines the contract instead, with the divergent `HEAD~1` vs anchor-file rule documented in F02.
- problem: The shared snippet's first sentence is provably false. Combined with F02 (HEAD~1) and F03 (dual-SoT class), this is one of three shared snippets in `_shared/` that claim canonical status but are either unused or contradict the spine. R5 says references should save tokens OR enable subagent isolation — this one does neither, while introducing a drift hazard. Per the cross-cutting principle "minimal does NOT mean short," the issue is not length but uncited drift surface.
- proposed_fix: Either include `_shared/review-loop.md` from the using-qrspi spine and reduce the inlined section to the include line (eliminate the duplicate body), or delete `_shared/review-loop.md` outright.
- links_to_existing_issue: none

### F14 — using-qrspi Apply-fix protocol step 2's "trailing-newline normalize, not hard fail" is a fail-soft escape that contradicts the surrounding fail-loud rule
- file: skills/using-qrspi/SKILL.md
- line_range: [411, 411]
- severity: medium
- rule_violated: contradiction (within-section)
- evidence: `Step 2 also fails loud on: malformed YAML, missing required fields, malformed `change_type` enum values that are out-of-enum (not one of style/clarity/correctness/scope/intent), unrouted `(step, tag)` route (no route entry in the Expected-Reviewer Matrix for this combination). Trailing-newline malformations are normalized (deterministic strip+append-`\n`) with a one-line audit warning, NOT a hard fail.`
- problem: The step 2 contract is "schema violations fail loud, with no silent normalization." Trailing-newline normalization IS silent (a "one-line audit warning" is silent under autopilot; no validation menu fires). The carve-out is named in-context, so it is technically documented — but the rationale for why this particular schema bit is forgivable when malformed YAML / missing fields / out-of-enum values are not is NOT explained, and the precedent it sets ("schema violations that are easy to repair get normalized") opens the door to additional carve-outs.
- proposed_fix: Either drop the trailing-newline carve-out (treat as schema violation, fail loud like the others — emit a menu entry "fix trailing newline in finding file X") OR explain the rationale (e.g., "third-party editors strip trailing newlines on save; reviewer output is otherwise valid"). State the rationale as a `Why:` line per R2.
- links_to_existing_issue: none

### F15 — Cross-file vocabulary drift: "second-reviewer" vs "Codex" vs "second-model reviewer" used interchangeably
- file: across slice
- line_range: using-qrspi [125, 144], [330]; implement [19, 396, 411]; plan [219, 228, 238]; integrate [62, 118, 128]; test [55, 112, 122]
- severity: medium
- rule_violated: contradiction (vocabulary drift); R7 (lexical anchoring)
- evidence: using-qrspi line 133 names the field `second_reviewer:` and the probe `scripts/second-reviewer-available.sh`. using-qrspi line 125 names the dispatch `second-model reviewers when `second_reviewer: true``. Plan line 228 names the routed dispatches `*-codex route third-party`. Plan line 219 names them `Codex parallels when codex_reviews: true`. Test line 112 names them `Codex when codex_reviews: true`. Integrate line 118 names them `Codex peers when codex_reviews: true`.
- problem: The v0.7.3 rename moved the config field from `codex_reviews` to `second_reviewer:` to vendor-neutralize. But the user-facing prose (and the dispatch tag pattern `*-codex` in REVIEW_AGENTS strings) still says "Codex." This is not just F01 (field name); it's the broader vocabulary problem: the dispatch tag pattern (e.g., `quality-codex`, `spec-codex`, `security-codex`) is vendor-specific even though the field controlling it is vendor-neutral. Per R7, the orchestrator-LLM matches trigger tokens — drift between `second_reviewer:` (the schema field) and `*-codex=` (the literal REVIEW_AGENTS suffix) creates the failure case where an editor switches Codex out for, say, Gemini, and discovers the entire dispatch-tag layer is hardcoded to the old vendor name.
- proposed_fix: This is a larger sweep than F01. Minimum: name the rule once in using-qrspi (e.g., "the `*-codex` suffix is the literal dispatch-tag convention for the second-reviewer dispatch path; it is a tag string, not a vendor-binding"). Better: rename the suffix to `*-second` (or similar) so the literal tag matches the config field name. Either way, document the convention so the apparent contradiction is intentional.
- links_to_existing_issue: none (related to vendor-neutrality work in v0.7.3)

### F16 — Plan § Dispatch parameters inlines a 1600-character REVIEW_AGENTS literal that duplicates plan reviewer agent names tabulated 30 lines above
- file: skills/plan/SKILL.md
- line_range: [207, 215] (table) and [235, 235] (literal)
- severity: medium
- rule_violated: R1 (cuttable repetition without behavioral payload)
- evidence: Plan reviewer agent table at lines 207-215 enumerates seven reviewers with their `qrspi-plan-*` agent names. The REVIEW_AGENTS literal at line 235 then repeats every one of those names twice (once with `-claude` suffix, once with `-codex` suffix), bundled into a single 1600-char string. The two block forms encode the same information.
- problem: The literal IS load-bearing (it is the dispatch parameter the shell variable carries), so it cannot be cut. But the table above it duplicates the same enumeration in human-readable form — and the table itself is meta-documentation (R1: "Cross-skill ownership metadata...other skills reference back, owned by skill Z"). Per the "What NOT to tighten" carve-out, anchor strings are preserved verbatim — but the descriptive table that pre-announces them adds zero orchestration behavior.
- proposed_fix: Cut the table at lines 207-215; the REVIEW_AGENTS literal carries the canonical list. If a human-readable per-reviewer description is needed, attach it inline as a YAML-style comment block adjacent to the literal so the two cannot drift.
- links_to_existing_issue: none

### F17 — Test step opt-out from convergence narrowing duplicated three times across the slice
- file: skills/using-qrspi/SKILL.md, skills/test/SKILL.md, skills/implement/SKILL.md
- line_range: using-qrspi [340, 340] and [525, 525] and [584, 584]; test [100, 100]; implement [434, 434]
- severity: medium
- rule_violated: R1 (cross-file repetition without behavioral payload)
- evidence: using-qrspi line 340: `The test step (`skills/test/SKILL.md`) opts out of convergence narrowing entirely — independent of `scope_tagger_enabled`.` using-qrspi line 525: `**Per-step opt-out.** The `test` step (`skills/test/SKILL.md`) opts out of convergence narrowing entirely — its reviewers analyze test quality (assertion meaningfulness, flake risk, plan-criterion traceability), not "where in the diff."` using-qrspi line 584: `Test step → always `<ref>=<base-branch>` (per-step opt-out, reviewers analyze test quality not "where in the diff")` test line 100: `**Diff-file + scope-tagger opt-outs.** Test-step reviewers analyze test quality (assertion meaningfulness, flake risk, traceability), not diff location. Orchestrator does NOT emit `round-NN.diff`, does NOT dispatch scope-tagger, step 12 convergence does not fire, and reviewer dispatches do NOT carry `diff_file_path` or `scope_hint`. Independent of `scope_tagger_enabled`.`
- problem: The Test-step opt-out is stated four times: twice as a parenthetical inside using-qrspi, once as its own paragraph in using-qrspi step 12, once in test/SKILL.md itself. R1 keeps load-bearing repetition (R3 end-of-context restatement), but four restatements of the same exception across two files is past the line.
- proposed_fix: Keep the test/SKILL.md statement (line 100 — that is where the opt-out is actually consumed). In using-qrspi, keep ONE statement — the step 12 paragraph at line 525 is the most informative. Cut the two parenthetical restatements at lines 340 and 584.
- links_to_existing_issue: none

### F18 — Implement smoke check's `phase:` backfill writes to a config field whose missing-on-read case is not in any validation menu
- file: skills/implement/SKILL.md vs skills/using-qrspi/SKILL.md
- line_range: implement [96, 102]; using-qrspi [304, 310] (Exceptions to no-silent-defaults)
- severity: medium
- rule_violated: contradiction / architectural
- evidence: using-qrspi line 304: `### Exceptions to the no-silent-defaults rule` enumerates exactly three runtime-backfill carve-outs (`verifier_enabled`, `scope_tagger_enabled`, `visual_fidelity_required`) and line 310 ends with: `These three are the only carve-outs from the no-silent-defaults rule above.` implement line 97 then performs a fourth runtime backfill — `phase:` — with its own scan/ordinal-derive/round-trip-check semantics, none of which are mentioned in using-qrspi's no-silent-defaults section.
- problem: using-qrspi's "These three are the only carve-outs" is provably false: implement adds a fourth. Either the rule needs `phase:` added to the enumeration (with its scan-derive procedure documented as a fourth carve-out), or the implement backfill needs to go through the no-silent-defaults procedure (halt with a validation menu, not silently scan and write back). Currently it's neither — implement just does the write, and using-qrspi declares only three carve-outs.
- proposed_fix: Add `phase:` as a fourth carve-out in using-qrspi line 304-310 with a brief description of the scan-derive procedure (or a `see implement/SKILL.md § Implement-Entry Smoke Check` link). Fix the "These three are the only carve-outs" sentence to read "These four are the only carve-outs."
- links_to_existing_issue: F06 (same root cause: `phase:` is undocumented in using-qrspi); could merge with F06 if folded together.

## Cross-file patterns

- **Vendor-name drift (codex / second-reviewer / Codex):** appears in plan, integrate, test, implement, and using-qrspi line 411. Recommend centralizing the vocabulary decision in using-qrspi (one line: "the dispatch-tag suffix `*-codex` is a fixed tag name, not a vendor binding; the config field is `second_reviewer:`") and sweeping `codex_reviews` → `second_reviewer` across all consumers (F01, F05, F15 all share root).
- **Dual-SoT shared snippets:** `_shared/config-validation.md` vs inlined using-qrspi § Config Validation Procedure; `_shared/review-loop.md` vs inlined using-qrspi § Standard Review Loop; `_shared/reviewer-dispatch.md` vs `_shared/reviewer-dispatch-prose.md`; `_shared/compaction-checkpoint.md` vs `using-qrspi/references/compaction-checkpoints-detail.md`. Recommend picking one canonical home per contract and deleting the duplicate (F03, F04, F13).
- **`phase:` config field is undocumented in the schema** but read and written by Implement (F06, F18). Recommend adding to the canonical schema and the no-silent-defaults carve-outs.
- **Cross-file Test-step opt-out restatement** (F17): mentioned in 4 places across 2 files. Recommend collapsing to 1 statement in test/SKILL.md + 1 in using-qrspi step 12.
- **`Agent({...})` vs `Task({...})` dispatch vocabulary drift** (F11): pick one literal API name and sweep.

## Centralization opportunities

- The `## Config Validation Procedure` section in using-qrspi/SKILL.md (lines 242-348, ~106 lines) duplicates `_shared/config-validation.md` (122 lines). Pick one. The "Field-specific menus" sub-section is the most repeated and most edit-prone.
- The Apply-fix protocol (using-qrspi lines 396-526, ~130 lines) is the longest contiguous block in the spine that no other skill cites by section name. Consider moving the script-level details (step 4 verifier dispatch parameter list; step 5 `verifier-fan-in.sh` assembly format; step 12 anchor-file lookup script invocation) to a `references/apply-fix-protocol.md` snippet that the spine `!cat`-includes, keeping only the orchestration-step list inline. This addresses both the using-qrspi length (622 lines after v0.7.3 trim) and the visibility problem (the Apply-fix step 12 ref-selection table is the load-bearing convergence rule but lives deep inside a long section).
- The visual-fidelity sentinel schema is referenced from multiple files (using-qrspi line 413, implement line 399, plan line 432). `using-qrspi/references/visual-fidelity-sentinel.md` exists — confirm every other site links to it rather than restating.
- The OBC contract is restated in implement (lines 474-484) and integrate (lines 173-208) and test (lines 134-144) with near-identical script-invocation prose, near-identical Batch Gate autopilot branches, and identical "Acknowledge and continue suppressed when Dispatch defects non-empty" rule. Recommend `skills/_shared/orchestration-boundary-check.md` carrying the shared contract + per-skill phase parameter override.

## Acknowledgements (things you explicitly checked and found acceptable)

- The Iron Law / iron-law placement at start AND end of each SKILL.md (implement lines 22-28 + 511-513; integrate lines 24-28 + 301-307; test lines 16-18 + 305-309; plan lines 40-44 + 442-446; using-qrspi lines 6-8 + 618-622) correctly applies R3 end-of-context placement.
- using-qrspi's `<SUBAGENT-STOP>` directive at the top of the file (lines 6-8) is the right cross-cutting subagent exemption mechanism and is correctly cited by every spine's PRECONDITION line.
- The `<HARD-GATE>` XML wrapping is used consistently across plan (lines 40-44), implement (lines 73-75 + 104-106 + 365-367), and integrate (lines 70-75); using-qrspi does not use `<HARD-GATE>` but its iron-laws section is the equivalent.
- The verifier change-type score thresholds (style/clarity ≥80, correctness ≥70) are stated consistently in using-qrspi lines 116, 429, 446, and implement line 350. The asymmetric correctness floor (≥70) carries a `Why:` line per R2 ("hardening-relevant correctness gaps in the 72-78 'real but low-severity' rubric band"). Good R2 application.
- The `scripts/second-reviewer-available.sh` probe is referenced by both using-qrspi line 133 and goals/SKILL.md line 163; the script exists on disk under `scripts/`. Verified.
- Plan's Sweep Task Contract (lines 367-386) carries the rerunnable `grep -rn -- 'pattern' tests/` shape with explicit `--` argument-separator rationale ("the `--` argument separator neutralizes flag-shaped patterns") — strong R2 (rationale alongside prohibition) and good lexical anchoring per R7.
- The `references/` directories in this slice are mostly composed of files >40 lines that genuinely benefit from extraction; few obvious R5 misapplications other than the `_shared/` dual-SoT class.

## Declined findings (per the finding-type gate; not in main list)

- **detail-suggestion (declined):** "Plan should expand the Schema-Migration Task Shape section with more worked examples" — would grow length without adding signal; the existing reference at `plan/references/schema-migration-task-shape.md` is the right home.
- **detail-suggestion (declined):** "Implement's Per-Task Reviewer Dispatch wiring could be diagrammed" — Mermaid is explicitly forbidden by R6 and the existing prose carries the dispatch chain.
- **example-suggestion (declined):** "Add a contrastive good/bad example for the implement smoke check `phase:` backfill" — I have not observed a failure mode for this; per R4, examples are for observed failure modes only.
- **scope-extension (declined):** "Audit the agents/qrspi-*.md bodies referenced by these skills for matching `tier:` fields" — out of slice scope; agents files are not in the audit set.
- **scope-extension (declined):** "Investigate the visual-fidelity binding chain end-to-end across Goals→Design→Phasing→Plan→Implement" — touches goals/design/phasing skills outside my slice.

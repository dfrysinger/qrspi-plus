---
verifier_enabled: true
scored: 34
kept: 11
dropped: 23
failed: 0
clean: 1
---

<!-- @@FINDING: goal-traceability-codex.finding-F01 @@ -->
---
finding_id: R1-F01
reviewer_tag: goal-traceability-codex
artifact: plan.md
round: 1
severity: high
change_type: clarity
location: "All task References blocks (systemic) — e.g. T01 lines 170-174; T25 lines 1587-1590"
---

## Issue

Plan References blocks cite anchors as full heading strings (e.g. `goals.md ### G7`, `design.md ## G7`) and prose phrases (e.g. T25 `structure.md per-file blocks for the 6 new files...`), not as § form. The dispatch shim asserted §-anchor traceability as load-bearing.

## Why

If §-anchor format is the contract, automated anchor-resolution scripts that match on `§G<N>` will not find these references — the trace graph can appear complete while containing unresolvable references at the literal-syntax level. Non-heading prose citations (T25's "per-file blocks for the 6 new files") have no anchor to resolve to at all.

## Fix

Either (a) normalize the contract: confirm that "`goals.md ### G7`" is the canonical anchor form (not "`§G7`"), and update any §-form references in the dispatch shim and reviewer prompts to match; or (b) rewrite plan References to use §-form. Replace prose-citation forms ("per-file blocks for the 6 new files") with enumerated anchor lists.

## Disposition note (orchestrator)

Counter-evidence: goal-traceability-claude verified all anchors DO resolve (the `### G7` heading exists in goals.md). The §-shorthand was my dispatch-shim notation, not the literal format used in plan.md. The substantive concern is the non-heading prose citation in T25, not the cross-form mismatch.
<!-- @@SCORE: goal-traceability-codex.finding-F01.score @@ -->
score: 20
reason: Reviewer's own disposition note concedes the §-form contract was their dispatch-shim notation (not actually required); the plan SKILL.md template prescribes no §-anchor syntax and anchors verifiably resolve, leaving only a minor prose-citation nit in T25.
<!-- @@FINDING: quality-claude.finding-F01 @@ -->
---
finding_id: R1-F01
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
artifact: plan.md
round: 1
reviewer: quality-claude
---

# T25 "Blocks" field mislabels downstream consumers — disagrees with the actual Slice 1.5 task list

## What's wrong

T25 (the hand-authored G31 prompt-prose primitives pilot, around plan.md line 1548) declares:

> **Dependencies:** none. **Blocks:** T26 (Plan/Design `!cat` include sites), T27 (reviewer-protocol consumer), T28-T31 (remaining G31 consumers).

But the canonical Slice 1.5 task list earlier in the same plan (the "Task List by Slice" block) assigns those task numbers to entirely different goals:

- T26 — G31 prompt-prose include sites across Design, Plan, and reviewer agents ← the *only* downstream G31 consumer
- T27 — CD-2 evergreen-output-rule shared snippet (goals: G3/G4/G22/G27) — **not** a reviewer-protocol consumer, **not** a G31 consumer
- T28 — CD-3 multi-actor-flow-check (goals: G1/G30/G33) — **not** a G31 consumer
- T29 — G34 Design scope-reviewer alignment — **not** a G31 consumer
- T30 — G1 Design phase decision-completeness template — **not** a G31 consumer
- T31 — G33 Design skill interactive dialog clarity — **not** a G31 consumer

Cross-check from the other direction: of T27–T31, only T29 lacks a `Dependencies:` line citing T25, and none cite T25 as a dep — T27, T28, T33, T34, T36 all declare `Dependencies: none`; T29 declares `Dependencies: none`; T30 depends on T29; T31 depends on T30; T32 depends on T30 + T31. The "Blocks" assertion in T25 is unsupported in both directions.

This looks like stale numbering from an earlier draft where the G31 consumer cluster was packed densely after the primitives task. After Slice 1.5 absorbed CD-2 / CD-3 / G34 / G1 / G33 tasks in between, the pilot's hand-authored Blocks field was not updated.

## Why it matters

The Blocks declaration is the human-readable dependency-graph artifact reviewers and Implement orchestration scan to plan task-merge order. A wrong Blocks list:

- misroutes attention if a reviewer audits "every consumer of T25's prompt-prose primitives" against T27–T31, when only T26 is a real consumer;
- contradicts the canonical task list above it, which is the kind of internal inconsistency the plan-spec contract is supposed to prevent;
- specifically mislabels T27 as a "reviewer-protocol consumer" — there is no reviewer-protocol consumer task for G31 primitives in this plan at all (T26's reviewer-agent consumer set is Design / Plan / lightweight-implementer / Design scope-reviewer / Plan test-coverage reviewer, none of which are the reviewer-protocol skill).

The dispatch prompt flagged T25 as the hand-authored pilot and asked me to be alert for anomalies without assuming the new shape is itself the problem. This is one such anomaly — the bullet-layer schema, not the new prose layer, carries the defect.

## Suggested fix

Replace the T25 Blocks line with the actually-supported set:

```
Dependencies: none. Blocks: T26 (G31 `!cat` include sites + skill-frontmatter preloads), T39 (G32 build pipeline's defensive copy of `skills/_shared/prompt-prose-detection.md`).
```

(T39 already declares `Dependencies: Task 25` and explains its dependence on the prompt-prose-detection.md defensive-copy site in the dependency-graph commentary at the top of the plan — that's the only other real downstream consumer.)
<!-- @@SCORE: quality-claude.finding-F01.score @@ -->
score: 72
reason: Verified — T25's Blocks field (line 1542) cites T27 as "reviewer-protocol consumer" and T28-T31 as "G31 consumers", but the canonical Task List by Slice and Dependency Graph (lines 75-114) clearly show T27=CD-2, T28=CD-3, T29=G34, T30=G1, T31=G33 (none are G31 consumers); only T26 and T39 are real downstream consumers of T25.
<!-- @@FINDING: quality-claude.finding-F02 @@ -->
---
finding_id: R1-F02
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
artifact: plan.md
round: 1
reviewer: quality-claude
---

# T05 claims `(create)` for `scripts/verifier-fan-in.sh` that T02 already creates

## What's wrong

T05 (G13 `change_type` enum drift hardening, around plan.md line 353) declares:

> **Target files:** scripts/verifier-fan-in.sh (create), skills/reviewer-protocol/SKILL.md (modify), tests/unit/test-change-type-partition.bats (modify)
> **Dependencies:** Task 02, Task 04

But Task 02 (G12 verifier-fan-in script, line 188) already declares:

> **Target files:** scripts/verifier-fan-in.sh (create), skills/_shared/verifier-dispatch-prose.md (create)

So `scripts/verifier-fan-in.sh` is asserted to be created by both T02 and T05, and T05 explicitly depends on T02. By the time T05 runs, T02 has already landed the file (and T05's own scope text confirms it: "Add the canonical `change_type` enum (`style`, `clarity`, `correctness`, `scope`, `intent`) to the `scripts/verifier-fan-in.sh` header" — that wording is unambiguously modification of an existing file).

## Why it matters

The `(create) | (modify)` marker on Target files is part of the canonical bullet schema the implementer agent and the plan reviewer rely on. Two consequences when the marker is wrong:

1. **Implementer ambiguity.** A fresh-context implementer dispatched against T05's spec will see the script listed as `(create)` and may either (a) try to write the file from scratch, clobbering T02's work, or (b) detect the mismatch with the on-disk state and stall to clarify with the orchestrator. Both are recoverable but waste a round.

2. **Reviewer-graph noise.** Plan-reviewer / Structure-reviewer correctness checks that cross-reference Target files against the dependency DAG should flag every `(create)` as the unique owner of that path — having two `(create)` claims for the same file is exactly the schema violation the marker exists to catch.

This is symmetric with T13 (which correctly declares `scripts/round-prepare.sh (modify)` after T12 created it) — the convention is in place, T05 just deviates from it.

## Suggested fix

Change T05's Target-files line to:

```
**Target files:** scripts/verifier-fan-in.sh (modify), skills/reviewer-protocol/SKILL.md (modify), tests/unit/test-change-type-partition.bats (modify)
```

No other change required — T05's Definition of done and Test expectations already read as modifications, not initial creation.
<!-- @@SCORE: quality-claude.finding-F02.score @@ -->
score: 75
reason: Confirmed in plan.md — T02 (line 182) and T05 (line 347) both mark scripts/verifier-fan-in.sh as (create) despite T05 depending on T02 and its scope clearly describing modifications; the (create)/(modify) marker is a load-bearing schema field consumed by implementers and reviewers.
<!-- @@FINDING: quality-claude.finding-F03 @@ -->
---
finding_id: R1-F03
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
artifact: plan.md
round: 1
reviewer: quality-claude
---

# T13 references post-rename `dispatch-agent.sh --implementer-commit` without depending on T20, and no task owns the new subcommand

## What's wrong

T13 (G9 per-task review orchestration, around plan.md line 815) modifies `skills/implement/SKILL.md` to install a between-round checklist invoking the renamed dispatcher under a new subcommand:

> **Scope > In:** ... "Insert the G9 between-round checklist into `skills/implement/SKILL.md` at the per-task reviewer fan-out site, covering scope-tagger dispatch, implementer `commit_sha:` extraction, **`dispatch-agent.sh --implementer-commit` invocation**, and exit-code branches for success, orchestrator bug, worktree integrity break, and implementer re-dispatch."
>
> **Test expectations:** ... "Grep audit on `skills/implement/SKILL.md`: the per-task reviewer fan-out section contains the checklist items for ... `dispatch-agent.sh --implementer-commit`, and exit-code branches 0/10/11/12."
>
> **Dependencies:** Task 12

Two interlocking gaps with this:

### Gap A — Rename ordering

The script name `dispatch-agent.sh` does not exist until T20 (G3, plan.md line 1229) lands the hard rename of `scripts/run-codex-review.sh` → `scripts/dispatch-agent.sh`. T20's bullet list confirms: "rename `scripts/run-codex-review.sh` → `scripts/dispatch-agent.sh`". T13's only declared dependency is T12.

The overview's Dependency Graph section enumerates three cross-slice chains and explicitly omits T13 from the G3 rename chain ("G3 splitter rename (Slice 1.4) → G16 dispatch-agent path-filter (Slice 1.4) → G32 build pipeline (Slice 1.7)"). If T13 lands before T20 (legitimate under the declared deps), implement/SKILL.md will contain a grep-audited instruction to invoke a script that does not yet exist under that name.

### Gap B — Missing subcommand owner

Even granting that T20 introduces the renamed binary, neither T20's spec nor T13's Target-files list adds an `--implementer-commit` subcommand to `dispatch-agent.sh`. T13 modifies `scripts/round-prepare.sh` (the per-task SHA / commit-anchor work belongs there), and the recovery codes 10/11/12 T13 names match the exit codes T12 already documented on `round-prepare.sh`. T20's scope is the dispatcher rename + per-skill prose migration, with no new subcommand mentioned.

So the orchestrator instruction `dispatch-agent.sh --implementer-commit <sha>` references a CLI subcommand that no task in this plan creates. Either (a) the instruction should call `scripts/round-prepare.sh` directly (which matches the per-task target-file work T13 actually does), or (b) some task must add a thin `--implementer-commit` subcommand wrapper to `dispatch-agent.sh` and that work needs an owner with the right deps.

## Why it matters

This is the same v0.7.1 failure-mode class the release is trying to close — Plan-phase under-scoping cross-task consumer surface (G18). T13 names a contract surface (a wrapper subcommand) without enumerating which task creates it. Compounded with the rename-ordering gap, an Implement-phase orchestrator dispatching T13 ahead of T20 will produce a green per-task gate (T13's grep audits pass against the prose T13 itself authored) while the actual instruction is unrunnable, and the breakage surfaces only at the next per-task review round on a different task.

## Suggested fix

Pick one of:

1. **Drop the subcommand wrapper.** Rewrite T13's `dispatch-agent.sh --implementer-commit` references to call `scripts/round-prepare.sh` directly. T13 already owns round-prepare.sh modifications and the recovery-code wiring is self-contained there. Then add T20 to T13's Dependencies only if implement/SKILL.md's per-task checklist also references the renamed dispatcher for other reasons (it may; if so, the prose still needs T20 ahead of T13).

2. **Give the subcommand an owner.** Add `scripts/dispatch-agent.sh (modify)` to T13's Target files plus an In-scope deliverable defining the `--implementer-commit <sha>` subcommand semantics (or assign that work to T20's already-large rename task), AND add T20 to T13's Dependencies so the rename precedes T13's grep-audited prose.

Either resolution should also be reflected in the Dependency Graph commentary so the third bullet's chain reads ".../G3 splitter rename (Slice 1.4) → {G9 per-task orchestration (Slice 1.3), G16 dispatch-agent path-filter (Slice 1.4), G32 build pipeline (Slice 1.7)}." if option 2 is chosen.
<!-- @@SCORE: quality-claude.finding-F03.score @@ -->
score: 55
reason: Gap A (T13→T20 rename/file-conflict dep missing from the graph for a task whose grep audit pins the post-rename script name) is a real Plan-level cross-task-surface oversight matching the G18 closure goal; Gap B materially misreads `--implementer-commit` as a missing subcommand when design.md CD-1 documents it as a flag on the universal dispatch-agent owned implicitly by T20's rename + universal-entry-point responsibility, so the finding is partially correct, partially overreached.
<!-- @@FINDING: quality-claude.finding-F04 @@ -->
---
finding_id: R1-F04
severity: low
change_type: clarity
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
artifact: plan.md
round: 1
reviewer: quality-claude
---

# T19 and T20 canonical-bullet `Model:` line carries a malformed annotation

## What's wrong

Two tasks deviate from the canonical bullet schema for the `Model:` line:

- T19 (G27 second-reviewer-available helper, plan.md line 1167):
  `- **Model:** opus  (sizing_exception → opus)`

- T20 (G3 dispatch-script rename collapse, plan.md line 1235):
  `- **Model:** opus  (sizing_exception → opus)`

The canonical shape, as carried by every other task in this plan (e.g. T12, T16, T25, T39), is two separate bullets:

```
- **Model:** opus
- **Sizing exception:** reusable primitives   ← (or "schema migration" / "CI scaffolding")
```

T19 and T20 both already include the separate `- **Sizing exception:** reusable primitives` bullet *below* the `Model:` line. The `(sizing_exception → opus)` parenthetical on the Model line is therefore redundant — and the arrow grammar is semantically ambiguous: a reader cannot tell whether it means "the sizing exception forces the model up to opus", "the sizing exception is the reason this task is opus rather than the default", or "the sizing exception's recommended model is opus." The other reusable-primitive tasks in this plan (T12 ~280 LOC; T25 ~340 LOC; T39 ~360 LOC) do not carry this annotation, so the deviation is not consistently load-bearing.

## Why it matters

- **Parser fragility.** The dispatch / Implement pipeline reads the canonical bullets via lightweight grep / awk. A parser tolerant of `**Model:** opus` is not necessarily tolerant of `**Model:** opus  (sizing_exception → opus)` — the parenthetical can spill into a captured model name or trip a strict-mode validation.
- **Schema-drift signal.** If the new prose-section template (the dispatch prompt called out as the v0.7.3 SKILL update) is meant to preserve the bullet schema *exactly*, then divergent shapes on T19/T20 weaken the per-task-spec schema contract that the rest of the file honors. Better to be uniformly clean than to leave two anomalies that a future schema-validator must learn to tolerate.

## Suggested fix

Drop the parenthetical on both tasks; the separate `Sizing exception:` bullet already carries the rationale:

T19:
```
- **Model:** opus
```

T20:
```
- **Model:** opus
```

If the intent was to document *why* opus was selected (sizing exception forced a model escalation), restate that in the Overview prose section instead — that is exactly the kind of decision context the new prose layer is built to carry.
<!-- @@SCORE: quality-claude.finding-F04.score @@ -->
score: 40
reason: Real two-task deviation from the canonical `- **Model:** opus` bullet shape used by T10/T12/T14/T25/T39 (parenthetical is redundant with the separate `Sizing exception:` bullet below it on T19/T20), but low severity / clarity-class with no Iron Rule violation and the parser-fragility concern is speculative.
<!-- @@FINDING: quality-codex.finding-F01 @@ -->
---
finding_id: R1-F01
reviewer_tag: quality-codex
artifact: plan.md
round: 1
severity: high
change_type: correctness
location: "Task 29, Task 37, Task 38 — Target files sets vs structure.md required files"
---

## Issue

`structure.md` requires three files that are not owned by any Plan task: `skills/structure/owns-defers.md`, `tests/lint/test-design-altitude-boundary-include.bats`, and `tests/lint/test-structure-altitude-boundary-include.bats`. Task 29, 37, and 38 are the natural homes for these files but none enumerate them in their Target files sets.

## Why

A file required by structure but unclaimed by any task will not be written — the implementer's contract is the task's Target files set, not the structure inventory. Each goal-level coverage check would pass while the actual disk surface ships incomplete.

## Fix

Audit structure.md's per-file blocks against the union of all Plan Target files sets; assign each unclaimed file to a single task. For these three: add `skills/structure/owns-defers.md` to T29; add the two `tests/lint/test-*-altitude-boundary-include.bats` to T37 (design) and T38 (structure).
<!-- @@SCORE: quality-codex.finding-F01.score @@ -->
score: 78
reason: Verified — structure.md lines 122, 129, 132 require `tests/lint/test-design-altitude-boundary-include.bats`, `skills/structure/owns-defers.md`, and `tests/lint/test-structure-altitude-boundary-include.bats` for G34/G35, but none appear in any Plan task's Target files (T29/T37/T38 spot-checked); this violates Plan's contract to break all of structure into tasks, leaving three required files unowned — fix-recipe task assignments are slightly off (structure/owns-defers belongs naturally in T37, not T29) but the underlying coverage gap is real and high-impact.
<!-- @@FINDING: quality-codex.finding-F02 @@ -->
---
finding_id: R1-F02
reviewer_tag: quality-codex
artifact: plan.md
round: 1
severity: medium
change_type: correctness
location: "Task 33 sizing_exception value vs cross-task token convention"
---

## Issue

T33 codifies `sizing_exception: schema-migration` (hyphenated), while other task sizing-exception declarations elsewhere in plan.md use the space-form `schema migration`. The closed sizing-exception enum cannot accept both spellings.

## Why

Whichever validator/reviewer reads sizing_exception will accept one spelling and reject the other. Either T33 fails validation at parse time, or the other tasks do.

## Fix

Pick one canonical token form (recommend hyphenated `schema-migration` since the enum is a code-level identifier, not prose) and normalize all sizing_exception lines across plan.md to match. Cross-link the closed enum surface in structure.md or design.md.
<!-- @@SCORE: quality-codex.finding-F02.score @@ -->
score: 72
reason: Verified — T33 spec uses hyphenated `schema-migration` (lines 2040/2053/2054/2062) while T16 task-list entry (line 63) and T33's own closed-set enumeration (lines 2049, 2067) use spaced `schema migration`; this is a real intra-plan contradiction that will misfire the structural lint or T16 once implemented.
<!-- @@FINDING: quality-codex.finding-F03 @@ -->
---
finding_id: R1-F03
reviewer_tag: quality-codex
artifact: plan.md
round: 1
severity: low
change_type: clarity
location: "Task 24 — Slice 1.4 placement vs Goal IDs"
---

## Issue

T24 is placed under Slice 1.4 but carries Goal IDs `[G6, G11, G12]`, which phasing.md defines as Slice 1.1 goals.

## Why

Slice-level traceability is one of the orientation lenses a reviewer uses on plan.md. A task whose goals straddle slices weakens that lens without adding information.

## Fix

Either move T24 under Slice 1.1 to match its goal cluster, or add a one-line cross-slice rationale to T24's overview/dependencies explaining why the work is correctly placed in 1.4 despite the goal IDs (e.g. it consumes T01/T02/T03 outputs).
<!-- @@SCORE: quality-codex.finding-F03.score @@ -->
score: 45
reason: Real low-severity clarity mismatch — Task 24 sits under Slice 1.4 but lists only Slice 1.1 goal IDs (G6/G11/G12), confirmed against phasing.md slice rosters; placement is defensible (CD-4 cross-cutting helper grouped with other Slice 1.4 dispatch infra) but the cross-slice rationale is implicit, so a one-line note would meaningfully aid reviewer orientation.
<!-- @@FINDING: scope-claude.finding-F01 @@ -->
---
finding_id: R1-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-30-v072-release/plan.md:L347, docs/qrspi/2026-05-30-v072-release/plan.md:L358-L360]
artifact: plan
round: 1
reviewer: scope-claude
---

Task 05 (G13 `change_type` enum drift hardening) carries a contradiction between **Target files** and **Scope: In** that this scope reviewer is asked to flag per the dispatch instructions ("Flag contradictions between Scope and Target files (e.g., Scope says 'create X' but Target files lists 'modify X' or vice versa).").

**Concrete contradiction:**

- Target files (line 347) lists `scripts/verifier-fan-in.sh (create)`.
- Scope: In (lines 358–360) describes "Add the canonical `change_type` enum (`style`, `clarity`, `correctness`, `scope`, `intent`) to the `scripts/verifier-fan-in.sh` header" and "Make `scripts/verifier-fan-in.sh` treat an out-of-enum `change_type:` as a contract violation: exit non-zero, write `.verifier-fan-in-audit.json` …" — i.e. extending/modifying behavior of an already-existing script.
- Dependencies (line 348) cite `Task 02`, and Task 02 (line 182) already lists `scripts/verifier-fan-in.sh (create)` as its Target file and is responsible for creating that script as the verifier-fan-in primitive.

By the time T05 executes (sequenced after T02 per the explicit dependency), `scripts/verifier-fan-in.sh` already exists. T05's Target-files marker must be `(modify)`, not `(create)`. The `(create)` marker also collides with T02's own canonical create-of-record, which would make two task specs claim creation of the same file path — exactly the kind of ownership ambiguity the per-task `(create)/(modify)` annotation exists to prevent.

**Why this is a scope finding rather than artifact-quality:**

The Plan reviewer dispatch contract handed to this scope reviewer explicitly carves out Scope-vs-Target-files contradictions as in-scope for me. The mis-marked annotation is a scope/boundary signal — it makes T05 appear to own the script's creation surface (a structural claim) when the OWNS/DEFERS-consistent reading of Scope: In is that T05 only owns an enum-hardening modification layered onto T02's already-created script. Left uncorrected, this would mis-route ownership of the file's create surface across two tasks.

**Suggested resolution:**

Change Target files line 347 from `scripts/verifier-fan-in.sh (create), …` to `scripts/verifier-fan-in.sh (modify), …`. No other Plan content needs to change — Scope: In, DoD, Dependencies, and Test expectations are already self-consistent against the modify reading.
<!-- @@SCORE: scope-claude.finding-F01.score @@ -->
score: 80
reason: Confirmed — T05 Target files line 347 marks scripts/verifier-fan-in.sh as (create) while T02 (line 182) already creates it and T05 depends on T02; this is a real Scope-vs-Target-files contradiction and a duplicate-create ownership ambiguity explicitly in scope for this reviewer.
<!-- @@FINDING: scope-codex.finding-F01 @@ -->
---
finding_id: R1-F01
reviewer_tag: scope-codex
artifact: plan.md
round: 1
severity: high
change_type: scope
location: "Plan-level Phase 1 acceptance block and slice sequencing rationale"
---

## Issue

Plan includes a Phase 1 acceptance-criteria block and a Dependency Graph section that articulates slice sequencing rationale. Per skills/plan/owns-defers.md, vertical-slice authoring and phase boundaries are owned by phasing.md; plan.md should defer to those sources, not re-author them.

## Why

Duplicating phasing content in plan.md creates two sources of truth. Future edits to slice ordering or acceptance criteria must update both files in lock-step; one will drift.

## Fix

Replace the Phase 1 acceptance block with a one-line pointer to phasing.md's Phase 1 acceptance criteria section. Replace the slice sequencing rationale with a pointer to phasing.md's vertical-slice section. Plan retains the per-task `Dependencies:` bullets (which ARE plan-owned).

## Disposition note (orchestrator)

Counter-evidence: scope-claude verdict is that this content stays at plan's altitude because Phase 1 acceptance is plan-authored when there is a single phase. Surfaced here for verifier triage.
<!-- @@SCORE: scope-codex.finding-F01.score @@ -->
score: 55
reason: Real boundary-drift per owns-defers.md (phasing-owned content) — plan items 6-7 strictly duplicate phasing.md's acceptance gate and Overview borrows slice-sequencing framing; partial since items 1-5 are plausibly Plan-altitude cross-task behaviors.
<!-- @@FINDING: scope-codex.finding-F02 @@ -->
---
finding_id: R1-F02
reviewer_tag: scope-codex
artifact: plan.md
round: 1
severity: medium
change_type: scope
location: "Many tasks — exact file operations, command sequences, exit-code branches"
---

## Issue

Many task specs descend to implementation-contract level: exact byte-for-byte file operations, exact command sequences, exit-code branches in Test expectations. Per owns-defers, that altitude is owned by structure.md (interfaces) and the implementer (line-level).

## Why

Plan's altitude is "what each task accepts as input, produces as output, and proves in test." When plan pins exit codes and command sequences, it removes the implementer's ability to refactor without re-opening plan; it also re-authors structure-owned interface contracts.

## Fix

Sweep each task's DoD and Test expectations: replace literal command sequences with behavioral assertions ("rejects symlink that resolves outside repo root"), replace exit-code pins with pass/fail outcome descriptions, and cross-reference structure.md for the interface contract.

## Disposition note (orchestrator)

Counter-evidence: this verdict opposes scope-claude's "no boundary drift" finding. The specificity in test expectations is part of the new template's value proposition (T25 pilot deliberately pins exact behavior). Surfaced here for verifier triage.
<!-- @@SCORE: scope-codex.finding-F02.score @@ -->
score: 22
reason: Plan owns "test expectations in plain language — behaviors, inputs/outputs, edge cases, error conditions"; exit-0/non-zero outcomes, kept-set file contents, halt-cause names, and grep audits are canonical behavioral assertions and don't match any of owns-defers's lexical leakage signals (function signatures, expect()/assert., control flow, trade-off, phase-N), and several "command sequences" the finding cites are actually the prose contents of deliverable snippet files (T02's verifier-dispatch-prose.md) rather than implementer commands — orchestrator's own counter-evidence note flagged this as opposing scope-claude.
<!-- @@FINDING: scope-codex.finding-F03 @@ -->
---
finding_id: R1-F03
reviewer_tag: scope-codex
artifact: plan.md
round: 1
severity: medium
change_type: scope
location: "plan.md aggregate size (2733 lines for 44 tasks)"
---

## Issue

Plan aggregate length (~2733 lines) suggests scope inflation beyond concise plan intent — content has been pulled in from downstream artifacts (design/structure).

## Why

Size is a proxy for boundary drift. Even if each individual task respects altitude, an aggregate that approaches structure.md's size is a smell that downstream content has migrated upward.

## Fix

Audit per-task average (62 lines/task) against the owns-defers rubric; tighten any task whose prose is >80 lines by replacing inlined design/structure content with cross-references.

## Disposition note (orchestrator)

Counter-evidence: scope-claude explicitly judged 62 lines/task as "consistent with the corpus average." Size-as-smell may be a false signal under the new 5-prose-section template. Surfaced here for verifier triage.
<!-- @@SCORE: scope-codex.finding-F03.score @@ -->
score: 20
reason: Size-as-smell with no concrete per-task evidence of design/structure inlining; scope-claude's counter-evidence (62 lines/task matching the template's 5-section structure) and the finding's own disposition note both undercut this; Plan SKILL imposes no aggregate-length ceiling.
<!-- @@FINDING: security-claude.finding-F01 @@ -->
---
finding_id: R1-F01
reviewer_tag: security-claude
artifact: plan.md
round: 1
severity: high
change_type: correctness
location: "Task 21 (G16 path-filter exfil hardening in dispatch-agent.sh) — Scope (In) / Definition of done / Test expectations"
---

## Issue

Task 21's Scope (In) bullet at plan.md:1312 explicitly requires the
`assert_path_under_repo_root` guard to be applied to **"the agent file and
every `--subject-code`, `--artifact-body`, `--companion`, and `--diff-file`
path family"** (emphasis on the agent file).

However, both the Definition of done (plan.md:1329) and the Test expectations
(plan.md:1336–1343) enumerate only the four `--<flag>` argument families and
silently drop the agent-file path. The DoD line reads:
> "`--subject-code`, `--artifact-body`, `--companion`, and `--diff-file` all
> pass through the same repo-boundary enforcement point"

…with no corresponding clause for the agent file. Test expectations include
fixtures for the four flag families plus a symlink regression on
`--subject-code`, but no regression that asserts the agent-file path is
canonicalized and rejected when it resolves outside `$REPO_ROOT/`.

## Why this is a security gap

The implementer is contractually bound only by what tests pin. A test-writer
working from this spec will produce RED tests for the four flag families;
the implementer will satisfy those tests and ship. The Scope mention of the
agent file becomes unenforced prose, and a `dispatch-agent.sh` invocation
that resolves the agent-body path from any caller-controllable source
(subagent-type lookup, env var, future flag) becomes a sanctioned-channel
exfil sink — exactly the regression class G16 exists to close.

This is the same fail-mode G16 itself was filed against: a path the dispatcher
reads with `cat` before emission is the load-bearing exfil surface.
Inconsistency between Scope and DoD/Tests on the very file that motivates
the guard is a load-bearing omission, not a wording nit.

## Required fix at plan level

Add to Task 21:

1. **Definition of done** — append: "The agent-file path resolved by
   `dispatch-agent.sh` (whether from `--subagent-type` lookup, an explicit
   agent-path argument, or any other caller-influenced source) passes through
   the same `assert_path_under_repo_root` enforcement point before any
   `cat`/read or prompt emission."

2. **Test expectations** — append: a regression that drives the agent-file
   resolution path with a value whose canonical target is outside
   `$REPO_ROOT/` (both the absolute-path and in-repo-symlink-to-outside
   cases) and asserts non-zero exit with the `resolves outside repository`
   diagnostic before any prompt file is emitted.

Without these, the agent-file mention in Scope is unenforceable and the
guard's coverage is materially narrower than the design intends.
<!-- @@SCORE: security-claude.finding-F01.score @@ -->
score: 55
reason: Real internal-consistency gap — Task 21 Scope lists the agent file alongside the four flag families but DoD enumeration (line 1329) and Test expectations (lines 1336-1343) only pin the four flags; design.md line 1636 confirms AGENT_FILE_ABS is a guarded call site, though design's own test list also omits an agent-file regression, and generic DoD line 1326 partially mitigates by covering "any canonicalized prompt-ingested path." Severity "high" is somewhat elevated since the agent path is typically derived from subagent-type lookup (not directly caller-controllable), but the test-pinning argument is sound.
<!-- @@FINDING: security-claude.finding-F02 @@ -->
---
finding_id: R1-F02
reviewer_tag: security-claude
artifact: plan.md
round: 1
severity: medium
change_type: correctness
location: "Task 39 (G32 plugin build pipeline) — Scope (In) / Definition of done / Test expectations; compare against Task 21's symlink-canonicalization requirement"
---

## Issue

Task 39's `!cat` resolver in `tools/build-plugin.mjs` is required to fail
non-zero for "malformed `!cat` lines, missing targets, include cycles with
full cycle printed, absolute/path-traversal attempts, outside-root includes,
and any `${CLAUDE_SKILL_DIR}` occurrence in shipped files" (plan.md:2384, DoD
at 2406, tests at 2420). The phrase **"outside-root includes"** is not bound
to a canonicalization rule.

By contrast, Task 21 (the sister exfil-hardening task) explicitly requires
"`realpath` / `readlink -f` … rejects paths whose canonical target is not
under canonical `$REPO_ROOT/`" (plan.md:1311) and pins a symlink regression
"whose lexical path appears allowed but whose canonical target is outside
the repository" (plan.md:1337). Task 39 has no analogous clause.

## Why this is a security gap

A symlink committed under the source tree (e.g.
`skills/_shared/secret-include.md → ../../../etc/passwd`, or any in-repo
symlink whose target is outside the repo, or a symlink into a developer's
home directory on a CI runner) would, under a lexical-only "outside-root"
check, pass the resolver's outside-root gate (because the *literal* include
path is under-root) and have its target content inlined into a shipped
`build/skills/.../SKILL.md` file. That file is then committed into the repo,
distributed via `marketplace.json` pointing at `./build`, and loaded by
every host that installs the plugin.

This is a build-time exfil → distribution path:
- The resolver reads file contents and writes them into shipped artifacts.
- The shipped artifacts are committed and published.
- An adversarial PR (or a contributor accidentally `git add`ing a symlink
  pointing into their home directory) can leak local secrets or CI runner
  contents into a public plugin release through CI's reproducible-build
  diff gate, which will *pass* because the build is deterministic from the
  symlinked source.

The G32 release-acceptance criterion at plan.md:24 — "`${CLAUDE_SKILL_DIR}`
does not appear anywhere in the shipped tree" — does not catch this:
arbitrary inlined file contents are not flagged by any
`${CLAUDE_SKILL_DIR}`-name check.

## Required fix at plan level

Add to Task 39:

1. **Definition of done** — append: "The `!cat` resolver canonicalizes each
   include target with realpath/symlink-following and rejects any include
   whose canonical resolved target is outside canonical repo root, including
   the case where the literal include path is under-root but resolves
   outside-root via a symlink. Resolver rejects symlinks that escape
   `$REPO_ROOT/`, mirroring the boundary contract Task 21 establishes for
   `dispatch-agent.sh`."

2. **Test expectations** — append: a resolver failure fixture where an
   under-root include path is a symlink whose canonical target is outside
   the repo; assert non-zero exit with file:line and a diagnostic naming
   the symlink-escape condition, and assert the shipped `build/` tree is
   not produced.

3. **Cross-link note** — explicitly reference Task 21's
   `assert_path_under_repo_root` contract as the shared canonicalization
   pattern; both repo-boundary surfaces should use the same conceptual
   guard so the security model is uniform across runtime dispatch and
   build-time inclusion.

Without these, the build pipeline ships with a weaker boundary than the
runtime dispatcher and creates a new committed-into-`build/` exfil class
that did not exist before G32.
<!-- @@SCORE: security-claude.finding-F02.score @@ -->
score: 70
reason: Real plan-level asymmetry — Task 21 explicitly requires realpath canonicalization and a symlink regression while Task 39's "outside-root includes" / "path-traversal attempts" is not bound to symlink-following, leaving a plausible build-time exfil path (in-repo symlink → outside-root target inlined into shipped build/) that the ${CLAUDE_SKILL_DIR} grep gate does not catch; fix is concrete, plan-altitude, and security-relevant.
<!-- @@FINDING: security-codex.finding-F01 @@ -->
---
finding_id: R1-F01
reviewer_tag: security-codex
artifact: plan.md
round: 1
severity: high
change_type: correctness
location: "Task 16 (G22) — _resolve-lib.sh precedence, plan.md ~994, ~1009, ~1021"
---

## Issue

T16 explicitly requires fallback to hardcoded `medium` when tier resolution exhausts override/agent/default sources. The precedence chain ends in "hardcoded medium with loud warning" rather than fail-loud halt.

## Why (security gap)

Invalid/missing routing config does not hard-fail; dispatch proceeds on an unintended model/vendor path. A misconfigured routing surface ships as "success" with wrong-vendor dispatch — exactly the silent-substitution class G7b exists to close.

## Fix

Require missing/invalid tier resolution to be fatal (non-zero exit), not default-substituted. Add tests asserting rejection at each precedence step. Note: design.md's CD-1 source for this fallback should also be reviewed; the carve-out may need to be removed at the design level.

## Disposition note (orchestrator)

Concurs with sf-codex F01 (same surface, escalated to high). sf-claude F01 also flagged the same surface at low. Verifier should consolidate.
<!-- @@SCORE: security-codex.finding-F01.score @@ -->
score: 22
reason: Altitude mismatch — Plan faithfully mirrors approved design.md CD-1 point 4 ("hard-coded fallback medium with loud warning"); finding mischaracterizes a loud-warning fallback as G7b silent substitution and even concedes the carve-out belongs at design altitude.
<!-- @@FINDING: security-codex.finding-F02 @@ -->
---
finding_id: R1-F02
reviewer_tag: security-codex
artifact: plan.md
round: 1
severity: medium
change_type: correctness
location: "Task 14/15 (~lines 880, 941-963) and Task 33 (~line 2043)"
---

## Issue

T14/T15 require rerunning author-supplied search commands (e.g. `grep ...`) from repo root. T33 requires the reviewer to execute a `structural_lint:` command from the spec. No requirement or test constrains these to a safe allowlist or rejects shell-metachar/injection payloads.

## Why (security gap)

The plan content itself is an untrusted-data surface (sub-subagent-authored, codex-co-authored). A malicious or accidentally adversarial plan field can trigger arbitrary command execution during review or implementation.

## Fix

Enforce a strict command schema/allowlist (e.g. structured fields with a canonical command/arg JSON, not free-form shell strings), and add negative tests for injection/metachar cases (`; rm -rf`, backticks, dollar-paren substitution, redirects).
<!-- @@SCORE: security-codex.finding-F02.score @@ -->
score: 25
reason: Plan content is authored and human-reviewed in-loop on the developer's own machine; the "untrusted plan = command injection" threat model is weak for this dev-tool workflow, and an allowlist would significantly constrain the legitimate use of grep/structural_lint commands without a recorded upstream constraint demanding it.
<!-- @@FINDING: security-codex.finding-F03 @@ -->
---
finding_id: R1-F03
reviewer_tag: security-codex
artifact: plan.md
round: 1
severity: medium
change_type: correctness
location: "Task 20 (~lines 1243-1262, 1269-1276)"
---

## Issue

T20 writes files using `<tag>`-derived paths (`.dispatch/<tag>.raw`, prompt files, finding materialization) but no explicit validation or tests reject `../`, slashes, or unsafe tag chars.

## Why (security gap)

Path traversal / overwrite outside the intended round directory via a crafted `<tag>` value. The reviewer-tag string flows from configuration into a filesystem path — exactly the class of trust-boundary that needs explicit validation.

## Fix

Add a canonical tag regex (e.g. `^[a-z0-9][a-z0-9-]*$`), reject unsafe tags fail-closed at the dispatch boundary, and add traversal regression tests (`../`, `foo/bar`, absolute paths, NULL bytes).
<!-- @@SCORE: security-codex.finding-F03.score @@ -->
score: 25
reason: Likely altitude mismatch — tag-traversal hardening is a goals/design-level concern that no upstream goal (G3, G16) requested, and `<tag>` derives from orchestrator-configured reviewer tags rather than untrusted user input, making this a speculative defense-in-depth ask rather than a concrete Plan-level scope gap.
<!-- @@FINDING: silent-failure-claude.finding-F01 @@ -->
---
finding_id: R1-F01
severity: low
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
  - docs/qrspi/2026-05-30-v072-release/design.md
artifact: plan.md
---

# T16 (G22) `_resolve-lib.sh` hardcoded-`medium` fallback is a log-and-continue silent failure

## Where

`plan.md` § **Task 16: G22 `model_routing` config schema and agent-sweep migration**:

- **Scope → In:** "Create/update `scripts/_resolve-lib.sh` as the shared routing resolver for agent-frontmatter `tier:` parsing, precedence (`--tier-override` / per-dispatch override → agent `tier:` → `default_tier:` → **hardcoded `medium` with loud warning**), …"
- **Test expectations:** "Exercise/grep `_resolve-lib.sh` coverage for per-dispatch tier override, agent `tier:`, `default_tier:`, and **hardcoded-medium-with-warning** precedence."

Carried forward verbatim from `design.md` § **CD-1 → component 1 → Override precedence**, step 4: *"Hard-coded fallback `medium` with loud warning"*.

## What goes wrong silently

This is a designed-in `log-and-continue` fallback (silent-failure-hunter criterion #4) layered on top of an "or default if missing" pattern (criterion #2). When the resolver reaches precedence step 4, the conditions are:

- An agent dispatch was requested with no `--tier-override`, AND
- The agent's frontmatter has no `tier:` field, AND
- `config.md` has no `default_tier:` (or `default_tier:` is malformed and the validator did not catch it).

The resolver's documented response is to **emit a stderr warning and continue dispatch at tier `medium`** rather than halt. In an LLM-orchestrator runtime (Claude Code, Copilot CLI, Codex CLI), bash stderr warnings emitted by a script that returns exit 0 do not reliably surface in the orchestrator's conversation context — only the exit code drives orchestrator branching. The orchestrator will therefore proceed as if the agent ran at its intended tier, when in fact:

- An agent intended for `high` (e.g., a sensitive code-quality reviewer) silently runs at `medium`, downgrading review depth without an observable signal.
- An agent intended for `low` silently runs at `medium`, over-spending without an observable signal.
- An audit of the round's dispatch manifest will record `model: <medium-tier-model>` with no record that this differed from the agent's declared intent (the agent had no declared intent — that's the failure mode being papered over).

The T16 DoD explicitly carves out *some* silent-fallback prohibitions — `"never silently falls back to a neighboring tier or agent-bundled model"` — but this prohibition does not name the hardcoded-`medium` fallback case (because `medium` is neither a "neighboring tier" relative to the agent's missing-tier nor an "agent-bundled model"). The carve-out is precisely the silent-failure surface.

## Why the warning is not loud enough

The brief's criterion #4 says: *"Does the task treat logging as a substitute for error propagation?"* The answer here is yes. The "loud warning" is stderr text; the propagation is missing because:

1. **Exit code is 0.** Callers (skill prose, dispatch-agent.sh stdout-consumer code, orchestrator branching) cannot distinguish "resolved cleanly" from "fell through to hardcoded default".
2. **Dispatch manifest does not flag the fallback.** Per CD-1, manifest entries record resolved `model` only; there is no `tier_resolution_source:` field that would let a reviewer audit notice the fallback fired.
3. **No round-end summary surfaces stderr warnings.** `await-round.sh` (T12) is explicitly bounded to a "short status line" of stdout/stderr; the loud warning bypasses that summary path.

## Why the validation procedure does not cover this

T16 also creates `skills/_shared/config-validation-procedure.md`, and T17 adds a `model_routing:` validation-table row that fails loudly when the block is missing. But:

- T16 DoD says "missing or malformed `model_routing:` configuration fails loudly" — it does not say "missing `default_tier:` specifically fails loudly". `default_tier:` is a sub-field; a config with `model_routing:` present but `default_tier:` absent is not obviously covered by the existing validation path.
- T16 sweeps every existing `agents/qrspi-*.md` to declare `tier:` — but the resolver fallback fires for *any future agent* (third-party, downstream consumer plugin) added without `tier:`. The sweep is a one-time hygiene, not a permanent invariant.

So in practice, the fallback's reachability is "defense-in-depth that should rarely fire" — but when it does fire, it fires silently from the orchestrator's perspective.

## Suggested remediation (plan-level edit, not implementation work)

Tighten the T16 precedence chain in **Scope → In** and **Definition of done** so step 4 halts loudly instead of continuing:

> *Precedence (`--tier-override` → agent `tier:` → `default_tier:` → halt with non-zero exit and a diagnostic naming the unresolved agent and missing `default_tier:` lookup).*

And tighten the **Test expectations** correspondingly:

> *Exercise/grep `_resolve-lib.sh` coverage for per-dispatch tier override, agent `tier:`, `default_tier:`, and **unresolved-tier halt** behavior; verify the resolver never returns a hardcoded-default tier without a non-zero exit.*

This makes the fallback fail-loud (consistent with the `none`-tier halt the same task already requires) and aligns the resolver with the dispatch-routing fail-loud invariant T18 establishes for the broader section.

If the operator wants to preserve the design-approved "warning + continue" behavior because it functions as a migration-window safety net, the plan should at minimum require:

- The resolver writes a `tier_resolution_source: hardcoded-medium-fallback` field to the dispatch manifest entry so post-round audits can grep for fallback fires.
- The `await-round.sh` short status line surfaces a non-zero count of fallback fires for the round.

Either remediation closes the log-and-continue loop. The current plan + design as written does neither.

## Severity rationale

`low` (not `medium` or `high`) because:

- The fallback's reachability requires two failures (missing agent `tier:` AND missing/malformed `default_tier:`) — the T16 agent sweep + T17 validation row together make it rare.
- It does not affect security or data integrity; the worst case is degraded review quality from a silent tier downgrade.
- The behavior is explicitly approved at design.md ## CD-1 component 1, so this finding is asking the operator to re-confirm a known trade-off rather than fix an oversight.

But `low` (not `informational`) because:

- Silent tier downgrades on reviewer agents directly affect the correctness-gating posture v0.7.2 is supposed to harden.
- The "loud warning" framing in plan + design papers over the fact that stderr warnings are not reliably visible to LLM orchestrators, which is the exact runtime context this release operates in.
- The fix is small (change one precedence step from "warn + continue" to "halt") and reverses the silent-failure surface without losing any documented behavior the agent sweep already establishes.
<!-- @@SCORE: silent-failure-claude.finding-F01.score @@ -->
score: 28
reason: Plan faithfully carries an explicitly approved design.md ## CD-1 decision (warn-and-continue at precedence step 4); finding is a Design-altitude re-litigation flagged at Plan review, self-rated low, and acknowledges it asks the operator to re-confirm a known trade-off rather than fix a Plan defect.
<!-- @@FINDING: silent-failure-codex.finding-F01 @@ -->
---
finding_id: R1-F01
reviewer_tag: silent-failure-codex
artifact: plan.md
round: 1
severity: high
change_type: correctness
location: "Task 16 (G22) — _resolve-lib.sh precedence Scope / Test expectations"
---

## Issue

T16's resolver chain ends in "hardcoded medium with loud warning" — a log-and-continue fallback. Warning-on-stderr + exit 0 does not surface in LLM-orchestrator context.

## Why silent

Caller gets continued execution instead of a required failure signal. The orchestrator cannot branch on a warning it cannot see, so misconfiguration silently ships.

## Fix

Replace step 4 of the precedence chain with a non-zero exit + named diagnostic, consistent with the `none`-tier halt the same task already requires.

## Disposition note (orchestrator)

Concurs with sf-claude F01 (Codex escalates to high, Claude rated low). Also concurs with security-codex F01. Verifier should consolidate.
<!-- @@SCORE: silent-failure-codex.finding-F01.score @@ -->
score: 20
reason: Altitude mismatch — Plan T16 faithfully transcribes design.md CD-1's approved 4-step precedence chain (step 4 "Hard-coded fallback medium with loud warning"); challenging that step relitigates a locked Design decision rather than auditing Plan-to-Design fidelity.
<!-- @@FINDING: silent-failure-codex.finding-F02 @@ -->
---
finding_id: R1-F02
reviewer_tag: silent-failure-codex
artifact: plan.md
round: 1
severity: medium
change_type: correctness
location: "Task 12 (G4) DoD / Test expectations — backward-loop flag delete"
---

## Issue

T12's backward-loop flag DoD describes "delete when possible" with "on delete failure only surface a diagnostic". State-mutation failure is treated as log-and-continue, not fatal.

## Why silent

Failure to delete a consume-once flag leaves sticky state. The next round's ref-selection step reads the flag and broadens regardless of convergence — non-deterministic future routing behavior with no fail-loud signal.

## Fix

Treat flag-delete failure as fatal (non-zero exit, halt the loop). Surface the failure as a Review-Loop Pause Gate that requires user action, not a continue-and-log path.
<!-- @@SCORE: silent-failure-codex.finding-F02.score @@ -->
score: 35
reason: Real concern about sticky consume-once flag, but plan already requires a diagnostic on delete failure (not silent), the design.md G4 spec only says "read-and-delete" without mandating fatal handling, and the sticky-flag failure mode broadens (the conservative direction) rather than silently dropping safety; reviewer's preferred fatal/Pause-Gate fix is a defensible design choice, not a documented invariant violation.
<!-- @@FINDING: silent-failure-codex.finding-F03 @@ -->
---
finding_id: R1-F03
reviewer_tag: silent-failure-codex
artifact: plan.md
round: 1
severity: medium
change_type: correctness
location: "Task 19 (G27) Scope — second_reviewer probe fallback"
---

## Issue

T19 Scope describes `second_reviewer: false on probe failure` — probe failure is converted into a config fallback that disables the second review.

## Why silent

Loses review coverage while appearing like a normal configured single-reviewer run. The orchestrator cannot distinguish "user intentionally chose single reviewer" from "second reviewer was silently disabled because probe failed."

## Fix

Treat probe failure as fatal (halt with operator-actionable diagnostic). If the user wants single-reviewer mode, they should configure it explicitly, not get it as a probe-failure side effect.
<!-- @@SCORE: silent-failure-codex.finding-F03.score @@ -->
score: 15
reason: Plan T19 faithfully implements design.md G27 § D3's explicit "skip silently and write second_reviewer: false" decision for hosts with no available second-reviewer vendor; the probe still emits a loud [second-reviewer-unavailable] stderr diagnostic (per T19 test expectations) and D4 enforces a runtime halt if a user manually sets second_reviewer: true on an unsupported host, so the finding's "treat as fatal" fix contradicts the approved upstream design rather than catching a real defect.
<!-- @@FINDING: spec-claude.finding-F01 @@ -->
---
finding_id: R1-F01
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
artifact: plan.md
round: 1
reviewer: spec-claude
---

# Dependency graph misses ordering edges around T20 (G3 script-rename collapse)

## What's wrong

T20 renames three live scripts:

- `scripts/run-codex-review.sh` → `scripts/dispatch-agent.sh`
- `scripts/run-third-party-llm.sh` → `scripts/dispatch-companion.sh`
- `scripts/codex-finding-splitter.sh` → `scripts/third-party-finding-splitter.sh`

with **no compatibility shim** ("no compatibility shim or live caller left on the old names" — T20 In-scope item 1).

The plan's dep graph encodes the rename's downstream consumers correctly (T20 blocks T21 / T39 via the explicit `G3 → G16 → G32` cluster in the "Dependency Graph" section). But three other tasks touch the same rename surface and carry **no edge to T20** in either direction:

1. **T09 (G20)** — `Target files: ..., scripts/run-codex-review.sh (modify), ...` (line 573). `Dependencies: Task 08` only. The task adds dispatch-manifest host/vendor/model persistence to the pre-rename script. T20 is not a dep, and T09 does not appear in T20's `Blocks:` list.

2. **T11 (G29)** — `Target files: skills/using-qrspi/SKILL.md (modify), scripts/run-codex-review.sh (modify), ...` (line 692). `Dependencies: none`. The task adds first-party / third-party manifest-provenance fields to the pre-rename script. T20 is not a dep, and T11 does not appear in T20's `Blocks:` list. T11's own References entry even cites "`structure.md ### scripts/run-codex-review.sh` — Slice 1.2 manifest-provenance persistence … and cross-slice rename note" — acknowledging the rename without ordering against it.

3. **T13 (G9)** — `skills/implement/SKILL.md (modify)` In-scope item: "Insert the G9 between-round checklist … `dispatch-agent.sh --implementer-commit` invocation, and exit-code branches…" (line 829). The SKILL prose names the **post-rename** script. `Dependencies: Task 12` only; T20 is not listed.

Whichever ordering the implementer runtime picks, at least one of these three tasks lands against a target-file path that does not exist or no longer exists:

- If T20 lands before T09 / T11, both list `scripts/run-codex-review.sh` as a target that has just been renamed away. The implementer agent then either fails the target-file existence check or silently re-targets to `scripts/dispatch-agent.sh` (no explicit guidance in the spec).
- If T09 / T11 land before T20, T20's "rename collapse" subsumes their diff and must re-apply it atomically to the renamed file, with no provenance edge documenting the absorption.
- If T13 lands before T20, the SKILL.md prose references a script name (`dispatch-agent.sh`) that does not yet exist on disk; the per-task gate would emit a SKILL whose load-bearing dispatch instruction names a non-existent path.

This is structurally the same defect class the release is trying to close in G18 (Plan-phase under-scopes cross-task consumer surface) — "the original spec scopes each task's own changes but does not systematically enumerate the downstream consumers of the contracts being changed" (goals.md G18). The rename in T20 is a contract change with three undeclared consumers in the same plan.

## Why it matters

Without explicit dep edges around T20:

- The implementer dep-graph executor has no ordering constraint and can interleave T09 / T11 / T20 in any order; whichever runs first wins, the others race.
- The Phase 1 acceptance criterion "End-to-end pipeline run … cleanly with `verifier_enabled: true` … codex_reviews: true … no orchestrator chat-parsing fallback fires" requires all three of T09 (actual_model audit), T11 (manifest provenance), and T20 (rename + universal dispatcher) to coexist in the final dispatch script. A merge order with implicit interleaving risks losing one of the three on conflict resolution.
- T13's SKILL.md prose referencing `dispatch-agent.sh` before T20 lands turns the per-task gate into a documentation-vs-code drift — the same failure class G17 (stale prose in implementer-protocol after T2 added committed gitignore) is fixing as a side effect of v0.7.1.

The dep graph is the plan's primary correctness artifact for sequencing — operating it with three known-missing edges defeats the purpose.

## Suggested fix

Add the missing edges in the existing dep-graph format. Two equivalent options:

**Option A — sequence T20 last among the run-codex-review consumers.** Update T20's `Dependencies:` line:

```
Dependencies: Task 09, Task 11, Task 12, Task 13, Task 19.
```

…with a short note in T20's Overview ("This rename collapses the script after T09 / T11 land their manifest-provenance fields and T13 wires the SKILL.md callsite, so the rename absorbs all three diffs atomically").

Update T09 and T11 to declare `Blocks: T20`. Update T13's `Blocks:` list to include T20.

**Option B — sequence T20 first and re-target T09 / T11 / T13.** Update T09 / T11 / T13 to declare `Dependencies: …, Task 20`, and rewrite their `Target files:` and prose to use the post-rename script names (`scripts/dispatch-agent.sh`). T20's task body already produces the renamed script; T09 / T11 / T13 then layer their changes onto it.

Either option also requires updating the "Dependency Graph" prose section near the top of plan.md (currently enumerates 3 cross-slice clusters; this rename-consumer cluster is implicit there and should be named explicitly so reviewers can audit it without re-deriving the surface). The current dep-graph text describes the renamed-file cluster as `G3 → G16 → G32` only; the actual cluster is wider.

Either resolution also fixes the implicit assumption that "global task numbering ≈ implementation order." The plan's Overview explicitly says "Cross-slice dependency (Slice 1.4 G4 → Slice 1.3 G9) forces Task 12 (G4 cumulative diff helper) to land before the Slice 1.3 block" — proving the project does encode numbering-vs-deps mismatches when they matter. The T20 rename cluster deserves the same explicit treatment.
<!-- @@SCORE: spec-claude.finding-F01.score @@ -->
score: 78
reason: Verified — T09 (line 567) and T11 (line 686) list `scripts/run-codex-review.sh` as a Target with no dep on T20 (T11 deps: none), and T13 (line 823) references the post-rename `dispatch-agent.sh --implementer-commit` in `skills/implement/SKILL.md` while depending only on Task 12; T20's `Dependencies: Task 12, Task 19` / `Blocks: T21` confirm the missing edges around the T20 rename cluster — a concrete correctness gap in the dep graph that ironically embodies the very G18 under-scoping pattern this release is closing.
<!-- @@FINDING: spec-claude.finding-F02 @@ -->
---
finding_id: R1-F02
severity: low
change_type: clarity
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
artifact: plan.md
round: 1
reviewer: spec-claude
---

# T05 target-file annotation says `(create)` for `scripts/verifier-fan-in.sh` that T02 (its dep) already creates

## What's wrong

T05 (G13 `change_type` enum drift hardening) declares (around plan.md line 353):

> **Target files:** scripts/verifier-fan-in.sh (create), skills/reviewer-protocol/SKILL.md (modify), tests/unit/test-change-type-partition.bats (modify)
> **Dependencies:** Task 02, Task 04

T02 already carries `scripts/verifier-fan-in.sh (create)` in its own Target files (line ~190 — T02 is the canonical creator of the fan-in script under the CD-4 design). T05 explicitly depends on T02, so by the time T05 runs, the script exists. T05's actual work on that file is to add the canonical enum to the script header and the out-of-enum halt cause — described in T05's own Definition of done and Scope sections in terms that fit a **modify**, not a create:

- DoD: "`scripts/verifier-fan-in.sh` exposes one canonical enum definition in its header and uses that same definition for all `change_type` membership checks." — extending the existing script.
- Scope (In): "Add the canonical `change_type` enum … to the `scripts/verifier-fan-in.sh` header …" — incremental edit.
- Scope (Out): "Baseline verifier-fan-in script creation, well-formed-round success behavior, generic halt plumbing, and verifier-dispatch prose — T02 owns." — explicit hand-off.

So the `(create)` annotation on T05 is internally inconsistent with T05's own scope/DoD and with the dep edge to T02.

## Why it matters

The `(modify)` vs `(create)` annotation on `Target files:` is the machine-parsed bullet the implementer agent uses to decide between a Write-tool first-creation flow versus an Edit-tool incremental flow. A spurious `(create)` on a file the predecessor task creates can cause:

- The implementer at T05 to either fail an existence pre-check, or to overwrite (rather than edit) the T02 baseline file — in the worst case losing T02's well-formed-round behavior and dispatch-prose include without that loss showing up in T05's per-task tests (which only exercise the enum-drift cases T05 owns).
- A reviewer audit comparing target-file annotations across the dep chain to flag the mismatch as a finding in a later round (the failure mode this finding is catching now).
- The structure.md per-file cross-reference for `scripts/verifier-fan-in.sh` to ambiguously list two creators, which inverts the single-owner property structure.md is supposed to enforce.

This is a low-severity drift — easy to miss, easy to fix, but exactly the class of small annotation mistakes that the plan-spec contract exists to catch before Implement starts.

## Suggested fix

Change T05's Target files line to:

```
Target files: scripts/verifier-fan-in.sh (modify), skills/reviewer-protocol/SKILL.md (modify), tests/unit/test-change-type-partition.bats (modify)
```

No other text change is required — T05's DoD, Scope, Test expectations, and References are already consistent with a modify. Only the bullet-layer annotation needs updating.

While the spec author is in that file, a one-pass audit of every Target-files line with `(create)` against the dep chain (does any earlier dep already create the file?) is cheap insurance — the same drift pattern could exist on other tasks the reviewer did not exhaustively check (T10's verifier sidecars updates, T15's plan.md updates, etc., would be worth a sweep).
<!-- @@SCORE: spec-claude.finding-F02.score @@ -->
score: 65
reason: Verified — T02 line 182 already lists scripts/verifier-fan-in.sh (create), and T05 line 347 redundantly marks the same file (create) while its own Scope/DoD/Out-of-scope clearly describe a modify; low-severity but real annotation drift that could mislead the implementer's Write-vs-Edit decision.
<!-- @@FINDING: spec-codex.finding-F01 @@ -->
---
finding_id: R1-F01
reviewer_tag: spec-codex
artifact: plan.md
round: 1
severity: medium
change_type: correctness
location: "Task 42 Target files (~lines 2568-2581)"
---

## Issue

T42 Target files declares `tests/unit/test-agent-frontmatter-no-model.bats (or ... successor ...)` and includes "locate the current owner..." prose. The target path is conditional/discovery-dependent rather than a single concrete file.

## Why

A task whose Target files is conditional cannot be reviewed or implemented atomically: discovery happens during execution, and the actual disk surface is unknown at plan time. The Definition of done becomes non-deterministic.

## Fix

Lock one concrete target path for v0.7.2 (resolve against structure.md now), or split T42 into a discovery/update-structure task (T42a) followed by a fixed-path implementation task (T42b).
<!-- @@SCORE: spec-codex.finding-F01.score @@ -->
score: 60
reason: Verified — T42 Target files carries an "or … successor" alternative plus a "Locate the current owner…" discovery instruction in Scope, which conflicts with Plan SKILL's exact-path / self-contained-task requirement and makes the Definition of done non-deterministic; design.md G24 anticipated tree-audit uncertainty so it isn't a hard policy violation, but the planner could (and per HARD-GATE arguably should) have resolved it against structure.md now or split T42 into discover-then-fix.
<!-- @@FINDING: spec-codex.finding-F02 @@ -->
---
finding_id: R1-F02
reviewer_tag: spec-codex
artifact: plan.md
round: 1
severity: medium
change_type: correctness
location: "Task 43 (~lines 2626, 2641, 2648, 2666)"
---

## Issue

T43 uses conditional file scope: `test-using-qrspi-routing-block.bats if present after Task 42` and "re-audit post-T42 tree". Same shape as F01 — task contract is not fixed at planning time.

## Why

Same determinism problem as F01. T43's actual file surface depends on a runtime check after T42 completes.

## Fix

(a) Enumerate exact existing files now using the current test-surface inventory; or (b) split into a first task that reconciles live test-surface inventory and a second task that does fixed-path dedup.
<!-- @@SCORE: spec-codex.finding-F02.score @@ -->
score: 50
reason: Real determinism concern — T43's target file list literally says "if present after Task 42" and "re-audit post-T42 tree", which violates the plan SKILL's self-contained-task expectation; the planner could have inventoried the tree now since T42 does not create/delete the listed BATS files, though the conditional language is partly defensible given design.md's caveat that historical F01 surfaces may be moot.
<!-- @@FINDING: spec-codex.finding-F03 @@ -->
---
finding_id: R1-F03
reviewer_tag: spec-codex
artifact: plan.md
round: 1
severity: medium
change_type: correctness
location: "Task 26 (~lines 1592-1649)"
---

## Issue

T26 bundles multiple independent observable changes (Design `include::` directives, Plan SKILL classification rewrite, Plan dispatch payload changes, 3+ agent contract updates) without a `sizing_exception` declaration.

## Why

Atomicity/sizing guidance treats each independent observable change as a separate task unless a sizing_exception is declared. Without the exception, T26 is over-bundled — hard to review, hard to roll back, and concurrent implementer work on the bundled surfaces will conflict.

## Fix

Either (a) add a `sizing_exception` with rationale, or (b) split T26 into atomic sub-tasks:
- T26a: Design + Plan SKILL include/classification changes
- T26b: agent preload updates (implementer-lightweight, design-reviewer)
- T26c: plan-test-coverage-reviewer Rule C / lightweight-skip contract
<!-- @@SCORE: spec-codex.finding-F03.score @@ -->
score: 32
reason: T26 is ~140 LOC (under the 200-LOC splitting threshold) and represents one coherent observable change (plumbing G31 primitives across all consumer sites); Plan SKILL only forces split + sizing_exception above the LOC ceiling, and the closed exception list (schema migration, CI scaffolding, reusable primitives) wouldn't apply anyway — finding overreads the atomicity rule.
<!-- @@FINDING: test-coverage-claude.finding-F01 @@ -->
---
finding_id: R1-F01
reviewer: test-coverage-claude
artifact: plan.md
task: Task 22
severity: high
change_type: correctness
---

# T22 — "concise references" and "manual review" test expectations are not falsifiable

## What

Task 22 (G24-F02 `using-qrspi` per-H4 prose redundancy consolidation) has two
test expectations that are not deterministically verifiable:

1. **Grep/diff audit of `skills/using-qrspi/SKILL.md` confirms the four old
   H4-specific fail-loud mirror paragraphs have been collapsed to *concise
   references* while the class-level fail-loud contract remains present.**
2. **Manual review of the `model_routing:`, `trusted_path:`, `validators:`, and
   missing-`model_routing:` backfill surfaces confirms each still communicates
   halt-loudly/no-silent-fallback semantics.**

The matching DoD bullets are equally soft:

- "Each affected H4 retains a concise local reference *or equivalent wording*
  that points readers back to the single class-level fail-loud contract rather
  than restating the full invariant."
- "No dispatch path loses the no-silent-fallback / halt-loudly requirement..."

## Why this is a test-coverage problem

The Test phase will need to write an acceptance test for "the four old H4
mirror paragraphs have been collapsed to concise references." There is no
falsifiable criterion:

- "Concise reference" has no measurable property (line count? word count?
  absence of a specific anchor phrase?). Two implementations — one that leaves
  a 3-sentence reference paragraph and one that leaves a 1-line cross-reference
  — would both arguably satisfy this expectation.
- "Manual review … confirms each still communicates halt-loudly semantics" is
  a thought-experiment, not a test recipe. The Test writer cannot generate a
  deterministic assertion from it. T44 (G24-F05) DOES pin silent-fallback
  intent regex assertions — but T22 lands BEFORE T44 in the dependency graph
  (T18 → T22 → T23 → … → T44), so T22 has no executable backstop at its
  commit point.

## Falsifiable alternative

Make the test expectation name observable properties:

- Either pin an explicit anchor phrase that the consolidated reference must
  contain (e.g., "see the class-level fail-loud invariant above") and a max
  line count for each of the four H4 sections after the edit, OR
- Defer T22's pass criterion to the post-T44 acceptance surface and explicitly
  state that T22's only verifiable contract is "the four named H4 sections no
  longer carry the four pre-T22 literal pin strings X, Y, Z, W" (positive
  identification of what was removed).

The Test writer needs at least one of: a positive-anchor presence check or an
enumerated negative-anchor absence check, with the specific anchor strings
named in the expectation.

## References

- plan.md ### Task 22 — DoD and Test expectations sections.
- plan.md ### Task 44 — silent-fallback intent regex pins, which would be the
  proper backstop but lands later in the dependency chain.
<!-- @@SCORE: test-coverage-claude.finding-F01.score @@ -->
score: 60
reason: Real test-coverage issue — T22 expectation #3 literally says "Manual review … confirms" (non-falsifiable) and "concise references" has no measurable property; the alternative is concrete; mitigated only by T22 being prose-only and T44 adding stronger pins downstream.
<!-- @@FINDING: test-coverage-claude.finding-F02 @@ -->
---
finding_id: R1-F02
reviewer: test-coverage-claude
artifact: plan.md
task: Task 38
severity: high
change_type: correctness
---

# T38 — "Mental-replay check" is not a verifiable test expectation

## What

Task 38 (G35 Structure reviewers enforce architecture-only-in-structure
boundary) lists this Test expectation:

> Mental-replay check: a v0.7.2 `structure.md` containing a unified system
> architecture Mermaid diagram plus a top-level `## Test Architecture`
> section stitching per-goal/per-CD acceptance criteria by test type would
> not trigger a Structure scope finding under these reviewer prompts.

This is a thought experiment, not a test. There is:

- No fixture document path the Test writer should create.
- No reviewer-dispatch invocation a test harness can run against the fixture.
- No assertion on observable output ("no finding files written," "empty
  `clean.md` sentinel," "no `severity: high` row in `<reviewer_tag>.finding-*`
  files," etc.).
- No way to detect failure: a Test writer can only "mentally replay" the
  fixture, which is exactly the human-judgement loop the test phase is
  supposed to remove.

The same DoD bullet ("`agents/qrspi-structure-reviewer.md` positively instructs
the reviewer to recognize a unified system architecture diagram and a
top-level `## Test Architecture` section as expected Structure content while
preserving minimal artifact-quality reviewer duties") is verifiable as a grep
audit. The mental-replay expectation adds nothing that grep audits can't carry
deterministically.

## Why this is a test-coverage problem

Test criteria 4 (Test Expectation Quality) requires:
- **Observable** — describes something visible to a caller or test harness.
- **Deterministic** — the same inputs always produce the same expected output.
- **Falsifiable** — there exists an implementation that would fail this
  expectation.

The mental-replay check fails all three: no observable output, no
deterministic recipe, no failing implementation a Test writer could write to
RED.

## Falsifiable alternative

Either:

1. Replace the mental-replay bullet with a concrete fixture + dispatch
   recipe: "Create a fixture `structure.md` at <path> containing the named
   Mermaid block and `## Test Architecture` section; dispatch
   `agents/qrspi-structure-scope-reviewer.md` against the fixture; assert the
   reviewer writes only a `<reviewer_tag>.clean.md` sentinel and no
   `<reviewer_tag>.finding-F*.md` files in the round directory." OR
2. Remove the bullet — the grep audits already cover the prose contract, and
   the structure-reviewer dispatch coverage belongs to a broader Phase-1
   acceptance test, not a per-task expectation.

## References

- plan.md ### Task 38 — Test expectations bullet 5.
- Test criteria 4 (Test Expectation Quality) from this reviewer's dispatch
  contract.
<!-- @@SCORE: test-coverage-claude.finding-F02.score @@ -->
score: 38
reason: Mental-replay bullet is genuinely weaker (non-falsifiable thought experiment), but task is lightweight prompt-prose (non-TDD), other 5 bullets already cover auditable content via grep/inspect, and design.md ## G35 itself uses "mental-replay acceptance criterion" terminology — severity:high overstates a largely-redundant qualitative check.
<!-- @@FINDING: test-coverage-claude.finding-F03 @@ -->
---
finding_id: R1-F03
reviewer: test-coverage-claude
artifact: plan.md
task: Task 06
severity: medium
change_type: correctness
---

# T06 — verifier sidecar `score:` integer-range bounds (0-100) not exercised

## What

Task 06 (G11 verifier sidecar extension correction) DoD specifies:

> The verifier sidecar contract requires frontmatter containing `score:` as
> an integer from 0 through 100.

But the Test expectations only verify the field's presence and extension path,
not the bounds or integer-type contract:

- "Post-implementation run of `tests/unit/test-verifier-agent-file.bats`
  passes only when the verifier agent file pins `.score.md`, **requires
  `score:` in sidecar frontmatter**, and contains no `.score.yml` allowance."

There is no edge-case coverage for:

- `score: -1` (below lower bound)
- `score: 101` (above upper bound)
- `score: 85.5` (non-integer)
- `score: "high"` (non-numeric)
- `score:` (empty value)

This is the canonical boundary-condition gap from Test criteria 2 (Edge Cases:
maximum/minimum values if the task operates on bounded quantities).

## Why this is a test-coverage problem

T06's verifier sidecar is the load-bearing input to `scripts/verifier-fan-in.sh`
(T02). If the contract documents integer-0-to-100 but no test pins the bounds,
an implementation could accept `score: 150` or `score: -5`, and the fan-in
script's score-threshold filter (also T02) could silently treat out-of-range
scores as above-threshold (passing) or as parse failures, with no clear test
to distinguish the two.

T05 covers `change_type` enum drift on both reviewer-emit and
orchestrator-consume sides. T06 should mirror that bilateral-pin pattern for
score values: pin the bounds in `agents/qrspi-finding-verifier.md` prose AND
add fan-in-script test fixtures that fail on out-of-bounds values.

## Falsifiable alternative

Add Test expectations such as:

- "Bats fixture: a verifier sidecar with `score: -1`, `score: 101`,
  `score: 85.5`, or `score: ""` is rejected by the fan-in score-parser path
  exercised in `tests/unit/test-verifier-agent-file.bats`, with a diagnostic
  naming `score out of range` or `score not integer`."
- "Grep audit confirms `agents/qrspi-finding-verifier.md` documents the
  literal range `0 through 100` (or equivalent canonical form) at the
  sidecar-frontmatter contract site."

The fan-in-script integer-bounds rejection may belong to T02 instead of T06;
if so, T02's Test expectations should also be extended to cover the bounds
case, since T02 currently tests `unparseable score` (a parser failure) but
not in-range vs out-of-range integers.

## References

- plan.md ### Task 06 — Definition of done + Test expectations.
- plan.md ### Task 02 — `unparseable score` halt cause (parser-failure path,
  distinct from out-of-range integer).
- plan.md ### Task 05 — bilateral-pin pattern for `change_type` enum
  (precedent for splitting reviewer-emit vs fan-in-consume coverage).
<!-- @@SCORE: test-coverage-claude.finding-F03.score @@ -->
score: 45
reason: Real gap — T06 DoD names `score:` as integer 0–100 but neither T06 nor T02 test expectations pin the integer-bounds (T02's `unparseable score` covers parser-failure only, not out-of-range integers); however the impact is bounded (out-of-range scores would still gate correctly by threshold comparison and the finding is medium-severity test-coverage rather than a functional defect).
<!-- @@FINDING: test-coverage-claude.finding-F04 @@ -->
---
finding_id: R1-F04
reviewer: test-coverage-claude
artifact: plan.md
task: Task 10
severity: medium
change_type: correctness
---

# T10 — `defect_class:` ≤30-character limit not exercised at boundary

## What

Task 10 (G28 verifier convergent-evidence exception and
sub-threshold-observations instrumentation) DoD specifies:

> Verifier sidecar examples and rubric prose require a `defect_class:`
> frontmatter field emitted after scoring and before sidecar write, using
> lowercase kebab-case letters, digits, and hyphens, **no more than 30
> characters**.

The Test expectations cover:

- Token shape (lowercase kebab-case, letters/digits/hyphens)
- `unspecified` fallback
- Sub-threshold requires `defect_class:`; above-threshold may carry it

They do NOT cover:

- The 30-character boundary: `defect_class:` of length 30 (accepted),
  length 31 (rejected).
- Uppercase letters (rejected).
- Underscores or other separators (rejected).
- Empty value `defect_class:` with no token (rejected vs. interpreted as
  `unspecified`?).
- Trailing/leading hyphens (e.g., `-foo`, `bar-`) — ambiguous in kebab-case
  conventions.

The "lowercase kebab-case letters, digits, and hyphens, no more than 30
characters" rule is a four-axis validation (case + alphabet + separator
charset + length). The Test expectations exercise only "lowercase kebab-case
letters, digits, and hyphens" loosely as a shape check, without naming the
rejected counter-examples or the 30-char boundary.

## Why this is a test-coverage problem

Test criteria 2 (Edge Cases) explicitly calls out "maximum/minimum values if
the task operates on bounded quantities." The 30-character cap is a hard
upper bound. Without a 30-vs-31 boundary fixture, a length validator could
ship as ≤29 or ≤31 (off-by-one) and still pass every existing test.

Test criteria 3 (Error Conditions) explicitly calls out "the behavior when
input is malformed or invalid." The Test expectations describe what good
input looks like but not what rejection looks like for malformed cases
(uppercase, underscores, empty string, overlength).

## Falsifiable alternative

Extend the T10 Test expectations:

- "Unit fixture: `defect_class:` of exactly 30 characters is accepted; 31
  characters is rejected with a token-shape diagnostic naming the length
  limit."
- "Unit fixture: `defect_class: Foo-Bar` (uppercase) is rejected with a
  case-shape diagnostic; `defect_class: foo_bar` (underscore) is rejected
  with a charset-shape diagnostic."
- "Unit fixture: an empty `defect_class:` value (no token at all) is
  rejected with a missing-required-token diagnostic, distinct from
  `defect_class: unspecified` which is accepted as the documented absence
  signal."

## References

- plan.md ### Task 10 — Definition of done bullets 1–2 and Test expectations
  bullets 1–3.
- Test criteria 2 (Edge Cases) and 3 (Error Conditions) from this reviewer's
  dispatch contract.
<!-- @@SCORE: test-coverage-claude.finding-F04.score @@ -->
score: 35
reason: Real but minor coverage refinement; Plan-altitude expectations already specify shape-matching fixtures, and boundary/rejection-row enumeration is typically Test-phase detail rather than a Plan-blocking gap.
<!-- @@FINDING: test-coverage-claude.finding-F05 @@ -->
---
finding_id: R1-F05
reviewer: test-coverage-claude
artifact: plan.md
task: Task 12, Task 11
severity: medium
change_type: correctness
---

# T12 & T11 — atomic / parallel-dispatch test recipe unspecified

## What

Two tasks claim atomic + parallel-dispatch safety in their DoD but leave the
parallel-dispatch test recipe unspecified.

**T12 (G4 round-prepare)** DoD:

> `scripts/round-prepare.sh` exists and writes `round-NN.diff`,
> `.round-prepare.json`, and the round commit anchor on valid inputs, with
> deterministic repeated output and **no sidecar corruption under parallel
> dispatch**.

T12 Test expectation:

> Exercise `round-prepare.sh` happy-path inputs and verify it writes
> `round-NN.diff`, `.round-prepare.json`, and the round commit anchor;
> rerun with the same inputs and verify **deterministic output without
> corrupting sidecars under parallel dispatch**.

"Rerun with the same inputs" is a sequential repetition, not parallel
dispatch. The expectation invokes the concept ("under parallel dispatch")
but does not name:

- How many concurrent processes to launch.
- Whether shared `.round-prepare.json` is the target or per-round files.
- What "corruption" looks like in a positive test (truncated JSON, partial
  write visible to a concurrent reader, lost entry, duplicate entry).
- Whether the test should use `flock`, `&` background launches, or a
  process-pool fixture.

**T11 (G29 artifact_path escape hatch)** DoD:

> Manifest append behavior is **atomic and append-safe** across multiple
> reviewer tags in one round and **repeated invocations** for the same
> output directory; no entries are lost or malformed.

T11 Test expectation:

> Run **repeated** dispatch-script invocations against the same round
> output directory with multiple reviewer tags, then validate the manifest
> remains well-formed JSON with all expected entries present.

"Repeated" implies sequential. The DoD requires "atomic" — which is a
concurrency property — but the test recipe is serial-only. A serial-only test
can never falsify the atomicity claim.

## Why this is a test-coverage problem

Test criteria 1 (Behavioral Coverage) asks "Can someone write a deterministic
test from this expectation?" — for the atomicity claim, the answer is no,
because the test recipe doesn't specify the concurrency-introducing mechanism.

Test criteria 3 (Error Conditions) asks what the caller receives when this
task fails — under parallel dispatch the failure modes are race-condition-
specific (interleaved writes, lost updates, partial JSON), but the test
recipe doesn't name them.

A Test writer following the current expectations will produce a serial test
that passes against a non-atomic implementation. This is exactly the
"vacuous pass" class T40 (G21 bats short-circuit hardening) exists to
prevent — yet T11/T12 introduce a new instance of it at a different layer.

## Falsifiable alternative

For both tasks, specify:

- "Launch N (e.g., 8) concurrent `round-prepare.sh` or dispatch-agent.sh
  invocations against the same round directory using `&` background launches
  + `wait`; after all complete, assert the resulting manifest/sidecar is
  well-formed JSON with exactly N entries (or the expected count), no
  duplicate keys, no truncated values, and no interleaved partial lines."
- OR explicitly state that atomicity is enforced by an external lock (e.g.,
  `flock(1)`) and pin the lock-file path / acquisition behavior in the test,
  so the atomic claim is structural rather than concurrency-tested.
- OR remove the "atomic" / "parallel dispatch" language from the DoD and
  scope the contract to "single-writer append" so the serial test
  legitimately covers the contract.

## References

- plan.md ### Task 12 — DoD bullet 1, Test expectation bullet 2.
- plan.md ### Task 11 — DoD bullet 3, Test expectation bullet 3.
- plan.md ### Task 40 — G21 bats short-circuit hardening (precedent for
  rejecting vacuous-pass test recipes).
<!-- @@SCORE: test-coverage-claude.finding-F05.score @@ -->
score: 60
reason: Real test-coverage gap — T11 DoD requires atomic/append-safe behavior across "multiple reviewer tags in one round" yet the test recipe is serial ("repeated invocations") and cannot falsify atomicity; T12's parallel-dispatch test recipe is similarly serial ("rerun with the same inputs"). Finding quotes the artifact accurately and offers actionable falsifiable alternatives. T11 case is strong (parallel reviewer dispatch is the real workload); T12 case is weaker since round-prepare.sh isn't typically run concurrently, which moderates the overall importance.
<!-- @@FINDING: test-coverage-claude.finding-F06 @@ -->
---
finding_id: R1-F06
reviewer: test-coverage-claude
artifact: plan.md
task: Task 34
severity: medium
change_type: correctness
---

# T34 — block-hash trailing-whitespace normalization invariance not exercised

## What

Task 34 (G5 Plan post-approval split idempotency) DoD specifies:

> Hash calculation is documented as sha256 hex, no salt, over the normalized
> source `### Task N` block; **normalization strips trailing whitespace from
> each line and preserves all other characters and line breaks**.

The Test expectation echoes the documentation:

> The hash calculation is verified as sha256 hex with no salt over the
> normalized source `### Task N` block, where normalization strips trailing
> whitespace from each line and preserves all other characters and line
> breaks.

But there is no test fixture exercising the *invariance* the normalization
exists to guarantee. The normalization rule's whole purpose is that two
plan.md edits that differ only in trailing whitespace should produce the same
hash, so a whitespace-only edit doesn't trigger the
"plan.md task block has changed" halt diagnostic.

Test expectations cover:

- Block-hash header presence ✓
- Hash calculation shape ✓
- Mismatch halt path ✓
- Missing-header halt path ✓
- Malformed-header halt path ✓
- Hand-edit preservation (when hash matches) ✓
- Quick-fix path ✓

They do NOT cover:

- "Edit `plan.md` `### Task N` block to add/remove trailing whitespace on N
  lines; re-run split; verify hash still matches and the task file is safe-
  skipped (no false-positive mismatch halt)."
- "Edit `plan.md` `### Task N` block to add/remove a blank line in the
  middle of the block (blank line = empty line, which is NOT trailing
  whitespace on the prior content line); re-run split; verify hash differs
  and the mismatch halt fires (positive control that normalization does NOT
  collapse blank lines)."

## Why this is a test-coverage problem

Test criteria 4 (Test Expectation Quality, falsifiable): there exists an
implementation that would fail this expectation. The current test recipe
verifies hash *calculation* shape but not normalization *behavior*. An
implementation that strips ALL whitespace (instead of trailing whitespace
only) or one that strips no whitespace at all would both satisfy the existing
test expectations as written, because no fixture distinguishes those
implementations.

The whole load-bearing reason for trailing-whitespace stripping (per design.md
## G5) is editor-driven whitespace churn between commits. A test that doesn't
exercise the invariance can't prevent regressions where an
over-aggressive normalizer collapses a meaningful edit, or where an
under-aggressive normalizer flags a no-op edit as a conflict.

## Falsifiable alternative

Extend the T34 Test expectations with two paired fixtures:

- "Whitespace-invariance fixture: edit `plan.md` `### Task N` block to add
  trailing spaces/tabs on every line; rerun the split; assert the existing
  `tasks/task-NN.md` is safe-skipped (no mismatch halt) and the file is not
  rewritten."
- "Blank-line-sensitivity fixture: edit `plan.md` `### Task N` block to
  insert or delete a blank line within the block body (not adjacent to the
  task heading boundaries); rerun the split; assert the mismatch halt fires
  with the documented `task-NN.md exists but its source block in plan.md has
  changed…` diagnostic."

These two fixtures jointly pin the normalization scope to "trailing
whitespace only" with falsifiable positive and negative controls.

## References

- plan.md ### Task 34 — DoD line 4, Test expectation line 2.
- design.md ## G5 — normalization rule scope and editor-driven-churn
  rationale.
<!-- @@SCORE: test-coverage-claude.finding-F06.score @@ -->
score: 55
reason: Real gap — T34 test expectations document the trailing-whitespace normalization rule but no fixture exercises the invariance (whitespace-only edit safe-skip vs blank-line mismatch halt); finding is well-formed and falsifiable, though somewhat overlaps with the existing hash-calculation pin so it's medium importance rather than load-bearing.
<!-- @@FINDING: test-coverage-codex.finding-F01 @@ -->
---
finding_id: R1-F01
reviewer_tag: test-coverage-codex
artifact: plan.md
round: 1
severity: medium
change_type: correctness
location: "Task 27 (~lines 1687-1692 out-of-scope; ~1695-1710 DoD/Test expectations)"
---

## Issue

Design CD-2 requires two additional acceptance surfaces: (1) reviewer-protocol enforcement for antagonist-pattern findings, and (2) a `using-qrspi/SKILL.md` one-line pointer to `_shared/evergreen-output-rule.md`. T27 explicitly excludes these and no other task test expectations cover them.

## Why

CD-2 design scenarios are not testable from any plan task. The plan-to-design coverage check passes (T27 maps to CD-2) but the test-level coverage check fails (CD-2's two acceptance surfaces have no test home).

## Fix

Either (a) extend T27 to include the two CD-2 acceptance surfaces and their test expectations, or (b) add a new task (T27b) that owns them. Reference design.md ~285-289 for the canonical acceptance text.
<!-- @@SCORE: test-coverage-codex.finding-F01.score @@ -->
score: 75
reason: Verified — design.md CD-2 acceptance lines 288-289 (antagonist-pattern reviewer enforcement and using-qrspi/SKILL.md pointer) are explicitly excluded from T27's Out section (line 1691) and no other task (incl. T35 which is about procedural-authority anti-fabrication, not antagonist patterns) owns them, leaving two CD-2 acceptance surfaces without a plan-task home.
<!-- @@FINDING: test-coverage-codex.finding-F02 @@ -->
---
finding_id: R1-F02
reviewer_tag: test-coverage-codex
artifact: plan.md
round: 1
severity: medium
change_type: correctness
location: "Task 11 DoD (~line 714) vs Test expectations (~lines 721-727)"
---

## Issue

T11 DoD claims "atomic and append-safe" but the Test expectations cover only repeated invocations and "well-formed JSON with expected entries" — no concurrent/overlap writes or interruption/race scenarios.

## Why

A non-atomic implementation can still pass the current expectations. The atomicity claim is unverifiable from the test surface; concurrent dispatchers writing to the same audit log could interleave or lose entries.

## Fix

Add explicit concurrency fixtures: two parallel dispatchers writing to the same log file, with an assertion that all N entries are present and well-formed. Add an interruption fixture: terminate the writer mid-write and assert no torn entry. Concurs with tc-claude F05's broader "concurrency invariants are unverifiable" finding.
<!-- @@SCORE: test-coverage-codex.finding-F02.score @@ -->
score: 35
reason: Real gap — DoD claims "atomic" but tests only exercise sequential repeated invocations, not concurrent writers or interruption; however, dispatch is typically invoked sequentially per round so practical risk is modest and the proposed concurrency/interruption fixtures may exceed Plan-altitude testing expectations.
<!-- @@CLEAN: goal-traceability-claude.clean @@ -->
---
artifact: plan.md
round: 1
reviewer: goal-traceability-claude
actual_model: claude-sonnet-4.6
---

# Goal-Traceability Review — Clean Sentinel

No findings. Forward and backward goal-traceability hold, the reference-anchor existence load-bearing check resolved cleanly across the sampled surface, and the plan's task structure is faithful to the design.

## Coverage summary

### Forward trace (goals.md → tasks → plan-authored criteria)

All 35 goals in `goals.md` (G1–G35) are covered by at least one task in `plan.md`, and every task carries a `## Test expectations` block authoring acceptance criteria. The per-phase `### Phase 1 Acceptance Criteria` block (plan.md L17–29) carries seven cross-task observable behaviors at the phase boundary.

| Goal | Covering tasks (primary + secondary) |
|------|--------------------------------------|
| G1   | T30 (+T28 via CD-3) |
| G2   | T33 |
| G3   | T20 (+T27 via CD-2) |
| G4   | T12 (+T27 via CD-2) |
| G5   | T34 |
| G6   | T03 (+T24 via CD-4) |
| G7   | T01 |
| G8   | T04 |
| G9   | T13 |
| G10  | T35 |
| G11  | T06 (+T24 via CD-4) |
| G12  | T02 (+T24 via CD-4) |
| G13  | T05 |
| G14  | T07 |
| G15  | T14 |
| G16  | T21 |
| G17  | T36 |
| G18  | T15 |
| G19  | T08 |
| G20  | T09 |
| G21  | T40 |
| G22  | T16 (+T27 via CD-2) |
| G23  | T17 |
| G24  | T22 (F02), T23 (F04), T42 (F01), T43 (F03), T44 (F05) |
| G25  | T18 |
| G26  | T41 |
| G27  | T19 (+T27 via CD-2) |
| G28  | T10 |
| G29  | T11 |
| G30  | T32 (+T28 via CD-3) |
| G31  | T25 + T26 |
| G32  | T39 |
| G33  | T31 (+T28 via CD-3) |
| G34  | T29 |
| G35  | T37 + T38 |

The three cross-cutting tasks (T24=CD-4, T27=CD-2, T28=CD-3) carry secondary Goal IDs that legitimately trace each Cross-Goal Decision back to the upstream goals the CD touches — this is intentional integration traceability, not over-scoping.

### Backward trace (tasks → goals/research)

Every one of the 44 task specs carries a canonical `Goal IDs: [G<N>]` (or `[CD-<N>, ...]`) bullet AND an Overview parenthetical of the form `(Why: see goals.md ### G<N>. Approach: see design.md ## G<N>.)`. No task is untraceable; no task exists without an authored upstream justification.

### Reference-anchor existence check (load-bearing)

The dispatch instructions flagged anchor fabrication as a high-severity concern. Sampled and verified the following anchor conventions and concrete instances across plan.md's References sections (T01–T44):

- **goals.md `### G<N>` headings** — convention holds for G1–G35; all `goals.md ### G<N>` citations resolve.
- **design.md `## G<N>` headings** — convention holds. Verified concrete presence for G1, G2, G3, G5, G6, G7, G9, G10, G11, G12, G13, G14, G16, G17, G18, G19, G20, G22, G23, G24, G25, G26, G28, G29, G30, G31, G32, G34, G35.
- **design.md `### CD-<N>` headings** — present for CD-1, CD-2, CD-3, CD-4.
- **design.md sub-anchors via `→`** — verified concrete sub-anchors:
  - `## G31 → File 4` and `→ File 5` — design.md G31 contains `#### File 1` through `#### File 5` and `#### Addition A` through `#### Addition D`.
  - `### CD-4 → B. Verifier sidecar`, `→ F`, `→ G7 acceptance`, `→ I.7` — design.md CD-4 contains lettered components A–I including the I.1–I.7 sub-blocks; §I.7 (Interaction-mode detection) is present.
  - `## G34 → D2`, `→ D3`, `→ D4` and `## G35 → D2/D3/D4` — design.md uses `**D<N> — …**` bold sub-blocks under those goal sections.
- **structure.md `### \`<filepath>\`` per-file blocks** — convention holds across the 109-row File Index. Multi-slice files (e.g., `agents/qrspi-finding-verifier.md` appears in slices 1.1 and 1.2; `skills/using-qrspi/SKILL.md` appears in slices 1.2, 1.4, 1.5) have multiple `### \`<filepath>\`` H3 blocks, and plan.md disambiguates with either `→ Slice 1.N` or `— Slice 1.N` descriptor suffix — both forms are meta on top of a real heading.
- **structure.md `## Cross-Cutting Schemas` numbered sub-sections** — verified `### 7. Host-and-tier-aware second-reviewer override`, `### 8. Section-anchor index files`, `### 9. Verifier sidecar schema`, `### 10. Dispatch manifest schema`, `### 11. .verifier-fan-in-audit.json schema`, `### 12. Interaction-mode detector`, `### 13. Dispatch companion script`, `### 14. Round-completion barrier`, `### 15. Third-party finding splitter`, `### 16. .orchestrator-fixes.json rescue audit schema`. Plan.md citations to §§7, 9, 10, 12 resolve.
- **structure.md `## Hook-Point Cross-Slice Index` sub-anchors** — verified `### CD-1 reviewer-dispatch-prose !cat include sites`, `### CD-2 evergreen-output-rule !cat include sites`, `### CD-3 multi-actor-flow-check !cat include sites`, `### CD-4 / G12 verifier-dispatch-prose !cat include sites`, `### G31 prompt-prose !cat include sites`, `### G34 design-altitude-boundary !cat include sites`, `### G35 structure-altitude-boundary !cat include sites`. Plan.md citations resolve.
- **Rename-pair per-file blocks** — for rename actions (e.g., `scripts/run-codex-review.sh → scripts/dispatch-agent.sh`, `skills/reviewer-protocol/codex-emission-override.md → skills/reviewer-protocol/third-party-emission.md`), structure.md uses the **source path** as the H3 heading and records the rename target in the body's `**Action:** Rename → ...` field. Plan.md cites the same source path with the rename target appended via `→` as a descriptor; the underlying H3 anchor resolves.

No fabricated or hallucinated anchors were observed in the References sections of any sampled task spec.

### Gap analysis (design → plan)

Spot-checked design commitments against plan tasks for the four locked Cross-Goal Decisions and the three largest goal-decompositions (G24 F-bundle, G31 distribution table, G32 build pipeline):

- **CD-1** (universal dispatch architecture) is implemented across T19 (`_host-detect`, `_resolve-lib`, `second-reviewer-available`), T20 (script renames + per-skill prose migration via `reviewer-dispatch-prose.md !cat`), T16 (model_routing config schema), and the entire dispatch-script surface — every CD-1 component listed in design.md L19–213 has at least one task target.
- **CD-2** (evergreen-output rule) → T27 (creates `skills/_shared/evergreen-output-rule.md` + includes into 9 artifact-producing SKILL.md files); CD-2's nine consumer-file table in structure.md `## Hook-Point Cross-Slice Index` matches T27's scope.
- **CD-3** (multi-actor flow check) → T28 (creates `skills/_shared/multi-actor-flow-check.md` + includes into 4 downstream-gate SKILL.md files); matches the structure.md include-site table.
- **CD-4** (verifier-fan-in pipeline) → T02 (`verifier-fan-in.sh`), T01 (filter-rule snippet), T03–T07 (reviewer disk-write + change_type + verifier sidecar + Informational rubric), T24 (`detect-interaction-mode.sh`), with T10 covering G28 defect-class instrumentation that rides on CD-4. Every CD-4 component A–I has a task home.
- **G24 F-bundle**: design.md G24 re-scopes to F05 only with F01/F03/F04 audited as mooted by the v0.7.1 tree state; plan still allocates T22 (F02 prose redundancy), T23 (F04 tier-regex), T42 (F01 caller dedup), T43 (F03 H4-extraction), T44 (F05 regex pin hardening) — i.e., plan keeps the full F01–F05 surface but the per-task scope-out clauses correctly defer to G25 (F02) and instruct conditional implementation against the live tree (F01, F03, F04). The expanded coverage is broader than design.md G24 strictly requires; not a traceability defect since each task still anchors to G24 framing.
- **G31** distribution table (9 consumers) maps cleanly to T25 (primitives + wrapper SKILLs) and T26 (consumer include-site sweep).
- **G32** D1–D5 + Acceptance map to T39's full file inventory.

No design commitment was found that plan.md fails to carry as a task or as a test expectation.

### Spec-to-design fidelity

Plan's 7 vertical slices (1.1 Apply-fix/verifier backbone; 1.2 Verifier rubric calibration + instrumentation; 1.3 Per-task review pipeline corrections; 1.4 Dispatch infrastructure; 1.5 Skill prose & interactive dialog quality; 1.6 Structure SKILL absorbs unified architecture; 1.7 Build & release tooling + test-infrastructure hardening) match phasing.md and structure.md's slice partitioning. The single cross-slice forward dependency (Slice 1.4 G4 → Slice 1.3 G9) is explicitly called out in plan.md's Task List by Slice section and respected by Task 12's slice/numbering placement.

### Decomposition check

For each goal with multiple amendment items (G24 F01–F05; G31's 5-file + 4-Addition distribution; CD-4's components A–I), the per-task scope blocks decompose cleanly from the goal's problem framing in goals.md. No task introduces work that is not motivated by the goal's problem text.

## Conclusion

Plan.md is clean for goal-traceability. Forward and backward traceability hold, the load-bearing reference-anchor existence check resolved without fabrication, design intent is faithfully reflected in plan structure, and the per-phase acceptance block + per-task `## Test expectations` blocks supply authored criteria for every goal.

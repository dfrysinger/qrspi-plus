---
verifier_enabled: true
scored: 4
kept: 2
dropped: 3
failed: 0
clean: 1
---

<!-- @@FINDING: quality-claude.finding-F01 @@ -->
---
finding_id: R5-F01
reviewer_tag: quality-claude
artifact: structure
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
---

# Halt-response protocol (CD-4 §I.3) missing from `implement/SKILL.md` and §17 consumer/writer attribution

## What the structure says

R4 extended Slice 1.2's `skills/using-qrspi/SKILL.md` responsibility cell to carry the orchestrator-side halt-response protocol (rescue layer + drift counting) and added Interface §17 `.orchestrator-fixes.json`:

> `skills/using-qrspi/SKILL.md` … Modify … "Define round instrumentation, sub-threshold observation logging, verifier-visible audit surfaces, and **orchestrator-side halt-response protocol (CD-4 §I.3): read `orchestrator_rescue` and `max_drift_per_round` from config.md to gate rescue-layer behavior and drift-count enforcement**." (Slice 1.2, line 36)

> "Path: `<round-dir>/.orchestrator-fixes.json`. **Writer: orchestrator rescue layer** … **Consumer: `using-qrspi/SKILL.md` round-summary prose surface**, which sources per-tier counts for `round-NN-dispositions.md`." (§17, line 480)

`skills/implement/SKILL.md` only appears in Slice 1.3 ("Require `round-prepare` outputs and scope-tagger/fan-in artifacts …", line 50) and Slice 1.4 ("Adopt shared reviewer dispatch and pass per-task tier overrides …", line 86). Neither row carries any halt-response, rescue-tier, or `.orchestrator-fixes.json`-write responsibility.

## Why this is a structural gap

Design CD-4 §F (line 458) is explicit that both consumers host the verifier-fan-in invocation at their respective apply-fix levels:

> - `using-qrspi/SKILL.md` — … Replace the per-finding verifier dispatch loop … with `scripts/dispatch-agent.sh --verifier-fanout …` … followed by `await-round.sh`.
> - `implement/SKILL.md` — … replace the per-finding verifier dispatch loop … with the same single `dispatch-agent.sh --verifier-fanout` + spec-line iteration + `await-round.sh` pattern; **add a precondition that `scripts/verifier-fan-in.sh` must have exited 0 for the round before apply-fix runs**.

Design CD-4 §I.3 (lines 519–541) frames the halt-response protocol generically — "Orchestrator-side rescue does NOT compute the kept set" / "Every halt cause escalates …" / `.orchestrator-fixes.json` written "after each successful tier 1/2/3 fix completes". The protocol fires whenever `scripts/verifier-fan-in.sh` halts non-zero. That can happen at *either* level — artifact-level apply-fix (using-qrspi rounds) and per-task apply-fix (implement rounds). The implement-side precondition ("verifier-fan-in.sh must have exited 0 before apply-fix runs") makes this concrete: if fan-in halts mid-task, the per-task orchestrator has to execute the same rescue→retry→escalate→drift-count→write-audit ladder, and write the per-tier breakdown into the per-task round's `round-NN-dispositions.md`.

As R4 currently locks structure:

1. **No row in any slice puts halt-response on `implement/SKILL.md`.** A planner reading the file map will not author rescue-layer prose into `implement/SKILL.md` because nothing in its Modify cells says to.
2. **§17 names only `using-qrspi/SKILL.md` as the round-summary consumer.** A planner reading §17 will not wire `.orchestrator-fixes.json` reads into `implement/SKILL.md`'s apply-fix surface.
3. **No shared snippet absorbs the protocol.** Slice 1.1's `skills/_shared/verifier-dispatch-prose.md` responsibility is scoped narrowly to "`dispatch-agent.sh --verifier-fanout` invocation + spec-line contract + `await-round.sh` follow-up" (line 20) — it does not carry the post-halt rescue layer. So there is no `!cat` path by which `implement/SKILL.md` would inherit the protocol implicitly.

The net effect: at structure altitude, the per-task apply-fix loop is shown invoking `verifier-fan-in.sh` (via Slice 1.3 + the shared dispatch snippet) but has no documented response when it halts. Either the per-task path silently has no rescue layer (contradicts design CD-4 §I.3's generic framing and §I.5 iron-rule preservation, which applies "under every interaction-mode × rescue-config combination"), or the responsibility is implicit and Plan/Implement will have to invent the placement.

## What to fix

Pick one of these three resolutions (all are structurally adequate; the first two are cheaper):

**Option A — Mirror the responsibility on `implement/SKILL.md`.** Add a Slice 1.2 row for `skills/implement/SKILL.md` with the same halt-response wording, e.g.: "Modify — Carry per-task orchestrator-side halt-response protocol (CD-4 §I.3): read `orchestrator_rescue` and `max_drift_per_round` from config.md to gate rescue-layer behavior at per-task apply-fix; write per-tier rescue breakdown into per-task `round-NN-dispositions.md` from `.orchestrator-fixes.json`." Then update §17's Writer/Consumer wording from "`using-qrspi/SKILL.md` round-summary prose surface" to "`using-qrspi/SKILL.md` (artifact-level) and `implement/SKILL.md` (per-task) round-summary prose surfaces".

**Option B — Lift the protocol into a shared snippet.** Add `skills/_shared/halt-response-protocol.md` (Create) to Slice 1.2 with responsibility "Hold the single CD-4 §I.3 halt-response protocol prose (rescue tiers, drift counting, dispositions write) consumed by `using-qrspi/SKILL.md` and `implement/SKILL.md`." Then both consumer SKILL.md rows just `!cat` it, matching the pattern already used for `verifier-dispatch-prose.md` (Slice 1.1 → both consumers). Update §17 Writer to "orchestrator rescue layer (prose lives in `skills/_shared/halt-response-protocol.md`, `!cat`-included into `using-qrspi/SKILL.md` and `implement/SKILL.md`)" and Consumer to name both surfaces. Add the new shared file to the Section Contracts table.

**Option C — Explicitly scope the protocol to artifact-level only.** Add a one-line note in Slice 1.2 / §17 saying the rescue layer intentionally does not fire at per-task apply-fix (e.g., per-task halts surface as a hard fail to the artifact-level orchestrator instead). This contradicts design CD-4 §I.3's framing, so it would also require a backward loop to design to record that scoping decision — making this the most expensive option and recommended only if there is a real reason per-task apply-fix should not rescue.

Option B is the strongest structural fit because it preserves the same DRY pattern already established for verifier-dispatch-prose; Option A is the simplest local edit if the planner prefers to keep the protocol out of `_shared/`.

<!-- @@SCORE: quality-claude.finding-F01.score @@ -->
score: 68
reason: Verified gap — Slice 1.2 puts CD-4 §I.3 halt-response on using-qrspi only and §17 names only using-qrspi as consumer, but design CD-4 §F mandates implement/SKILL.md also runs the fan-in pipeline (which can halt per-task) and the verifier-dispatch-prose snippet is scoped narrowly to dispatch+await, so a planner has no row directing rescue/disposition prose into implement/SKILL.md.

<!-- @@FINDING: quality-codex.finding-F01 @@ -->
---
finding_id: R5-F01
severity: medium
change_type: correctness
referenced_files:
  - structure.md (line 212, §3 verifier-fanout invocation)
  - design.md (line 470, CD-4 §H verifier-fanout invocation form)
---

## Finding

Structure §3 verifier-fanout invocation declares `[--tier-override qrspi-finding-verifier=<tier>]`, but design.md CD-4 §H authority specifies `[--tier-override <tier>]` for the same surface. Two artifacts now contractually disagree on the verifier-fanout `--tier-override` argument shape.

## Evidence

- structure.md:212 (post-R4): `[--tier-override qrspi-finding-verifier=<tier>]`
- design.md:470 (CD-4 §H authority): `[--tier-override <tier>]`

## Why this matters

design.md is the authoritative spec for CD-4 (which both Plan and Implement will consume); structure.md is the architect-of-the-phase translation. A divergence here propagates to the Plan-task that implements the verifier-fanout flag parser: it will be told two different argument shapes by the two artifacts and will pick one (likely the structure.md shape, since structure.md is closer in the QRSPI handoff chain).

The R4 fix that introduced this drift (R4-F01) was responding to a R3 finding about structure-internal disagreement between §3 and §7. The reconciliation direction was inverted: §7's CSV grammar exists for the reviewer-fanout case (CD-1), where multiple reviewers can have distinct tier overrides; verifier-fanout (CD-4) has a singleton agent, so the tag-prefix is meaningless and design.md uses the simpler bare-`<tier>` form.

## Suggested fix

1. Revert §3 line 212 from `[--tier-override qrspi-finding-verifier=<tier>]` to `[--tier-override <tier>]` (match design.md authority).
2. Tighten §7 wording to clarify that the CSV grammar `tag=tier,...` applies to reviewer-fanout's multi-reviewer surface; verifier-fanout takes a simpler bare `<tier>` because its agent is a singleton. One added sentence in §7 should suffice.

<!-- @@SCORE: quality-codex.finding-F01.score @@ -->
score: 78
reason: Confirmed direct contradiction between structure.md §3 line 212 (`[--tier-override qrspi-finding-verifier=<tier>]`) and design.md CD-4 §H line 470 (`[--tier-override <tier>]`); design is the authority, verifier-fanout's singleton agent makes the tag-prefix meaningless, and the divergence was introduced by R4's fix — Plan/Implement will see two contractual shapes for the same flag.

<!-- @@FINDING: scope-codex.finding-F01 @@ -->
---
finding_id: R5-F01
severity: medium
change_type: scope
referenced_files:
  - structure.md (lines 209-213, §3 verifier-fanout invocation)
  - design.md (line 470, CD-4 §H verifier-fanout invocation form)
  - design.md (line 63, CD-1 reviewer-fanout invocation form)
  - structure.md (line 204, §3 reviewer-fanout invocation)
  - structure.md (line 279, §7 canonical --tier-override grammar)
---

## Finding

R4-F01 over-corrected: structure.md §3 verifier-fanout now reads `--tier-override qrspi-finding-verifier=<tier>` (a `tag=tier` pair), but design.md CD-4 §H authority specifies bare `[--tier-override <tier>]` for verifier-fanout. This creates an authority-level contract conflict.

## Evidence — design.md uses TWO distinct forms by mode

- **Reviewer-fanout (CD-1, design.md:63):** `[--tier-override tag1=high,tag2=medium,...]` — CSV of `tag=tier` pairs (multiple reviewer agents, each tier-overridable individually).
- **Verifier-fanout (CD-4 §H, design.md:470):** `[--tier-override <tier>]` — bare tier (the verifier is a SINGLETON agent `qrspi-finding-verifier`; no tag namespace needed).

Structure.md §3 R4 fix unified the two modes under §7's CSV grammar, which is incorrect: §7's CSV grammar exists for the reviewer-fanout case where multiple distinct reviewer tags can be tier-tuned independently. Verifier-fanout has only one agent so the `tag=` prefix is meaningless noise.

## Why R3 flagged this (and why the R3 fix was wrong)

R3's quality-claude finding (R3-F01 against §3 vs §7) was correct that the two structure sections disagreed, but the *reconciliation direction* was wrong. The fix should have been to clarify §7 that CSV grammar scopes to reviewer-fanout, while verifier-fanout uses the simpler `<tier>` form. Instead, R4 inflated §3 verifier-fanout to fit §7's grammar.

## Suggested fix

Two-part fix at structure-altitude (no implementation detail needed):

1. **Revert §3 verifier-fanout invocation form (line 212)** from `[--tier-override qrspi-finding-verifier=<tier>]` back to `[--tier-override <tier>]` to match design.md authority.
2. **Clarify §7 (line 279)** that the `<csv>` grammar applies to reviewer-fanout's multi-reviewer surface, and verifier-fanout uses a simpler bare-tier form because the verifier is a singleton agent. One sentence: "Note: this CSV grammar applies to reviewer-fanout. Verifier-fanout's `--tier-override` accepts a bare `<tier>` because the verifier is a singleton agent (`qrspi-finding-verifier`)."

## 3-check scope procedure

1. **Owns?** Yes — interface/CLI contract is structure-altitude (Structure owns interface contracts per skills/structure/owns-defers.md).
2. **Within structure altitude?** Yes — Interface §3 and §7 are structure-altitude surfaces.
3. **Fix altitude correct?** Yes — wording alignment between two structure-altitude sections + alignment with design.md authority; no Plan-altitude or implementation detail needed.

<!-- @@FINDING: stitching-audit.finding-F01 @@ -->
---
finding_id: R5-F01
severity: medium
change_type: correctness
referenced_files:
  - structure.md §17 (.orchestrator-fixes.json rescue audit schema)
  - structure.md ## Architectural Diagram / subgraph S12 (Slice 1.2 Calibration + instrumentation)
  - structure.md ## File Map / Slice 1.2 (using-qrspi/SKILL.md row)
  - design.md CD-4 §I.3 (Rescue audit file lock)
---

The R4 fix introduced §17, which declares `using-qrspi/SKILL.md` as the consumer of `.orchestrator-fixes.json` — the round-summary prose surface reads per-tier rescue counts from this file to populate `round-NN-dispositions.md`. However, the Architectural Diagram's S12 subgraph (Slice 1.2) was not updated to reflect this new data-flow dependency: `.orchestrator-fixes.json` is absent as a node, and no edge representing the rescue-layer → `.orchestrator-fixes.json` → `UQ[skills/using-qrspi/SKILL.md]` path exists in the diagram. This gap was explicitly flagged as a caveat in the R4 fix description ("§17 adds a new consumer dependency on using-qrspi/SKILL.md round-summary prose that is not yet wired into the Architectural Diagram's Slice 1.2 subgraph") but was not resolved by R4 — it was named, not fixed. The practical risk is that Plan/Implement engineers navigating the S12 subgraph as the primary structural reference for Slice 1.2 will not see the `.orchestrator-fixes.json` reader obligation for `using-qrspi/SKILL.md`'s round-summary prose surface, increasing the likelihood that the consumer-side implementation is omitted or treated as optional. The §17 prose is correctly specified; the fix is to add a `.orchestrator-fixes.json` node and a directed edge into `UQ` in the S12 subgraph.

<!-- @@SCORE: stitching-audit.finding-F01.score @@ -->
score: 30
reason: Real gap between §17 and S12 subgraph, but the diagram convention is consistently source-files-only (no other audit artifacts — §11, §13, manifest — appear as nodes either), so adding `.orchestrator-fixes.json` would break convention while the authoritative §17 prose already binds the consumer obligation; low practical risk.

<!-- @@FINDING: stitching-audit.finding-F02 @@ -->
---
finding_id: R5-F02
severity: low
change_type: clarity
referenced_files:
  - structure.md §11 (.verifier-fan-in-audit.json schema)
  - structure.md §17 (.orchestrator-fixes.json rescue audit schema)
  - design.md CD-4 §I.3 (Rescue audit file / schema authority cited by §17)
  - design.md CD-4 §C (verifier-fan-in.sh / implicit §11 schema authority)
---

§17 (added in R4) introduces a structured schema-documentation convention — explicit "Writer:", "Consumer:", and "Schema authority: design.md CD-4 §I.3" prose appended after the JSON example block — that its sibling interface section §11 (`.verifier-fan-in-audit.json`) does not follow. §17 even explicitly invites comparison by stating "Co-exists with §11 `.verifier-fan-in-audit.json` — separate writers, separate files, no merge semantics," yet §11 carries no "Schema authority" pointer, no "Writer:" attribution, and no "Consumer:" identification. The canonical schema definition for §11 is in design.md CD-4 §C (the `verifier-fan-in.sh` component specification), but structure.md provides no path to it — an implementer extending or reading §11's schema contract has no pointer to its design-time authority. R4 applied the more rigorous convention only to the new section, leaving the established section under-specified by comparison. The fix is to add a one-sentence schema-authority, writer, and consumer annotation to §11 following the §17 pattern, resolving the asymmetry. No functional behavior is affected; the risk is purely implementer-navigation confusion when the two sections are read as a pair.

<!-- @@SCORE: stitching-audit.finding-F02.score @@ -->
score: 55
reason: Real asymmetry verified — §17 (line 480) carries Writer/Consumer/Schema-authority prose absent from §11 (lines 352-369), and §17 explicitly invites comparison via "Co-exists with §11"; finding is correct but low-severity clarity-only with no functional impact.

<!-- @@CLEAN: scope-claude.clean @@ -->
---
artifact: structure
reviewer_tag: scope-claude
round: 5
status: clean
---

# scope-claude — round 5 — no scope findings

Applied the 3-check scope/boundary procedure (skills/structure/owns-defers.md) to the R5 narrow diff against the scope-hint surface (File Map, Interfaces, CI Pipeline).

## Checks performed

1. **Boundary-drift detection vs. Structure DEFERS** — no prose asserting DEFERS items:
   - File Map row (`skills/using-qrspi/SKILL.md`): added Responsibility text names the config keys consumed from `config.md` (`orchestrator_rescue`, `max_drift_per_round`) — that is an inter-file dependency, which Structure OWNS. Authority cross-ref to design.md CD-4 §I.3 properly defers the decision upstream.
   - `--tier-override qrspi-finding-verifier=<tier>` (Interfaces §3 verifier-fanout mode) — CLI argument shape, Structure OWNS.
   - Locked-platform-directory sentence change (Interfaces §13) — *removes* duplicated per-platform return values and points to design.md CD-4 §I.7. Reduces Design-altitude drift.
   - New Interfaces §17 (`.orchestrator-fixes.json` rescue audit schema) — documents path, writer, consumer, on-disk shape, and explicit "Schema authority: design.md CD-4 §I.3" cross-ref, plus a co-existence note vs. §11 `.verifier-fan-in-audit.json`. This is a file-boundary contract (Structure OWNS: file paths, inter-file dependencies, data shape at boundary). The "partial-failure semantics — failed attempts write `tier_outcome: 'failed'`" clause mirrors the boundary-contract pattern already established in §11/§13–16 and remains at structure altitude (it tells consumers what value to read at the boundary, not how the writer implements it).
   - Section Contracts paragraph — adds `§17` to the "already contracted in Interfaces" cross-ref list. Bookkeeping only.

2. **Scope compliance per Structure OWNS** — §17 covers all required boundary facets (path / writer / consumer / shape / authority / co-existence). File Map / Interfaces / Section Contracts cross-refs remain internally consistent after the diff. No OWNS gaps introduced.

3. **Lexical boundary-drift signal** — no implementation/business-logic code, no phase assignments, no compaction-callout wording, no prompt or agent-file body prose, no test-assertion text, no per-task LOC or commit ranges. The JSON block in §17 documents data shape (Structure OWNS), not implementation.

## Outside-scope-hint scan

One observation outside the hinted surface, intentionally NOT raised as a scope finding because it is a labeling/quality concern, not a Structure-DEFERS violation: the File Map "Goal IDs" cell for `skills/using-qrspi/SKILL.md` now mixes `CD-4` with `G19/G20/G28/G29`. Column-semantics consistency is the artifact-quality reviewer's beat (`qrspi-structure-reviewer`), not scope.

No scope findings to emit.


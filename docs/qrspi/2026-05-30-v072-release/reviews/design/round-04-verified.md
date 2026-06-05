---
verifier_enabled: true
scored: 5
kept: 4
dropped: 1
failed: 0
clean: 1
---

<!-- @@FINDING: quality-claude.finding-F01 @@ -->
---
severity: high
change_type: correctness
artifact: design
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/design.md:628-630
  - docs/qrspi/2026-05-30-v072-release/design.md:645-653
  - docs/qrspi/2026-05-30-v072-release/design.md:671
  - docs/qrspi/2026-05-30-v072-release/design.md:675
---

# `.interaction-mode-audit.json` writer is internally contradictory for the `llm-context` detection type

## Summary

CD-4 §I.7's `.interaction-mode-audit.json` specification — rewritten in R3 per the qc R3-F02 fix that moved the audit destination from `<run-dir>/.verifier-fan-in-audit.json` to `<round-dir>/.interaction-mode-audit.json` with a flattened schema — carries three mutually inconsistent statements about who writes the file. The contradiction is load-bearing because the `llm-context` branch (covering both supported v0.7.2 hosts: Copilot CLI and Claude Code) cannot be implemented under any of the three contradictory readings.

## The three incompatible specifications

**1. The Contract section (L628–630)** locks the script's output channel to stdout only:

> Outputs a small structured block on stdout (one key per line, `KEY=value` shape) describing how the orchestrator should determine auto vs. interactive for the active host. Exit code 0 on successful detection (including the safe-default branch); nonzero only on internal script error.

No file-write is in the script's contract.

**2. The Audit-log entry section (L671)** attributes the JSON file write to the script, and the separation note explicitly names the script as the single writer:

> Every round-start invocation of the detection script writes `<round-dir>/.interaction-mode-audit.json` with shape `{platform, detection_type, verdict, evidence}` …
>
> Separate file from Component E's `.verifier-fan-in-audit.json` (different writer — `scripts/detect-interaction-mode.sh` vs `scripts/verifier-fan-in.sh`; different timing — round-start vs round-end; **single-owner property preserved per file**).

**3. The LLM-context branch description (L645–653) and the Caching section (L675)** locate verdict + evidence derivation in the orchestrator, not the script:

> Orchestrator action: read `INSTRUCTION`, execute the check against its own context, derive `auto` or `interactive`. The orchestrator MUST cite (in the audit log entry below) the specific context signal it observed (or its absence) so the decision is traceable post-hoc.

> Orchestrator invokes the script once per round-start, caches `{platform, detection_type, verdict, evidence}` for the round, and reuses it for every subsequent consumer check in that round. … The orchestrator's cached evidence is what gets cited in the audit log.

## Why this is a contradiction (not just under-specification)

For `DETECTION_TYPE=llm-context` (the case that covers both Copilot CLI and Claude Code, per the locked platform directory at L611–614), two of the four audit fields — `verdict` and `evidence` — are computed by the orchestrator inspecting its own context after the script returns. The script has no way to know either value. Therefore:

- If the script writes the audit file (per the Audit-log entry section + separation note), it cannot populate `verdict` or `evidence` for the `llm-context` case — the fields would be missing or wrong, defeating "this makes mis-detections diagnosable."
- If the orchestrator writes the audit file (the only actor with the data), the separation note's "single-owner property preserved per file" claim is false and the L671 sentence "the detection script writes" is incorrect.
- If both write (script writes shell-verdict + user-override-only cases, orchestrator writes llm-context cases), there are two writers for one file — also contradicting "single-owner property preserved per file" and unspecified mechanically (does the orchestrator overwrite, append, merge?).

There is no implementer-discoverable resolution in the design block.

## Concrete downstream impact

- **Structure / Plan / Implement guessing.** Sub-Rule C requires every output to name a consumer and every step's I/O to be traced. Here the *writer* is unspecified for the case that covers all supported v0.7.2 hosts. Plan task authoring for `scripts/detect-interaction-mode.sh` cannot decide whether the script needs a write capability (path arg, atomic-mv pattern, manifest entry) without re-opening Design.
- **Multi-Actor Flow Check (CD-3) will fire downstream.** Structure / Plan / Implement consumers running CD-3 on this decision will hit a missing element ("how A invokes B" / "who reads C's output" in the diagnostic template) and halt — exactly the failure mode CD-3 catches.
- **Sub-Rule D is also tripped.** The detection signal table at L611–614 is well-cited per Sub-Rule D, but the post-detection audit-write mechanism (a flow specification, not an external-knowledge claim) has no consistent owner.

## Recommendation

Pick one writer and rewrite the three sections to agree. Two clean shapes:

**Option A — Orchestrator-only writer.** Strip the audit-write responsibility from the script entirely. Update the Contract section to remain stdout-only (no change). Rewrite the Audit-log entry section to read "After each round-start invocation, the **orchestrator** writes `<round-dir>/.interaction-mode-audit.json` with shape `{platform, detection_type, verdict, evidence}`, populating `verdict` and `evidence` from the values it derived per the LLM-context INSTRUCTION (or the values the script returned for `shell-verdict` / `user-override-only` cases)." Update the separation note's writer attribution from `scripts/detect-interaction-mode.sh` to "orchestrator (post-script)." Single owner is preserved at the orchestrator.

**Option B — Two-pass script writer.** Extend the script's Contract to take an additional `--write-audit <path> --verdict <auto|interactive> --evidence <prose>` invocation form, invoked by the orchestrator *after* it derives the values from context inspection. The script then writes the audit JSON. The Contract section must be updated to document the second invocation form and its exit codes. The orchestrator-side flow becomes two bash calls per round-start (detect, then audit-write).

Option A is simpler (one bash call, one writer, no new script flags) and matches the precedent set by the `.orchestrator-fixes.json` audit file in I.3 (writer = orchestrator). Recommend Option A.

Either way, the three sections (Contract, Audit-log entry, Caching) must all use the same writer attribution, and the separation note's writer name must match.

## Why this matters at design quality (not scope)

This is internal contradiction within a single CD's locked-component spec — the design-quality check named in the reviewer protocol ("No internal contradictions — component descriptions, data-flow explanations, and interface definitions are mutually consistent"). It is not a scope boundary concern.
<!-- @@SCORE: quality-claude.finding-F01.score @@ -->
---
finding_id: R4-F01
reviewer_tag: quality-claude
score: 82
change_type: correctness
reason: I.7 writer-ownership contradiction is real and load-bearing — Contract says stdout-only, Audit-log says script writes, Caching says orchestrator derives evidence. Blocks deterministic implementation of the audit file. Hardening-relevant (single-writer principle is foundational across CD-4). Above the 70 correctness threshold; kept.
defect_class: writer-ownership-contradiction
---
<!-- @@FINDING: quality-claude.finding-F02 @@ -->
---
severity: medium
change_type: correctness
artifact: design
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/design.md:2259
  - docs/qrspi/2026-05-30-v072-release/design.md:2288
  - docs/qrspi/2026-05-30-v072-release/design.md:2305
  - docs/qrspi/2026-05-30-v072-release/design.md:587
  - docs/qrspi/2026-05-30-v072-release/design.md:707
---

# G28's CD-4 line-number references stale after R3 letter rename — readers navigating by line number reach wrong content

## Summary

The R3 CD-4 letter rename (A–G → J → [acceptance] → H → I rewritten to monotone A–J + acceptance moved to follow J per qc R3-F04) substituted the section-letter token `H.5 → I.5` everywhere it appeared in cross-references, but it did not refresh the *line numbers* that accompany those tokens. G28 carries the bulk of these stale references — five line citations into CD-4, four of which now point at the wrong content, and one which has drifted out of CD-4 entirely.

## The stale references in G28

All three citation sites in G28 use the same set of stale line numbers:

**Site 1 — G28 D4 (L2259):**

> CD-4's iron-rule preservation check (design.md L532, I.5) continues to hold trivially because the script's behavior is identical to v0.7.1.

**Site 2 — Cross-cutting note G28 ↔ CD-4 (L2288):**

> Future amendments to the kept-set logic MUST land in the script (per CD-4's amendment seam at design.md L642), NOT in orchestrator prose or dispositions overrides.

**Site 3 — References (L2305):**

> CD-4 (this file, L380-444 — verifier-fan-in pipeline; L400 context-cost iron rule; L417 threshold rule; L532 I.5 iron-rule preservation check; L642 amendment seam)

## Actual locations vs. cited locations

| Cited | Claimed content | Actual content at that line | Real location of claimed content |
|-------|-----------------|------------------------------|----------------------------------|
| L380 | "verifier-fan-in pipeline" header | inside Mermaid diagram body (`D->>FS: write per-tag PROMPT_FILEs + manifest entries`) | CD-4 header is at L352 |
| L400 | "context-cost iron rule" | inside Mermaid diagram Phase 3 body (`O->>S: verifier-fan-in.sh <round-dir>`) | Context-cost call-out is at L421 (choreography element #6) |
| L417 | "threshold rule" | choreography element #2 (Sequence) | Threshold rule is at L438 (§C step 3) |
| L532 | "I.5 iron-rule preservation check" | "**Tier 1 — mechanical fixes**" (inside §I.3) | I.5 is at L587 — 55 lines off |
| L642 | "amendment seam" | inside §I.7 platform directory / override chain prose | Amendment seam is at L707 |

The "L380-444" range purporting to cover the entire verifier-fan-in pipeline ends at L444, which is mid-Component E (`.verifier-fan-in-audit.json` schema example) — the pipeline section actually runs from L352 (header) past L709 (iron rule). So the cited *range* also under-shoots by ~270 lines.

## Why this matters

A reader following any of these line numbers reaches content that does not match what G28 claims is there. Concrete consequences:

1. **Plan task authoring against G28** — a Plan-time reader who Reads `design.md` at L532 looking for the iron-rule preservation check finds the tier-1 rescue list instead. The "iron rule still holds" claim G28 D4 makes (the core load-bearing rationale for "scripts/verifier-fan-in.sh unchanged") becomes unverifiable from G28 alone.
2. **Cross-cutting trace via References section** — the References block at L2305 is the audit trail for downstream skills consuming G28. Every CD-4 anchor in that audit trail is wrong. A future maintainer consulting "where is the amendment seam?" by following the L642 reference lands inside an unrelated platform-detection branch.
3. **The "L532, I.5" parenthetical is internally inconsistent on its own line** — it asserts that I.5 is at L532. The reader doesn't need to leave G28 D4 to notice the inconsistency once they look up either anchor.

## What R3 did and didn't do

R3 substituted the letter token (`H.5 → I.5`, `§H rescue tier → §I rescue tier`). The substitution was the right surface for the *named* anchor — the reader who follows "I.5" by searching the file (rather than jumping to a line number) reaches the correct content at L587. The line numbers were the unfortunate companion data that R3 did not refresh, and that subsequent insertions (CD-4 §I.7 rewrite for qc R3-F02, the new I.3 sub-paragraphs for qc R3-F01) drifted further.

## Recommendation

Two clean options:

**Option A — Delete the line numbers; keep the named anchors.** The named anchors (§I.5, §C, §E, amendment seam) are unambiguous within CD-4 and stable across future R5+ edits. The line numbers carry no information the named anchors don't already convey. Rewrite the three sites:

- **L2259:** "CD-4's iron-rule preservation check (CD-4 §I.5) continues to hold trivially..."
- **L2288:** "...per CD-4's amendment seam..." (drop "at design.md L642")
- **L2305:** "CD-4 (this file, § Verifier-Fan-In Pipeline — Mermaid diagram + choreography elements; §C threshold rule; §I.5 iron-rule preservation check; § Amendment seam — G19)"

**Option B — Refresh the line numbers.** Update all five references to point at the current locations (L352 for CD-4 header, L421 for context-cost, L438 for threshold rule, L587 for I.5, L707 for amendment seam). This works for this round but reintroduces the same rot risk on the next CD-4 edit.

Option A is more durable and matches the convention elsewhere in design.md (named-anchor references to external SKILL files use literal heading text, not line numbers, per G23 D2 acceptance criterion "phrasing matches the existing cross-link style…uses the literal heading text — not a line number — so the cross-link survives future re-numbering"). The same principle applies to internal references inside design.md.

## Scope note

This is one author's localized cross-reference rot in G28. A broader audit across the file (searching for any "design.md L<NNN>" or "this file, L<NNN>" pattern) may surface a small number of similar drifts; if so they should be fixed under the same Option A pattern. Not scoping that wider audit to this finding — flagging G28's specific cluster because R3 made these references concretely wrong rather than merely stale-by-aging.
<!-- @@SCORE: quality-claude.finding-F02.score @@ -->
---
finding_id: R4-F02
reviewer_tag: quality-claude
score: 75
change_type: correctness
reason: G28 cross-references in 3 sites point at wrong line numbers post-R3 letter rename. The letter-token substitution was done; the line-number refresh was not. Real but low-leverage — references still navigable via grep, but the artifact's stated invariants drift over time without surface fixes like this. Above the 70 correctness threshold; kept.
defect_class: stale-line-references
---
<!-- @@FINDING: quality-codex.finding-F01 @@ -->
---
finding_id: R4-F01
severity: high
change_type: correctness
referenced_files:
  - design.md (CD-4 § I.7)
---

## Issue
I.7 assigns `.interaction-mode-audit.json` to the wrong writer and leaves the write contract internally contradictory: the section says the audit file is written by `scripts/detect-interaction-mode.sh`, but the required `evidence` for `DETECTION_TYPE=llm-context` must be observed by the orchestrator from LLM context (which the script cannot access). The script contract also only specifies stdout key/value output, not a round-dir input needed to write a round-scoped file.

## Why it matters
This blocks deterministic implementation of interaction-mode auditing: implementers cannot satisfy both the script contract and the audit-file contract at once, and different implementations will diverge on who writes the file and when.

## Proposed change
Make ownership explicit and single-source: either (A) orchestrator writes `.interaction-mode-audit.json` after executing script output + context check, or (B) script writes only script-observable fields and orchestrator appends context evidence in a second step. Also lock the invocation surface needed for round-dir targeting.

## Citation
- design.md:L628-L637
- design.md:L653-L654
- design.md:L671-L677
<!-- @@SCORE: quality-codex.finding-F01.score @@ -->
---
finding_id: R4-F01
reviewer_tag: quality-codex
score: 72
change_type: correctness
reason: Convergent with quality-claude R4-F01 (cross-family agreement on the I.7 writer-ownership contradiction). Same root cause, slightly different framing. Above the 70 correctness threshold; kept (same fix as quality-claude.R4-F01).
defect_class: writer-ownership-contradiction
---
<!-- @@FINDING: quality-codex.finding-F02 @@ -->
---
finding_id: R4-F02
severity: medium
change_type: correctness
referenced_files:
  - design.md (CD-4 § I.3)
---

## Issue
The rescue/disposition accounting is inconsistent when `orchestrator_rescue: false`: behavior matrix says every halt escalates immediately, but `.orchestrator-fixes.json` is defined as rescue-tier event logging and the dispositions "Rescue tier breakdown" is sourced from that file. Under rescue-off, escalations occur without rescue-tier execution, so E1–E4 escalation counts are not reliably derivable from the declared source.

## Why it matters
Round-end dispositions can become non-repeatable or incorrect (showing zero/partial escalations despite real escalations), weakening the audit trail this change is intended to provide.

## Proposed change
Extend the audit contract to log escalation events independently of rescue-tier execution (including rescue-off paths), or narrow dispositions sourcing to only what the file can deterministically represent and define a second source for escalations.

## Citation
- design.md:L525-L533
- design.md:L539-L542
- design.md:L545-L549
<!-- @@SCORE: quality-codex.finding-F02.score @@ -->
---
finding_id: R4-F02
reviewer_tag: quality-codex
score: 68
change_type: correctness
reason: Rescue-off accounting gap is real but very low severity. Under orchestrator_rescue=false, no rescue events fire so .orchestrator-fixes.json stays empty, and the dispositions "Rescue tier breakdown" sourced from it would show zeros. Mitigations: (1) E2 escalations under rescue=off are trivially countable from halt events themselves, not dependent on this file; (2) v0.7.2 may opt to leave this implicit (the breakdown is implicitly rescue-on context). Below the 70 correctness threshold; dropped. Recorded under Sub-Threshold Observations for v0.7.3 calibration.
defect_class: implicit-disposition-context
---
<!-- @@FINDING: scope-codex.finding-F01 @@ -->
---
finding_id: R4-F01
severity: medium
change_type: scope
referenced_files:
  - design.md § G15
  - design.md § G18
  - design.md § G19 (and similar per-goal sections using "Plain-language problem" framing)
---

## Issue
Several per-goal sections reintroduce goals-altitude problem framing ("Plain-language problem", contextual incident history, and "Why this matters") inside `design.md`, instead of staying focused on solution definition, decision rationale, dependencies, and acceptance at Design altitude.

## Why it matters
This blurs Goals vs Design boundaries and makes Design carry repeated problem narrative that downstream consumers don't need at this phase, increasing artifact volume/noise and weakening the scope reviewer's ability to detect true altitude drift.

## Proposed change
For each goal block, remove problem-framing prose and keep a short source pointer (goal ID / issue link) plus design-owned content only: outcome, chosen solution, tradeoffs/why, dependencies/edge cases, and acceptance criteria.

## Citation
- design.md:L1528 (`## G15` starts with "Plain-language problem…")
- design.md:L1713 (`## G18` starts with "Plain-language problem…")
- design.md:L1795 (`## G19` starts with "Plain-language problem…")
<!-- @@SCORE: scope-codex.finding-F01.score @@ -->
---
finding_id: R4-F01
reviewer_tag: scope-codex
score: 25
change_type: scope
reason: "Plain-language problem" sections in per-goal blocks were operator-blessed in R1 per PI-HKP-005 — they aid human review and the G1 per-goal template explicitly carries this shape. Recurring false-positive across review rounds. scope/intent findings bypass score filter per protocol step 8 — flows to pause gate as user-override.
defect_class: pi-hkp-005-recurring-pattern
---
<!-- @@CLEAN: scope-claude.clean @@ -->
---
artifact: design
reviewer_tag: scope-claude
round: 4
status: clean
---

# scope-claude — round 4 — clean

No scope/boundary-drift findings.

## Procedure applied

Read goals.md G34 first per operator's CRITICAL CONTEXT directive. G34 amends
the Design scope-reviewer's effective OWNS/DEFERS contract for v0.7.2:

- **OWNS additions (G34 D2):** detailed solution descriptions with full edge
  cases, end-to-end flows specifying actor sequence + per-step inputs/outputs,
  prompt-writing specifics (verbatim or paraphrased SKILL/agent prose when
  load-bearing), acceptance criteria including concrete examples and rough
  test-pairing shapes, per-solution diagrams per goal/CD block, naming and
  renames establishing cross-skill vocabulary, dependency-justified
  release-assignment phrases.
- **DEFERS retained (G34 D3):** function bodies with executable logic, full
  unit-test code, executable shell beyond a few illustrative lines (UNLESS the
  body IS the dispatch contract downstream consumers must read), file
  architecture (Structure's), unified system-wide architecture diagrams
  (Structure's), unified Test Strategy/Architecture (Structure's), task
  carving (Plan's).

Applied the 3-check procedure against the G34-amended contract over the full
3021-line base-branch diff (round 4 broadened to base-branch per
`scope_hint: (none)`).

## Boundary-drift detection

Scanned for the GENUINE scope concerns the operator named:

1. **Literal test assertions (`assert_equal "expected" "$actual"`-style code)**
   — not found. Acceptance criteria use shape language throughout (e.g.,
   "assert exit 10 AND stderr matches the orchestrator-bug diagnostic regex",
   "asserts non-zero exit and a diagnostic written to stderr naming the
   unconfigured tier", "fixture asserts both scope variants"). All
   acceptance-criteria-altitude per G34 OWNS.

2. **Full bash scripts inlined without dispatch-contract justification** —
   closest candidates:
   - G4 `round-prepare.sh` step 1 (~25 lines) — exit codes 10/11/12 are
     consumed by main chat's between-rounds recovery branch per CD-1 #3.
     Script body IS the dispatch contract. PI-HKP-005 R3 user-override
     precedent applies; G34-blessed per "script-body shapes when the script
     body IS the dispatch contract."
   - G16 `assert_path_under_repo_root` (~22 lines) — function body shape +
     stderr format is the security contract consumed by the bats fixtures in
     G16 deliverable 3 (which assert `"resolves outside repository"` stderr
     substring). Same dispatch-contract bless applies.
   - CD-4 §C 5-step `verifier-fan-in.sh` algorithm — prose enumeration of
     script behavior (halt conditions, audit JSON shape), not bash code; this
     IS the dispatch contract downstream consumers (using-qrspi, implement)
     read.
   None cross the G34 line under the dispatch-contract carve-out + R3
   user-override disposition.

3. **File paths to implementation modules Structure should own** — G16/G17
   cite specific line numbers in existing files as edit-site anchors
   (modification of existing files, not authoring of new file layouts). G22
   enumerates the 41-agent tier rubric (the rubric IS the design decision per
   CD-1's tier schema, not Structure's file map). G27/G31/G32 name new files
   by purpose and identity per G34 OWNS "naming and renames that establish
   cross-skill vocabulary." No Structure-altitude file-architecture leakage.

## Phasing-altitude scan

Many "v0.7.3+ follow-up" deferrals appear across G14/G15/G18/G19/G20/G21/G22/
G23/G24/G25/G26/G27/G28/G29/G31/G32/G34/G35, but each carries either
dependency-edge framing (e.g., "G27 lands AFTER CD-1 and AFTER G22 — both
upstreams must settle before G27's cross-link anchors are stable", "G34/G35
hard-depend on G32") or explicit operator-scope-decision framing (e.g.,
"investigation-first scope per goals dialogue"). No intra-v0.7.2 "Phase 1
ships X / Phase 2 ships Y" carving was found — that's `qrspi:phasing`'s
territory and is correctly absent from design.md per the existing
DEFERS pointer.

## Goals-altitude scan

Per-goal "Plain-language problem" / "Why we care" blocks (G10, G15, G16, G17,
G18, G19, G20, G21, G22, G23, G24, G25, G26, G27, G28, G31, G32, G34, G35)
ground each design decision with minimal context anchor; they do not
re-litigate goals.md problem framing wholesale. This pattern was present in
R1-R3 and is operator-blessed per the R1 decisions file's "phasing-leakage
phrases throughout — all kept per operator decision" disposition, which
extends naturally to problem-framing prose under PI-HKP-005's broader
user-override stance.

## Scope compliance per OWNS

Every goal in goals.md (G1-G35) and every cross-cutting decision (CD-1, CD-2,
CD-3, CD-4) has a per-goal/per-CD solution block present. G1's per-goal
template (Outcome / Solution / Why this approach / Dependencies + edge cases
/ Acceptance) is followed throughout. Per-solution Mermaid diagrams present
where load-bearing (CD-4). Rename inventories present (CD-1, G3). Sub-Rule C
end-to-end flow elements (actor inventory, sequence, per-step I/O, consumers,
loud-failure paths, context-cost callouts) specified for multi-actor
decisions (CD-1, CD-4, G4, G9). No OWNS gap detected.

## PI-HKP-005 directive applied

Per the operator's R4 directive, the three recurring categories — G4
round-prepare.sh body, CD-1 dispatch-agent.sh flag enumeration, assertion-
text examples in acceptance criteria — are G34-blessed and declined as
findings this round. No new round-4 surfaces were found that cross the G34
amended boundary and aren't already absorbed by the PI-HKP-005 disposition.

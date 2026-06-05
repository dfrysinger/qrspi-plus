---
step: design
round: 3
verifier_enabled: false
findings_total: 7
fixed: 5
user_override: 2
---

# Design Round 03 — Dispositions

## Review summary

R3 dispatched 2 Claude reviewers (qrspi-design-reviewer + qrspi-design-scope-reviewer) against `round-03.diff` (3026-line diff vs base-branch). Codex side not dispatched — this round prioritized actionable triage over cross-family redundancy given the small actionable surface. Verifier not run for the same reason (7 findings is tractable for direct triage; verifier-disabled-round assembly applies).

## Fixed (5 findings)

### qc R3-F01 (medium correctness) — `orchestrator_fixes[]` undefined writer/schema/path → FIXED

**Decision:** Reviewer's option (b) — define a new file `<round-dir>/.orchestrator-fixes.json` with locked schema, writer, consumer. Inlined inside I.3 (formerly H.3) rather than as a new component letter to keep the locked-component-shapes list (A-J) tight.

**Changes:**
- Added "Rescue audit file" sub-paragraph in I.3: locks path `<round-dir>/.orchestrator-fixes.json`, schema `{rescue_events: [{finding_id, cause, tier, original_value, fixed_value, fix_method, citation?, tier_outcome}]}`, writer (orchestrator rescue tiers, after each tier 1/2/3 fix completes, partial-failure semantics), consumer (round-summary prose surface). Explicitly notes "separate file from Component E's `.verifier-fan-in-audit.json`; no merge semantics required" to forestall the co-write ambiguity.
- Added "Round-summary prose surface" sub-paragraph in I.3: locks `reviews/{step}/round-NN-dispositions.md` (the existing standard apply-fix dispositions file) as the user-visible per-tier-count surface; orchestrator appends a "Rescue tier breakdown" subsection at round end.
- Updated I.5 and I.6 backward references from `orchestrator_fixes[]` → `.orchestrator-fixes.json` with citation to I.3's lock.

### qc R3-F02 (medium correctness) — H.7 (now I.7) audit-log destination contradicts Component E → FIXED

**Decision:** Reviewer's first option — rename I.7's destination to a separate file. Cheapest fix; preserves Component E's single-owner property.

**Changes:**
- I.7 "Audit-log entry" now writes to `<round-dir>/.interaction-mode-audit.json` (was `<run-dir>/.verifier-fan-in-audit.json`).
- Schema flattened to top-level `{platform, detection_type, verdict, evidence}` (was nested under `interaction_mode_resolution:`).
- Added explicit cross-reference clarifying separation from Component E: different writer (`scripts/detect-interaction-mode.sh` vs `scripts/verifier-fan-in.sh`), different timing (round-start vs round-end), single-owner property preserved per file.
- Acceptance fixtures (I.7 acceptance criteria block) were path-agnostic — no fixture edits required.

### qc R3-F03 (low clarity) — orphan EOF bullets → FIXED

**Decision:** Delete all 3 bullets. The Q5 bullet was already redundant (covered in G3 + CD-1). The other 2 were substantive observations worth preserving — filed as GitHub issues rather than relocating inline to an existing goal's "Open Questions for v0.7.3+" block (which would have expanded artifact scope).

**Changes:**
- Deleted L3022-3024 (3 orphan bullets after G35's closing paragraph).
- Filed #284 (PI-PG-001) — Pause Gate option 3 cascade undiscoverable; proposes observability counter for v0.7.3+.
- Filed #285 (PI-DGN-001) — Design SKILL lacks incremental persistence during long Goals-walkthroughs; proposes per-goal incremental persistence in v0.7.3+.
- File now ends cleanly at G35's `**Plain-language summary.**` paragraph.

### qc R3-F04 (low clarity) — letter ordering A-G→J→[acceptance]→H→I → FIXED

**Decision:** Reviewer's option (a) — full alphabetic rename and move acceptance subsections to the end. Letters are now contiguous A-J with acceptance + amendment seam + iron-rule framing following.

**Changes:**
- Renamed J → H (verifier dispatch, formerly between G and acceptance, now contiguous with A-G).
- Renamed old H → I (halt-response protocol). Sub-clauses H.1-H.7 → I.1-I.7. All inline references (`H.2 budget`, `enumerated in H.1`, `per H.3`, `§H.3`, etc.) updated.
- Renamed old I → J (reviewer-side hardening).
- Moved "Per-goal acceptance mapping" + "Behavioral acceptance" subsections from between G and J (old position) to after J (new position) — components A-J are now contiguous before acceptance prose.
- Updated 1 backward reference outside CD-4 (`L532, H.5` → `L532, I.5` in G28 References; `CD-4 §H rescue tier` → `CD-4 §I rescue tier` in G34's mental-replay).
- 30+ surgical sed-equivalent replacements; verified clean by grepping for stray `H.[1-7]` in the CD-4 region (zero matches).

### sc R3-F03 (low scope) — phasing/release-assignment drift → PARTIALLY FIXED

**Decision:** Fix the one site that names a temporal ship-order without a dependency edge (L1771's "G15 ships first"). The other 4 cited sites (G24 ordering at L2069, G35 D7 hard-deps, G32 v0.7.3+ deferral, G34 D1 hard-dep on G32) are either G34-blessed release labels OR already attach dependency-edge rationale to the ordering commitment.

**Changes:**
- L1777 (Cross-cutting note G15 ↔ G18): "G15 ships first (was locked before G18) — its `dependent_tests:` mechanism for sweep tasks is the structural template G18 mirrors" → "G18 depends on G15's `dependent_tests:` mechanism as a structural template (G15 was the first to lock that mechanism; G18 mirrors it). … Phase assignment is Phasing's call." Names the dependency edge without committing to phase order.

## User override (2 findings)

### sc R3-F01 (low scope) — line-by-line procedural logic + flag signatures → USER OVERRIDE per G34

**Cited sites:** G4 round-prepare.sh body (L1042-1075), CD-1 #3 `scripts/dispatch-agent.sh` invocation spec (L63-90).

**Rationale:** Both are G34-blessed under D2's "OWNS" allowances list: "end-to-end flows specifying actor sequence and per-step inputs/outputs, prompt-writing specifics (the actual prose a SKILL or agent file will carry, paraphrased or verbatim when load-bearing), acceptance criteria including concrete examples." The G4 script body and the dispatch-agent flag enumeration are load-bearing dispatch contracts that downstream consumers (Structure, Plan) need at full fidelity. Recurring false-positive across R1/R2/R3 — PI-HKP-005 pattern. G34's amended contract has not yet shipped (it lands in v0.7.2); reviewer is operating against installed v0.7.1 OWNS/DEFERS.

**Disposition:** Operator override at human gate per PI-HKP-005. G34's amended scope-reviewer will retroactively bless these sites once shipped. No artifact change.

### sc R3-F02 (low scope) — full assertion text in acceptance criteria → USER OVERRIDE per G34

**Cited sites:** CD-1 acceptance (L211), CD-4 acceptance (L596-598 / now post-rename position), and 3 other inline acceptance specs.

**Rationale:** G34 D2 OWNS list includes "acceptance criteria including concrete examples and rough test-pairing shapes." Several cited sites are exactly this shape — they name the test scaffold (single bats test, fixture inputs, assertion target) without authoring the literal `expect()` lines. Reviewer is reading them as Implement-altitude content under the installed v0.7.1 contract; G34 explicitly loosens this.

**Disposition:** Same as sc R3-F01 — operator override per PI-HKP-005, G34 retroactively blesses on ship. No artifact change.

## Round-status

- 5 of 7 findings fixed in-artifact.
- 2 of 7 findings dispositioned as user-override per PI-HKP-005 + G34 (will become moot on G34 ship).
- 0 findings unresolved.
- Net artifact change: -5 lines (3026 → 3021).

## Codex coverage

Not dispatched this round. F3 in #283 confirms Codex IS available in Copilot CLI via `model: gpt-5.3-codex` Task override. R3 prioritized actionable triage over cross-family redundancy; if R4 needed, dispatch Claude + Codex in parallel as in R1/R2. Verifier likewise not dispatched (7 findings tractable for direct triage; verifier-disabled-round assembly applies).

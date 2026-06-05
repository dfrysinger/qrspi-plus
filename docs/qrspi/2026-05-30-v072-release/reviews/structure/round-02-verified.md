---
verifier_enabled: true
scored: 4
kept: 6
dropped: 0
failed: 0
clean: 1
---

<!-- @@FINDING: quality-claude.finding-F01 @@ -->
---
finding_id: R2-F01
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
line_range: 651-651
---
**Hook-Point Locations §G34 cites wrong design section: "design.md CD-4 §D1" should be "design.md G34 §D1"**

Structure.md line 651 reads:

> `skills/_shared/design-altitude-boundary.md` is `!cat`-included in two consumer files **per design.md CD-4 §D1**:

`CD-4 §D1` is the design section for the Verifier-Fan-In Pipeline's `--verifier-fanout` extension to `dispatch-agent.sh`. It has no relationship to the design-altitude-boundary snippet. The correct authority is **`design.md G34 §D1`** — the decision node that establishes the Candidate-B (`!cat` single shared snippet into both consumers) pattern for `skills/_shared/design-altitude-boundary.md` (design.md lines 2895–2895, heading "D1 — Adopt Candidate B").

The sibling G35 entry on line 660 correctly cites "per design.md G35 §D1" — the G34 entry is inconsistently and incorrectly cross-referenced.

**Impact:** A Plan author or reviewer consulting the cited "CD-4 §D1" will read the verifier dispatch flag specification and find no authority for the design-altitude-boundary `!cat` pattern. The correct source (G34 §D1, lines 2895–2923) and its hard dependency statement ("Hard dependency on G32") are invisible from this incorrect citation.

**Fix:** Change line 651 from `per design.md CD-4 §D1` to `per design.md G34 §D1`.
<!-- @@SCORE: quality-claude.finding-F01.score @@ -->
score: 80
reason: Verified — structure.md line 651 cites "design.md CD-4 §D1" but the design-altitude-boundary `!cat` pattern is established in design.md G34 §D1 (line 2895); CD-4 is the universal dispatch decision and unrelated, and the sibling G35 entry on line 660 correctly uses the matching pattern, confirming the inconsistency.

<!-- @@FINDING: quality-claude.finding-F02 @@ -->
---
finding_id: R2-F02
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
line_range: 337-355
---
**Interface §11 `.verifier-fan-in-audit.json` schema diverges from the locked shape in design.md CD-4 §E**

Structure.md Interface §11 (lines 341–354) defines:

```json
{
  "round_dir": "reviews/plan/round-01",
  "scored": 6,
  "failed": 1,
  "dropped": 2,
  "kept": 4,
  "halts": [...]
}
```

Design.md CD-4 §E (lines 444–453) gives the **locked** shape:

```json
{
  "scored": 12,
  "kept": 4,
  "dropped": 8,
  "halts": [],
  "thresholds": { "style": 80, "clarity": 80, "correctness": 70 }
}
```

Three discrepancies:

| Discrepancy | Structure §11 | Design CD-4 §E | Direction |
|---|---|---|---|
| `round_dir` field | present | absent | extra in structure |
| `failed` field | present | absent | extra in structure |
| `thresholds` field | absent | **present and locked** | missing from structure |

The `thresholds` field is the most significant: CD-4 §C step 4 explicitly requires "counts + **threshold echo**" in the audit file, and CD-4 §E locks the field name and per-enum values. Omitting `thresholds` from Interface §11 means Plan tasks implementing `scripts/verifier-fan-in.sh` have contradictory schema authority — structure.md says three fields are excluded/added versus the design-locked contract.

**Fix:** Update Interface §11's JSON example to match CD-4 §E exactly: remove `round_dir` and `failed`, add `thresholds: { "style": 80, "clarity": 80, "correctness": 70 }`. If `round_dir` is an intentional addition not in CD-4 §E, the design authority must be cited; otherwise it is unsanctioned schema extension.
<!-- @@SCORE: quality-claude.finding-F02.score @@ -->
score: 75
reason: Verified — structure.md Interface §11 JSON omits the `thresholds` field that design.md CD-4 §E locks and step 4 explicitly mandates ("counts + threshold echo + halts: []"), and adds `round_dir`/`failed` fields not present in the locked shape; this is a real schema divergence on a design-locked contract that Plan implementers will reference.

<!-- @@FINDING: quality-claude.finding-F03 @@ -->
---
finding_id: R2-F03
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
line_range: 488-489
---
**Architectural Diagram contains a spurious `VF --> PR` cross-subgraph edge with no design basis**

The Mermaid diagram (line 488 of structure.md, outside all `subgraph` blocks) contains:

```
VF --> PR
```

`VF` is `scripts/verifier-fan-in.sh` (subgraph S11). `PR` is `scripts/round-prepare.sh` (subgraph S13).

No interface contract, design.md decision, or CD-4 §I.7 flow description establishes a direct script-to-script dependency from `verifier-fan-in.sh` to `round-prepare.sh`. The locked CD-4 sequence (design.md lines 399–491) shows fan-in output flowing to `<round-dir>/kept-findings.txt` → orchestrator → apply-fix. `round-prepare.sh`'s responsibility (Interface §2) is "canonicalize cumulative diff/ref selection and next-round narrowing inputs" — it takes a `<task-branch>` and `<round-NN>` as inputs, not a kept-findings artifact.

The edge implies `verifier-fan-in.sh` produces output that `round-prepare.sh` consumes, which is architecturally incorrect. A reader following the diagram would misunderstand the post-fan-in data flow.

**Fix:** Remove the `VF --> PR` edge. If the intent was to show the round-loop connection (fan-in completing → orchestrator advances to next round → round-prepare for next round), that cross-round relationship should be represented differently (e.g., an orchestrator node, or a comment, or removed entirely as implicit pipeline flow).
<!-- @@SCORE: quality-claude.finding-F03.score @@ -->
score: 75
reason: Confirmed — line 488 of structure.md has a stray `VF --> PR` edge outside all subgraphs, and design.md CD-4 §I.7 shows fan-in flows to kept-findings.txt/orchestrator (not round-prepare.sh), so the edge has no design basis and misrepresents data flow.

<!-- @@FINDING: quality-codex.finding-F01 @@ -->
---
finding_id: R2-F01
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
line_range: 170-177,337-355
---
`structure.md`'s fan-in interfaces drift from the CD-4 locked contract in `design.md`:

1. **Interface §1** says `kept-findings.txt` is "newline-separated finding IDs" (lines 175–176), but CD-4 component D locks this as **one absolute finding-file path per line**.
2. **Interface §11**'s `.verifier-fan-in-audit.json` example uses `halts[].reason` and omits the locked `thresholds` object (lines 341–355), while CD-4 component E/I.1 lock `halts[].cause` semantics and threshold echo in the audit object.

This creates a structural contract mismatch for downstream Plan/Implement/test authoring. Update Interfaces §1 and §11 so they match CD-4's canonical fan-in outputs (`kept-findings.txt` path lines; audit object with threshold echo and halt-cause shape).
<!-- @@SCORE: quality-codex.finding-F01.score @@ -->
score: 85
reason: Verified — structure.md §1 line 175 says "newline-separated finding IDs" but CD-4 component D locks "one absolute finding-file path per line", and §11's audit example uses `reason` (vs CD-4's `cause`) and omits the `thresholds` echo locked in component E; both are real structural contract drifts.

<!-- @@FINDING: scope-claude.finding-F01 @@ -->
---
finding_id: R2-F01
severity: medium
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
artifact: structure
line_range: [370, 391]
---

## Boundary drift — Interface §13 embeds orchestrator implementation behavior and internal detection signals

**What the artifact does.**  
Interface §13 ("Interaction-mode detector", lines 370–391) correctly opens with a bash comment block that declares the script's exit codes and stdout output shapes — that is within Structure OWNS ("script entry points, CLI argument shapes"). But two items in the post-code prose cross into DEFERS territory:

**Item A — Detection signal parentheticals (line 388):**
> Locked platform directory (verified at design time as of 2026-05-31): Copilot CLI **(COPILOT_CLI=1)** returns `llm-context`; Claude Code **(no COPILOT_CLI, system-reminder framing present)** returns `llm-context`; unknown host returns `user-override-only`.

The parenthetical fragments `(COPILOT_CLI=1)` and `(no COPILOT_CLI, system-reminder framing present)` specify the environment-variable signals and framing heuristics that the script uses internally to identify each platform. These are implementation details of the detection algorithm — not the interface outputs. The interface contract is "Copilot CLI → `DETECTION_TYPE=llm-context`"; *how* the script identifies Copilot CLI (`COPILOT_CLI=1` env var inspection) belongs in Plan/Implement.

**Item B — Orchestrator behavior prose (line 390):**
> Audit file: after each detection cycle, the orchestrator (exclusive writer) writes `<round-dir>/.interaction-mode-audit.json` with shape `{platform, detection_type, verdict, evidence}`. **For `shell-verdict` and `user-override-only` the orchestrator copies fields directly from script stdout; for `llm-context` the orchestrator derives verdict and evidence from its own context inspection.** Separate file from `.verifier-fan-in-audit.json` (different writer, different timing — round-start vs round-end).

The bolded sentence specifies how the orchestrator must process the script's output differently for each `DETECTION_TYPE` — a conditional processing algorithm. This is orchestrator implementation behavior, not the script's interface contract. The audit file path and schema (`{platform, detection_type, verdict, evidence}`) are OWNS (comparable to Interface §11's audit JSON schema). The orchestrator conditional logic — "copies fields directly" vs. "derives verdict and evidence from its own context inspection" — is implementation and belongs in Plan/Implement.

**Analogous R1 fix for reference.**  
R1 scope-claude-F01 flagged Interface §12 for pre-authoring the complete wording of `skills/_shared/verifier-filter-rule.md` and required collapsing to a placeholder. The same boundary applies here: Structure should declare the audit file path and schema but not author the orchestrator's per-DETECTION_TYPE processing logic.

**What Structure should do instead.**  

For Item A, strip the parenthetical detection signals and retain only the output mapping:
> Locked platform directory (verified at design time): Copilot CLI returns `DETECTION_TYPE=llm-context`; Claude Code returns `DETECTION_TYPE=llm-context`; unknown host returns `DETECTION_TYPE=user-override-only`. See design.md CD-4 §I.7 for full platform table.

For Item B, retain the audit file path/schema contract and drop the orchestrator logic sentence:
> Audit file: `<round-dir>/.interaction-mode-audit.json` with shape `{platform, detection_type, verdict, evidence}`. Separate from `.verifier-fan-in-audit.json` (different writer, different timing).

The orchestrator's per-DETECTION_TYPE field-derivation behavior belongs in the Plan/Implement authoring pass for `skills/using-qrspi/SKILL.md` (or whichever skill owns the audit-write procedure).

<!-- @@FINDING: scope-claude.finding-F02 @@ -->
---
finding_id: R2-F02
severity: medium
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
artifact: structure
line_range: [162, 391]
---

## OWNS gap — No interface contracts for `dispatch-companion.sh`, `await-round.sh`, or `third-party-finding-splitter.sh`

**What the artifact does.**  
The File Map (Slice 1.4, lines 60–96) lists three public scripts as Create actions:

| Script | Responsibility |
|---|---|
| `scripts/dispatch-companion.sh` | Launch vendor-specific third-party review jobs beneath the universal dispatcher |
| `scripts/await-round.sh` | Drain background reviewer jobs, finalize manifest state, and write round completion summaries |
| `scripts/third-party-finding-splitter.sh` | Split third-party stdout boundaries into per-finding files |

The `## Interfaces` section (lines 162–391) defines 13 numbered interface entries. None of the three scripts above has a dedicated entry.

**Why this is an OWNS gap.**  
Structure OWNS "Function/script exports and parameter shapes. Public function signatures, exported types, script entry points, CLI argument shapes — what the unit exposes at its boundary." All three scripts are non-underscored (public by naming convention), all are Create actions (newly introduced by this release), and all have distinct CLI surfaces invoked by downstream consumers:

- `dispatch-companion.sh` is invoked by `dispatch-agent.sh` to launch background third-party jobs and reappears as the `await_cmd` prefix in the dispatch manifest (Interface §10 example: `"scripts/dispatch-companion.sh await job-123"`). Its argument shapes, exit codes, and stdout format are unknown.
- `await-round.sh` is the post-dispatch drain step referenced in the shared verifier-dispatch-prose snippet (Slice 1.1 Responsibility: "`await-round.sh` follow-up"). It has no invocation signature anywhere in the Interfaces section — neither CLI shape nor exit codes.
- `third-party-finding-splitter.sh` appears in the dispatch manifest as the `split_cmd` value (Interface §10 example: `"scripts/third-party-finding-splitter.sh --round-dir /abs/path/reviews/plan/round-01"`), but the `--round-dir` argument is the only hint of its interface. Exit codes, success contract, and output paths are unspecified.

The analogous gap for `scripts/detect-interaction-mode.sh` was caught by R1 quality reviewers (R1-F04, severity high) because design.md CD-4 §I.7 had a detailed locked contract for it. The three scripts above likewise have public CLI surfaces that Plan/Implement will need interface contracts to work against.

**Partial coverage through Interface §10 is not sufficient.**  
Interface §10 (Dispatch manifest schema) embeds `dispatch-companion.sh` and `third-party-finding-splitter.sh` invocation examples as string values inside JSON. That shows invocation patterns incidentally, not as authoritative interface entries. `await-round.sh` is not present in Interface §10 at all. None of the three scripts has exit codes, output contracts, or argument-shape specifications.

**What Structure should add.**  
Three new Interfaces entries (or equivalent short-form contracts in the Section Contracts table) covering at minimum:

- CLI argument shape / required flags
- Exit code semantics (success / failure conditions)
- Stdout/side-effect outputs (e.g., what `await-round.sh` writes as a round completion summary; where `third-party-finding-splitter.sh` emits per-finding files)

Prose content under each script's implementation (what it does internally) remains DEFERS to Plan/Implement.

<!-- @@CLEAN: scope-codex.clean @@ -->
---
reviewer_tag: scope-codex
round: 2
status: clean
---
Zero scope/intent findings in structure.md round 02. The R1 fix round (which added `## Section Contracts` and `## Hook-Point Locations`, collapsed Interface §12, and corrected component placements) brought the artifact into compliance with Structure OWNS as amended by design.md G35 D2/D3. No further boundary drift detected.


---
verifier_enabled: true
scored: 11
kept: 8
dropped: 4
failed: 0
clean: 1
---

<!-- @@FINDING: quality-claude.finding-F01 @@ -->
---
artifact: structure
reviewer_tag: quality-claude
finding_id: R3-F01
round: 3
severity: medium
change_type: correctness
line_range: [556, 566]
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
---

## G25 absent from T1 (Unit tests) Feeds list despite having a unit test in the file map

### Location

`## Test Architecture` → `### T1 — Unit tests`, line 560:

```
Feeds: G6, G7, G8, G11, G13, G14, G16, G17, G19, G20, G21, G22, G23, G24, G26, G27, G28, G31, G32, G34, G35.
```

### Problem

G25 is absent from T1's Feeds list, but Slice 1.4's file map (line 93) assigns `tests/unit/test-config-model-routing.bats` to **G22, G23, G25** — all three goals together. G22 and G23 appear in the T1 feed list; G25 does not. This creates an asymmetry: two goals sharing the same unit test file are included, while the third is silently dropped from the test-type coverage taxonomy.

G25's design block (design.md lines 2091–2127) confirms that G25's executable enforcement is "a single bats smoke test invoking `dispatch-agent.sh` against a `config.md` fixture" — the same test pattern as `test-config-model-routing.bats`. The smoke test is classified as a CD-1 acceptance criterion but rides in the `tests/unit/` bucket per the file map assignment.

### Impact

An implementer constructing the T1 test gate will see G22 and G23 as required T1 coverage targets but will have no signal that G25 also belongs to T1. G25 is covered by T6 ("G1–G35") but T6 is the self-host run — losing the T1-level traceability means the goal's unit-gate coverage goes unverified before T6.

### Fix

Add `G25` to the T1 Feeds list at line 560, between `G24` and `G26` (to preserve numeric order):

```
Feeds: G6, G7, G8, G11, G13, G14, G16, G17, G19, G20, G21, G22, G23, G24, G25, G26, G27, G28, G31, G32, G34, G35.
```

<!-- @@SCORE: quality-claude.finding-F01.score @@ -->
score: 68
reason: Verified internal inconsistency — Slice 1.4 file map (line 93) assigns tests/unit/test-config-model-routing.bats to G22/G23/G25, but T1 Feeds (line 560) lists G22 and G23 and omits G25; trivial-fix correctness asymmetry in traceability, partially compensated by T6's G1–G35 sweep.

<!-- @@FINDING: quality-claude.finding-F02 @@ -->
---
artifact: structure
reviewer_tag: quality-claude
finding_id: R3-F02
round: 3
severity: high
change_type: correctness
line_range: [391, 408]
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
---

## Interface §14 misattributes `.dispatch-manifest.json` append to `dispatch-companion.sh` — design authority assigns it to `dispatch-agent.sh`

### Location

`## Interfaces` → `### 14. Dispatch companion script`, lines 406–408:

```bash
# Side effect (launch): appends {tag, mode: background, status: pending, await_cmd, split_cmd}
#                       entry to <round-dir>/.dispatch-manifest.json
```

### Problem

Interface §14 says `dispatch-companion.sh` (launch subcommand) has the side effect of appending the manifest entry to `.dispatch-manifest.json`. This contradicts design.md CD-1 §3 PATH B, which is an authoritative behavioral description of `dispatch-agent.sh`:

> "PATH B (third-party): invoke `dispatch-companion.sh` to launch background; **capture jobId**; **append entry to `.dispatch-manifest.json`** with `mode: background`, `status: pending`, `await_cmd`, `split_cmd`."

The grammatical subject of PATH B's entire bullet is `dispatch-agent.sh` (the universal entry point whose behavior CD-1 §3 is specifying). The sequence is:
1. `dispatch-agent.sh` invokes `dispatch-companion.sh` → launches background job
2. `dispatch-agent.sh` captures `jobId` from `dispatch-companion.sh`'s stdout
3. `dispatch-agent.sh` appends the manifest entry, constructing `await_cmd` and `split_cmd`

CD-1 §5's description of `dispatch-companion.sh` further confirms: it is a "vendor-routing tier underneath dispatch-agent … routes to vendor-specific transport" — no mention of manifest writing.

The `split_cmd` field (`"scripts/third-party-finding-splitter.sh --round-dir …"`) also supports this attribution: `dispatch-companion.sh` is vendor-transport-focused and has no reason to know about `third-party-finding-splitter.sh`; `dispatch-agent.sh` is the orchestrator-layer script that knows both the splitter and the round-dir.

### Impact

Interface §14 was added in R2 (disposition item 6). If implemented as specified, `dispatch-companion.sh` would own manifest-append logic that the design assigns to `dispatch-agent.sh`. This creates a dual-write risk and mis-scopes `dispatch-companion.sh`'s responsibilities. Plan/implementer tasks derived from structure.md will build the wrong ownership boundary into the two scripts.

### Fix

Remove the manifest-append side effect from Interface §14 and replace with the correct side effect:

```bash
# Side effect (launch): returns JOB_ID on stdout (consumed by dispatch-agent.sh, which
#                       appends the manifest entry to <round-dir>/.dispatch-manifest.json)
```

The manifest-append side effect belongs in Interface §3 (Universal dispatch CLI) or in `dispatch-agent.sh`'s description prose — not in §14.

<!-- @@SCORE: quality-claude.finding-F02.score @@ -->
score: 80
reason: Structure §14 attributes the `.dispatch-manifest.json` append side effect to `dispatch-companion.sh`, but design CD-1 §3 PATH B (whose grammatical subject is `dispatch-agent.sh` under its "Behavior:" loop) and CD-1 §5 (companion is "vendor-routing tier ... routes to vendor-specific transport") both assign manifest-append to `dispatch-agent.sh`; the contradiction is real, load-bearing for ownership boundaries, and will mis-implement two scripts.

<!-- @@FINDING: quality-codex.finding-F01 @@ -->
---
finding_id: R3-F01
severity: medium
change_type: correctness
referenced_files: [structure.md]
line_range: 104-129
---
Slice 1.5's file map omits `agents/qrspi-design-scope-reviewer.md`, even though the same artifact later treats that file as an implementation surface for G34 include wiring (`Hook-Point Locations`, lines 704-706). This leaves one design-required component outside the slice map, which weakens vertical-slice completeness and can cause planning/execution gaps.

<!-- @@SCORE: quality-codex.finding-F01.score @@ -->
score: 78
reason: Confirmed — Slice 1.5 file map omits agents/qrspi-design-scope-reviewer.md though structure.md lines 704-706 designate it as a required G34 !cat consumer, and the parallel Slice 1.6 entry for qrspi-structure-scope-reviewer.md (line 140) shows the intended pattern.

<!-- @@FINDING: quality-codex.finding-F02 @@ -->
---
finding_id: R3-F02
severity: medium
change_type: correctness
referenced_files: [structure.md]
line_range: 434-441
---
Interface 16 ("Third-party finding splitter") is not fully concrete on the zero-findings output contract: it says "writes NO_FINDINGS sentinel file" but does not specify the exact sentinel filename/path shape. Given this release's strict per-finding/clean-sentinel disk contract, this interface should name the exact emitted clean file path pattern to avoid implementation drift.

<!-- @@SCORE: quality-codex.finding-F02.score @@ -->
score: 45
reason: Real consistency gap — sibling interfaces in structure.md all name exact filenames (kept-findings.txt, .round-complete.json, <tag>.finding-FNN.md) while this one says only "NO_FINDINGS sentinel file"; legitimate Structure-altitude lock to add, but narrow practical impact since the fan-in script globs *.finding-F*.md and Plan could pin the sentinel name without contradicting Structure.

<!-- @@FINDING: scope-claude.finding-F01 @@ -->
---
finding_id: R3-F01
reviewer_tag: scope-claude
artifact: structure
change_type: scope
severity: minor
line_range: [546, 550]
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - .github/workflows/ci.yml
---

## Finding

**`## CI Pipeline` Build-sync gate bullet embeds implementation commands inside a section-list contract.**

### Location

`## CI Pipeline` → Build-sync gate bullet, lines 546–550.

```markdown
- **Build-sync gate inside PR CI**: after checkout and Node setup, run
  `node tools/build-plugin.mjs` and then
  `git diff --exit-code build/ .claude-plugin/marketplace.json`;
  any stale built tree or malformed `!cat` stops the PR.
  This is the G32 release-integrity gate.
```

### Why it drifts

Structure OWNS section-list contracts at **heading-level granularity, not prose content** (OWNS rule: "Which top-level sections each file must contain… Heading-level granularity, not prose content"). For `.github/workflows/ci.yml`, the three bullets correctly name three CI job/section boundaries (lint, build-sync gate, BATS execution shape). That naming is within OWNS.

The **Build-sync gate bullet body**, however, goes further:

- it specifies the exact commands to execute inside the job (`node tools/build-plugin.mjs`, `git diff --exit-code build/ .claude-plugin/marketplace.json`),
- it imposes the step ordering within the job ("after checkout and Node setup, run X and then Y"),
- it describes what the step does when it fails ("any stale built tree or malformed `!cat` stops the PR").

These are the **implementation steps inside a CI job body** — the plan/implement task spec for G32, not the section-list contract for the file. The other two bullets stay at the right level (they name the section and reference which test files or coverage it adds, without specifying job-body commands). This bullet breaks the pattern.

Counterpart note: the lint and BATS-shape bullets do reference specific test-file paths — that is consistent with OWNS "test file layout" — so those bullets are fine. Only the Build-sync gate bullet drifts.

### Required fix

Trim the Build-sync gate bullet to heading-level: name the job section and the property it validates (G32 build-sync integrity), remove the commands and step sequencing. The exact `node tools/build-plugin.mjs` + `git diff` invocation belongs in the Plan task spec for G32, Slice 1.7.

**Before (drift):**
```
- **Build-sync gate inside PR CI**: after checkout and Node setup, run
  `node tools/build-plugin.mjs` and then
  `git diff --exit-code build/ .claude-plugin/marketplace.json`; …
```

**After (within OWNS):**
```
- **Build-sync gate inside PR CI**: guards that the committed `build/`
  tree matches source; blocks PRs when the built plugin is stale or
  `!cat` expansion has drifted. G32 release-integrity gate.
```

<!-- @@FINDING: stitching-audit.finding-F01 @@ -->
---
finding_id: R3-F01
reviewer_tag: stitching-audit
severity: high
change_type: correctness
gap_class: missing-wiring
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
line_range: [195, 202]
---

# Interface §3 missing `--verifier-fanout` mode invocation form

## Gap description

Interface §3 ("Universal dispatch CLI") at structure.md lines 195–202 documents only the
**reviewer dispatch** invocation form of `scripts/dispatch-agent.sh`:

```bash
scripts/dispatch-agent.sh --step <step> --round <N> --output-dir <round-dir> \
  --artifact <artifact-name> \
  --agents tag1=agent-name-1,tag2=agent-name-2,... \
  [--task-branch <worktree-path> --implementer-commit <40-char-SHA>] \
  [--tier-override tag1=high,tag2=medium,...]
# Stdout: M lines of form: MODE=first_party TAG=<tag> SUBAGENT_TYPE=<agent-name> MODEL=<resolved-model> PROMPT_FILE=<absolute-path>
```

The `--verifier-fanout` mode is entirely absent from Interface §3. This mode is a first-class
CD-4 deliverable specified in design.md CD-4 §H (lines ~464–503), which locks a distinct
invocation form with a different argument set:

```bash
scripts/dispatch-agent.sh --verifier-fanout \
  --step <step> --round <N> --output-dir <round-dir> \
  [--tier-override <tier>]
```

The two modes differ significantly in semantics: `--agents` is not used; `--artifact` is
not used; the script auto-enumerates findings under `--output-dir` instead of taking an
explicit agent list. The stdout contract is also different: one spec line per **finding**
(not per reviewer tag).

## Why this is high severity

Interface §3 is the implementer's contract for `dispatch-agent.sh`. Without `--verifier-fanout`
in the interface, an implementer who reads only structure.md will build a script that handles
only reviewer dispatch. CD-4's verifier dispatch path — which eliminates the per-finding
orchestrator loop and is a core G12 acceptance criterion — will either be omitted entirely or
implemented inconsistently with the design.

CD-4 G12 acceptance criteria (design.md lines ~708) explicitly require:
> "`scripts/dispatch-agent.sh --verifier-fanout` exists and emits one spec line per finding"

The structure.md File Map row for `dispatch-agent.sh` in Slice 1.4 (line 60) also omits any
mention of the `--verifier-fanout` mode, listing only: "Universal batched dispatch entrypoint:
resolve tier/model, prepare rounds, write manifests, and emit first-party task specs." The
omission is consistent across both the file map row and Interface §3, meaning the implementer
has no structural.md signal that this mode exists.

## Stitching chain broken

The verifier fan-out forms a dedicated chain:

```
orchestrator → dispatch-agent.sh --verifier-fanout → spec lines (per finding)
→ parallel Task batch (one per spec line) → verifier sidecars
→ await-round.sh → verifier-fan-in.sh → kept-findings.txt
```

Without the `--verifier-fanout` mode in Interface §3, the seam between **orchestrator prose**
(which will call this mode per `skills/_shared/verifier-dispatch-prose.md`) and the
**script implementation** is broken: the prose calls a mode the implementer was never told
to build.

## Minimal-altitude fix

Add a second invocation block to Interface §3 documenting the `--verifier-fanout` form with:
- its distinct flag set (`--verifier-fanout`, `--step`, `--round`, `--output-dir`,
  `[--tier-override <tier>]`)
- its auto-enumeration behavior ("script globs `<round-dir>/*.finding-F*.md` to enumerate
  findings; `--agents` is not used")
- its stdout contract ("one spec line per finding: `MODE=first_party TAG=<reviewer-tag>.F<NN>
  SUBAGENT_TYPE=qrspi-finding-verifier MODEL=<resolved-model> PROMPT_FILE=<absolute-path>`")

Also extend the Slice 1.4 `dispatch-agent.sh` Create row responsibility to mention the
`--verifier-fanout` mode explicitly.

<!-- @@SCORE: stitching-audit.finding-F01.score @@ -->
score: 88
reason: Verified — design CD-4 §H and G12 acceptance lock the `--verifier-fanout` mode with a distinct invocation form and stdout contract, but structure.md Interface §3 (and the Slice 1.4 dispatch-agent.sh row) document only the reviewer-dispatch form, leaving a real stitching gap the implementer's interface contract will hit.

<!-- @@FINDING: stitching-audit.finding-F02 @@ -->
---
finding_id: R3-F02
reviewer_tag: stitching-audit
severity: high
change_type: correctness
gap_class: missing-wiring
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
line_range: [70, 70]
---

# `config.md` Modify row missing CD-4 §I.4 halt-response config fields

## Gap description

The `config.md` Modify row in Slice 1.4 (structure.md line 70) carries the responsibility:

> "Surface `model_routing`, `trusted_path`, and validator blocks consumed by universal dispatch."

This covers the CD-1 config additions. But design.md CD-4 §I.4 (lines ~578–585) adds two
further config fields that are NOT covered by this row:

```yaml
orchestrator_rescue: false        # default; opt-in for silent orchestrator-driven fixes
max_drift_per_round: 3            # default; counts friction events
```

These fields are load-bearing for the halt-response protocol specified in CD-4 §I.3. Their
absence from the `config.md` row means:
1. The implementer working from the file map may not know `config.md` needs these additions.
2. No test row references these fields — the CD-4 §I.6 acceptance criteria require testing
   the full `orchestrator_rescue × interaction-mode` behavior matrix, and the missing
   config row is the structural gap that surfaces that test-coverage gap too.

## Downstream dead-end

CD-4 §I.3 specifies a three-tier rescue layer (mechanical fix, interpretive fix, subagent
re-dispatch) gated on `orchestrator_rescue`. Without the config field in the file map:

- The `using-qrspi/SKILL.md` and `implement/SKILL.md` prose that references
  `orchestrator_rescue` will refer to a config field that no implementer was told to add.
- The CD-4 §I.4 fields have no upstream creator in the phase — they are dead-end inputs.

## Producer/consumer chain broken

```
config.md (orchestrator_rescue, max_drift_per_round)  ← NOT in file map
    ↓ consumed by
halt-response protocol in using-qrspi/SKILL.md + implement/SKILL.md
    ↓ gated by
scripts/verifier-fan-in.sh halt-response dispatch
```

The `orchestrator_rescue` field is also read by `config-validation-procedure.md` consumers
(the validation procedure should validate the type/domain of the new fields), but the
validation row at Interface §4 (`validators:` block) only shows `change_type_enum` and
`finding_schema_required` — not the new CD-4 fields.

## Minimal-altitude fix

Extend the Slice 1.4 `config.md` Modify row responsibility to include: "Add
`orchestrator_rescue` (default: false) and `max_drift_per_round` (default: 3) config fields
per CD-4 §I.4 for the halt-response protocol."

Optionally: update Interface §4 to show the full config block including the CD-4 §I.4
additions alongside the CD-1 additions.

<!-- @@SCORE: stitching-audit.finding-F02.score @@ -->
score: 80
reason: Confirmed missing-wiring gap — design.md CD-4 §I.4 mandates two config.md fields (orchestrator_rescue, max_drift_per_round) that the Slice 1.4 config.md row and Interface §4 omit, leaving CD-4's halt-response consumers without an upstream file-map producer.

<!-- @@FINDING: stitching-audit.finding-F03 @@ -->
---
finding_id: R3-F03
reviewer_tag: stitching-audit
severity: high
change_type: correctness
gap_class: missing-wiring
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
line_range: [12, 28]
---

# No test file row covers CD-4 §I halt-response protocol acceptance criteria

## Gap description

Design.md CD-4 §I (halt-response protocol, lines ~538–718) specifies an extensive set of
acceptance criteria (§I.6) that must be verified by tests. None of the test rows in the
Slice 1.1 or Slice 1.4 File Maps cover any part of this protocol.

### What §I.6 requires to be testable

Per design.md CD-4 §I.6, the halt-response behavior must be verified across:

1. **Halt-cause × mode matrix**: four halt causes (`drift_count > max_drift_per_round`,
   `hard-blocked`, `scope-exceeded`, `config-invalid`) × two interaction modes
   (`interactive`, `auto`) × two `orchestrator_rescue` values (`true`/`false`) =
   16 fixture combinations.

2. **Tier-rescue behaviors**: tier-1 (mechanical find-and-replace), tier-2 (interpretive
   cascade), tier-3 (sub-agent re-dispatch) must each fire correctly and must NOT fire when
   `orchestrator_rescue: false`.

3. **Interactive-mode menu**: six-option menu must render with correct options; each selection
   must produce the documented effect (Apply fix, Skip finding, Accept as-is, Flag for human,
   Enable rescue round-scoped, Enable rescue run-scoped).

4. **Auto-mode halt**: when `drift_count > max_drift_per_round` in auto mode, the pipeline
   must halt and produce a valid `.orchestrator-fixes.json` audit file.

5. **`.orchestrator-fixes.json` audit file**: the Interface §11 schema (structure.md lines
   308–335) covers the audit file schema, but no test row validates that the file is written,
   that its schema is valid, and that `drift_count` appears in the expected fields.

### Current Slice 1.1 test rows

The existing test rows in Slice 1.1 (structure.md lines 25–27) cover:
- `tests/unit/test-verifier-dispatch.bats` — CD-4 verifier dispatch mode (G8, G13)
- `tests/unit/test-verifier-sidecar.bats` — verifier sidecar output (G11, G14)

Neither test file covers the halt-response protocol. The halt-response is downstream of
verifier dispatch — the `verifier-fan-in.sh` output gates the halt-response — but no test
file maps to the halt-response path at all.

## Stitching gap

The full verifier chain in structure.md (Architectural Diagram lines 456–530) shows:

```
verifier-fan-in.sh → [halt-response logic] → orchestrator-fixes.json / interactive menu
```

The upstream tests (verifier dispatch, sidecar extension) end at `verifier-fan-in.sh`'s
inputs. The downstream behavior — the halt-response logic, the rescue tiers, the
`drift_count` / `orchestrator_rescue` gate — has no test row. This creates a structural gap
where the most user-visible behavior (pipeline halt, interactive menu, automated rescue)
will enter implementation with zero specified test coverage.

## No R1/R2 coverage

R1 added `test-verifier-dispatch.bats` and `test-verifier-sidecar.bats` rows.
R2 made no further test additions. Neither round addressed halt-response testing.

## Minimal-altitude fix

Add a test file row in Slice 1.1 (the slice that owns verifier fan-in):

```
| `tests/integration/test-halt-response.bats` | Create | Test halt-response protocol:
  drift_count threshold gate, orchestrator_rescue × interaction-mode matrix,
  interactive menu options, auto-mode halt, `.orchestrator-fixes.json` schema.
  Fixture coverage per CD-4 §I.6. | G12, G13 |
```

The integration rather than unit placement is appropriate because the test must wire together
`verifier-fan-in.sh` output, config loading, and the halt-response dispatch path.

<!-- @@SCORE: stitching-audit.finding-F03.score @@ -->
score: 65
reason: Real stitching gap — design.md CD-4 §I.6 enumerates ~7 explicit acceptance criteria for the halt-response protocol (drift_count gates, tier-1/2/3 rescue, interactive menu, auto-mode halt, .orchestrator-fixes.json schema, round-vs-run-scoped "Enable rescue") yet no Slice 1.1/1.2/1.4 File Map test row carries any of them; the Test Architecture cross-cutting "CD-4 — T2 + T3" invariant assigns test types but names no file, while every other Slice 1.1 row names concrete .bats files, so the omission is genuinely at Structure's file-enumeration altitude, though one could argue test-phase1-acceptance.bats modification implicitly absorbs it.

<!-- @@FINDING: stitching-audit.finding-F04 @@ -->
---
finding_id: R3-F04
reviewer_tag: stitching-audit
severity: medium
change_type: correctness
gap_class: missing-wiring
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
line_range: [20, 50]
---

# `verifier-dispatch-prose.md` consumer SKILL.md Modify rows missing `!cat` include wiring

## Gap description

`skills/_shared/verifier-dispatch-prose.md` is created in Slice 1.1 (structure.md line 20)
with the explicit purpose:

> "Hold the shared verifier dispatch prose snippet … consumed by `using-qrspi/SKILL.md`
> and `implement/SKILL.md`."

The Hook-Point Locations section (structure.md lines 689–696) specifies the exact include
sites:

| Consumer file | Include-site heading |
|---|---|
| `skills/using-qrspi/SKILL.md` | artifact-level Apply-fix protocol section |
| `skills/implement/SKILL.md` | task-level Apply-fix protocol section |

However, **neither of the Modify rows for these two SKILL.md files mentions the `!cat`
include**:

- `skills/using-qrspi/SKILL.md` Slice 1.2 (line 36): "Define round instrumentation,
  sub-threshold observation logging, and verifier-visible audit surfaces." ← No `!cat`
- `skills/using-qrspi/SKILL.md` Slice 1.4 (line 69): "Carry the unified five-tier
  `model_routing:` schema, host matrix, validation rows, and fail-loud invariant prose."
  ← No `!cat`
- `skills/implement/SKILL.md` Slice 1.3 (line 50): "Require `round-prepare` outputs and
  scope-tagger/fan-in artifacts on each per-task review cycle." ← No `!cat`
- `skills/implement/SKILL.md` Slice 1.4 (line 85): "Adopt shared reviewer dispatch and pass
  per-task tier overrides into implementer/test-writer fan-out." ← No `!cat`

## Asymmetry with CD-1 reviewer-dispatch-prose

This is a direct structural asymmetry. For the analogous CD-1 shared snippet
(`skills/_shared/reviewer-dispatch-prose.md`), every consumer SKILL.md's Modify row
explicitly calls out "Replace inline reviewer-dispatch prose with a thin preamble plus shared
include." The R1 round applied this pattern consistently across 12 consumer skills.

The CD-4 `verifier-dispatch-prose.md` has only **2** consumers (much simpler), yet neither
consumer's Modify row mentions the include. This asymmetry means:

1. An implementer modifying `using-qrspi/SKILL.md` for Slice 1.2 (G20/G28/G29 scope) will
   add round instrumentation prose but won't know to insert the `!cat` include.
2. An implementer modifying `using-qrspi/SKILL.md` for Slice 1.4 (G3/G22 scope) will add
   model-routing schema but won't know to insert the `!cat` include.
3. The build step (`tools/build-plugin.mjs`, Slice 1.4) will encounter a missing `!cat`
   include site in these SKILL.md files and produce incomplete built output.

## Dead-end output

`skills/_shared/verifier-dispatch-prose.md` will be **created** (Slice 1.1) but never
**included** anywhere, because neither consumer Modify row wires the include. This is a
dead-end output for the created file.

## Minimal-altitude fix

Add a single sentence to one of each consumer's Modify rows (either the existing row or a
new dedicated row) calling out the include:

- `skills/using-qrspi/SKILL.md` Slice 1.2 or Slice 1.4 row: append "Add
  `!cat skills/_shared/verifier-dispatch-prose.md` at the Apply-fix protocol section per
  CD-4/G12 Hook-Point Locations."
- `skills/implement/SKILL.md` Slice 1.3 or Slice 1.4 row: append "Add
  `!cat skills/_shared/verifier-dispatch-prose.md` at the task-level Apply-fix protocol
  section per CD-4/G12 Hook-Point Locations."

The Slice 1.3/1.4 rows are the better candidates because they are the ones closest in
concern (reviewer dispatch / fan-in) to the verifier prose content.

<!-- @@SCORE: stitching-audit.finding-F04.score @@ -->
score: 40
reason: Real CD-1/CD-4 Modify-row asymmetry, but the include wiring is canonically locked in the Hook-Point Locations table (lines 689–696), so "dead-end output" overstates the gap; remaining issue is cross-referencing consistency.

<!-- @@FINDING: stitching-audit.finding-F05 @@ -->
---
finding_id: R3-F05
reviewer_tag: stitching-audit
severity: medium
change_type: correctness
gap_class: missing-wiring
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
line_range: [57, 97]
---

# `_shared/codex/launch-await-pattern.md` vendor-neutrality rename missing from file map

## Gap description

Design.md CD-1 "Rename inventory" (line 201) specifies:

> `_shared/codex/launch-await-pattern.md` → `_shared/third-party/launch-await-pattern.md`

This rename is part of the vendor-neutrality wave that removes the `codex/` namespace from
shared snippets (the same wave also renames `_shared/codex/` dispatcher files to
`_shared/third-party/`). The rename is co-shipped with CD-1.

Structure.md Slice 1.4 (lines 57–97) is the slice that carries the vendor-neutrality rename
rows for the `codex/` → `third-party/` migration (consistent with the CD-1 File Map
description on structure.md lines 57–60). Slice 1.4 contains 37 file rows, none of which is
a Rename row for `skills/_shared/codex/launch-await-pattern.md`.

## Compound gap: G32 also touches this file

The file is referenced twice more in design.md in G32 context:

- Line 2724: "update `skills/_shared/codex/launch-await-pattern.md` line 45 — change the
  `<!-- Embedded via: ... -->` comment to the bare-relative convention."
- Line 2791/2841: "The 2 existing legacy sites (`goals/SKILL.md:8` directive +
  `_shared/codex/launch-await-pattern.md:45` comment) are converted to the bare form as a
  co-shipped cleanup before G32 ships."

G32 requires a content edit to the file AND the CD-1 rename renames the file. Structure.md
should have:
1. A **Rename** row in Slice 1.4: `skills/_shared/codex/launch-await-pattern.md` →
   `skills/_shared/third-party/launch-await-pattern.md`
2. A **Modify** row (possibly in Slice 1.4 or Slice 1.5 alongside the G32 build pipeline
   rows) to update line 45's comment from the Claude-coupled form to the bare-relative form.

Neither row is present.

## Downstream impact

Without the rename row:
- The G32 content-edit row (if added) would target the old path, causing implementers to
  try to edit a file that has not been renamed.
- Any `!cat`-include or `source` reference to the old path (`skills/_shared/codex/launch-await-pattern.md`)
  will be a stale reference post-rename; consumers need to be updated. Without a rename row
  in the structure, the implementer has no signal to audit consumers.

Design.md G32 line 2841 states this as a G32 acceptance criterion:
> "Repo-wide grep for `${CLAUDE_SKILL_DIR}` returns zero hits in shipped files."

This criterion requires the rename + content edit to have been performed. With no file map
row, this criterion will be unmeetable.

## Minimal-altitude fix

Add two rows to Slice 1.4:

```
| `skills/_shared/codex/launch-await-pattern.md` | Rename →
  `skills/_shared/third-party/launch-await-pattern.md` | Vendor-neutrality rename per
  CD-1 rename inventory. | G3 |
```

And add a Modify row in Slice 1.4 or Slice 1.5:

```
| `skills/_shared/third-party/launch-await-pattern.md` | Modify | Update line 45 comment
  from Claude-coupled `${CLAUDE_SKILL_DIR}` form to bare-relative form per G32 co-shipped
  cleanup. | G32 |
```

<!-- @@SCORE: stitching-audit.finding-F05.score @@ -->
score: 75
reason: Verified — `launch-await-pattern.md` is in CD-1's rename inventory (design.md:201) and explicitly named in G32's acceptance criterion (design.md:2841) for the `${CLAUDE_SKILL_DIR}` cleanup, yet no row for either the old or renamed path appears in Slice 1.4 (or anywhere in structure.md); peer renames like `dispatch-agent.sh` do appear, making this a genuine omitted stitching row.

<!-- @@FINDING: stitching-audit.finding-F06 @@ -->
---
finding_id: R3-F06
reviewer_tag: stitching-audit
severity: medium
change_type: correctness
gap_class: missing-wiring
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
line_range: [88, 91]
---

# All-41-agents schema migration has only 4 representative rows; 37 agents unrepresented

## Gap description

Design.md CD-1 "Schema migrations" (lines ~189–215) requires two changes applied to
**all 41 agent files**:

1. **`tier:` frontmatter field** — every agent gains a `tier:` key (e.g., `tier: standard`
   or `tier: high`) so universal dispatch can route model selection.
   Acceptance criterion: "Agent frontmatter lint: every agent has `tier:` field."

2. **DISPATCH_FILE first-action instruction** — every reviewer agent body
   (`agents/qrspi-*-reviewer.md`) gains the instruction: "**Read your `DISPATCH_FILE`
   as your full dispatch before doing anything else.**"
   Acceptance criterion: "Every reviewer agent body (`agents/qrspi-*-reviewer.md`) carries
   the first-action instruction."

The file map in Slice 1.4 (structure.md lines 88–91) has Modify rows for **4 agents**:

| File | Responsibility |
|---|---|
| `agents/qrspi-implementer.md` | "Add the orchestrator-only-script allowlist and universal `DISPATCH_FILE` first-action pattern." |
| `agents/qrspi-code-quality-reviewer.md` | "Add `tier:` frontmatter and dispatch-file first action on a representative reviewer body." |
| `agents/qrspi-plan-reviewer.md` | "Add `tier:` frontmatter and dispatch-file first action on a plan reviewer body." |
| `agents/qrspi-test-writer.md` | "Add `tier:` frontmatter so test-writer dispatch co-escalates with implementer dispatch." |

The phrase "on a **representative** reviewer body" (line 89) makes the intended scope clear:
this is one example to illustrate the pattern, not the full sweep. There are 41 agents
on disk (`agents/qrspi-*.md`), and ~32 are reviewer agents (names containing `-reviewer`,
plus related agents like `qrspi-scope-tagger`, `qrspi-finding-verifier`, etc.).
The remaining 37 agents have no Modify row.

## Missing wiring: no schema-migration sweep row

G2 (schema migration task shape) establishes the pattern for bulk agent sweeps — a row with
`sizing_exception: schema migration` covering all affected files with a shared change. No
such row exists for the tier-frontmatter + DISPATCH_FILE first-action sweep.

The acceptance criteria cited in CD-1 ("every agent has `tier:`", "every reviewer body
carries the first-action instruction") will **not pass** if only 4 agents are modified.

## Stitching impact

The universal dispatch chain is:

```
orchestrator calls dispatch-agent.sh --agents tag1=qrspi-code-simplifier,...
→ dispatch-agent.sh reads agent frontmatter: agent[tier]
→ resolves model per tier
→ emits spec line with MODEL=<resolved>
```

If `qrspi-code-simplifier.md` lacks `tier:` frontmatter, `dispatch-agent.sh`'s tier
resolution will hit a missing-key path. Whether this silently defaults or fails-loud depends
on implementation — but the correct behavior per CD-1 is that every agent **has** the field
so the default path is never exercised.

Similarly, if a reviewer agent body lacks the DISPATCH_FILE first-action instruction and the
orchestrator dispatches it via the PROMPT_FILE mechanism (writing the prompt to a temp file),
the reviewer will see an empty or templated prompt and produce garbage findings.

## Minimal-altitude fix

Add a schema-migration Modify row to Slice 1.4 covering all agents:

```
| `agents/qrspi-*.md` (all 41 files) | Modify — schema migration | Add `tier:` frontmatter
  (value per G22 model-routing table) to every agent; add DISPATCH_FILE first-action
  instruction to every reviewer agent body (`agents/qrspi-*-reviewer.md`). Batch change;
  no behavioral logic. | G22 |
```

The 4 existing representative rows can remain as-is for documentation value (they include
richer responsibilities beyond the schema sweep), but the sweep row must exist to drive
complete implementation.

<!-- @@SCORE: stitching-audit.finding-F06.score @@ -->
score: 78
reason: Structure file map's 4 explicitly-"representative" agent rows omit ~37 other agents required by design.md CD-1's "every agent has tier:" and "every reviewer body carries DISPATCH_FILE first-action" acceptance criteria; no sweep row exists, so Plan would under-generate tasks.

<!-- @@FINDING: stitching-audit.finding-F07 @@ -->
---
finding_id: R3-F07
reviewer_tag: stitching-audit
severity: medium
change_type: correctness
gap_class: unanswered-question
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
line_range: [308, 441]
---

# `split_cmd` / splitter interface seam: per-entry command vs. round-dir-only argument

## Gap description

The dispatch manifest (Interface §10, structure.md lines 308–335) stores a `split_cmd` field
per background manifest entry:

```json
"split_cmd": "scripts/third-party-finding-splitter.sh --round-dir /abs/path/reviews/plan/round-01"
```

`await-round.sh` (Interface §15, line 423) calls this command "per resolved entry":
> "invokes split_cmd (third-party-finding-splitter.sh) per resolved entry to materialize
> per-finding files"

The splitter (Interface §16, lines 432–441) accepts only one argument:
```bash
scripts/third-party-finding-splitter.sh --round-dir <abs-round-dir>
```

Its side-effect description (line 439) is:
> "writes `<round-dir>/<tag>.finding-F<NN>.md` for each `<<<FINDING-BOUNDARY>>>` block"

The `<tag>` in the output path implies the splitter is tag-aware, yet the CLI has no
`--tag` argument. There is no `--input-file` argument either. The only way the splitter
can be tag-aware is if it discovers the tag from somewhere inside the round-dir — but no
interface specifies how.

## The seam mismatch

`await-round.sh` calls `split_cmd` once **per resolved entry**. In a round with two
background entries (e.g., `quality-codex` and `quality-gpt`):

1. Entry 1 (`quality-codex`) resolves. `await-round.sh` calls `split_cmd` for entry 1.
   The splitter runs with `--round-dir`; it finds `.dispatch/quality-codex.raw` and
   writes `quality-codex.finding-F01.md`, `quality-codex.finding-F02.md`, etc. ✓

2. Entry 2 (`quality-gpt`) resolves. `await-round.sh` calls `split_cmd` for entry 2.
   The splitter runs with the same `--round-dir` with no per-entry discriminator. What
   does it process? If it re-processes all `.raw` files in the round-dir (including
   `.dispatch/quality-codex.raw`), it double-writes `quality-codex.finding-F*.md` files.
   If it has state (tracks which `.raw` files were already processed), that state mechanism
   is undocumented.

The two interfaces are inconsistent:
- Interface §14/§10: `split_cmd` is a per-entry field with no tag or input-file in the
  command string.
- Interface §15: split_cmd is invoked "per resolved entry."
- Interface §16: the splitter has only `--round-dir` with no per-entry identifier.

Either the "per resolved entry" description in §15 is wrong (the splitter should be called
once at the end of the round, not per entry), or the splitter needs a `--tag` or
`--input-file` argument, or `split_cmd` should include the specific `.raw` file path.

## Why this is an unanswered-question rather than seam-mismatch

The three interfaces together could be internally consistent if the intended semantics are
one of:

(a) **Per-entry, tag-discriminated**: `split_cmd` stored per entry would include
    `--tag quality-codex` but this is not shown in Interface §10's example. The splitter
    would read `<round-dir>/.dispatch/<tag>.raw` and write only that tag's findings.
    This is the cleanest design but requires `--tag` in Interface §16.

(b) **Per-entry, all-unprocessed**: the splitter processes all `.raw` files not yet split
    (using a marker file or inode check). Multiple calls are idempotent because the splitter
    skips already-split files. This requires a documented state-tracking mechanism.

(c) **Round-level, called once**: `await-round.sh` calls `split_cmd` once after **all**
    entries resolve. The "per resolved entry" prose in §15 is incorrect. This would mean
    every entry stores the same `split_cmd` string and only the first invocation runs (or
    await-round.sh deduplicates before calling). This is simpler but contradicts §15's prose.

None of these is currently specified. The gap is real because an implementer of the splitter
cannot determine from Interface §16 alone which semantics to implement, and an implementer
of `await-round.sh` cannot determine from §15 alone whether to call `split_cmd` once or N
times.

## Minimal-altitude fix

Add a clarifying sentence to Interface §16 stating explicitly which of the three semantics
applies. For option (a), also add `[--tag <reviewer-tag>]` to the CLI spec and update the
Interface §10 `split_cmd` example to include `--tag quality-codex`. For option (c), change
§15's "per resolved entry" to "once after all entries resolve."

The `<tag>` in Interface §16's side-effect description (line 439) — `<tag>.finding-F<NN>.md`
— implies option (a) is the intended design (the splitter is tag-aware); the fix would be
to add `--tag` to the Interface §16 CLI spec and to the §10 `split_cmd` example.

<!-- @@SCORE: stitching-audit.finding-F07.score @@ -->
score: 72
reason: Verified seam mismatch — Interface §10's split_cmd example and §16's CLI spec take only --round-dir, but §15 invokes it per-entry and §16's output path embeds `<tag>`, leaving the splitter with no way to discriminate which entry it is processing; this is a real, actionable gap at Structure altitude.

<!-- @@CLEAN: scope-codex.clean @@ -->
---
reviewer_tag: scope-codex
round: 3
status: clean
---

# Scope-codex review — Round 3 — CLEAN

No scope/boundary violations detected. Structure.md content in R3 stays within the structure step's owned territory:
- File map (Slices 1.1–1.7), interfaces (1–16), architectural diagram (G35 D2 authority), CI pipeline, test architecture (G35 D3 authority), section contracts, hook-point locations.
- No design content (no decision-driver rationale, no option scoring, no acceptance-criteria authoring); no plan content (no per-task specs, no LOC budgets, no dependency edges).
- The §"Architectural Diagram", §"Test Architecture", §"Section Contracts", §"Hook-Point Locations" sections are sanctioned by G35 D2/D3 as the structure step's responsibility for v0.7.2.


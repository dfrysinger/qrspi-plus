---
verifier_enabled: true
scored: 12
kept: 14
dropped: 2
failed: 0
clean: 0
---

<!-- @@FINDING: quality-claude.finding-F01 @@ -->
---
finding_id: R1-F01
artifact: structure
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
---

## Missing component: `skills/_shared/evergreen-output-rule.md` absent from file map

### What is missing

`skills/_shared/evergreen-output-rule.md` is not listed as a Create action in any slice
of structure.md's file map. CD-2 in the approved design.md explicitly requires creation
of this file as the single source of truth for the Evergreen-Output Rule. Nine consumer
SKILL.md files are specified to `!cat`-include it:

- `skills/goals/SKILL.md`
- `skills/questions/SKILL.md`
- `skills/research/SKILL.md`
- `skills/design/SKILL.md`
- `skills/structure/SKILL.md`
- `skills/phasing/SKILL.md`
- `skills/plan/SKILL.md`
- `skills/parallelize/SKILL.md`
- `skills/replan/SKILL.md`

### Why this is a problem

Without a file-map entry for this snippet, Plan phase has no task to create it.
The nine consumer skills are all present in the file map with "Modify" entries, but
their `!cat` includes will point to a file that was never created. All nine consumers
depend on a single shared file that structure.md is silent about.

CD-2's acceptance criteria include a lint check (`grep -rln "evergreen-output-rule.md"
skills/` returns 9 hits) — that check will always fail if the file's creation is never
scheduled. This is also a YAGNI-inverse violation: nine file-map entries describe a
dependency on a component that has no corresponding Create entry.

### Expected fix

Add a Create entry for `skills/_shared/evergreen-output-rule.md` to Slice 1.5 (Skill
prose & interactive dialog quality) with goal IDs covering CD-2's consumer set. CD-2
spans all 9 artifact-producing skills, which are exactly the files Slice 1.5 touches.
Suggested table row:

| `skills/_shared/evergreen-output-rule.md` | Create | Hold the single Evergreen-Output Rule snippet consumed by all nine artifact-producing skills via `!cat`. | CD-2 |
<!-- @@SCORE: quality-claude.finding-F01.score @@ -->
score: 90
reason: Verified — CD-2 in design.md explicitly requires creating skills/_shared/evergreen-output-rule.md with 9 consumer skills `!cat`-including it, but structure.md's file map has no Create entry (conspicuous absence alongside peer shared snippets that ARE listed), which would leave Plan with no task to create the file and break all 9 consumer includes.

<!-- @@FINDING: quality-claude.finding-F02 @@ -->
---
finding_id: R1-F02
artifact: structure
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
---

## Missing component: `skills/_shared/multi-actor-flow-check.md` absent from file map

### What is missing

`skills/_shared/multi-actor-flow-check.md` is not listed as a Create action in any
slice of structure.md's file map. CD-3 (Multi-Actor Flow Check) in the approved
design.md requires creation of this shared snippet, which must be `!cat`-included into
exactly four SKILL.md consumer files:

- `skills/structure/SKILL.md`
- `skills/plan/SKILL.md`
- `skills/parallelize/SKILL.md`
- `skills/implement/SKILL.md`

CD-3 acceptance criteria include the lint check: `grep -rln "multi-actor-flow-check.md"
skills/` must return exactly 4 SKILL.md files plus the source file (5 total). That lint
check permanently fails if the file's creation is never scheduled.

### Why this is a problem

All four consumer SKILL.md files are present in the file map with Modify entries.
Their `!cat` directives will reference a file that was never created. The four checks
are a layered defense (each consumer runs the check independently per CD-3's
"Redundancy is the layered defense" contract). Without the source snippet, all four
layers silently disappear.

CD-3 is a cross-cutting design decision in the approved design.md; it is not tagged
to a specific goal ID because it resolves a pattern rather than a discrete goal.
Structure.md carries no Create entry covering it.

### Expected fix

Add a Create entry for `skills/_shared/multi-actor-flow-check.md` to Slice 1.5
(Skill prose & interactive dialog quality), alongside the four Modify entries for its
consumers. Suggested table row:

| `skills/_shared/multi-actor-flow-check.md` | Create | Hold the single Multi-Actor Flow Check snippet `!cat`-included into structure, plan, parallelize, and implement SKILL.md files. | CD-3 |

If no goal ID column is appropriate for cross-cutting design decisions, CD-3 is the
correct attribution (or a new "CD" column could be added, though aligning to the
nearest in-scope goal cluster is simpler: G9, G15, G18 all depend on plan/implement
consuming this check correctly).
<!-- @@SCORE: quality-claude.finding-F02.score @@ -->
score: 85
reason: Verified — CD-3 in approved design.md mandates creation of `skills/_shared/multi-actor-flow-check.md` with a grep-lint expecting the source file plus 4 consumers, but structure.md's file map (all 7 slices) contains no Create entry for it while listing the four consumer SKILL.md Modify entries, mirroring exactly how peer CD shared snippets (verifier-filter-rule.md, design-altitude-boundary.md, structure-altitude-boundary.md) ARE listed; high-severity correctness gap in the file map.

<!-- @@FINDING: quality-claude.finding-F03 @@ -->
---
finding_id: R1-F03
artifact: structure
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
---

## Missing component: `skills/_shared/verifier-dispatch-prose.md` absent from file map

### What is missing

`skills/_shared/verifier-dispatch-prose.md` is not listed as a Create action in any
slice of structure.md's file map. CD-4 component H in the approved design.md explicitly
requires this file:

> **Shared dispatch prose snippet — `skills/_shared/verifier-dispatch-prose.md`.**
> Mirror of `skills/_shared/reviewer-dispatch-prose.md` (CD-1 §11). Carries the
> `dispatch-agent.sh --verifier-fanout` invocation, the spec-line iteration contract,
> and the `await-round.sh` follow-up. `!cat`-included into every consumer skill that
> runs verification (`using-qrspi/SKILL.md` artifact-level Apply-fix protocol;
> `implement/SKILL.md` task-level Apply-fix protocol).

The G12 acceptance criteria in design.md additionally state:

> `skills/_shared/verifier-dispatch-prose.md` exists and is `!cat`-included into both
> `using-qrspi/SKILL.md` (artifact-level Apply-fix protocol) and `implement/SKILL.md`
> (task-level Apply-fix protocol).

That acceptance check will permanently fail if the snippet is never scheduled for
creation.

### Why this is a problem

`skills/using-qrspi/SKILL.md` and `skills/implement/SKILL.md` are both in the file map
with Modify entries (Slices 1.2 and 1.3). Both need to adopt the `!cat` include for
the verifier dispatch prose. Without a Create entry for the source file, neither
consumer can satisfy CD-4's DRY requirement — they would have to inline the
`--verifier-fanout` invocation prose independently, re-introducing exactly the drift
pattern CD-4 and G12 were designed to eliminate.

The reviewer-dispatch-prose snippet (`skills/_shared/reviewer-dispatch-prose.md`) IS
in the file map (Slice 1.4, Create). Its symmetric verifier counterpart is absent.

### Expected fix

Add a Create entry for `skills/_shared/verifier-dispatch-prose.md` to Slice 1.1
(Apply-fix / verifier backbone) or Slice 1.2 (Verifier rubric calibration +
instrumentation), alongside the other verifier infrastructure. Suggested table row:

| `skills/_shared/verifier-dispatch-prose.md` | Create | Hold the shared verifier dispatch prose snippet (`dispatch-agent.sh --verifier-fanout` invocation + spec-line contract + `await-round.sh` follow-up) consumed by `using-qrspi/SKILL.md` and `implement/SKILL.md`. | G12 |
<!-- @@SCORE: quality-claude.finding-F03.score @@ -->
score: 85
reason: Verified — design.md CD-4 component H (line 494) and G12 acceptance (line 708) explicitly require `skills/_shared/verifier-dispatch-prose.md`, but structure.md's file map contains no Create entry for it (while the symmetric `reviewer-dispatch-prose.md` is present in Slice 1.4), so G12 acceptance will fail.

<!-- @@FINDING: quality-claude.finding-F04 @@ -->
---
finding_id: R1-F04
artifact: structure
severity: high
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
---

## Missing component: `scripts/detect-interaction-mode.sh` absent from file map and Interfaces

### What is missing

`scripts/detect-interaction-mode.sh` is not listed in any slice of structure.md's
file map, and its CLI contract does not appear in the `## Interfaces` section.

CD-4 §I.7 of the approved design.md locks a complete, named contract for this script,
including:

- A specific output format (KEY=VALUE pairs on stdout, one per line)
- Three distinct output shapes keyed on `DETECTION_TYPE`:
  - `shell-verdict` (PLATFORM, DETECTION_TYPE, VERDICT, EVIDENCE)
  - `llm-context` (PLATFORM, DETECTION_TYPE, INSTRUCTION)
  - `user-override-only` (DETECTION_TYPE, safe-default `interactive`)
- Exit codes: 0 on successful detection; nonzero only on internal script error
- An implementation-start verification procedure (Iron Law — direct runtime
  observation is mandatory before locking the Copilot-CLI / Claude-Code branches)

The design also carries a locked per-host directory table (verified at design time)
mapping host discriminators to their auto-mode signal and output shape. This is
load-bearing infrastructure for CD-4 §I's halt-response protocol: the orchestrator's
rescue behavior matrix (`orchestrator_rescue` × interaction mode) branches on the
verdict this script returns.

### Why this is a problem

Without a file-map entry, Plan phase will not schedule a task to create this script.
The halt-response protocol (CD-4 §I.1–I.6) is the design's resolution of how to
handle verifier-fan-in halt causes under the two interaction modes. Both modes
(interactive and auto) depend on the orchestrator correctly detecting auto vs.
interactive — which is entirely delegated to `scripts/detect-interaction-mode.sh`
per CD-4 §I.7's "script-encapsulated platform directory" design decision. Without
the script, every halt cause effectively becomes an unclassified escalation, and
the `orchestrator_rescue` config field becomes untestable.

The Interfaces section currently defines 12 interfaces. CD-4 §I.7's contract for
`scripts/detect-interaction-mode.sh` is equally concrete (specific output format
with locked shapes, exit-code semantics) as the other script interfaces defined in
`## Interfaces`. Its absence from that section means the downstream skills (Plan,
Implement) have no interface specification to implement against.

### Expected fix

**File map:** Add a Create entry to Slice 1.1 or Slice 1.2 (whichever carries the
verifier halt-response protocol work):

| `scripts/detect-interaction-mode.sh` | Create | Encapsulate per-host auto-mode detection; return shell-verdict, llm-context instruction, or user-override-only signal depending on the active host. | CD-4 |

**Interfaces section:** Add Interface #13 (or renumber as appropriate) for this
script, using the contract format locked in CD-4 §I.7:

```text
# scripts/detect-interaction-mode.sh
# Usage: detect-interaction-mode.sh (no arguments)
# Exit 0: detection succeeded (including safe-default branch)
# Exit non-zero: internal script error only
# Stdout: KEY=VALUE pairs, one per line; DETECTION_TYPE ∈ {shell-verdict, llm-context, user-override-only}
# shell-verdict: PLATFORM=<name> DETECTION_TYPE=shell-verdict VERDICT=auto|interactive EVIDENCE=<signal>
# llm-context:  PLATFORM=<name> DETECTION_TYPE=llm-context INSTRUCTION=<prose>
# user-override-only: DETECTION_TYPE=user-override-only
```
<!-- @@SCORE: quality-claude.finding-F04.score @@ -->
score: 85
reason: Confirmed — CD-4 §I.7 of design.md locks a named contract for `scripts/detect-interaction-mode.sh` (KEY=VALUE stdout, three DETECTION_TYPE shapes, exit codes, locked platform directory, Iron-Law verification procedure), but the script is absent from every slice's file map and from the 12 Interfaces; without a file-map entry Plan will not schedule its creation, and the entire halt-response protocol (CD-4 §I.1–I.6) loses its auto/interactive discrimination.

<!-- @@FINDING: quality-claude.finding-F05 @@ -->
---
finding_id: R1-F05
artifact: structure
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
---

## Duplicate "Create" action for `scripts/dispatch-agent.sh` across Slice 1.2 and Slice 1.4

### What is wrong

`scripts/dispatch-agent.sh` appears with a **Create** action in two separate slices:

- **Slice 1.2** (Verifier rubric calibration + instrumentation):
  > `scripts/dispatch-agent.sh` | Create | Persist resolved host/vendor/model metadata
  > into the dispatch manifest for later observability. | G20, G29

- **Slice 1.4** (Dispatch infrastructure):
  > `scripts/dispatch-agent.sh` | Create | Universal batched dispatch entrypoint:
  > resolve tier/model, prepare rounds, write manifests, and emit first-party task specs.
  > | G3, G4, G16, G22, G23, G25, G27

A file can only be created once. Having "Create" in two different slices is ambiguous:
Plan will either create the file in Slice 1.2 tasks (with only the G20/G29
instrumentation responsibility) and then face a conflict when Slice 1.4 tries to
Create it again, or Plan will interpret one entry as canonical and silently ignore
the other's responsibility description — causing G20/G29 observability requirements
to fall through the crack.

### Why this is a problem

The primary responsibility of `scripts/dispatch-agent.sh` is unambiguously the CD-1
universal dispatch entrypoint (Slice 1.4's description). The G20/G29 observability
work (persisting host/vendor/model metadata into the dispatch manifest) is an
additional capability layered onto the same script — it requires the script to already
exist with its core entrypoint logic in place.

Given slice ordering (1.2 precedes 1.4), a Plan reader would create the file in
Slice 1.2 with only observability instrumentation logic, then find a second "Create"
for the same file in Slice 1.4 — which is a conflict. Either way, the
implementer receives contradictory instructions.

### Expected fix

The Slice 1.2 entry should use **Modify** rather than **Create**:

| `scripts/dispatch-agent.sh` | **Modify** | Add host/vendor/model metadata persistence into the dispatch manifest for later observability. | G20, G29 |

The Create entry in Slice 1.4 is correct and should remain as-is. This aligns with
the standard pattern in the file map where a file is Created in the slice that owns
its core contract and Modified in subsequent slices that extend it.
<!-- @@SCORE: quality-claude.finding-F05.score @@ -->
score: 80
reason: Verified — `scripts/dispatch-agent.sh` has `Create` on both Slice 1.2 line 36 and Slice 1.4 line 59; a file cannot be created twice, so this is a real ambiguity Plan will hit, and the proposed Modify-in-1.2 fix matches the file-map convention.

<!-- @@FINDING: quality-claude.finding-F06 @@ -->
---
finding_id: R1-F06
artifact: structure
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
---

## Duplicate "Create" action for `scripts/round-prepare.sh` across Slice 1.3 and Slice 1.4

### What is wrong

`scripts/round-prepare.sh` appears with a **Create** action in two separate slices:

- **Slice 1.3** (Per-task review pipeline corrections):
  > `scripts/round-prepare.sh` | Create | Prepare per-task diff, scope, and
  > commit-anchor artifacts before every review round. | G9

- **Slice 1.4** (Dispatch infrastructure):
  > `scripts/round-prepare.sh` | Create | Canonicalize cumulative diff/ref selection
  > and next-round narrowing inputs. | G4

A file can only be created once. Two Create entries for the same file introduce the
same conflict as R1-F05: Plan will produce one task in Slice 1.3 that creates the
script for per-task diff/scope/commit-anchor purposes, and a second task in Slice 1.4
that creates the same file for diff/ref canonicalization purposes. The implementer
faces a conflict: they cannot create the same script twice from different task specs.

### Why this is a problem

The primary design motivation for `round-prepare.sh` is G4 (Canonical cumulative diff
helper) — this is Interface #2 in structure.md's Interfaces section, and the full CLI
contract is specified there. The G9 responsibility (per-task diff, scope, and
commit-anchor artifacts) is an extension layered on top of the same script per CD-1's
design notes ("Behavior: Check `<output-dir>/.round-prepare.json`; if absent,
auto-invoke `round-prepare.sh` (G4), forwarding `--task-branch` and
`--implementer-commit` when set").

Slice 1.3 processes before Slice 1.4 in implementation order. A Plan reader would
create the script in Slice 1.3 with G9's per-task responsibilities, then see a second
"Create" in Slice 1.4 for G4's canonicalization work — an unresolvable conflict.

### Expected fix

The Slice 1.3 entry should use **Modify** rather than **Create**:

| `scripts/round-prepare.sh` | **Modify** | Add per-task diff, scope, and commit-anchor artifact emission alongside the existing canonical diff/ref selection logic. | G9 |

The Create entry in Slice 1.4 is correct and should remain as-is, since G4 owns the
canonical definition of this script's contract (it is Interface #2). This mirrors the
same correct pattern used for `scripts/dispatch-agent.sh` (Create in its canonical
slice, Modify in extending slices).
<!-- @@SCORE: quality-claude.finding-F06.score @@ -->
score: 82
reason: Verified — `scripts/round-prepare.sh` is listed with action "Create" in both Slice 1.3 (line 46) and Slice 1.4 (line 62) of structure.md, which is a real correctness issue that will produce two conflicting create-tasks for Plan; the proposed Modify-in-1.3 / Create-in-1.4 fix is well-reasoned.

<!-- @@FINDING: quality-claude.finding-F07 @@ -->
---
finding_id: R1-F07
artifact: structure
severity: low
change_type: clarity
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
---

## Test Architecture: G25 absent from T1-T5 Feeds; traceability gap to CD-1 smoke test

### What is wrong

G25 ("top-level fail-loud invariant for the dispatch-routing section") does not appear
in any T1–T5 Feeds line in the Test Architecture section. It is implicitly covered only
by T6 (Self-host acceptance), which feeds all G1–G35.

G25's acceptance criteria, per design.md, are primarily exercised by the CD-1
acceptance smoke test:

> An executable smoke test exercises a tier-resolved-to-none dispatch and asserts
> the dispatcher halts with the loud diagnostic per CD-1 #2's no-silent-fallback rule.
> Form: a single bats test invoking `dispatch-agent.sh` against a `config.md` fixture
> with one tier set to `none` and an agent targeting that tier; asserts non-zero exit
> and a diagnostic written to stderr naming the unconfigured tier.

This smoke test is unit-test shaped (a single bats invocation against a fixture) and
would fall under T1 (unit tests) or T2 (integration tests, since it exercises
dispatch routing). CD-1 does appear in T2 Feeds, so the coverage is transitively
present — but the traceability from G25 to its specific test type is invisible in the
Test Architecture section.

### Why this matters

The Test Architecture section's stated purpose is "Structure stitches design acceptance
blocks into those boundaries." G25 has a concrete acceptance block in design.md that
names a specific test type (bats fixture, script invocation). The absence of G25 from
T1 or T2 Feeds breaks the traceability chain that lets the Test phase verify whether
G25's acceptance criteria have been covered by the right test type.

This is not a coverage gap — G25's requirements ARE tested through CD-1's coverage —
but it is a traceability gap. A Test phase reviewer reading the Test Architecture
section cannot trace G25 to its test type without consulting design.md directly to
discover the CD-1 absorption relationship.

### Expected fix

Add G25 to T2 Feeds (integration tests, since CD-1's fail-loud smoke test spans
dispatch routing which is multi-script behavior):

> Feeds: CD-1, CD-3, CD-4, G3, G4, G6, G9, G12, G15, G16, G18, G22, G23, **G25**, G27, G32.

Alternatively, add it to T1 Feeds if the smoke test is classified as a unit test
(single script invocation against a fixture is arguably T1). Either T1 or T2 is
defensible; what matters is that G25 is explicitly traced rather than relying on
implicit CD-1 absorption.

If the design.md decision to absorb G25 into CD-1 means G25's acceptance is
considered fulfilled by CD-1's coverage alone, a parenthetical note in the Test
Architecture section would close the traceability gap without changing Feeds lines:
e.g., in the CD-1 cross-cutting invariant entry, append "(G25 acceptance subsumed by
this invariant — see design.md CD-1 Acceptance)".
<!-- @@SCORE: quality-claude.finding-F07.score @@ -->
score: 60
reason: Verified — G25 is listed in file-map unit test `test-config-model-routing.bats` (G22, G23, G25) yet absent from T1 and T2 Feeds; real but low-severity clarity/traceability gap with a clear fix.

<!-- @@FINDING: quality-codex.finding-F01 @@ -->
---
finding_id: R1-F01
severity: high
change_type: correctness
artifact: structure
referenced_files: [docs/qrspi/2026-05-30-v072-release/structure.md, docs/qrspi/2026-05-30-v072-release/design.md]
round: 1
reviewer: quality-codex
---

`structure.md` is missing `skills/_shared/verifier-dispatch-prose.md` from the file
map, even though CD-4/G12 in `design.md` explicitly locks this file and requires it
to be included by both `using-qrspi/SKILL.md` and `implement/SKILL.md`. This leaves
a design-locked shared snippet absent from the file map, breaking the structure
matches design quality check.

Originally hand-persisted from chat-only Codex dispatch (per qrspi-plus issue #288).
<!-- @@SCORE: quality-codex.finding-F01.score @@ -->
score: 82
reason: Design CD-4 explicitly locks `skills/_shared/verifier-dispatch-prose.md` as a Create file `!cat`-included into both `using-qrspi/SKILL.md` and `implement/SKILL.md`, and structure.md's file map (verified across all 7 slices) contains no row for it — a real structure-matches-design gap on a design-locked shared snippet.

<!-- @@FINDING: quality-codex.finding-F02 @@ -->
---
finding_id: R1-F02
severity: medium
change_type: correctness
artifact: structure
referenced_files: [docs/qrspi/2026-05-30-v072-release/structure.md, docs/qrspi/2026-05-30-v072-release/design.md]
round: 1
reviewer: quality-codex
---

`structure.md` omits `tests/lint/test-design-altitude-boundary-include.bats`, which
is a required G34 regression guard in `design.md` (D5 + acceptance criteria). The
existing file map includes the G35 counterpart (`test-structure-altitude-boundary-include.bats`)
but not the G34 sibling. This leaves the Design boundary include-drift protection
incomplete in the structure map.

Originally hand-persisted from chat-only Codex dispatch (per qrspi-plus issue #288).
<!-- @@SCORE: quality-codex.finding-F02.score @@ -->
score: 78
reason: Verified — design.md G34 D5 + acceptance criteria (lines 2925, 2934) explicitly require `tests/lint/test-design-altitude-boundary-include.bats`; structure.md Slice 1.5 omits it while the parallel G35 file is present in Slice 1.6, a real file-map gap.

<!-- @@FINDING: quality-codex.finding-F03 @@ -->
---
finding_id: R1-F03
severity: medium
change_type: correctness
artifact: structure
referenced_files: [docs/qrspi/2026-05-30-v072-release/structure.md, docs/qrspi/2026-05-30-v072-release/design.md]
round: 1
reviewer: quality-codex
---

`structure.md` does not represent CD-4's locked interaction-mode component surfaces
(`scripts/detect-interaction-mode.sh` and round audit output `.interaction-mode-audit.json`)
that are specified with contract and acceptance criteria in `design.md`. This is a
missing-component gap between design and structure — a file/contract locked by
design.md has no corresponding entry in the file map or interfaces sections.

Originally hand-persisted from chat-only Codex dispatch (per qrspi-plus issue #288).
<!-- @@SCORE: quality-codex.finding-F03.score @@ -->
score: 80
reason: Confirmed — design.md CD-4 § I.7 locks `scripts/detect-interaction-mode.sh` (full contract + acceptance criteria, lines 600–693) and `<round-dir>/.interaction-mode-audit.json` (orchestrator-written audit-log shape, lines 671–677), but structure.md's File Map and Interfaces sections contain no entry for either, so a Design-locked component surface has no Structure representation.

<!-- @@FINDING: quality-codex.finding-F04 @@ -->
---
finding_id: R1-F04
severity: high
change_type: correctness
artifact: structure
referenced_files: [docs/qrspi/2026-05-30-v072-release/structure.md, docs/qrspi/2026-05-30-v072-release/design.md]
round: 1
reviewer: quality-codex
---

The fan-in audit interface in `structure.md` conflicts with `design.md`: structure
defines `fan-in-audit.json` (Interface 11 in the Interfaces section), while CD-4
locks the filename as `.verifier-fan-in-audit.json` (dotfile prefix + full name).
This filename contract mismatch can break downstream consumers and tests that
verify the locked path.

Originally hand-persisted from chat-only Codex dispatch (per qrspi-plus issue #288).
<!-- @@SCORE: quality-codex.finding-F04.score @@ -->
score: 82
reason: Confirmed mismatch — structure.md Interface 11 and the script usage block name `fan-in-audit.json`, but design.md CD-4 (components C, E, and sequence diagram lines 403/408/439) locks `.verifier-fan-in-audit.json`; this is a real contract drift on a CD-4 locked path.

<!-- @@FINDING: scope-claude.finding-F01 @@ -->
---
finding_id: R1-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-30-v072-release/structure.md:L356-L365]
artifact: structure
round: 1
reviewer: scope-claude
---

## Boundary drift — Interface §12 embeds actual prose body of `skills/_shared/verifier-filter-rule.md`

**What the artifact does.**  
Interface §12 ("Shared verifier filter rule snippet") at lines 356–365 pre-authors the complete wording of `skills/_shared/verifier-filter-rule.md`:

```markdown
## Verifier Filter Rule

Apply the verifier score only to `style`, `clarity`, and `correctness` findings.
- `style` and `clarity` require the higher threshold.
- `correctness` uses the lower hardening threshold.
- `scope` and `intent` bypass score filtering.
```

**Why this is out of scope.**  
The OWNS/DEFERS contract (v0.7.1, unchanged by G35 D2) defers "Actual prompt or SKILL.md text content → Plan / Implement." The file `skills/_shared/verifier-filter-rule.md` is a prose snippet that will be `!cat`-included directly into orchestrator skill prose (per Slice 1.1's Responsibility column: "Hold the single threshold/filter rule consumed by orchestrator prose and verifier fan-in"). Its wording — the actual rule sentences — is Plan/Implement deliverable content, not a structural interface declaration.

The contrast within the artifact makes the problem legible: Interfaces §5 and §6 (the altitude-boundary snippets) correctly use `<boundary rule prose>` and `- ...` placeholders to declare the file's section structure without pre-authoring the body. Interface §12 does the opposite — it pastes the complete rule text rather than declaring a section heading and role.

**What Structure should do instead.**  
Structure owns the section heading and the file's role at the interface boundary:

```markdown
### 12. Shared verifier filter rule snippet

Concrete v0.7.2 path: `skills/_shared/verifier-filter-rule.md`.
Required section: `## Verifier Filter Rule`.
Role: single threshold/filter rule; consumed by `scripts/verifier-fan-in.sh`, apply-fix, and reviewer-facing documentation.
```

The actual rule sentences belong in the Plan/Implement authoring pass for `skills/_shared/verifier-filter-rule.md`.

<!-- @@FINDING: scope-claude.finding-F02 @@ -->
---
finding_id: R1-F02
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-30-v072-release/structure.md:L22-L155]
artifact: structure
round: 1
reviewer: scope-claude
---

## OWNS gap — New `skills/` prose files lack section-list contracts

**What the artifact does.**  
The File Map tables (Slices 1.1–1.6) identify ten new `skills/` prose files and give each a single-sentence Responsibility description. The files in question are:

| File | Slice |
|---|---|
| `skills/reviewer-protocol/first-party-emission.md` | 1.1 |
| `skills/reviewer-protocol/third-party-emission.md` | 1.1 |
| `skills/_shared/reviewer-dispatch-prose.md` | 1.4 |
| `skills/_shared/config-validation-procedure.md` | 1.4 |
| `skills/_shared/prompt-prose-detection.md` | 1.5 |
| `skills/_shared/prompt-prose-writer-addition.md` | 1.5 |
| `skills/_shared/prompt-prose-reviewer-addition.md` | 1.5 |
| `skills/_shared/prompt-design-rules.md` | 1.5 |
| `skills/prompt-prose-writer/SKILL.md` | 1.5 |
| `skills/prompt-prose-reviewer/SKILL.md` | 1.5 |

**Why this is an OWNS gap.**  
Structure OWNS "Section-list contracts per file. Which top-level sections each file must contain (e.g., for a SKILL.md: `## Overview`, `## Process`, `## Red Flags`); which named blocks live where. Heading-level granularity, not prose content." This requirement applies to every file the project **creates** — without it, an implementer authoring these files has no structural contract to implement against.

The artifact handles this correctly for other new files: Interface §5 declares the structural skeleton of `skills/_shared/structure-altitude-boundary.md` (sections `## Structure Altitude Boundary`, `### What Structure OWNS`, `### What Structure DEFERS`), and Interface §6 does the same for `skills/_shared/design-altitude-boundary.md`. But none of the ten files listed above receive equivalent treatment.

For the two new wrapper SKILL.md files (`skills/prompt-prose-writer/SKILL.md`, `skills/prompt-prose-reviewer/SKILL.md`) the Responsibility column says "Wrapper skill that preloads detection + writer/reviewer rules" but names no required sections — which preloaded sections must appear, what the `## Overview` and `## Process` headings are called, where the shared-include blocks live.

For the shared snippet files, the same gap applies: `reviewer-dispatch-prose.md` "provides the one shared orchestrator dispatch snippet included by all review-producing skills" but the section heading that includes must reference is unspecified.

**What Structure should add.**  
For each of the ten files, an Interfaces subsection (or a brief section-list table) naming the required top-level headings and any named blocks, at the same heading-level granularity as §5 and §6. The actual prose under those headings remains deferred to Plan/Implement.

<!-- @@FINDING: scope-codex.finding-F01 @@ -->
---
finding_id: R1-F01
severity: medium
change_type: scope
artifact: structure
referenced_files: [docs/qrspi/2026-05-30-v072-release/structure.md]
round: 1
reviewer: scope-codex
---

Structure OWNS "section-list contracts per file" (per v0.7.1 owns-defers.md), but the
artifact currently provides file paths, actions, and responsibilities only and does
not specify required top-level section contracts for the listed SKILL / agent /
protocol files in the File Map. Add explicit per-file section/heading contract
definitions (at least for files whose section structure is load-bearing — e.g.,
`skills/structure/SKILL.md` after G35, `skills/_shared/structure-altitude-boundary.md`,
`skills/_shared/design-altitude-boundary.md`, `agents/qrspi-structure-scope-reviewer.md`)
to satisfy owned scope.

Originally hand-persisted from chat-only Codex dispatch (per qrspi-plus issue #288).

<!-- @@FINDING: scope-codex.finding-F02 @@ -->
---
finding_id: R1-F02
severity: medium
change_type: scope
artifact: structure
referenced_files: [docs/qrspi/2026-05-30-v072-release/structure.md]
round: 1
reviewer: scope-codex
---

Structure OWNS "cross-cutting hook-point locations" (per v0.7.1 owns-defers.md), but
the artifact does not enumerate concrete hook placement sites across files (the
File Map gives per-file responsibilities and the Interfaces section gives signatures
only). Add a dedicated hook-point location map (file + exact section/location) for
cross-cutting insertions — for example, the four compaction-callout placement sites
per skill, the `!cat` include sites the G34/G35 shared snippets land at, the four
introducer-prose insertion points for scope-reviewer agents — locations only, never
the text (text content remains DEFERS).

Originally hand-persisted from chat-only Codex dispatch (per qrspi-plus issue #288).

<!-- @@FINDING: scope-codex.finding-F03 @@ -->
---
finding_id: R1-F03
severity: low
change_type: correctness
artifact: structure
referenced_files: [docs/qrspi/2026-05-30-v072-release/structure.md]
round: 1
reviewer: scope-codex
---

Placeholder content remains in interface contracts in the Interfaces section
(structure.md L222-L233 carries literal `<boundary rule prose>` and `- ...` inside
the Structure altitude-boundary snippet shape; L307-L328 carries `/abs/path/...`
shape placeholders inside the dispatch manifest schema illustration), which
conflicts with the no-placeholder boundary expectation for structure-level
contracts. Replace placeholders with concrete contract shapes (a one-line schema
description of what the snippet body must contain; concrete `<example>` paths
labeled as example rather than `...` stubs) so downstream agents are not forced to
infer missing structure.

Originally hand-persisted from chat-only Codex dispatch (per qrspi-plus issue #288).
<!-- @@SCORE: scope-codex.finding-F03.score @@ -->
score: 20
reason: The flagged "placeholders" are intentional shape/schema illustrations (snippet section-list contracts and a dispatch-manifest JSON shape with a sample `/abs/path/...` value); Structure OWNS section-list contracts and schema shapes while DEFERRING actual prose content to Plan/Implement, so filling these in with concrete prose would itself drift across the OWNS/DEFERS boundary. The "no placeholders" rule cited in owns-defers.md applies to file-map paths ("no directory placeholders, no 'various', no 'TBD'"), not to schema illustrations, and each snippet already pairs the shape with a concrete file path (e.g., `skills/_shared/structure-altitude-boundary.md`).


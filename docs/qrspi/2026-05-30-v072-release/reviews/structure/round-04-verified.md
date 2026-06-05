---
verifier_enabled: true
scored: 7
kept: 4
dropped: 4
failed: 0
clean: 1
---

<!-- @@FINDING: quality-claude.finding-F01 @@ -->
---
finding_id: R4-F01
artifact: structure
reviewer_tag: quality-claude
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
line_range: [215, 296]
---

## §3 verifier-fanout `--tier-override <tier>` signature contradicts §7 grammar (introduced in R3)

The R3 addition of the verifier-fanout invocation form to Interface §3 documents the override flag as a bare tier value:

```
scripts/dispatch-agent.sh --verifier-fanout \
  --step <step> --round <N> --output-dir <round-dir> \
  [--tier-override <tier>]
```

But Interface §7 (`Host-and-tier-aware second-reviewer override`) — the canonical contract for the same `--tier-override` flag — defines a strict grammar that requires every value to be a tag=tier assignment, optionally CSV-joined:

```
--tier-override <csv>

csv        := assignment ("," assignment)*
assignment := <reviewer-tag> "=" <tier>
tier       := extra-low | low | medium | high | extra-high
```

and adds:

> the override is applied per emitted reviewer tag, so one batch can escalate only the second reviewer while leaving primary reviewers unchanged
> invalid tag names or tier values halt dispatch before any Task invocation

A bare `--tier-override high` would therefore be rejected by §7's parser ("invalid tag name"), so as written, the verifier-fanout invocation form in §3 is unimplementable against §7's contract. The two surfaces disagree on the flag's value shape.

This is a contract-level correctness issue, not just a clarity one: it forces the implementer to either (a) silently relax §7's grammar to accept a bare tier, (b) re-author §3 to use the assignment form (e.g., `--tier-override qrspi-finding-verifier=<tier>`), or (c) introduce a second, undocumented flag — and Plan/Implement will need to make that choice without any guidance from Structure.

### Recommended fix

Pick one and align both sections. The cleanest option is to keep §7's single grammar and rewrite §3's verifier-fanout form to use it explicitly, since every fan-out dispatch resolves to the same agent:

```
[--tier-override qrspi-finding-verifier=<tier>]
```

If a bare-tier shorthand is intentional for the fan-out single-agent case, §7 should be amended to document a second accepted shape (e.g., `csv := assignment ("," assignment)* | <tier>` with the note "bare-tier form is only valid in `--verifier-fanout` mode, where the agent is fixed"), and §3 should cross-reference §7 for the grammar definition so the two stay coupled.

Either way, both interface sections must agree on the value shape before this becomes a downstream lookup problem for the dispatch script implementer and the test author of `tests/unit/test-routing-matrix-application.bats`.

<!-- @@SCORE: quality-claude.finding-F01.score @@ -->
score: 78
reason: Confirmed in artifact — §3 verifier-fanout shows bare `--tier-override <tier>` while §7's canonical grammar (assignment, optionally CSV) would reject a bare tier as an invalid tag name; the two interface sections genuinely disagree on the flag's value shape and need alignment before Plan/Implement.

<!-- @@FINDING: quality-codex.finding-F01 @@ -->
---
artifact: structure
reviewer_tag: quality-codex
finding_id: R4-F01
round: 4
severity: medium
change_type: correctness
line_range: [210, 214]
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
---

# Interface §3 verifier-fanout glob `*.finding-F*.md` may match sidecar files

## Problem

Interface §3 (line 213) specifies:

```
# Script globs <round-dir>/*.finding-F*.md to enumerate findings; --agents is not used
```

The verifier-fanout entry point will dispatch one verifier per matched file. If sidecar files share a `.finding-F<NN>.` segment in their filename, reruns/retries could re-dispatch verifiers against sidecar artifacts rather than the original finding files.

## Impact

If sidecars match the glob, verifier-fanout reruns would over-dispatch. The contract should constrain enumeration to finding files only (e.g., by glob shape or explicit exclusion).

## Fix

Either:
- Tighten the glob to be exclusive of sidecar suffixes (e.g., `*.finding-F[0-9][0-9].md` — note that sidecars are written as `.score.yml` per the using-qrspi spec, so a `.md`-anchored glob may already exclude them; verify and document explicitly).
- OR document the sidecar suffix convention inline (the using-qrspi protocol uses `.score.yml`) and state that the glob is safe because sidecars are `.yml`.

Either way, make the exclusion explicit in the interface contract so an implementer who reads §3 in isolation doesn't accidentally write sidecars as `.md` files.

<!-- @@SCORE: quality-codex.finding-F01.score @@ -->
score: 18
reason: Glob is `.md`-anchored and sidecars are `.yml` per using-qrspi protocol, so enumeration cannot match sidecars; finding reduces to an optional inline-doc nitpick the author already acknowledges.

<!-- @@FINDING: quality-codex.finding-F02 @@ -->
---
artifact: structure
reviewer_tag: quality-codex
finding_id: R4-F02
round: 4
severity: medium
change_type: clarity
line_range: [449, 457]
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
---

# Interface §16 splitter NO_FINDINGS sentinel filename/path unspecified

## Problem

Interface §16 (line 456) says:

```
# Side effect: ... writes NO_FINDINGS sentinel file on clean NO_FINDINGS stdout
```

The sentinel filename/path is not defined. Sibling interfaces in structure.md all name exact filenames (`kept-findings.txt`, `.round-complete.json`, `<tag>.finding-F<NN>.md`), but this one says only "NO_FINDINGS sentinel file."

## Impact

Implement and Test consumers of this interface cannot know what filename to look for when checking whether a third-party reviewer returned NO_FINDINGS. The apply-fix protocol's clean-sentinel detection logic depends on knowing the sentinel's exact path.

## Fix

Specify the exact output path/filename. Recommended tag-scoped form to mirror the per-finding pattern:

```
# Side effect: ... writes <round-dir>/<tag>.no-findings on clean NO_FINDINGS stdout
```

Or pin to the canonical clean-sentinel pattern used elsewhere in the apply-fix protocol: `<round-dir>/<tag>.clean.md` with `status: clean` frontmatter.

<!-- @@SCORE: quality-codex.finding-F02.score @@ -->
score: 65
reason: Confirmed — §16 says "writes NO_FINDINGS sentinel file" without naming the path, while sibling interfaces (§15 `.round-complete.json`, §9 explicit path rule, §14 `<round-dir>/.dispatch/<tag>.raw`) all name exact filenames; downstream test contract (test-per-finding-file-emission.bats clean-sentinel behavior) and apply-fix consumers need the concrete path, so this is a real clarity gap at Structure altitude, though modest (Plan could backfill).

<!-- @@FINDING: scope-claude.finding-F01 @@ -->
---
finding_id: R4-F01
severity: low
change_type: scope
referenced_files: [docs/qrspi/2026-05-30-v072-release/structure.md:L402]
line_range: L384-L404
artifact: structure
round: 4
reviewer: scope-claude
---

Interface §13 ("Interaction-mode detector") includes a "Locked platform
directory" paragraph at line 402 that re-states architecture decisions
owned by Design:

> Locked platform directory (verified at design time as of 2026-05-31):
> Copilot CLI returns `DETECTION_TYPE=llm-context`; Claude Code returns
> `DETECTION_TYPE=llm-context`; unknown host returns
> `DETECTION_TYPE=user-override-only`. See design.md CD-4 §I.7 for full
> platform table.

The paragraph itself cites `design.md CD-4 §I.7` as the authoritative
source for the full platform→detection-type table, then duplicates a
subset of that table inline. Per the OWNS/DEFERS contract this is
boundary drift in two ways:

1. **Architecture decisions → Design (DEFERS rule).** Which signal each
   platform returns is *which approach* the host probe takes on that
   platform — a CD-4 architectural decision. Structure declares the
   script's CLI/API surface (which it correctly does in the code block
   on lines 388-398 with `Stdout: KEY=VALUE pairs...` and the
   per-`DETECTION_TYPE` shapes). Enumerating per-platform return values
   is architecture content, not interface-shape content.
2. **Single-source violation.** With the full table living in design.md
   CD-4 §I.7 and a subset re-stated here, the two surfaces can drift
   independently when a new host is added or a platform's detection
   type changes. The whole point of citing design.md is to avoid that.

The same risk does NOT apply to the rest of §13: the script-comment
block (exit codes, stdout shapes, KEY=VALUE grammar) and the audit-file
schema (`{platform, detection_type, verdict, evidence}`) are
parameter-shape / interface-surface content that Structure correctly
owns. Likewise the "Override chain" paragraph at line 400 is on the
borderline (env-var *name* is interface shape, but the safe-default
value `interactive` is also a Design decision) — flagging only the
clearer signal at line 402.

Suggested resolution: drop the "Locked platform directory" sentence
entirely and let the existing `See design.md CD-4 §I.7 for full
platform table.` citation stand alone (it already does the work). If
Structure needs a one-line pointer for navigability, replace the
duplicated mappings with a bare cross-reference such as: "Per-platform
return values are listed in design.md CD-4 §I.7."

<!-- @@FINDING: stitching-audit.finding-F01 @@ -->
---
finding_id: R4-F01
reviewer_tag: stitching-audit
severity: high
change_type: correctness
gap_class: dead-end-output
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
line_range: [71, 71]
---

# `orchestrator_rescue` / `max_drift_per_round` config fields have no consuming skill or file mapped in structure

## Gap description

R3 added `orchestrator_rescue` (default: false) and `max_drift_per_round` (default: 3) to
Interface §4 (`config.md` schema) and to the Slice 1.4 `config.md` file-map row
(structure.md line 71). These fields are now produced, but no structure file-map row or
interface contract assigns their *consumption* to any skill or script.

Design.md CD-4 §I.3 (lines 505–598) assigns the consuming behavior explicitly to the
orchestrator: "Halt-response protocol (orchestrator-side). When the script exits non-zero,
the orchestrator... applies a layered response keyed on halt cause + retry budget +
interaction mode + `orchestrator_rescue` config." The orchestrator is
`skills/using-qrspi/SKILL.md`. But neither of the two using-qrspi Modify rows carries
this responsibility:

- **Slice 1.2** `skills/using-qrspi/SKILL.md` — "Define round instrumentation,
  sub-threshold observation logging, and verifier-visible audit surfaces." Goals G20, G28,
  G29. No mention of CD-4 §I.3 halt-response protocol.
- **Slice 1.4** `skills/using-qrspi/SKILL.md` — "Carry the unified five-tier
  `model_routing:` schema, host matrix, validation rows, and fail-loud invariant prose."
  Goals G3, G22, G23, G24, G25, G27. No mention of CD-4 §I.3.

Similarly, `skills/implement/SKILL.md` (the other task-level orchestrator surface) has no
row that references CD-4 §I.3 behavior.

The result is a dead-end output: the config fields are defined, their semantics are detailed
in design.md, but no implementer has a structure-level mandate to build the consuming
logic.

## Authority (cite design.md section)

design.md CD-4 §I — "Halt-response protocol (orchestrator-side)" (lines 505–598):
- §I.3: "Per-finding budget exhaustion — `orchestrator_rescue` gates the rescue layer;
  interaction mode determines escalation shape." Three-branch behavior matrix covering
  `rescue=true/any`, `rescue=false/interactive`, `rescue=false/auto`.
- §I.4 (inferred from structure §4 comment "per CD-4 §I.4"): config.md default values lock.
- §I.5: "Iron-rule preservation check. Orchestrator-side rescue does NOT compute the kept
  set… Tier 1/2 fixes adjust the script's INPUT." The orchestrator is the actor.

design.md also locks `detect-interaction-mode.sh` (CD-4 §I.7) as a script, but §I.3's
halt-response branching logic is explicitly orchestrator-resident prose, not script-resident.

## Impact on implementation

Plan cannot assign the halt-response protocol work without a structure-level row that says
which file owns reading `orchestrator_rescue` / `max_drift_per_round`. Implementers of
`using-qrspi/SKILL.md` see only G20/G28/G29 (instrumentation) and G3/G22–G27 (dispatch
schema) responsibilities — CD-4 §I.3 is invisible from structure. The config fields will be
written but never read unless Plan independently reconstructs the connection from design.md.
This breaks the structure→plan hand-off contract.

## Fix (Structure-altitude only)

Extend one of the two `skills/using-qrspi/SKILL.md` Modify rows (Slice 1.2 is the better
home given its "round instrumentation" scope) to add the halt-response protocol
responsibility and the CD-4 goal reference. Minimal structure-altitude wording:

> `skills/using-qrspi/SKILL.md` | Modify | Define round instrumentation, sub-threshold
> observation logging, verifier-visible audit surfaces, **and orchestrator-side
> halt-response protocol (CD-4 §I.3): read `orchestrator_rescue` and
> `max_drift_per_round` from config.md to gate rescue-layer behavior and
> drift-count enforcement.** | G20, G28, G29, **CD-4**

Alternatively the Slice 1.4 row could absorb it since it already carries the model-routing
config context. Either row must gain the CD-4 goal tag and an explicit halt-response
responsibility clause so Plan can produce a task spec with the right file surface and test
expectations.

<!-- @@SCORE: stitching-audit.finding-F01.score @@ -->
score: 82
reason: Verified — config.md producer row adds orchestrator_rescue/max_drift_per_round per CD-4 §I.4, but no File Map row assigns the §I.3 orchestrator-side halt-response/rescue consumer to using-qrspi or implement SKILL.md (their existing rows scope to instrumentation and model_routing only); the lone CD-4-tagged row covers detect-interaction-mode.sh (§I.7) not the rescue branching, so this is a real dead-end-output gap blocking the structure→plan handoff.

<!-- @@FINDING: stitching-audit.finding-F02 @@ -->
---
finding_id: R4-F02
reviewer_tag: stitching-audit
severity: medium
change_type: correctness
gap_class: missing-wiring
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
line_range: [65, 65]
---

# `_resolve-lib.sh` responsibility description omits agent-frontmatter parsing, leaving the `agents/*.md` sweep output without an explicit consumer path

## Gap description

R3 added the `agents/*.md (sweep — all 41 files)` Modify row to Slice 1.4 (structure.md
line 93). That row produces agent files each carrying a `tier:` frontmatter field. The
downstream consumer is `scripts/_resolve-lib.sh`, which is called by `dispatch-agent.sh`
(and internally during `--verifier-fanout` mode) to resolve the tier → vendor → model chain.

However, structure.md's `_resolve-lib.sh` file-map row (line 65) describes its
responsibility as:

> "Own host×vendor routing, tier resolution, default-tier fallback, and fail-loud
> routing lookups."

It does **not** name agent-frontmatter parsing — the mechanism by which `_resolve-lib.sh`
reads `tier:` from `agents/<agent-name>.md` at dispatch time. Design.md is explicit about
this:

> design.md CD-1 component #7 (line 107): "`scripts/_resolve-lib.sh` — shared library:
> **agent-frontmatter parsing**, tier→vendor+model lookup against config.md's
> `model_routing:` table, `default_tier:` fallback, and fail-loud halt."

The stitching gap is: the sweep adds `tier:` fields to agent files, `_resolve-lib.sh`
says "tier resolution," but the connection — that `_resolve-lib.sh` reads
`agents/<agent-name>.md` frontmatter to get the tier — is not stated in structure.md.
An implementer reading only structure.md cannot tell what input the tier-resolution logic
consumes or where to find agent tier values at script runtime.

The gap is also present in the `--verifier-fanout` path: §3 says dispatch-agent.sh
resolves the verifier agent's tier via `_resolve-lib.sh` using hardcoded
`qrspi-finding-verifier` as the agent name, but there is no structure-level statement
that the resolution reads `agents/qrspi-finding-verifier.md` frontmatter.

## Authority (cite design.md section)

design.md CD-1, component list (lines 107–108):
> "`scripts/_resolve-lib.sh` — shared library: agent-frontmatter parsing,
> tier→vendor+model resolution, host × vendor matrix lookup. Single source of truth
> for resolution algorithm."

design.md CD-1, dispatch-agent.sh behavior step (line 70):
> "Resolve agent tier → vendor → model via `_resolve-lib.sh`."

design.md G22 deliverable 1 (lines 1950–1960): tier-assignment rubric establishes that
agent files carry `tier:` as the first-lookup value in the resolution chain
(`--tier-override` → agent `tier:` → `default_tier:` → hardcoded medium).

## Impact on implementation

Without "agent-frontmatter parsing" named explicitly in `_resolve-lib.sh`'s structure
responsibility, Plan may not assign a task to implement the file-read logic, or may place
it in `dispatch-agent.sh` instead of in the shared library. This would fragment the
"single source of truth" that design.md requires and create a seam where future
agents or override paths bypass the canonical lookup.

Additionally, the `--verifier-fanout` mode (§3) relies on the same mechanism for
`qrspi-finding-verifier`'s tier resolution; without the connection being named, that path
could be implemented with a hardcoded tier bypass rather than the frontmatter read,
silently voiding the verifier's participation in tier-assignment changes.

## Fix (Structure-altitude only)

Extend the `_resolve-lib.sh` Modify row's Responsibility column to name the
agent-frontmatter read:

> `scripts/_resolve-lib.sh` | Create | Own host×vendor routing, **agent-frontmatter
> parsing (reads `tier:` from `agents/<agent-name>.md` frontmatter at dispatch time),**
> tier→vendor+model resolution, default-tier fallback, and fail-loud routing lookups. | G22, G23, G25, G27

This connects the sweep output (agent files gain `tier:`) to the dispatch consumer
(`_resolve-lib.sh` reads `tier:`) at structure altitude — no prose content required.

<!-- @@SCORE: stitching-audit.finding-F02.score @@ -->
score: 40
reason: Real omission relative to design.md CD-1 #7 wording, but structure.md's "tier resolution" reasonably encompasses the agent-frontmatter read and design.md (cited via G22) supplies the full algorithm; minor wording tightening, unlikely to misroute Plan since the row is already tied to G22 whose authority spells out the parsing.

<!-- @@FINDING: stitching-audit.finding-F03 @@ -->
---
finding_id: R4-F03
reviewer_tag: stitching-audit
severity: medium
change_type: correctness
gap_class: missing-wiring
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
line_range: [234, 235]
---

# `.orchestrator-fixes.json` rescue audit file has no interface contract in structure despite design.md locking its schema

## Gap description

R3 added `orchestrator_rescue` and `max_drift_per_round` to Interface §4 (structure.md
lines 234–235), bringing CD-4 §I.3's halt-response protocol into structure scope. Design.md
CD-4 §I.3 defines a companion artifact produced by the rescue protocol:

> "Rescue audit file (`<round-dir>/.orchestrator-fixes.json`). All rescue events (every
> tier) are logged to this JSON file. **Schema:** JSON object `{rescue_events: [{finding_id,
> cause, tier, original_value, fixed_value, fix_method, citation?, tier_outcome}, ...]}` where
> `tier_outcome ∈ {applied, failed}`. **Consumer:** orchestrator-side round-summary prose
> surface (see below)."
> — design.md CD-4 §I.3 (line 539)

Structure.md contracts the sibling audit file `.verifier-fan-in-audit.json` in **Interface
§11** (lines 352–368) with a full JSON schema block. But `.orchestrator-fixes.json`, which
has an equally locked schema in design.md and a named consumer (the round-summary surface
in `reviews/{step}/round-NN-dispositions.md`), has no corresponding interface contract in
structure.md. No Interface section names it. No file-map row includes it. No side-effect
note in §3, §14, or §15 references it.

The R3 fix that added `orchestrator_rescue` to §4 brought the rescue protocol into
structure but did not bring the rescue file it produces.

## Authority (cite design.md section)

design.md CD-4 §I.3 (lines 539–541):
- Defines `.orchestrator-fixes.json` writer (orchestrator rescue tiers), schema
  (`rescue_events` array with fields: finding_id, cause, tier, original_value, fixed_value,
  fix_method, citation?, tier_outcome), consumer (orchestrator-side round-summary prose
  surface writing to `reviews/{step}/round-NN-dispositions.md`), and co-existence semantics
  ("the rescue file and `.verifier-fan-in-audit.json` are separate files with separate writers").

design.md CD-4 §I.5 (line 587): "All rescue events (every tier) are logged to this JSON
file" — rescue file is mandatory, not optional.

## Impact on implementation

Plan implementers working from structure.md will not know:
1. That `.orchestrator-fixes.json` must exist at `<round-dir>/` after any rescue event.
2. What fields the schema requires (the design.md `rescue_events` array shape).
3. That the writer is the orchestrator, not a script.
4. That the consumer is the round-summary dispositions file.

Without a structure-level interface, implementations of `using-qrspi/SKILL.md`'s rescue
behavior will likely omit or invent a different schema for this file, breaking the audit
trail that design.md requires for post-hoc inspection of rescue actions.

Compare: `§11` for `.verifier-fan-in-audit.json` gives implementers the exact schema they
need. The rescue file deserves the same treatment because it has the same design-time
commitment.

## Fix (Structure-altitude only)

Add **Interface §17** — `.orchestrator-fixes.json` rescue audit schema — between the
existing §16 and the `## Architectural Diagram` section. Structure-altitude form (schema
only; no prose content):

```json
{
  "rescue_events": [
    {
      "finding_id": "R1-F03",
      "cause": "missing_change_type",
      "tier": 1,
      "original_value": "category",
      "fixed_value": "change_type",
      "fix_method": "frontmatter-key-rename",
      "citation": null,
      "tier_outcome": "applied"
    }
  ]
}
```

Writer: orchestrator rescue layer (after each tier 1/2/3 fix attempt, including failed
attempts). Path: `<round-dir>/.orchestrator-fixes.json`. Consumer: `using-qrspi/SKILL.md`
round-summary prose surface (sources per-tier counts for `round-NN-dispositions.md`).
Co-exists with `§11` `.verifier-fan-in-audit.json` — separate writers, separate files.

Also update the Section Contracts cross-reference list preamble (line 634) to note
`<round-dir>/.orchestrator-fixes.json` → §17.

<!-- @@SCORE: stitching-audit.finding-F03.score @@ -->
score: 70
reason: Verified gap — design.md §I.3 line 539 explicitly locks `.orchestrator-fixes.json` schema/writer/consumer, and structure.md contracts the sibling `.verifier-fan-in-audit.json` in §11 but omits a parallel interface section for the rescue audit file, leaving implementers without a structure-altitude contract for a design-locked artifact.

<!-- @@FINDING: stitching-audit.finding-F04 @@ -->
---
finding_id: R4-F04
reviewer_tag: stitching-audit
severity: low
change_type: correctness
gap_class: seam-mismatch
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
line_range: [205, 215]
---

# Interface §3 PATH B side-effect description does not name the `--tag` argument passed to `dispatch-companion.sh`, leaving a seam with §14's `--tag`-required launch form

## Gap description

R3 added `--tag <reviewer-tag>` to Interface §14 (`dispatch-companion.sh` launch form) and
updated Interface §10's `split_cmd` example to include `--tag`. But Interface §3
(`dispatch-agent.sh`) describes the PATH B side effect only as:

> "background entries after dispatch-companion.sh returns JOB_ID on third-party path"
> (structure.md lines 205–215, Side effect comment)

§3 does not name `--tag` as one of the arguments dispatch-agent.sh passes when it invokes
dispatch-companion.sh. Yet §14 requires `--tag <reviewer-tag>` in the launch form:

> "Usage (launch): dispatch-companion.sh --vendor <vendor> --model <model-id>
> --prompt-file <abs-path> --round-dir <abs-round-dir> --tag <reviewer-tag>"
> (structure.md line 415)

And §14's `await` side-effect writes `<round-dir>/.dispatch/<tag>.raw` — which means the
`--tag` value passed at launch time is the key that allows `await-round.sh` to subsequently
invoke `split_cmd` pointing at the right `.raw` file. The chain requires:

  dispatch-agent.sh --tag X → dispatch-companion.sh --tag X → <tag>.raw → split_cmd --tag X

§3 describes the entry into this chain without naming `--tag`, while §14 requires it and
§10/§16 depend on it. This is a seam mismatch: the caller (§3) and the callee (§14)
disagree on the documented interface at the argument level.

## Authority (cite design.md section)

design.md CD-1, dispatch-agent.sh PATH B (line 78):
> "PATH B (third-party): invoke `dispatch-companion.sh` to launch background; capture jobId;
> append entry to `.dispatch-manifest.json` with `mode: background`, `status: pending`,
> `await_cmd`, `split_cmd`."

design.md CD-1, component #5 (lines 100–102):
> "`scripts/dispatch-companion.sh` (rename of `run-third-party-llm.sh`) — vendor-routing
> tier underneath dispatch-agent. Takes `--vendor` + resolved `--model`; routes to
> vendor-specific transport."

The design.md description of dispatch-companion already uses `--vendor` / `--model` as named
args. `--tag` was added in R3; design.md's concise component description did not enumerate
all args, but the R3 fix added `--tag` to structure's §14 without updating §3's side-effect
description to reflect the call.

## Impact on implementation

An implementer of `dispatch-agent.sh` working only from §3 will see PATH B described as
"invoke dispatch-companion.sh to launch background; capture jobId." They won't know to pass
`--tag` to dispatch-companion.sh. When they later implement dispatch-companion.sh from §14
(which shows `--tag` as part of the launch form and uses it to name the `.raw` file), the
two implementations will be inconsistent unless the implementer cross-reads both interfaces
and infers the argument.

The `.raw` file naming (`<tag>.raw`) creates a hard dependency: the tag passed at launch
**must** be the same tag used to name the `.raw` file, which is the same tag in `split_cmd`.
If `--tag` is not passed at launch, dispatch-companion.sh has no tag to use and the file
naming breaks.

## Fix (Structure-altitude only)

Extend §3's PATH B side-effect comment to name `--tag` as a required argument to
dispatch-companion.sh:

> Side effect (PATH B): invokes `dispatch-companion.sh --vendor <vendor> --model <model>
> --prompt-file <abs-path> --round-dir <abs-round-dir> **--tag <reviewer-tag>**`; captures
> JOB_ID from stdout; appends manifest entry to `<round-dir>/.dispatch-manifest.json` with
> `mode: background`, `status: pending`, `await_cmd: "dispatch-companion.sh await <JOB_ID>"`,
> `split_cmd: "third-party-finding-splitter.sh --round-dir <abs-round-dir> --tag <reviewer-tag>"`.

This closes the seam: every argument named in §14's launch form is now traceable to the §3
caller description that passes it.

<!-- @@SCORE: stitching-audit.finding-F04.score @@ -->
score: 22
reason: §3's PATH B comment is intentionally high-level and enumerates no dispatch-companion.sh args (not --vendor, --model, --prompt-file, or --tag); §14 carries the full launch signature so an implementer cross-reads both, and singling out --tag as a "seam mismatch" is a low-severity nit rather than a real interface disagreement.

<!-- @@CLEAN: scope-codex.clean @@ -->
---
reviewer_tag: scope-codex
round: 4
status: clean
---

# Scope-codex review — Round 4 — CLEAN

No scope/boundary violations in R3 fixes. The 8 applied R3 changes (Interface §3 --verifier-fanout form, Interface §4 orchestrator_rescue + max_drift_per_round, Interface §14 manifest-append correction, Interface §16 --tag argument, Slice 1.4 rename + sweep rows, Slice 1.5 design-scope-reviewer row, §10 split_cmd update, CI build-sync trim) all stay within Structure's owned territory and remain consistent with G35 D2/D3 authority. No Design-level rationale or Plan-level decomposition introduced.


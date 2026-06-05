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

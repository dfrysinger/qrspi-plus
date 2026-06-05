---
status: approved
task: 5
phase: 1
pipeline: full
goal_ids: [G13]
task_type: code
model: opus
---

# Task 05: G13 `change_type` enum drift hardening on both reviewer-emit and orchestrator-consume sides

- **Target files:** scripts/verifier-fan-in.sh (modify), skills/reviewer-protocol/SKILL.md (modify), tests/unit/test-change-type-partition.bats (modify)
- **Dependencies:** Task 02, Task 04
- **LOC estimate:** ~110
- **Dispatch order:** test-writer first, implementer second (RED-verification gate between).

**Overview**

Harden the reviewer finding `change_type` enum on both sides of the fan-in boundary: reviewer-facing protocol prose must emit only the canonical values, and `scripts/verifier-fan-in.sh` must fail loudly on any out-of-enum value instead of silently keeping or dropping it. This preserves deterministic confidence gating and a reproducible audit trail. (Why: see goals.md ### G13. Approach: see design.md ## G13 and design.md ### CD-4.)

**Scope**

- **In:**
  - Add the canonical `change_type` enum (`style`, `clarity`, `correctness`, `scope`, `intent`) to the `scripts/verifier-fan-in.sh` header and use that single script-side set for validation.
  - Make `scripts/verifier-fan-in.sh` treat an out-of-enum `change_type:` as a contract violation: exit non-zero, write `.verifier-fan-in-audit.json`, record `cause: change_type_out_of_enum`, identify the offending finding, and avoid successful kept-finding fan-in.
  - Preserve the existing missing-field path as a distinct `missing_change_type` schema failure.
  - Update `skills/reviewer-protocol/SKILL.md` so the reviewer emission contract documents the same canonical enum once and describes out-of-enum emission as a fan-in-consumed contract violation.
  - Extend `tests/unit/test-change-type-partition.bats` with failing and passing fixtures for out-of-enum rejection, all canonical enum values, missing-field distinction, single script-side enum use, and no duplicated skill-side enum alternations.

- **Out:**
  - Baseline verifier-fan-in script creation, well-formed-round success behavior, generic halt plumbing, and verifier-dispatch prose — T02 owns.
  - Renaming reviewer frontmatter from `category:` to required `change_type:` and rejecting missing `change_type:` as the field-name defect — T04 owns.
  - Verifier sidecar extension and score-sidecar output contract — T06 owns.
  - Informational-finding message-prefix semantics and verifier rubric handling — T07 owns.

**Definition of done**

- `scripts/verifier-fan-in.sh` exposes one canonical enum definition in its header and uses that same definition for all `change_type` membership checks.
- A finding with `change_type:` outside the canonical enum causes `scripts/verifier-fan-in.sh` to exit non-zero and write `.verifier-fan-in-audit.json` with a `halts[]` entry containing `cause: change_type_out_of_enum` and the offending finding identifier.
- Out-of-enum findings do not produce a successful `kept-findings.txt` fan-in result and are not silently default-kept, silently kept, or silently dropped.
- A fixture covering every canonical value (`style`, `clarity`, `correctness`, `scope`, `intent`) succeeds through the same parser path, emits `kept-findings.txt`, and records an audit with no halts.
- Missing `change_type:` still reports the dependency-introduced `missing_change_type` behavior, distinct from `change_type_out_of_enum`.
- `skills/reviewer-protocol/SKILL.md` documents the canonical enum once as the reviewer emission contract and says out-of-enum emission is a contract violation consumed by the fan-in script.
- Repository grep coverage confirms duplicated skill-side enum alternations are not introduced outside `skills/reviewer-protocol/SKILL.md`.

**Test expectations**

- `tests/unit/test-change-type-partition.bats` includes a fixture round with an out-of-enum `change_type:` value and asserts `scripts/verifier-fan-in.sh` exits non-zero, writes `.verifier-fan-in-audit.json`, records `cause: change_type_out_of_enum`, identifies the offending finding, and does not proceed as a successful kept-finding fan-in.
- The same bats file includes a well-formed fixture covering every canonical enum value (`style`, `clarity`, `correctness`, `scope`, `intent`) and asserts success, `kept-findings.txt` emission, and an audit with no halts.
- A missing-`change_type:` fixture asserts `missing_change_type`, not `change_type_out_of_enum`, preserving the dependency task's distinct schema failure.
- A script audit asserts `scripts/verifier-fan-in.sh` exposes one canonical enum definition in its header and validation uses that single set, so tests fail if unknown values are silently defaulted, silently kept, or silently dropped.
- A reviewer-protocol audit asserts `skills/reviewer-protocol/SKILL.md` documents the same canonical enum once as the reviewer emission contract and describes out-of-enum emission as a fan-in contract violation.
- A repository grep assertion confirms duplicated skill-side enum alternations are absent outside `skills/reviewer-protocol/SKILL.md`.

**References**

- goals.md ### G13 — problem framing for out-of-enum reviewer emissions bypassing confidence gating and breaking reproducible audit decisions.
- design.md ## G13 — resolved approach: canonical enum in the fan-in script and reviewer protocol, with named out-of-enum halt and no silent default-keep.
- design.md ### CD-4 — end-to-end verifier fan-in flow, loud-failure paths, script component shape, reviewer update surface, and G13 acceptance row.
- structure.md ### `scripts/verifier-fan-in.sh` — script header constants, enum validation, halt causes, audit output, and `test-change-type-partition.bats` coverage.
- structure.md ### `skills/reviewer-protocol/SKILL.md` — reviewer protocol responsibility for the canonical `change_type:` field name and enum, plus the single SKILL-side source requirement.
- structure.md ### `tests/unit/test-change-type-partition.bats` — test responsibility for field-name, enum-membership, partition-routing, and loud-failure coverage.

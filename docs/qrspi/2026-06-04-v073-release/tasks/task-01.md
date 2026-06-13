---
status: approved
task: 1
phase: 1
pipeline: full
goal_ids: [CD-1, G1, G4]
task_type: tdd
tier: high
---

# Task 01: Create scripts/upstream-paths.sh with always-appended hygiene path, fail-soft unknown-step, and Plan-step branch

- **Target files:** `scripts/upstream-paths.sh` (Create), `tests/unit/test-upstream-paths.bats` (Create), `skills/using-qrspi/SKILL.md` (Modify)
- **Dependencies:** none
- **LOC estimate:** ~150
- **cross_task_consumers:**
  - `agents/qrspi-finding-verifier.md` (T09) — `co-edit` not applicable here (T09 is a separate task that consumes this script's output via the new rubric clause's `<upstream_paths>` Read); disposition: `pass-through`.
  - `tests/unit/test-finding-verifier-id-hygiene-grounding.bats` (T10) — disposition: `pass-through` (T10 reads the script's stdout for the assertion; no edit to this task's deliverables required).
- **Atomicity note:** Single observable: one script emitting the per-step path manifest; per-step branches (Goals/Questions/Research/Design/Phasing/Structure/Parallelize/Replan/Plan/unknown, plus the always-appended SKILL list including the Plan-branch config.md read) are internal control flow, not separate deliverables. The task is one coherent script with one well-defined contract surface and is not split.
- **Author note:** silent-claude R01-F03 raised a silent-degrade concern about the unknown-step fail-soft branch (the script returns the always-appended SKILL paths and exits 0 — a verifier dispatched against an unrecognised step still receives the SKILL paths and can produce a plausible-looking review without the artifact upstream paths the step actually requires). Addressing it would require a design.md amendment changing CD-1 Acceptance bullet 2 from fail-soft to fail-loud; the approved design currently mandates the fail-soft direction (CD-1 Acceptance bullet 2 + structure.md row 17). This plan honours the design contract and does not introduce a plan-side workaround. Re-opening the contract is a Design-phase decision, not a Plan-phase one.
- **Author Note (defer-to-upstream):** security-codex R4-F01, silent-failure-codex R4-F01, security-codex R6-F01, silent-failure-claude R6-F04, silent-failure-codex R6-F01, security-codex R7-F01, silent-failure-codex R7-F01, silent-failure-codex R8-F01, and scope-codex R7-F01 (insofar as the latter implicates this task's named-diagnostic / fail-soft control-flow as a Plan-OWNS-drift example) reiterate the same fail-loud-on-unknown-step request; design.md § CD-1 Acceptance bullet 2 and structure.md row 17 contract the fail-soft direction. Re-opening requires a Design-phase amendment per `skills/plan/owns-defers.md` § Upstream-contract deferrals.
- **Description:** A context-free script emits the per-step upstream-artifact path list to stdout, honouring the always-appended SKILL paths (including `skills/implementer-protocol/SKILL.md` as the canonical ID-hygiene authority) and reading `pipeline:` from `<artifact-dir>/config.md` only on the Plan branch. The script accepts `--step <step>` and optional `--artifact-dir <path>` and prints repo-relative paths and step-relative artifact basenames (the orchestrator joins them against `<abs_path>` per the existing dispatch composition pattern). An unknown `--step` value returns the always-appended SKILL paths only and exits 0 (per design.md CD-1 Acceptance bullet 2 and structure.md row 17 — fail-soft direction; the orchestrator's prose behaviour on an absent step was non-erroring, and the script preserves that contract). On the Plan branch, a missing `config.md` at `<artifact-dir>/config.md` halts non-zero with the `config-missing:` named diagnostic; a `config.md` that exists but does not contain a recognised `pipeline:` value (i.e., neither `full` nor `quick`) halts non-zero with the `config-malformed:` named diagnostic. The using-qrspi SKILL.md edit rewrites the prior "Per-step upstream-artifact lists" prose block into a one-line directive citing `scripts/upstream-paths.sh` as the sole source of truth for the per-step path set.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - For every supported step (Goals, Questions, Research, Design, Phasing, Structure, Parallelize, Replan), the script prints the documented set — captured against a fixture (traces design.md CD-1 Acceptance bullet 1).
  - Unknown step name returns the always-appended SKILL paths only and exits 0 — no diagnostic on stderr (CD-1 Acceptance bullet 2 — fail-soft direction; matches structure.md row 17).
  - Plan-step with `pipeline: full` config returns `goals.md, research/summary.md, design.md, phasing.md, structure.md` plus the always-appended SKILL paths (G4 Acceptance bullet 1).
  - Plan-step with `pipeline: quick` config returns `goals.md, research/summary.md` plus the always-appended SKILL paths (G4 Acceptance bullet 2).
  - Plan-step with missing `<artifact-dir>/config.md` halts with the `config-missing:` named diagnostic and exits non-zero (G4 Acceptance bullet 3).
  - Plan-step with `<artifact-dir>/config.md` present but lacking a recognised `pipeline:` value (e.g., empty file, `pipeline: bogus`, or no `pipeline:` line) halts with the `config-malformed:` named diagnostic and exits non-zero (G4 Acceptance bullet 3 — the malformed-config half of "missing or malformed").
  - The always-appended array contains `skills/implementer-protocol/SKILL.md` (G1 Acceptance bullet 2).
  - The using-qrspi SKILL.md no longer contains the per-step upstream-artifact prose block; it carries a one-line directive citing `scripts/upstream-paths.sh` (CD-1 Acceptance bullet 3).

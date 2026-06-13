---
status: approved
task: 2
phase: 1
pipeline: full
goal_ids: [G3]
task_type: tdd
tier: medium
---

# Task 02: Create scripts/design-absorption-markers.sh

- **Target files:** `scripts/design-absorption-markers.sh` (Create), `tests/unit/test-design-absorption-markers.bats` (Create)
- **Dependencies:** none
- **LOC estimate:** ~80
- **cross_task_consumers:**
  - `scripts/review-prep.sh` (T03) — disposition: `pass-through` (T03 invokes this script for Design and Plan steps; T03 owns its own caller-side code).
  - `skills/plan/SKILL.md` (T15) — disposition: `pass-through` (T15 adds an anchor sentence directing the plan-author to run this script; the script itself is not edited).
  - `agents/qrspi-plan-spec-reviewer.md`, `agents/qrspi-design-reviewer.md` (T16) — disposition: `pass-through` (T16 adds rubric clauses that consume the script's output via the absorption map; the script is not edited).
  - `tests/unit/test-plan-spec-reviewer-absorption.bats`, `tests/unit/test-design-reviewer-fidelity.bats`, `tests/unit/test-design-reviewer-dispatch-defect.bats` (T17a/T17b/T17c) — disposition: `pass-through` (these reviewer-fixture tests consume the script's output via fixtures; no edit to this task's deliverables required).
  - `tests/lint/test-design-absorption-marker-set.bats` (T18) — disposition: `pass-through` (the lint enforces the marker-set discipline this script depends on; no edit to this task's deliverables required).
- **Description:** A script reads `design.md` from an explicit path argument and prints a tab-separated absorbed-goal redirect map to stdout, one line per absorbed ID with the absorbing-ID (or the sentinel `no-task`) in the second column. The script recognises exactly the four canonical absorption-marker forms enumerated in G3.a (heading-suffix moot/absorbed/already-fixed, block-internal explicit-non-goal, acceptance-criterion no-separate-task, free-prose deferred-to); marker shapes outside that enumerated set are not recognised (T18's structural lint owns the marker-set discipline). A marker-free design.md exits 0 with empty stdout; a missing or unreadable design path exits non-zero with the `design-path-unreadable:` named diagnostic.
- **Test expectations:**
  - Dispatch order: test-writer first, implementer second (RED-verification gate between).
  - Against a fixture design.md containing all 4 marker forms, the script returns the expected map — one line per absorbed ID with the correct absorbing-ID column (G3 Acceptance bullet 1, first half).
  - Against a marker-free design.md, the script returns empty stdout and exits 0 (G3 Acceptance bullet 1, second half).
  - Each of the 4 enumerated marker forms is independently exercised by a fixture (regression guard against pattern drift).
  - A fixture containing a non-enumerated absorption-shaped marker is NOT recognised (the script ignores it; T18's structural lint owns the marker-set discipline).
  - Missing or unreadable design path exits non-zero with the `design-path-unreadable:` named diagnostic, not a silent empty map.
- **Author Note (defer-to-upstream):** silent-failure-codex R4-F04 requests this script halt on a non-enumerated absorption-shaped marker (silently-ignored markers may mask reviewer or author error); design.md § G3 and structure.md row 18 contract the lint-side ownership — `tests/lint/test-design-absorption-marker-set.bats` (T18) is the marker-set authority, while this script is intentionally narrow (enumerated-shape recognition only) so authors can extend marker shapes without touching the script. Re-opening requires a Design-phase amendment per `skills/plan/owns-defers.md` § Upstream-contract deferrals.
- **Author Note:** silent-failure-codex R8-F03 raises silent-ignore concern on non-enumerated absorption marker shapes; the loud channel for this concern is T18's `tests/lint/test-design-absorption-marker-set.bats` structural lint, which owns the marker-set discipline at the design.md authoring boundary (per T02 Description: "T18's structural lint owns the marker-set discipline"). T02's silent-ignore behaviour on the extraction side is the contracted shape because T18 is the loud surface; addressing it inside T02 would duplicate enforcement. No plan-side change required.

---
finding_id: R1-F02
severity: medium
change_type: added
artifact: plan
round: 1
reviewer: quality-claude
referenced_files:
  - docs/qrspi/2026-05-27-v071-hardening/plan.md
  - docs/qrspi/2026-05-27-v071-hardening/structure.md
---

# R1-F02: Task 8 creates `test-cache-mechanism-retired.bats` — absent from structure.md Slice 7 file map

## Location

`plan.md` → Task 8, Target files line (the `tests/unit/test-cache-mechanism-retired.bats` (create) entry).

## Observation

`structure.md` Slice 7 (G7a) lists the following target files:

| Action | File |
|--------|------|
| Delete | `scripts/g4-cache-probe.sh` |
| Delete | `docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md` |
| Delete | `tests/unit/test-cache-control-capability-gate.bats` |
| Delete | `tests/unit/test-cache-hit-rate.bats` |
| Modify | `skills/using-qrspi/SKILL.md` |
| Modify | `scripts/run-third-party-llm.sh` |
| Modify | `tests/unit/test-run-third-party-llm.bats` |
| Modify | `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` |

No creation of a new file is listed. `structure.md`'s "Created files" section (under Section Contracts) lists only two new files for the entire release: `tests/unit/test-host-detection.bats` (Slice 6) and `tests/unit/test-agent-frontmatter-no-model.bats` (Slice 8). `tests/unit/test-cache-mechanism-retired.bats` appears nowhere.

Task 8 includes `tests/unit/test-cache-mechanism-retired.bats` (create) in its target files and describes it as containing structural post-retirement invariant assertions (deleted files absent, patterns absent from modified files).

`design.md` DKR8 also reinforces the expectation that G7a is a pure deletion: "G7a has no design surface. Plan enumerates the exact line ranges and produces a single deletion task."

## Why it matters

A new file not in the approved structure introduces a component that was not reviewed by the structure reviewer or captured in the section-contracts table. This file is a test suite that pins structural invariants — an architectural surface the structure reviewer should have evaluated. The deviation also means the test-writer for Task 8 is creating a file with no prior section-contract specification, leaving its internal shape undefined by the pipeline's normal verification chain.

Additionally, the design's explicit statement that G7a "has no design surface" and should produce "a single deletion task" implies no new authored artifacts. The new test file is an authored artifact that goes against this design framing.

## Suggested resolution

**Option A (match structure):** Remove `tests/unit/test-cache-mechanism-retired.bats` from Task 8's target files. The RED-GREEN gate for the deletion work is provided by CI: the existing suites that exercised the deleted files will be gone, and CI passing with the deletions landed is the observable GREEN. No new structural assertion file is needed.

**Option B (add to structure):** If the plan author believes the new file adds important long-term invariant protection, add it to `structure.md` Slice 7's file map and section-contracts (including its `@test` block headings) and note the departure from design DKR8's "single deletion task" framing. This requires a structure.md update, not just a plan update.

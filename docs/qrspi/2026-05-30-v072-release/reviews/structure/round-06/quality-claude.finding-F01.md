---
finding_id: R6-F01
reviewer_tag: quality-claude
artifact: structure
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
---

# Rename-inventory drift: four renamed files marked `Create` instead of `Rename → …`

## What

Design CD-1 § "Rename inventory (hard cutover, no shim)" enumerates five renames:

```
- run-codex-review.sh                          → dispatch-agent.sh (also gains universal-entry-point responsibility)
- run-third-party-llm.sh                       → dispatch-companion.sh
- codex-finding-splitter.sh                    → third-party-finding-splitter.sh
- _shared/codex/launch-await-pattern.md        → _shared/third-party/launch-await-pattern.md
- reviewer-protocol/codex-emission-override.md → third-party-emission.md
```

`structure.md` § File Map · Slice 1.4 correctly captures only **one** of these as a rename — the `launch-await-pattern.md` row uses `Action: Rename → skills/_shared/third-party/launch-await-pattern.md`. The other four are listed as `Action: Create`:

- Slice 1.4: `scripts/dispatch-agent.sh | Create | Universal batched dispatch entrypoint: …`
- Slice 1.4: `scripts/dispatch-companion.sh | Create | Launch vendor-specific third-party review jobs …`
- Slice 1.4: `scripts/third-party-finding-splitter.sh | Create | Split third-party stdout boundaries …`
- Slice 1.1: `skills/reviewer-protocol/third-party-emission.md | Create | Define the stdout-boundary emission contract …`

## Why it matters (structure-quality dimension: structure-matches-design + interfaces-well-defined)

1. **Faithfulness to design.** Design names these explicitly as renames in a hard-cutover rename inventory; structure.md presents them as fresh creations. Downstream readers (Plan, Implement) won't see the rename in the file-map and have to recover the relationship from a different artifact.

2. **Inbound-reference sweep gets dropped.** A rename row implies "find and rewrite all consumers of the old name." A Create row carries no such obligation. CD-1's own rename inventory implicitly contracts an inbound-reference sweep across `skills/` and `scripts/` (e.g., for `run-codex-review.sh`, `codex-finding-splitter.sh`, `codex-emission-override.md`, `run-third-party-llm.sh`). With Action=Create, Plan has no structural signal that those sweeps are required; the load shifts entirely onto the design-text reader.

3. **Git-history continuity.** A Create-vs-Rename distinction maps to git's `git mv` vs new-file behavior. Marking renames as Create normalizes the file map toward "lose history on every renamed surface," which contradicts the implicit hard-cutover semantics in design.

4. **Internal inconsistency.** Structure.md already uses `Action: Rename → …` correctly for `launch-await-pattern.md`. The remaining four belong to the same CD-1 inventory and should follow the same pattern. The asymmetry is itself a structural defect: a reader has to guess whether the four `Create` rows represent design departures or just inconsistent annotation.

## Side effects on the test file

Note: `tests/unit/test-run-codex-review.bats` (Slice 1.4, Modify, G16) is named for the pre-rename script. Whether that test file is itself renamed to `test-dispatch-agent.bats` is a downstream decision, but the structural surface to make that decision visible only exists if the rename of `run-codex-review.sh` is itself marked as a rename in the file map. With the current `Create` action the test-file-rename question is structurally invisible.

## Suggested fix

Change Action for the four rows so they mirror the launch-await-pattern row:

| File | Action |
|---|---|
| `scripts/dispatch-agent.sh` | `Rename → scripts/dispatch-agent.sh` (from `scripts/run-codex-review.sh`); also gains universal-entry-point responsibility per CD-1 |
| `scripts/dispatch-companion.sh` | `Rename → scripts/dispatch-companion.sh` (from `scripts/run-third-party-llm.sh`) |
| `scripts/third-party-finding-splitter.sh` | `Rename → scripts/third-party-finding-splitter.sh` (from `scripts/codex-finding-splitter.sh`) |
| `skills/reviewer-protocol/third-party-emission.md` | `Rename → skills/reviewer-protocol/third-party-emission.md` (from `skills/reviewer-protocol/codex-emission-override.md`) |

(For `dispatch-agent.sh`, the responsibility text already notes the new universal-entry-point role, so the Responsibility column does not need to change; only Action does.)

This also lets the table act as the authoritative rename inventory for Plan to lift directly into a sweep task, eliminating one round of design.md re-reading.

---
finding_id: R1-F04
severity: low
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/phasing.md:L11-L33]
artifact: phasing
round: 1
reviewer: scope-claude
---

The slice descriptions in `## Slices` enumerate specific file paths that belong to Structure (DEFERS: "File paths, module boundaries, interface contracts, file maps → owned by Structure"). Phasing names slices and phases; it does not enumerate files.

Representative instances across multiple slices:

- Slice 1 (L13): "`config.md` schema extensions", "`scripts/run-third-party-llm.sh`"
- Slice 2 (L17): "`skills/implementer-protocol/SKILL.md`"
- Slice 3 (L21): "`.github/workflows/ci.yml`", "`hooks/**/*.sh`", "`scripts/**/*.sh`", "`tests/helpers/**.bash`"
- Slice 4 (L25): "`skills/parallelize/owns-defers.md`", "`skills/parallelize/SKILL.md`", "`agents/qrspi-parallelize-reviewer.md`", "`tests/helpers/skill-markdown.bash`", T09/T14/T19 BATS file references
- Slice 5 (L29): "`agents/qrspi-visual-fidelity-reviewer.md`", "`reviews/tasks/task-NN/reference-gate.md`"
- Slice 6 (L33): "`docs/qrspi/2026-05-17-v07-release/spikes/g4-cache-probe.md`", "`tests/unit/test-u14-lint.bats`", "`docs/qrspi/2026-05-17-v07-release/spikes/cost-baseline.md`"

The same file paths also appear in the replan-gate criteria (L44–L85), compounding the drift.

This is rated low because some file-path references in slice descriptions may serve as identification anchors rather than prescriptive file maps — it is arguable that naming `scripts/run-third-party-llm.sh` identifies a deliverable boundary vs. specifying its implementation. However the density and specificity (glob patterns, exact test file names, spike report paths) crosses into Structure territory. The fix is to remove or genericize file path references in slice descriptions to deliverable-level names (e.g. "the universal dispatcher script" instead of "`scripts/run-third-party-llm.sh`") and leave the enumeration to Structure.

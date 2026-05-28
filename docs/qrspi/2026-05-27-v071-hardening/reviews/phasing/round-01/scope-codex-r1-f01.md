---
finding_id: R1-F01
severity: high
change_type: boundary-drift
referenced_files: [docs/qrspi/2026-05-27-v071-hardening/phasing.md]
artifact: phasing
round: 1
reviewer: scope-codex
defers_to: [structure, plan, parallelize, implement]
---

`phasing.md` crosses deferred boundaries throughout the owned `## Slices` / `## Phases` surface: it specifies concrete file paths, function/helper names, tool/transport syntax (`task` + concrete model), Branch Map/Wave presentation decisions, and task-level test/acceptance mechanics. The OWNS/DEFERS contract for Phasing explicitly defers architecture/test-strategy relitigation (Design), file/module/interface mapping (Structure), task/test specs (Plan), wave/branch-map decisions (Parallelize), and implementation-level dispatch prose (Implement).

Fix by rewriting slices and phase gates to stay at phasing level (vertical delivery units + phase grouping + replan gates as outcome criteria), removing deferred implementation/structure/plan details from this artifact and leaving those specifics to their owning artifacts.

(Materialized from inline subagent return; Codex scope-reviewer environment does not write to disk.)

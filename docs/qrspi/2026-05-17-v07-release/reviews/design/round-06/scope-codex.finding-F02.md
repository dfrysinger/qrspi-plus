---
finding_id: R6-F02
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/design.md:L741-L770]
artifact: design
round: 6
reviewer: scope-codex
---

The G17 recommendation specifies the concrete GitHub Actions workflow implementation: the exact `.github/workflows/ci.yml` file, job names, package installs, command globs, trigger patterns, concurrency expression, and Integrate's `gh run list` query shape. That is downstream file/config authoring detail, not design-level architecture. Under the Design DEFERS rule, concrete implementation surfaces belong to Structure / Plan / Implement; Design should stay at the level of "add CI with BATS unit, BATS acceptance, and shellcheck gates, broad branch-family triggers, pinned actions, and an Integrate-consumable success signal."

Fix by reducing this section to the selected CI architecture and rationale, and leave the exact workflow YAML, job identifiers, dependency install commands, globs, and query command to downstream artifacts.

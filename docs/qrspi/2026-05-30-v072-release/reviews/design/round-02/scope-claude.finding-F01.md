---
finding_id: R2-F01
severity: medium
change_type: scope
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/design.md:720
  - docs/qrspi/2026-05-30-v072-release/design.md:722
  - docs/qrspi/2026-05-30-v072-release/design.md:726
artifact: design
round: 2
reviewer: scope-claude
---

The new `## Test Strategy` section (introduced by Round-01 fixes) carries three sub-blocks that cross from design-altitude test strategy into per-test specification territory deferred to Plan/Implement under the OWNS/DEFERS contract. The Component Map introduced in the same round is clean — no drift.

**T2 — per-test-file layout (L720).**
"Coverage boundary: one bats file per script under `scripts/`" prescribes the structural organization of test files (one test file per production script). The DEFERS list explicitly calls out "per-test-file layout" as deferred to Implement. Design-altitude wording names the framework (`bats-core`), what behavioral layer is covered (per-script unit behavior, happy paths, named exit codes), and what is NOT covered (cross-script integration) — without locking the file-per-script organization decision that Plan/Implement should own.

**T3 — per-test case count and specific assertion outcome (L722).**
Two phrases cross the line:
- "gets one fixture per change-type enum value" — enumerates a specific test-case count tied to enum membership. This is case-enumeration spec (how many fixtures, triggered by which enum values), not coverage strategy.
- "one Copilot-CLI fixture asserting exit-0 from `second-reviewer-available.sh`" — names a specific assertion outcome (`exit-0`) for a specific script under a specific platform. Design-altitude wording covers the G27 second-reviewer probe as an integration coverage area; Plan authors the specific fixture count and assertion conditions.

**T5 — specific per-test assertions in Plan acceptance-criteria form (L726).**
"Per-reviewer-agent smoke that asserts: (a) the agent's frontmatter `tier:` field is set, (b) the agent body contains the `change_type:` enum block in canonical form, (c) the first-party-emission OR third-party-emission file is present in the dispatch-prompt assembly for that agent." Items (a), (b), (c) are specific assertion conditions — exactly the form of Plan-level per-task test expectations. The design-altitude version of T5 names the test type (per-agent contract smoke), the coverage surface (every `agents/qrspi-*.md` reviewer agent), and the ownership claim (T5 owns reviewer-agent contract shape); it defers which specific fields and which specific prose blocks are asserted to Plan's task acceptance criteria.

**Not a finding — Component Map (L647–708).** The diagram shows architectural components (using their design-committed names from CD-1/CD-4/G6) and their interaction topology across five labelled subgraphs. It does not prescribe directory structure or file-organization layout — Structure is explicitly pointed to for that ("Structure phase maps these components onto files and module boundaries," L708). Naming shared libraries like `_resolve-lib.sh` as component nodes is consistent with design altitude when those components are already locked as named architectural decisions in the CD blocks. No scope drift on the Component Map.

**Recommended fix.** In T2: change "one bats file per script under `scripts/`" to "per-script behavioral coverage under `scripts/`" (removes the file-layout prescription while preserving the coverage claim). In T3: change the two drifted phrases to "CD-4 change-type handling (all enum values covered)" and "G27 second-reviewer probe (Copilot-CLI path)" — defer fixture counts and assertion conditions to Plan. In T5: replace items (a)(b)(c) with "verifies the canonical agent-body shape required by CD-1/CD-4 contracts" — defer the specific field-presence assertions to Plan's per-task acceptance criteria for the T5 implementation task.

---
finding_id: R01-F01
severity: medium
change_type: scope
referenced_files: ["docs/qrspi/2026-06-04-v073-release/design.md:L564-L565"]
artifact: design
round: 1
reviewer: scope-claude
---

The G9 Acceptance section at design.md L564–L565 names a concrete file inventory for `skills/_shared/` and declares per-skill `references/` directory population. L564 reads: "`skills/_shared/` populated. New snippets exist: `reviewer-dispatch.md`, `review-loop.md`, `config-validation.md`, `compaction-checkpoint.md`, `pause-gate.md`, `feedback-format.md`. Each is `!cat`-referenced from the skills that need it…" L565 reads: "`references/` populated per-skill. Skills with worked examples…have their pedagogical content moved to `skills/<name>/references/<topic>.md`."

Specifying which concrete files must exist under which directories is file architecture — "directory layout, module boundary lines — Structure's job" per Design DEFERS. Design owns the three-tier placement decision (naming the tiers by purpose and the kinds of content each holds), and the Pass 1 table at L513–L519 rightly establishes that at design altitude. But the Acceptance block at L564–L565 prescribes a specific six-file inventory for `_shared/` and the per-skill `references/` layout: that is Structure-artifact territory.

Recommended fix: replace the specific file list in the L564 acceptance bullet with a rough shape assertion (e.g., "at least one snippet file exists per content type identified in the Pass 1 table"), and replace the L565 bullet with a pattern assertion (e.g., "each skill that previously inlined worked examples has a corresponding `references/<topic>.md` file"). Leave the exact file inventory to the Structure artifact. The three-tier placement decision and the tier descriptions in the Pass 1 table require no change.

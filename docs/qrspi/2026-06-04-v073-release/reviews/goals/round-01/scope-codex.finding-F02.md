---
finding_id: R1-F02
severity: medium
change_type: scope
referenced_files: ["docs/qrspi/2026-06-04-v073-release/goals.md:L186", "docs/qrspi/2026-06-04-v073-release/goals.md:L192"]
artifact: goals
round: 1
reviewer: scope-codex
---

The artifact makes explicit phasing decisions ("This goal lands LAST…" / "phasing should sequence…"). In `skills/goals/owns-defers.md`, phasing decisions are deferred to phasing.md, so goals.md should state priority/intent without prescribing sequencing. Move sequencing directives to phasing.md and keep only the goal relationship rationale here.

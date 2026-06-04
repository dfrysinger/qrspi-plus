---
finding_id: R1-F01
severity: low
change_type: correctness
referenced_files:
  - skills/reviewer-protocol/SKILL.md:L3
  - skills/reviewer-protocol/SKILL.md:L8
artifact: task-03
round: 1
reviewer: spec-claude
---

SKILL.md frontmatter `description:` and opening paragraph still advertise `disk-write contract` as a core responsibility after the emission-agnostic split.

**Line 3 — frontmatter `description:` field:**

```yaml
description: Cross-cutting QRSPI reviewer protocol — finding schema, change-type classifier, untrusted-data handling, disk-write contract.
```

**Line 8 — opening paragraph:**

```
It defines the cross-cutting reviewer contract — finding schema, change-type classifier, disk-write contract, and untrusted-data handling — that every reviewer subagent uses.
```

Both lines were not updated when `## Per-Finding Disk-Write Contract` was moved to the sibling emission-contract files. The body section was correctly stripped, but the file's own self-description still claims ownership of the disk-write contract, contradicting the goal of the split. A reader consulting only the frontmatter or the first paragraph — the most common discovery surface — will believe the disk-write contract still lives in SKILL.md.

**Task-03 DoD requirement:** "SKILL.md contains no emission-contract prose requiring the Write tool or stdout emission; it keeps only the transport-neutral protocol surfaces named above." The phrase "disk-write contract" in the description/intro IS emission-contract prose advertising the moved-out concern. The bats test suite checks for `Write tool` and `stdout emission` patterns but does not grep for `disk-write contract`, so this stale copy passed the automated gate.

**Suggested fix:**

Replace line 3 with:
```yaml
description: Cross-cutting QRSPI reviewer protocol — finding schema, change-type classifier, untrusted-data handling, phase routing, and dispatch contract. Per-channel emission contracts live in first-party-emission.md and third-party-emission.md.
```

Replace the relevant clause on line 8 with:
```
It defines the cross-cutting transport-neutral reviewer contract — finding schema, change-type classifier, dispatch contract, and untrusted-data handling — that every reviewer subagent uses. The per-channel emission contracts (file-write vs. stdout-boundary) live in sibling files (`first-party-emission.md`, `third-party-emission.md`).
```

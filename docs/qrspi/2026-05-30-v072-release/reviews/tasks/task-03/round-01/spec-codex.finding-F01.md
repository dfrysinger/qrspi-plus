---
finding_id: R1-F01
reviewer_tag: spec-codex
round: 1
task: 3
severity: low
change_type: correctness
referenced_files:
  - skills/reviewer-protocol/SKILL.md
---

# F01 — SKILL.md self-description still claims "disk-write contract" after the emission-agnostic split

## Location

- `skills/reviewer-protocol/SKILL.md:3` (frontmatter `description:` field)
- `skills/reviewer-protocol/SKILL.md:8` (intro paragraph)

## Current state

Both lines still list `disk-write contract` as part of the core protocol's self-description:

```yaml
# Line 3 (frontmatter):
description: Cross-cutting QRSPI reviewer protocol — finding schema, change-type classifier, untrusted-data handling, disk-write contract.
```

```markdown
# Line 8 (intro paragraph):
This skill is the single consolidated reviewer-shared content asset for the QRSPI pipeline. It defines the cross-cutting reviewer contract — finding schema, change-type classifier, disk-write contract, and untrusted-data handling — that every reviewer subagent uses.
```

## Spec mismatch

Task-03's DoD requires SKILL.md to retain ONLY emission-agnostic protocol content (finding schema, classifier, untrusted-data handling, phase routing, dispatch contract, untrusted scope-hint guidance) and to delegate the disk-write contract to `first-party-emission.md`. The implementer correctly stripped the body section (`## Per-Finding Disk-Write Contract` removed), but the self-description at the top of the file still advertises the moved-out content as a current responsibility.

A reader inspecting only the frontmatter or the opening paragraph (the most common discovery surface) will believe the disk-write contract still lives in SKILL.md, defeating the purpose of the split — the file-contract layer must be authoritative in its own file.

## Suggested fix

Replace `disk-write contract` with the post-split self-description in both locations:

```yaml
# Line 3 (frontmatter):
description: Cross-cutting QRSPI reviewer protocol — finding schema, change-type classifier, untrusted-data handling, and dispatch contract. Emission contracts live in first-party-emission.md and third-party-emission.md.
```

```markdown
# Line 8 (intro paragraph):
This skill is the single consolidated reviewer-shared content asset for the QRSPI pipeline. It defines the cross-cutting transport-neutral reviewer contract — finding schema, change-type classifier, dispatch contract, and untrusted-data handling — that every reviewer subagent uses. The per-channel emission contracts live in sibling files (`first-party-emission.md`, `third-party-emission.md`).
```

## Severity rationale

Low: structural compliance — the body content is correctly stripped, only the self-description is stale. But this is exactly the kind of advertised-vs-actual drift that erodes trust in the contract layer; cheap to fix in R2.

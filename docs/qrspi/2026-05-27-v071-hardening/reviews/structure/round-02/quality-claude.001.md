---
artifact: structure
reviewer: qrspi-structure-reviewer
reviewer_tag: quality-claude
round: 2
severity: medium
change_type: correctness
status: open
---

# Section Contracts asserts top-level section names that do not exist in the three files it characterizes

## Location

`structure.md` § Section Contracts § Modified files (top-level section reshape) — the three blocks describing `skills/parallelize/SKILL.md`, `skills/using-qrspi/SKILL.md`, and `agents/qrspi-parallelize-reviewer.md`.

## What I observed

The Section Contracts section, newly added in R2 to address R1 review feedback, asserts "Top-level sections after rewrite" / "Touched top-level sections" lists that do not match the actual files. I cross-checked against the in-tree copies at `~/code/qrspi-plus-v0.7.1/`.

**1. `skills/parallelize/SKILL.md`** — Section Contracts claims the post-rewrite top-level section list is:

> - `## Overview`
> - `## Process`
> - `## Branch Map` (now contains `### Wave N` sub-sections instead of a flat three-column table)
> - `## Worked Examples` (updated Good/Bad pairs to Wave-grouped shape)
> - `## Red Flags`
>
> Removed top-level section: `## Execution Order` (subsumed by the Wave sub-section ordering)

The actual top-level (`##`) sections in `skills/parallelize/SKILL.md` are: `## Overview`, `## Why This Skill Is Separate From Implement`, `## Iron Law`, `## Parallelize OWNS / Parallelize DEFERS`, `## Artifact Gating`, `## Execution Modes`, `## Branch Model (Symbolic — Resolved by Implement)`, `## Process Steps`, `## Artifact`, `## Human Gate`, `## Review Round`, `## Terminal State`, `## Task Tracking (TodoWrite)`, `## Red Flags — STOP`, `## Common Rationalizations — STOP`, `## Worked Example — Good`, `## Worked Example — Multi-Stage Suffix`. Specifically:

- There is no `## Process` — the actual section is `## Process Steps`.
- There is no `## Branch Map` top-level section. "Branch Map" appears as a bullet in `## Artifact` (documenting `parallelization.md`'s required output table) and as an `## Branch Map` heading inside the worked-example markdown blocks (which are content inside `## Worked Example — Good`, not top-level skill sections).
- There is no `## Worked Examples` — the file has two separate sections `## Worked Example — Good` and `## Worked Example — Multi-Stage Suffix`.
- There is no `## Red Flags` — the actual section is `## Red Flags — STOP`.
- There is no `## Execution Order` top-level section to remove. "Execution Order" appears only in the `## Artifact` bullet list (a documented required sub-section of the `parallelization.md` output artifact) and inside the worked-example markdown blocks. The design's DKR4 phrase "the 'Execution Order' prose section is removed as redundant" refers to one of those embedded contexts, not a top-level skill section.

**2. `skills/using-qrspi/SKILL.md`** — Section Contracts asserts:

> - `## Codex Detection` (Slice 6: per-host transport prose, mismatch diagnostic)
> - `## Providers` (Slice 7: cache fields removed from YAML example and description bullets)
> - `## Model Routing` (Slice 8: …)

None of these three are top-level sections in the actual file:

- "Codex detection" appears as bold prose (`**Codex detection:**`) inside an existing section near line 405 — not as a `##` heading. There is no `## Codex Detection`.
- `providers:` appears as `#### `providers:` block` (an H4) under `### Dispatch routing blocks` (an H3) near lines 413–417. Not a top-level section.
- `model_routing:` appears as `#### `model_routing:` block` (an H4) in the same `### Dispatch routing blocks` cluster. Not a top-level section.

**3. `agents/qrspi-parallelize-reviewer.md`** — Section Contracts asserts:

> - `## Branch Map Structural Rules` (assertion set updated to require `### Wave N` sub-section grouping)

The actual top-level sections of this agent file are: `## Step 1 — load the artifact and companions`, `## Step 2 — apply checks`, `## Step 3 — emit findings`, `## Diff-File Read Pattern`, `## Scope Hint`. There is no `## Branch Map Structural Rules` section. The Branch Map structural rule is one bullet within `### Parallelize-specific quality checks` (an H3 nested under `## Step 2 — apply checks`):

> - **Symbolic-base vocabulary** — Branch Map `Base` values must use only the canonical symbolic vocabulary…

## Why it matters

Section Contracts is the part of `structure.md` that pins heading-level shape so Plan can verify its line-level edits against a known target. When those assertions don't match the files, Plan has two failure modes:

1. **Plan trusts the contracts and rewrites the files to match them.** This would corrupt three load-bearing files: `skills/parallelize/SKILL.md` would lose its `## Iron Law`, `## Parallelize OWNS / Parallelize DEFERS`, `## Branch Model`, `## Artifact`, `## Review Round`, `## Common Rationalizations`, etc.; `skills/using-qrspi/SKILL.md` would gain three fabricated top-level sections that displace the existing `### Dispatch routing blocks` H3 hierarchy and the in-line `**Codex detection:**` prose-block placement; `agents/qrspi-parallelize-reviewer.md` would gain a fabricated `## Branch Map Structural Rules` section that conflicts with the Step-1/Step-2/Step-3 reviewer-agent structural template every other reviewer agent shares. This is a "conflicts with existing codebase patterns" failure of the strongest kind — Plan would be following a contract that demands the codebase's existing patterns be broken.

2. **Plan recognizes the mismatch and discards Section Contracts.** Then the section is dead weight that the next reviewer round still has to re-evaluate, and the R1 finding the section was meant to address remains unresolved at the structural level.

Either way the contracts fail to do the job they were added for. The File Map rows describing the same edits don't have this problem: they speak in terms of touched content blocks ("the providers block", "the Codex-detection section", "the Branch Map structural-rule assertions") without asserting specific heading levels, so they remain accurate. Section Contracts upgrades those vague-but-true claims into precise-but-false ones.

This is fundamentally a "no conflicts with existing codebase patterns" issue (the existing files have their own established section structures that the contracts don't match) compounded by an interface-well-defined issue (the contracts claim to define heading-level shape but define a heading-level shape that doesn't and won't exist).

## Suggested resolution

Two options, in decreasing order of preference:

**Option A — Replace heading-level contracts with content-block contracts.** Rename the section "Touched content blocks" and rewrite each entry to name the content block being modified without asserting heading level. Example for `skills/using-qrspi/SKILL.md`:

```
**`skills/using-qrspi/SKILL.md`** (Slice 6 + Slice 7 + Slice 8)

Touched content blocks:
- Codex-detection prose block (Slice 6: per-host transport prose, mismatch diagnostic added; existing `**Codex detection:**` prose-block placement preserved)
- `providers:` YAML example + description bullets under `### Dispatch routing blocks` (Slice 7: cache fields removed)
- `model_routing:` block under `### Dispatch routing blocks` (Slice 8: dispatcher-prose paragraph added documenting tier-name resolution against `config.md` `model_routing` via `detect_host()` output)
```

Analogous rewrites apply to the `skills/parallelize/SKILL.md` and `agents/qrspi-parallelize-reviewer.md` blocks. The R1 quality concern (the file map said "Update the Codex-detection section" without naming what stays vs what changes) is addressed by naming the touched content blocks and what's added/removed, not by asserting a heading-level shape that doesn't match the files.

**Option B — Delete the Section Contracts section.** The File Map's responsibility cells already capture what's modified, and the per-file boundary remains clear without heading-level commitments. The R1 reviewer's concern was about per-file specificity, which the 41-agent enumeration and the additional G6 / G7b consumer rows already address; the Section Contracts section may not be load-bearing once those other R1 fixes are in.

Either option preserves the actual file structures. Plan can then carry the per-line edits against current `main` without being misdirected by false heading-level contracts.

Per-line edit locations (which heading-level subsection inside each file the edits land in) remain Plan-owned and out of scope for this finding.

---
artifact: structure
reviewer_tag: quality-claude
finding_id: R11-F02
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md:3337-3338
  - docs/qrspi/2026-05-30-v072-release/structure.md:2322-2332
  - docs/qrspi/2026-05-30-v072-release/structure.md:2354-2364
severity: high
change_type: correctness
---

# `## Section Contracts` table demands H2 sections for the prompt-prose wrapper SKILLs that contradict their own locked verbatim file bodies

## What is broken

`## Section Contracts` (structure.md L3317-3338) declares required top-level sections for the two new wrapper SKILLs:

```
| `skills/prompt-prose-writer/SKILL.md`   | `## Overview`, `## Detection`, `## Rules Application`, `## Process` |
| `skills/prompt-prose-reviewer/SKILL.md` | `## Overview`, `## Detection`, `## Rules Application`, `## Process` |
```

But the locked **`Lift type: Full file body`** verbatim payloads for the same two files (structure.md L2322-2332 and L2354-2364) contain **no H2 sections at all** — only frontmatter, a single H1, and two `!cat` directives. Reproducing `skills/prompt-prose-writer/SKILL.md` verbatim:

````markdown
```markdown
---
description: Apply prompt-design rules when authoring or planning prompt-prose deliverables. ...
---

# Prompt Prose Writer

!cat skills/_shared/prompt-prose-detection.md

!cat skills/_shared/prompt-prose-writer-addition.md
```
````

`skills/prompt-prose-reviewer/SKILL.md` has the identical shape (frontmatter + `# Prompt Prose Reviewer` H1 + two `!cat` lines).

Even after G32 build-time expansion of the two `!cat` directives, the inlined snippets (`prompt-prose-detection.md` and `prompt-prose-writer-addition.md` / `prompt-prose-reviewer-addition.md`) contain no `## Overview`, no `## Detection` H2 heading wrapper around the detection snippet, no `## Rules Application` heading, and no `## Process` heading. The detection snippet (structure.md L2221-2251) starts with a bold `**Prompt prose** is…` paragraph — no H2. The writer-addition (L2272-2275) is a `**Writer-side application.**` bold paragraph — no H2.

## Why it matters

Section Contracts is the table Plan and Implement consult when asking "what headings does this file need?" The contradiction means:

1. A Plan author following Section Contracts will demand four H2 sections that the verbatim file body explicitly forbids (`Lift type: Full file body` is contract-binding).
2. An Implement author following the verbatim file body will produce a file Section Contracts flags as non-conformant.
3. A structure-reviewer (or any future lint) will fail in opposite directions depending on which authority it consults first.

The four-H2 claim appears to be carried over from an earlier draft when wrapper SKILLs had a real authored body (procedure prose + sections), before G31 collapsed them to the pure `!cat`-aggregator shape. The Section Contracts table was not swept when the file bodies were locked at the aggregator shape.

The third entry in Section Contracts that has the same risk — `skills/reviewer-protocol/first-party-emission.md` (`## First-Party Emission Contract`, `### Write-Tool Requirements`, `### Path Rules`) and the corresponding third-party-emission.md row — is internally consistent: the Outline-only sections list (L261 and L289) for those files explicitly names the same three anchors as required, so Plan/Implement authors have a single coherent contract. Only the two wrapper-SKILL rows are contradictory.

## Suggested fix

Two options, both correct:

- **Option A (preferred — matches the locked file shape):** Replace both wrapper-SKILL rows in Section Contracts with a single-section claim that matches the verbatim body:

  ```
  | `skills/prompt-prose-writer/SKILL.md`   | `# Prompt Prose Writer` (H1 only; body is two `!cat` includes — see per-file block) |
  | `skills/prompt-prose-reviewer/SKILL.md` | `# Prompt Prose Reviewer` (H1 only; body is two `!cat` includes — see per-file block) |
  ```

- **Option B (if four H2 sections are genuinely required):** Update the verbatim payloads at L2322-2332 / L2354-2364 to interleave the four required H2 headings around the existing `!cat` includes (e.g., `## Detection` above the detection `!cat`, `## Rules Application` above the addition `!cat`, plus `## Overview` and `## Process` paragraphs whose body is Plan/Implement-authored). This requires re-lifting from design.md §G31 File 4 / File 5 (L2506-L2540) — and the current design.md prose there does not authorize the four-H2 expansion, so Option B would also need a Design re-open via Backward Loops.

Option A is the smaller, no-Backward-Loop fix.

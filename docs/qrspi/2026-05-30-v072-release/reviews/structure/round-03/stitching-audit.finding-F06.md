---
finding_id: R3-F06
reviewer_tag: stitching-audit
severity: medium
change_type: correctness
gap_class: missing-wiring
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
line_range: [88, 91]
---

# All-41-agents schema migration has only 4 representative rows; 37 agents unrepresented

## Gap description

Design.md CD-1 "Schema migrations" (lines ~189–215) requires two changes applied to
**all 41 agent files**:

1. **`tier:` frontmatter field** — every agent gains a `tier:` key (e.g., `tier: standard`
   or `tier: high`) so universal dispatch can route model selection.
   Acceptance criterion: "Agent frontmatter lint: every agent has `tier:` field."

2. **DISPATCH_FILE first-action instruction** — every reviewer agent body
   (`agents/qrspi-*-reviewer.md`) gains the instruction: "**Read your `DISPATCH_FILE`
   as your full dispatch before doing anything else.**"
   Acceptance criterion: "Every reviewer agent body (`agents/qrspi-*-reviewer.md`) carries
   the first-action instruction."

The file map in Slice 1.4 (structure.md lines 88–91) has Modify rows for **4 agents**:

| File | Responsibility |
|---|---|
| `agents/qrspi-implementer.md` | "Add the orchestrator-only-script allowlist and universal `DISPATCH_FILE` first-action pattern." |
| `agents/qrspi-code-quality-reviewer.md` | "Add `tier:` frontmatter and dispatch-file first action on a representative reviewer body." |
| `agents/qrspi-plan-reviewer.md` | "Add `tier:` frontmatter and dispatch-file first action on a plan reviewer body." |
| `agents/qrspi-test-writer.md` | "Add `tier:` frontmatter so test-writer dispatch co-escalates with implementer dispatch." |

The phrase "on a **representative** reviewer body" (line 89) makes the intended scope clear:
this is one example to illustrate the pattern, not the full sweep. There are 41 agents
on disk (`agents/qrspi-*.md`), and ~32 are reviewer agents (names containing `-reviewer`,
plus related agents like `qrspi-scope-tagger`, `qrspi-finding-verifier`, etc.).
The remaining 37 agents have no Modify row.

## Missing wiring: no schema-migration sweep row

G2 (schema migration task shape) establishes the pattern for bulk agent sweeps — a row with
`sizing_exception: schema migration` covering all affected files with a shared change. No
such row exists for the tier-frontmatter + DISPATCH_FILE first-action sweep.

The acceptance criteria cited in CD-1 ("every agent has `tier:`", "every reviewer body
carries the first-action instruction") will **not pass** if only 4 agents are modified.

## Stitching impact

The universal dispatch chain is:

```
orchestrator calls dispatch-agent.sh --agents tag1=qrspi-code-simplifier,...
→ dispatch-agent.sh reads agent frontmatter: agent[tier]
→ resolves model per tier
→ emits spec line with MODEL=<resolved>
```

If `qrspi-code-simplifier.md` lacks `tier:` frontmatter, `dispatch-agent.sh`'s tier
resolution will hit a missing-key path. Whether this silently defaults or fails-loud depends
on implementation — but the correct behavior per CD-1 is that every agent **has** the field
so the default path is never exercised.

Similarly, if a reviewer agent body lacks the DISPATCH_FILE first-action instruction and the
orchestrator dispatches it via the PROMPT_FILE mechanism (writing the prompt to a temp file),
the reviewer will see an empty or templated prompt and produce garbage findings.

## Minimal-altitude fix

Add a schema-migration Modify row to Slice 1.4 covering all agents:

```
| `agents/qrspi-*.md` (all 41 files) | Modify — schema migration | Add `tier:` frontmatter
  (value per G22 model-routing table) to every agent; add DISPATCH_FILE first-action
  instruction to every reviewer agent body (`agents/qrspi-*-reviewer.md`). Batch change;
  no behavioral logic. | G22 |
```

The 4 existing representative rows can remain as-is for documentation value (they include
richer responsibilities beyond the schema sweep), but the sweep row must exist to drive
complete implementation.

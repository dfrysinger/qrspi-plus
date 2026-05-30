---
reviewer: simplify-claude
finding: F02
task: task-10
round: 04
severity: advisory
category: prose-redundancy
file: skills/using-qrspi/SKILL.md
lines: 448-546
status: open
---

# F02 — `#### Model Routing` H4 (L522-L546) largely restates `#### `model_routing:` block` (L448-L470)

## What

The R1 fix added a new H4 section `#### Model Routing` at lines 522–546
of `skills/using-qrspi/SKILL.md` to document the dispatch-time
resolution flow. The pre-existing schema-doc H4
`#### `model_routing:` block` (lines 448–470) was edited to describe
the new host→tier→model shape. The two sections now overlap on the
same three substantive points:

| Point                          | Schema H4 (L448-L470)               | Model Routing H4 (L522-L546)     |
|--------------------------------|--------------------------------------|----------------------------------|
| Two-step resolution            | L450 ("(1) detecting the host CLI it is running under and (2) looking up the tier name…") | L530-L537 (numbered list reproducing the same two steps) |
| Why fully-versioned IDs        | L466 ("Values are fully versioned model IDs … Copilot CLI's model proxy emits a 'model not available' warning for bare tier requests but accepts versioned IDs.") | L539-L543 (paragraph restating the same Copilot-CLI-proxy fact) |
| `inherit` semantics            | L450 ("or `inherit` when the agent declares no explicit `model:` field") | L543-L546 ("The `inherit` row exists so that agents declaring no explicit `model:` field … still resolve to a concrete model…") |

The schema H4 also carries the fail-loud paragraph (L470) and the
forward pointer "See `#### Model Routing` below for the dispatch-time
resolution flow" (L468). The pointer exists because two sections are
needed; if one section is needed, the pointer is also unneeded.

The precedence-chain step 3 (L505) ALSO restates the same two-step
resolution at a third location ("indexed by the active dispatch host
(from `detect_host`) and the tier name carried on the agent (or
`inherit` when the agent declares no explicit `model:` field)").

## Why it's a simplification candidate

- **Three locations to keep in sync.** Any future schema change (a
  third host, a renamed tier, a different fallback story for `inherit`)
  has to be applied in three prose locations, plus the YAML example
  in the schema H4, plus the BATS fixture in TE7. Three-way prose
  drift is a known maintenance risk; the R1 fix that created this
  shape was itself triggered by a single-location-of-truth violation
  (the original schema H4 still claimed role→provider/model after the
  config moved to host→tier→model).
- **Reader cost.** A new reader of SKILL.md hitting L448 reads the
  two-step resolution, the versioned-ID rationale, and the `inherit`
  semantics. Then at L499 (Precedence chain step 3) they read a
  truncated version of the same content. Then at L522 they read an
  expanded version of the same content. The expanded version adds
  nothing the schema H4 doesn't already state — it just restates it
  in numbered-list form with slightly more words.
- **The H4 title is structurally awkward.** `#### Model Routing`
  (Title Case, no backticks, no underscore) sits adjacent to
  `#### `model_routing:` block` (lowercase, code-formatted, with
  backticks). The titles differ only by capitalization and
  formatting; their headings sort adjacently in the TOC and the
  distinction-by-title-style is fragile (TE6 had to spell this
  distinction out explicitly in its test comment: "the existing
  `#### `model_routing:` block` section (lowercase, code-formatted,
  about the YAML schema) does NOT satisfy this expectation"). The
  test comment is itself evidence that the two-headings shape is hard
  to disambiguate from prose alone.

## Suggested shape (semantics-preserving)

Two routes, either of which preserves every load-bearing fact:

**Route A: collapse the new H4 into the schema H4.** Move the
two-step numbered list from L530-L537 into the schema H4 immediately
after L450's intro sentence. Delete L468 (forward pointer), L522-L546
(new H4), and the duplicated rationale paragraphs. The schema H4
already names `detect_host`, both host strings, the four-tier shape,
the versioned-ID requirement, and the fail-loud rule. The numbered
list is the only structurally new content the new H4 adds.

**Route B: keep the new H4 but strip the schema H4 down.** Remove the
two-step resolution prose from L450 and the versioned-ID rationale
from L466 (leaving only schema-shape statements: "four tier rows",
"fully versioned IDs required"). Let the new H4 own the dispatcher-
behavior story. Then the forward pointer at L468 carries real
information.

Route A is shorter and removes more duplication; Route B preserves the
"schema vs. behavior" separation the R1 fix was reaching for. Either
preserves all observable test contracts (TE6 only requires the
"Model Routing" heading to exist AND name `detect_host` AND name
`model_routing`; both routes preserve that).

## Why this is advisory only

This is documentation-prose redundancy, not a functional defect. The
schema is correctly described in all three locations; readers receive
the right answer. The verifier may KEEP the current shape if the team
values explicit cross-referencing over single-source-of-truth. The
R1 fix-task spec required adding a "Model Routing" section by name
(TE6 pins that heading text), so collapsing it back into the schema
H4 would require updating the TE6 pin to grep for the resolution-flow
content under the schema H4 anchor instead. That's a coordinated edit,
not a regression.

## Pointer

- `skills/using-qrspi/SKILL.md:448-470` (schema H4)
- `skills/using-qrspi/SKILL.md:499-508` (Precedence chain step 3)
- `skills/using-qrspi/SKILL.md:522-546` (new Model Routing H4)
- `tests/unit/test-agent-frontmatter-no-model.bats:519-550` (TE6 — would need re-aiming if Route A is taken)

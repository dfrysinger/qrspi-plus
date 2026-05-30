---
status: draft
question_ids: [7]
research_type: codebase
---

# Q7: Validation table, dispatch-routing fail-loud paragraphs, and their prose pattern in `skills/using-qrspi/SKILL.md`

## Summary

**TL;DR:** The validation table at L647–660 is a 3-column Markdown table enumerating nine `config.md` fields, the skills that validate each, and their valid values; it lives under the section-heading `### Fields that affect pipeline behavior (must be validated)`. The four fail-loud paragraphs at L470, L488, L501, and L526 are in a separate earlier section (`### Dispatch routing blocks`, H4 sub-sections) and address dispatcher-runtime failures caused by the T9 sweep emptying agent-bundled `model:` fields; no field covered by the four paragraphs appears in the validation table. Each fail-loud paragraph follows a three-part prose template (trigger condition → halt/report statement → anti-fallback rationale citing G7b/#204). The class-level invariant directly above all four paragraphs appears at L422 as the opening sentence of `### Dispatch routing blocks`.

**Key findings:**

- **Validation table (L647–660):** A `| Field | Skills that validate it | Valid values |` 3-column table with nine rows: `route`, `pipeline`, `codex_reviews`, `review_depth`, `review_mode`, `verifier_enabled`, `scope_tagger_enabled`, `visual_fidelity_required`, and `question_budget`. Headed by `### Fields that affect pipeline behavior (must be validated)` at L647. None of the dispatcher-routing blocks (`model_routing:`, `trusted_path:`, `validators:`) appear as rows in this table.

- **Sectional separation:** The four fail-loud paragraphs live inside `### Dispatch routing blocks` (L420–552), a separate section that precedes the `## Config Validation Procedure` section (L554 onward) containing the validation table. The two sections address different layers: dispatcher-runtime routing vs. skill-level field validation.

- **Four fail-loud paragraph locations and their H4 parents:**
  - L470 — tail of `#### \`model_routing:\` block` (L448): covers config-load and dispatch-time detection of a missing host key, missing tier row, or bare short-form value in the `model_routing:` block.
  - L488 — tail of `#### \`trusted_path:\` block` (L472): covers the case where a `trusted_path:` match succeeds but the matched agent's frontmatter has no `model:` field (T9 sweep sub-case).
  - L501 — tail of `#### \`validators:\` block` (L490): covers the case where the `citation_density_floor` validator triggers a trusted-model re-run but the matched agent has no `model:` field (T9 sweep sub-case).
  - L526 — tail of `#### Missing \`model_routing:\` block in \`config.md\`` (L514): covers the case where `model_routing:` is absent from `config.md` and the in-memory backfill resolves to an agent with no `model:` field (T9 sweep sub-case).

- **Prose template shared by all four paragraphs:** Each paragraph follows three consecutive parts:
  1. *Trigger sentence:* "When [specific dispatcher path activates] [parenthetical: "the state established for all agents after the T9 sweep" where applicable], [consequence: 'X has no concrete Y to return/apply/use']."
  2. *Halt/report sentence:* "The dispatcher halts and reports [context-specific details of what is reported]."
  3. *Anti-fallback sentence:* "The dispatcher never falls back silently to [bypassed alternative] and never passes [dispatch/re-run] through to the host CLI's silent re-routing — both fallbacks would reproduce the G7b/#204 silent-fallback class this hardening release exists to close[, one layer deeper than the `model_routing:` [and `trusted_path:`] path[s]]."

- **Heading format for H4 sections:** Block-name H4s are formatted as `` #### `<block-name>:` block `` (backtick-wrapped name, colon included, literal word "block"). The anomalous section is `#### Missing \`model_routing:\` block in \`config.md\`` (L514), which follows a "Missing X in Y" pattern. The non-block H4s are `#### Precedence chain` (L503) and `#### Model Routing` (L528) — plain words, no backticks.

- **Cross-reference anchor format:** Internal references to H4 headings use backtick-quoted heading text inline (not `[text](#anchor)` links): e.g., `` See `#### Model Routing` below `` (L468) and `` See `#### \`model_routing:\` block` and `#### Model Routing` `` (L509).

- **Class-level invariant at L422:** The opening prose of `### Dispatch routing blocks` (L420) states: "The following four blocks in `config.md` are consumed by Slice 1 dispatch sites (the dispatcher, the per-task routing chain, and role-frontmatter resolution). They are optional in the `config.md` frontmatter — their absence means dispatch falls back to agent-bundled defaults. When present, all four blocks are authoritative and override any agent-bundled default." This is the only sentence-level invariant scoping the dispatch-routing section as a whole.

- **Additional class-level statement at L418:** Immediately before `### Dispatch routing blocks`, a bold paragraph `**No silent fallback.**` at L418 states: "All subsequent skills must read `config.md` for route and Codex config. … Skills do not silently default any field that affects pipeline behavior. There is no automatic derivation of the route." This is attached to the Goals section, not to the `### Dispatch routing blocks` heading itself, but it immediately precedes the section.

**Surprises:** The `providers:` block H4 (L424) is one of the "four blocks" named in the class-level invariant at L422 but is the only one of the five H4 sub-sections in `### Dispatch routing blocks` that has no fail-loud paragraph appended — it ends at L446 with the field description only.

**Caveats:** Line numbers are based on direct inspection; no guarantee they are stable across future edits. The `#### Precedence chain` (L503) and `#### Model Routing` (L528) H4 sub-sections were read in full and confirmed to contain no fail-loud paragraphs. The relationship between the fail-loud paragraphs and the validation table is structural (they are in separate sections with no cross-references between them); no explicit textual cross-reference from either to the other was found.

## Full findings

### Validation table at L647–660

The table is located under the `## Config Validation Procedure` section → `### Fields that affect pipeline behavior (must be validated)` sub-section (L647). It has three columns: `Field`, `Skills that validate it`, and `Valid values`.

**Table rows (L649–660):**

| Field | Skills that validate it | Valid values |
|-------|------------------------|--------------|
| `route` | Goals, Plan, Parallelize, Implement, Integrate, using-qrspi | ordered list of skill names |
| `pipeline` | Goals, Plan, Parallelize | `full` or `quick` |
| `codex_reviews` | Goals, Plan, Design, Phasing, Structure, Replan, Implement, Integrate, Test | `true` or `false` |
| `review_depth` | Implement | `quick` or `deep` |
| `review_mode` | Implement | `single` or `loop` |
| `verifier_enabled` | Goals, Implement | `true` or `false` |
| `scope_tagger_enabled` | Goals, Implement | `true` or `false` |
| `visual_fidelity_required` | Goals, Design, Phasing, Plan, Implement | `true` or `false` |
| `question_budget` | Goals, Plan, Parallelize (validators); Research (runtime consumer) | positive integer 1–50 |

None of the dispatcher-routing-block names (`model_routing:`, `trusted_path:`, `validators:`) appear as field names in this table. The table's scope is skill-level validation of scalar config fields; it does not enumerate validation procedures for the four dispatcher blocks.

### Section structure of `### Dispatch routing blocks`

`### Dispatch routing blocks` spans L420–552. It contains seven H4 sub-sections:

1. `#### \`providers:\` block` (L424) — no fail-loud paragraph
2. `#### \`model_routing:\` block` (L448) — fail-loud paragraph at L470
3. `#### \`trusted_path:\` block` (L472) — fail-loud paragraph at L488
4. `#### \`validators:\` block` (L490) — fail-loud paragraph at L501
5. `#### Precedence chain` (L503) — no fail-loud paragraph (only a numbered list)
6. `#### Missing \`model_routing:\` block in \`config.md\`` (L514) — fail-loud paragraph at L526
7. `#### Model Routing` (L528) — no fail-loud paragraph (resolution flow prose)

### Class-level invariants above the four fail-loud paragraphs

**L420–422** — The `### Dispatch routing blocks` section opens with a single prose block that acts as the class-level invariant for all H4 sub-sections within it (verbatim):

> "The following four blocks in `config.md` are consumed by Slice 1 dispatch sites (the dispatcher, the per-task routing chain, and role-frontmatter resolution). They are optional in the `config.md` frontmatter — their absence means dispatch falls back to agent-bundled defaults. When present, all four blocks are authoritative and override any agent-bundled default."

This is the only sentence immediately heading the section and the only statement that characterizes the dispatch-routing section as a whole. It establishes two invariants:
- **Optionality invariant:** the four blocks are optional; absence → agent-bundled fallback.
- **Authoritative-when-present invariant:** presence → override of all agent-bundled defaults.

**L418** — The bold `**No silent fallback.**` paragraph immediately preceding `### Dispatch routing blocks` (attached to the Goals narrative) states: "All subsequent skills must read `config.md` for route and Codex config. … Skills do not silently default any field that affects pipeline behavior. There is no automatic derivation of the route." This is not inside `### Dispatch routing blocks` but is the closest prior class-level statement of the no-silent-fallback rule.

### Prose pattern for the four fail-loud paragraphs

All four paragraphs follow the same three-part structure. The template is:

**Part 1 — Trigger condition sentence:**  
"When [specific dispatcher code path activates and creates a dead-end] [(optional parenthetical: "the state established for all agents after the T9 sweep")], [subject] has no concrete [value/target] to [return/apply/use]."

**Part 2 — Halt/report sentence:**  
"The dispatcher halts and reports [context-specific details of what is included in the report]."

**Part 3 — Anti-fallback sentence:**  
"The dispatcher never falls back silently to [the specific alternative that this code path bypasses] and never passes [the dispatch / re-run] through to the host CLI's silent re-routing — both fallbacks would reproduce the G7b/#204 silent-fallback class this hardening release exists to close[, one layer deeper than the `model_routing:` [and `trusted_path:`] path[s]]."

**Per-paragraph instantiation:**

**L470** (`model_routing:` block — dispatcher-scoped, config-structure errors):
- Trigger: `detect_host` returns an unrecognized host key, or an agent's tier name matches no row under the matched host's sub-mapping, or a tier value is a bare short-form rather than a fully versioned model ID.
- Halt/report: "the dispatcher halts and reports the missing or invalid entry."
- Anti-fallback: "The dispatcher never falls back silently to the agent-bundled default and never passes the dispatch through to the host CLI's silent re-routing — both fallbacks would reproduce the G7b/#204 silent-fallback class this hardening release exists to close."
- Notable: this paragraph does NOT include the "T9 sweep" parenthetical; it addresses structural errors in the `model_routing:` block itself, not the agent-bundled-default-is-empty sub-case. No "one layer deeper" qualifier.

**L488** (`trusted_path:` block — dispatcher-scoped, T9 sub-case):
- Trigger: `trusted_path:` matches but matched agent's frontmatter declares no `model:` field (T9 sweep parenthetical present).
- Halt/report: "The dispatcher halts and reports the trusted_path: match plus the empty agent-bundled default."
- Anti-fallback: "The dispatcher never falls back silently to `model_routing:` (which `trusted_path:` explicitly bypasses) and never passes the dispatch through to the host CLI's silent re-routing — both fallbacks would reproduce the G7b/#204 silent-fallback class this hardening release exists to close, **one layer deeper than the `model_routing:` path**."

**L501** (`validators:` block — dispatcher-scoped, T9 sub-case):
- Trigger: the `citation_density_floor` validator triggers a trusted-model re-run and the matched agent's frontmatter declares no `model:` field (T9 sweep parenthetical present).
- Halt/report: "The dispatcher halts and reports the validator trigger plus the empty agent-bundled default."
- Anti-fallback: "The dispatcher never falls back silently to `model_routing:` (which the re-run explicitly bypasses) and never passes the re-run through to the host CLI's silent re-routing — both fallbacks would reproduce the G7b/#204 silent-fallback class this hardening release exists to close, **one layer deeper than the `model_routing:` and `trusted_path:` paths**."

**L526** (Missing `model_routing:` block — missing-block, T9 sub-case):
- Trigger: in-memory backfill resolves an agent's "bundled default" but the matched agent's frontmatter declares no `model:` field (T9 sweep parenthetical present).
- Halt/report: "The dispatcher halts and reports the missing-`model_routing:` condition plus the empty agent-bundled default."
- Anti-fallback: "The dispatcher never falls back silently to the host CLI's silent re-routing and never substitutes an unannounced model — either fallback would reproduce the G7b/#204 silent-fallback class this hardening release exists to close, **one layer deeper than the `model_routing:` and `trusted_path:` paths**."
- Additional sentence (unique to L526): "The one-time warning above announces the missing block; the halt-and-report on empty step 4 announces the consequence."

**Depth qualifier escalation pattern:** L470 has no "layer deeper" qualifier; L488 adds "one layer deeper than the `model_routing:` path"; L501 and L526 add "one layer deeper than the `model_routing:` and `trusted_path:` paths". Each paragraph's depth qualifier names the set of paths already covered by earlier paragraphs in the section.

### Heading and anchor format

H4 block-name headings follow the pattern:
```
#### `<block-name>:` block
```
with the block name backtick-wrapped and the colon included inside the backticks (e.g., `` #### `model_routing:` block ``).

The missing-block H4 deviates:
```
#### Missing `model_routing:` block in `config.md`
```
using "Missing X in Y" wording with backticks around the block name and the filename separately.

Cross-reference anchor format: headings are referenced by backtick-quoting the full heading text inline, not using `[text](#anchor)` Markdown link syntax. Examples:
- L468: `` See `#### Model Routing` below for the dispatch-time resolution flow. ``
- L509: `` See `#### \`model_routing:\` block` and `#### Model Routing` for schema + resolution flow. ``

No named fragment anchors (HTML `<a id="...">` tags) were found; all heading references rely on backtick-quoted prose.

### Relationship between the four paragraphs and the validation table

The two pieces address orthogonal layers of config handling:

- **Validation table (L647–660):** Skill-level validation of nine scalar `config.md` fields during normal pipeline step execution. The fields covered (route, pipeline, codex_reviews, etc.) are read by named skills and validated on re-entry per the Config Validation Procedure.

- **Four fail-loud paragraphs (L470, L488, L501, L526):** Dispatcher-runtime failures within Slice 1 dispatch sites when either (a) the `model_routing:` block contains structurally invalid entries or (b) a post-T9-sweep agent has an empty `model:` field at the point where the dispatcher would resolve the agent-bundled default. These scenarios are not represented in the validation table.

No explicit cross-reference exists between the two. The `model_routing:`, `trusted_path:`, and `validators:` block names do not appear as rows in the validation table; conversely, the validation table's field names (route, pipeline, etc.) do not appear in the fail-loud paragraphs' trigger conditions. The fail-loud paragraphs enforce the G7b/#204 no-silent-fallback class specifically for the dispatcher's model-resolution chain, whereas the validation table enforces that skills read correct config field values before executing pipeline logic.

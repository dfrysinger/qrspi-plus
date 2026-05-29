---
finding_id: F01
change_type: clarity
severity: 80
location: skills/using-qrspi/SKILL.md:448-535 (and L488-497 cascade)
---

# Two contradictory schemas documented for the same `model_routing:` YAML key in adjacent sections of the same document

## Problem

After this round, `skills/using-qrspi/SKILL.md` contains two `####` subsections under the same `### Dispatch routing blocks` parent (L420) that purport to document the same YAML key, `model_routing:`, with incompatible schemas:

**Pre-existing (L448–459):** `#### \`model_routing:\` block`
```yaml
model_routing:
  researcher: my-provider/gpt-4o
  reviewer:   my-provider/gpt-4o-mini
  implementer: other-provider/claude-opus-4
```
Schema: flat `role → <provider-name>/<model-id>` mapping. L459 makes the schema load-bearing — `<provider-name>` must refer to an entry in `providers:`, and a missing reference is a hard config-validation error.

**Added this round (L511–535):** `#### Model Routing`
```yaml
model_routing:
  claude-code:
    haiku: claude-haiku-4.5
    ...
  copilot-cli:
    haiku: claude-haiku-4.5
    ...
```
Schema: nested `host → tier → <model-id>` mapping-of-mappings. No `providers:` reference appears.

These two shapes are mutually exclusive at the YAML level — a single `model_routing:` block in a real `config.md` cannot simultaneously match both. The new T10 block in `docs/qrspi/2026-05-27-v071-hardening/config.md` (added L23–34 of that file) commits to the host→tier→model shape, contradicting the pre-existing schema-doc at L448.

The contradiction cascades into the "Precedence chain" subsection (L488–497):

- L494: *"`model_routing:` role lookup — the role name resolved via the `model_routing:` block in `config.md`."*

This step walks through the old role-lookup mechanism that the new resolution flow does not use. A reader following the precedence chain hits a step that doesn't fit either the new section's two-step host/tier indexing or the v0.7.1 hardening's actual dispatch model.

The new `#### Model Routing` section *itself* is clean and well-written (clear two-step resolution prose, no em-dashes per user preference, sensible explanation of the bare-short-form rationale). The defect is structural: it was added *into* a parent section whose existing prose describes an incompatible schema for the same key, without reconciling the conflict.

Evidence the test-writer was already aware of the heading-name collision (test comment at TE6, diff L506–511):
> *"the existing `#### \`model_routing:\` block` section (lowercase, code-formatted, about the YAML schema) does NOT satisfy this expectation — the new section must be a distinct heading titled 'Model Routing' (capital M, capital R, no backticks) that documents the dispatcher resolution flow."*

The test disambiguates the two sections so its `_markdown_section "Model Routing"` lookup pins to the new one, but the underlying document defect — two incompatible schemas for the same YAML key in the same `###` parent — is left in place.

## Why this matters

Schema docs are read by future implementers building skills that consume `config.md`. When the same YAML key has two incompatible schemas documented 60 lines apart in the same parent section:

1. A future implementer of any dispatch-resolution code (Slice 1 wire-up; the T11+ dispatcher prose; downstream tasks consuming the table) faces an ambiguous source-of-truth question — they will need to either pick one and document the choice, or escalate.
2. The "Precedence chain" walk at L488–497 is now factually wrong for the v0.7.1 hardening's actual dispatch path. A reader walking the chain will produce an implementation that disagrees with the new section.
3. The two `####` headings within `### Dispatch routing blocks` advertise themselves as peer documentation surfaces for the same block — a quality signal that the document is in a clean state, when it is not.

## Suggested fix

Reconcile the schema. Two viable resolutions; both fit within or just past T10's scope:

- **(a) Replace the pre-existing schema block.** Rewrite L448–459 to document the host→tier→model shape (the v0.7.1 shape T10 commits to), and update the L488–497 precedence chain step 3 to describe the two-step host/tier resolution instead of the role lookup. Drop the new `#### Model Routing` section's content into the rewritten L448 block (or keep it as a sibling explicitly labeled "Resolution flow" / "Schema" pair). The role→provider/model shape was apparently from an earlier design iteration that v0.7.1 supersedes; if so, this is the right resolution.
- **(b) Frame the two as alternates with version pinning.** If the role→provider/model schema is still live for some configurations and the host→tier→model schema is v0.7.1-specific, mark each section with explicit scope ("Schema A — generic role routing", "Schema B — v0.7.1 per-host tier routing"), state which configurations use which, and update the precedence chain to fork on configuration shape.

Resolution (a) is the more likely correct outcome given that T9 sweep removed `model:` from all 41 agent files and T10 adds the per-host table — that combination reads as a complete schema replacement, not a parallel-schemas situation.

Either resolution is arguably out of T10's literal target-files scope (T10 only lists modifying L511-area new content, not L448-area pre-existing content), so the orchestrator may judge this as a planning gap surfaced by T10 rather than an implementer defect. Filing it because the document is shipped in a self-contradictory state after this round, regardless of who owns the fix.

## Confidence

High that the contradiction exists and is load-bearing for downstream maintenance. Medium on the right scope to fix it in (T10 vs. follow-up).

---
status: draft
task: 10
round: 1
fix_type: doc-reconciliation
target_files:
  - skills/using-qrspi/SKILL.md
test_targets:
  - tests/unit/test-agent-frontmatter-no-model.bats
---

# Fix-task 01 — Reconcile contradictory `model_routing:` schemas in skills/using-qrspi/SKILL.md

## Findings being closed

- `quality-claude.finding-F01.md` — verifier-scored 80 (AT clarity KEEP threshold per Hotfix B); KEPT.
- `quality-codex.finding-F01.md` — independent corroboration of the same defect.

## Problem

After T10 round 01, `skills/using-qrspi/SKILL.md` ships with two `####` subsections under the same `### Dispatch routing blocks` parent that document the same `model_routing:` YAML key with **mutually incompatible schemas**:

- **L448–460 (pre-existing):** `#### \`model_routing:\` block` — flat `role → <provider-name>/<model-id>` shape.
- **L511–535 (T10-added):** `#### Model Routing` — nested `host → tier → <model-id>` shape (which matches `docs/qrspi/2026-05-27-v071-hardening/config.md`'s actual block).

The L488–497 "Precedence chain" subsection at step 3 (L494) still says "**`model_routing:` role lookup** — the role name resolved via the `model_routing:` block in `config.md`." — describing the retired role-based scheme.

## Scope rationale

T10's target-files list named SKILL.md but the spec only authorized the new section (the L511-area content). L448–460 + L494 are pre-existing and out of T10's literal target. **However**, T9 removed `model:` from all 41 agent files and T10 adds host→tier→model — together this is a complete schema replacement for v0.7.1. Shipping the doc in a self-contradictory state is a Plan-phase scope-gap (third instance in this run after T4/T7/T8 patterns). Orchestrator authorizes the fix as in-scope correctness maintenance — the doc must be self-consistent before merge.

## Approach: schema replacement (reviewer option a)

The v0.7.1 hardening retires role-based routing. Replace the old schema doc with the new shape; do not keep both.

### Slice 1: Replace L448–460 schema doc

Replace the entire block (L448–460) with a concise schema doc for the host→tier→model shape that references the resolution-flow section below. The new schema doc should:

- Title: `#### \`model_routing:\` block` (keep existing heading text so any cross-references in other skills still match)
- Document the host→tier→model YAML shape with a small example
- Cross-reference the `#### Model Routing` section (L511) for resolution-flow prose
- Drop the old role-based example and the `<provider-name>/<model-id>` paragraph

Suggested replacement body (the inner triple-backtick fence is escaped to `\``` for this spec; un-escape when authoring SKILL.md):

```markdown
#### `model_routing:` block

Maps abstract Claude tier names to concrete versioned model IDs, per dispatch host. The dispatcher resolves an agent dispatch by (1) detecting the host CLI it is running under and (2) looking up the tier name carried on the agent (or `inherit` when the agent declares no explicit `model:` field).

\```yaml
model_routing:
  claude-code:
    haiku: claude-haiku-4.5
    sonnet: claude-sonnet-4.6
    opus: claude-opus-4.7-high
    inherit: claude-sonnet-4.6
  copilot-cli:
    haiku: claude-haiku-4.5
    sonnet: claude-sonnet-4.6
    opus: claude-opus-4.7-high
    inherit: claude-sonnet-4.6
\```

Top-level keys are the host names emitted by `detect_host` (see Codex dispatch transport routing). Each host sub-mapping contains exactly four tier rows: `haiku`, `sonnet`, `opus`, and `inherit`. Values are fully versioned model IDs (e.g. `claude-haiku-4.5`, not the bare tier short-form `haiku`) — Copilot CLI's model proxy emits a "model not available" warning for bare tier requests but accepts versioned IDs.

See `#### Model Routing` below for the dispatch-time resolution flow.
```

### Slice 2: Update L494 precedence chain step 3

Replace:

```markdown
3. **`model_routing:` role lookup** — the role name resolved via the `model_routing:` block in `config.md`.
```

with:

```markdown
3. **`model_routing:` host/tier lookup** — the concrete model ID resolved via the `model_routing:` block in `config.md`, indexed by the active dispatch host (from `detect_host`) and the tier name carried on the agent (or `inherit` when the agent declares no explicit `model:` field). See `#### \`model_routing:\` block` and `#### Model Routing` for schema + resolution flow.
```

### Slice 3: Anchor regeneration

The above edits will shift downstream line offsets. Run `bash tools/g4-section-anchor-refresh.sh` to regenerate `skills/using-qrspi/SKILL.anchors.json`. Re-run the unit suite and confirm `test-section-anchor-narrow-read.bats` passes.

### Slice 4: Pinning test (optional but recommended)

Add a single assertion to `tests/unit/test-agent-frontmatter-no-model.bats` (or follow the `tests/unit/test-implement-skill-vocab.bats` pattern from the W2/3 INTEGRATE fix) that pins the absence of the old `role → provider/model` schema language from SKILL.md so a future re-introduction would fail CI. Regex suggestion (case-sensitive, must NOT match):

- `Maps role names to provider-plus-model pairs`
- `model_routing: role lookup`
- The `<provider-name>/<model-id>` schema sentence

If adding a new pin file is too invasive for a round 01 fix, append the assertions to an existing skill-markdown pin file. Choose whichever is cleaner; both are acceptable.

## Test Expectations

- TE1: `skills/using-qrspi/SKILL.md` no longer contains the literal string `Maps role names to provider-plus-model pairs`.
- TE2: `skills/using-qrspi/SKILL.md` no longer contains `**\`model_routing:\` role lookup**`.
- TE3: `skills/using-qrspi/SKILL.md` `#### \`model_routing:\` block` section now documents the host→tier→model shape (grep-confirms presence of literal `haiku: claude-haiku-4.5` inside the YAML example AND presence of `claude-code:` + `copilot-cli:` as sub-keys).
- TE4: All pre-existing T9 + T10 tests in `tests/unit/test-agent-frontmatter-no-model.bats` remain GREEN (19/19 ok).
- TE5: Full unit suite passes (anchor regen handled; test-section-anchor-narrow-read.bats green).
- TE6 (pinning test, optional): added pin asserts absence of the retired schema language so future regression fails CI.

## Out of scope

- Code paths that consume the table at runtime (none exist in this round; future task will wire dispatcher).
- Re-running any review fan-out — round 02 fan-out will run after the fix lands.
- Touching `config.md` (already correct).
- Touching the L511 `#### Model Routing` section body (well-written per quality-claude; only update if cross-references shift).

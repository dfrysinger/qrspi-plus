# Finding F03

**change_type:** removal (incomplete — retired model-name vocabulary in advisory table)
**severity:** p0
**location:** `skills/implement/SKILL.md:1489–1496`

## Description

The `## Model Selection Guidance` section was **not changed** by the G22 migration and still contains:

```markdown
## Model Selection Guidance

| Task complexity | Recommended model |
|-----------------|-------------------|
| Mechanical tasks (1-2 files, clear spec) | Fast/cheap model (haiku) |
| Integration tasks (multi-file, pattern matching) | Standard model (sonnet) |
| Architecture/design/review | Most capable model (opus) |
```

This table does not appear anywhere in the round-03.diff for `skills/implement/SKILL.md`.

### Verdict (as requested by dispatch)

**This IS in-scope retired schema, not legit out-of-scope capability guidance.**

Rationale:

1. **Routing guidance, not capability narrative.** The table guides operators/dispatchers on which model to select for a given task complexity. That is exactly the routing decision G22 migrated from concrete model names to abstract tier names. The `### Per-Task Classification (Step 2)` section in `skills/plan/SKILL.md` already documents the correct post-migration form: `task_type == lightweight → tier: low`, ordinary code → `tier: medium`, escalated code → `tier: high`. Having the `## Model Selection Guidance` table in `implement/SKILL.md` tell dispatchers to use "haiku / sonnet / opus" directly contradicts that guidance.

2. **Task spec scope.** The task spec explicitly states: "Rewrite the G22 surfaces in `skills/implement/SKILL.md`: remove the old per-host `haiku`/`sonnet`/`opus`/`inherit` schema." The advisory table uses `haiku`, `sonnet`, and `opus` as routing-level vocabulary in `implement/SKILL.md`. It is squarely within the stated removal scope.

3. **Not a carve-out.** The dispatch carve-outs are: Codex-transport `detect_host` (using-qrspi ~411), `test_writer_tier`, and intentional test-guarded `model: "sonnet"` dispatch-call examples. The `## Model Selection Guidance` table fits none of these carve-outs.

4. **Contradiction risk (P0).** An operator reading `implement/SKILL.md` encounters:
   - The `### Per-Task Routing (task_type)` section (correctly migrated) which now says `(vendor, model)` is resolved through the Tier Resolution Chain.
   - The `## Model Selection Guidance` table below it which says "use haiku for mechanical tasks, sonnet for integration, opus for architecture."
   These two sections now contradict each other. The `## Model Selection Guidance` table has no reference to tier names and will lead operators to bypass the tier chain with direct model names.

## Suggested fix

Replace the `## Model Selection Guidance` table with tier-based guidance:

```markdown
## Model Selection Guidance

Task routing is driven by the per-task `tier:` field set by Plan (see `skills/plan/SKILL.md` § Per-Task Classification). The tier-to-model mapping is resolved by `scripts/_resolve-lib.sh` against `config.md`'s `model_routing:` block. The heuristic for selecting a tier:

| Task complexity | Recommended tier |
|-----------------|-----------------|
| Mechanical tasks (1-2 files, clear spec) | `low` |
| Integration tasks (multi-file, pattern matching) | `medium` (default) |
| Architecture/design/review | `high` |

The concrete model paired with each tier is set in `config.md` `model_routing:` and can be adjusted by the operator per-run without code changes. For co-escalation behavior (high-tier tasks escalate both implementer and test-writer), see `#### Tier Resolution Chain` above.
```

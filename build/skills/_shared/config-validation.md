# Config Validation Procedure (shared)

Single source of truth for `config.md` field validation across every skill that reads route or pipeline behavior. Every skill that reads `config.md` applies this procedure before using any field. Self-contained: every menu and rule the skill must apply is below.

## When config.md is missing entirely

Stop and present:

```
config.md not found in the artifact directory.

1) Re-run Goals to create config.md and set the pipeline mode
2) Abort
```

## When a required field is missing or has an invalid value

Stop and present the field-specific menu below. For an invalid value, also name the invalid value and the expected values before showing the menu. The set of fields each skill validates is per-skill (declared by each consuming skill); the menu for a given field is the same across all skills.

**If `route` is missing:**
1. Manually add a `route:` list to config.md
2. Abort

**If `pipeline` is missing or invalid (expected `full` or `quick`):**
1. Edit config.md and set `pipeline: full` or `pipeline: quick`
2. Abort

**If `second_reviewer` is missing or invalid (expected `true` or `false`):**
1. Edit config.md and set `second_reviewer: true` or `second_reviewer: false`
2. Abort

**If a legacy `codex_reviews:` field is present (renamed to `second_reviewer:`):**
1. `codex_reviews:` is no longer a valid field — it was renamed to `second_reviewer:`. Reject it loudly with a rename-naming diagnostic; do NOT silently alias `codex_reviews:` to `second_reviewer:`. Edit config.md: remove the `codex_reviews:` line and set `second_reviewer: true` or `second_reviewer: false`.
2. Abort

**If `visual_fidelity_required` is missing or invalid (expected `true` or `false`):**
1. Edit config.md and set `visual_fidelity_required: true` or `visual_fidelity_required: false`
2. Re-run Goals to regenerate config.md
3. Abort

**If `verifier_enabled` is missing or invalid (expected `true` or `false`):**
1. Edit config.md and set `verifier_enabled: true` or `verifier_enabled: false`
2. Abort

**If `scope_tagger_enabled` is missing or invalid (expected `true` or `false`):**
1. Edit config.md and set `scope_tagger_enabled: true` or `scope_tagger_enabled: false`
2. Abort

**If `question_budget` is missing, present-when-forbidden, or has an invalid value** (expected: a positive integer between 1 and 50 inclusive when `pipeline: quick`; absent entirely when `pipeline: full`). The four failure modes each present the same shape of menu:

- **Missing-when-quick-required** (`pipeline: quick` but `question_budget` absent):
  1. Re-run Goals to regenerate config.md with `question_budget: 5` (the default)
  2. Edit config.md and add `question_budget: <N>` (positive integer between 1 and 50 inclusive)
  3. Abort

- **Present-when-full-forbidden** (`pipeline: full` but `question_budget` is set; the field has no meaning on full-pipeline runs and a stale value would mislead readers):
  1. Edit config.md and remove the `question_budget` line entirely
  2. Re-run Goals to regenerate config.md (full pipeline omits the field)
  3. Abort

- **Value zero or negative** (e.g. `question_budget: 0`, `question_budget: -3`):
  1. Edit config.md and set `question_budget` to a positive integer between 1 and 50 inclusive (e.g. `5`)
  2. Re-run Goals to regenerate config.md
  3. Abort

- **Value non-integer or out-of-range** (e.g. `question_budget: 2.5`, `question_budget: many`, `question_budget: 0x5`, or any value greater than 50; the cap of 50 exists because Research specialist dispatch fan-out wider than 50 exhausts orchestrator subagent slots and produces diminishing-returns coverage):
  1. Edit config.md and set `question_budget` to a positive integer between 1 and 50 inclusive (e.g. `5`)
  2. Re-run Goals to regenerate config.md
  3. Abort

The missing-on-read case for `verifier_enabled`, `scope_tagger_enabled`, or `visual_fidelity_required` is covered by the runtime-backfill carve-outs below; these menus fire when the field has an invalid value (e.g. `verifier_enabled: yes`, `scope_tagger_enabled: disabled`) or is absent in a fresh-run context where backfill does not apply. The `question_budget` field has no runtime-backfill carve-out: the menu above fires for any missing/invalid case.

## No silent defaults

Skills must not:
- Assume `pipeline: full` when `pipeline` is missing
- Assume `second_reviewer: false` when `second_reviewer` is missing
- Attempt to derive `route` from `pipeline` when `route` is missing
- Proceed with a guessed or inferred field value

## Exceptions to the no-silent-defaults rule

- **`verifier_enabled` runtime backfill.** If the field is missing from `config.md` on the first verifier-aware Apply-fix invocation of a run, the runtime treats it as `true`, surfaces a one-line stderr warning once per session (form: `verifier_enabled missing from config.md — backfilling default 'true' for this run`), and writes the field back to `config.md`.

- **`scope_tagger_enabled` runtime backfill.** Same shape as `verifier_enabled`: if the field is missing from `config.md` on the first scope-tagger-aware Apply-fix invocation of a run, the runtime treats it as `true`, surfaces a one-line stderr warning once per session (form: `scope_tagger_enabled missing from config.md — backfilling default 'true' for this run`), and writes the field back to `config.md`.

- **`visual_fidelity_required` runtime backfill.** Same shape: if the field is missing from `config.md` on the first visual-fidelity-aware skill invocation of a run, the runtime treats it as `false` (the default), surfaces a one-line stderr warning once per session (form: `visual_fidelity_required missing from config.md — backfilling default 'false' for this run`), and writes the field back to `config.md`. These three backfills are the only carve-outs from the no-silent-defaults rule.

- **Hard-stop on write-back failure (applies to all three backfills above).** The write-back to `config.md` is part of the carve-out's contract, not a best-effort side effect. If the write fails for any reason (read-only filesystem, permission error, lock contention, disk full), the runtime MUST stop issuing tool calls and present this to the user (in main chat, then wait for the user's selection):

  ```
  Stop and present:

    failed to write `<field>` to config.md — resolve before continuing

    1) Resolve the underlying write failure (fix permissions, free disk space, release the lock) and re-invoke the current skill to retry
    2) Abort
  ```

  Do NOT silently fall back to the in-memory default after a failed write: the next invocation re-fires the backfill (re-warns, re-attempts the write) indefinitely, and any cross-invocation behavior change in the default would silently produce inconsistent results across rounds. Hard-stop is the only correct path; the user resolves the underlying write failure and re-invokes the skill.

## Fields that affect pipeline behavior (must be validated)

| Field | Skills that validate it | Valid values |
|-------|------------------------|--------------|
| `route` | Goals, Plan, Parallelize, Implement, Integrate, using-qrspi | ordered list of skill names (see Route Templates) |
| `model_routing:` | using-qrspi, Goals, Plan, Parallelize, Implement, Integrate | required top-level block — a per-vendor five-tier map (one `{ vendor:, model: }` per tier); see the schema heading `model_routing:` block for the definition and the fail-loud heading `Missing model_routing: block in config.md` for the enforcement when the block is absent |
| `pipeline` | Goals, Plan, Parallelize | `full` or `quick` |
| `second_reviewer` | Goals, Plan, Design, Phasing, Structure, Replan, Implement, Integrate, Test | `true` or `false` |
| `review_depth` | Implement | `quick` or `deep` — set by Implement at phase start |
| `review_mode` | Implement | `single` or `loop` — set by Implement at phase start |
| `verifier_enabled` | Goals, Implement | `true` or `false` — set at run creation; gates per-finding verifier dispatch in the Apply-fix protocol |
| `scope_tagger_enabled` | Goals, Implement | `true` or `false` — set at run creation; gates per-round scope-tagger dispatch and convergence narrowing |
| `visual_fidelity_required` | Goals, Design, Phasing, Plan, Implement | `true` or `false` — set at run creation; gates the visual-fidelity binding chain |
| `question_budget` | Goals, Plan, Parallelize (validators); Research (runtime consumer) | positive integer between 1 and 50 inclusive (e.g. `5`, `12`) — present required when `pipeline: quick`, absent when `pipeline: full`; caps Research specialist dispatch count |

## Fields that do NOT require validation (informational only)

| Field | Note |
|-------|------|
| `created` | ISO date, informational only — missing is not an error |

## Config Runtime Contract

This file is the orchestrator-runtime contract for `config.md`: dispatch routing, validation procedure, no-silent-defaults rules, runtime backfill, and the field-validation-by-skill table. For the authoring side (format, field definitions, writing procedure, `pipeline: quick` semantics), see `skills/goals/references/config-md-authoring.md`.

**No silent fallback.** All skills read `config.md` for route and second-reviewer config. Missing or invalid fields go through the **Config Validation Procedure** below; no field is silently defaulted, and `route` is never derived from `pipeline`.

### Dispatch routing blocks

Four `config.md` blocks drive dispatch: `providers:`, `model_routing:`, `trusted_path:`, `validators:`. Implementation lives in `scripts/_resolve-lib.sh` (tier resolution) and `scripts/dispatch-agent.sh` (request transport, trusted_path short-circuit, validators). `model_routing:` is required; the other three are optional. Validation rules and fail-loud diagnostics live in `skills/_shared/config-validation-procedure.md` — `!cat`-included by every skill that reads routing config.

**`providers:` block** — map of named provider entries. Each entry: `base_url` (HTTP(S) endpoint root), `api_key_env` (name of the env var holding the API key — never the key itself), `transport_type` (exactly `openai-chat-completions` or `codex-broker`), optional `default_headers` (string map merged into every request).

```yaml
providers:
  my-provider:
    base_url: https://api.example.com/v1
    api_key_env: MY_PROVIDER_API_KEY
    transport_type: openai-chat-completions
```

**`model_routing:` block (required)** — maps five vendor-neutral routing tiers to concrete `(vendor, model)` pairs. `default_tier:` supplies the tier for agents missing a `tier:` field during migration.

```yaml
model_routing:
  extra-low:  none                                              # operator opts in
  low:        { vendor: claude, model: claude-haiku-4.5 }
  medium:     { vendor: claude, model: claude-sonnet-4.6 }
  high:       { vendor: claude, model: claude-opus-4.7 }
  extra-high: { vendor: claude, model: claude-opus-4.7-high }
default_tier: medium
```

Exactly five tier rows. `extra-low` defaults to `none` (operator opt-in). `extra-high` is the high-ceiling escalation tier; operator MAY set to `none` to opt out. Missing block is a hard validation failure — no silent fallback to agent-bundled defaults (G7b/#204 silent-fallback class).

**`trusted_path:` block** — flat list of agent file paths or role names that bypass the tier chain and route to the agent-bundled default.

```yaml
trusted_path:
  - agents/qrspi-implementer.md
  - reviewer
```

**`validators:` block** — post-dispatch output gates.

```yaml
validators:
  citation_density_floor: 0.05   # default: 0.05
```

`citation_density_floor` triggers a trusted-model re-run when output falls below the floor; the re-run output replaces the original and is logged as a one-line note.

**Precedence chain** (implemented by `scripts/_resolve-lib.sh resolve_tier`): `--tier-override` > agent `tier:` frontmatter > `default_tier:` > hardcoded `medium` with a loud warning. The resolved tier is then looked up in `model_routing:`. `trusted_path:` is a short-circuit ahead of this chain — matching agents/roles bypass tier resolution entirely. Every fallback layer halts loudly on unresolved routing targets — never silently falls back through to the host CLI.

**Per-host second-reviewer dispatch transport.** Host detection and per-host dispatch transport (Copilot CLI task-tool vs Claude Code shell-pipeline via `scripts/dispatch-agent.sh`) are owned by `scripts/_host-detect.sh` and `scripts/detect-interaction-mode.sh`. The dispatch surface emits a single-line stderr diagnostic on host/config mismatch and continues with the configured policy.

### Config Validation Procedure

Run `tests/fixtures/validate-config-field.sh <field> <artifact_dir>` before using any field. The script exits 0 on success and exits 1 with the numbered repair menu when the field is missing or invalid (artifact-dir-missing → "Re-run Goals to create config.md and set the pipeline mode"; field-specific menus follow the same shape: "Edit config.md and set `<field>` to a valid value", then "Abort"). The shared canonical rule for `model_routing:` missing/malformed lives in `skills/_shared/config-validation-procedure.md`.

### No silent defaults

Skills must not:
- Assume `pipeline: full` when `pipeline` is missing
- Assume `second_reviewer: false` when `second_reviewer` is missing
- Derive `route` from `pipeline` when `route` is missing
- Proceed with a guessed or inferred field value

### Exceptions to the no-silent-defaults rule (runtime backfill)

Three fields carve out runtime backfill: `verifier_enabled` (default `true`), `scope_tagger_enabled` (default `true`), `visual_fidelity_required` (default `false`). When any is missing on the first protocol-aware invocation, the runtime treats it as the default, surfaces a one-line stderr warning once per session (`<field> missing from config.md — backfilling default '<value>' for this run`), and writes the field back to `config.md`.

**Hard-stop on write-back failure.** The write-back is part of the carve-out contract, not a best-effort side effect. If the write fails (read-only fs, permission, lock, disk full), the runtime MUST stop issuing tool calls and present:

>   failed to write `<field>` to config.md — resolve before continuing
>
>   1) Resolve the underlying write failure (fix permissions, free disk space, release the lock) and re-invoke the current skill to retry
>   2) Abort

Do NOT silently fall back to the in-memory default after a failed write: a mismatch with on-disk state re-fires the backfill (re-warns, re-attempts) indefinitely. Hard-stop is the only correct path.

### Fields that affect pipeline behavior (must be validated)

| Field | Skills that validate it | Valid values |
|-------|------------------------|--------------|
| `route` | Goals, Plan, Parallelize, Implement, Integrate, using-qrspi | ordered list of skill names (see Route Templates) |
| `model_routing:` | using-qrspi, Goals, Plan, Parallelize, Implement, Integrate | required top-level block; see schema above |
| `pipeline` | Goals, Plan, Parallelize | `full` or `quick` |
| `second_reviewer` | Goals, Plan, Design, Phasing, Structure, Replan, Implement, Integrate, Test | `true` or `false` |
| `review_depth` | Implement | `quick` or `deep` — set by Implement at phase start |
| `review_mode` | Implement | `single` or `loop` — set by Implement at phase start |
| `verifier_enabled` | Goals, Implement | `true` or `false` — gates per-finding verifier dispatch in apply-fix |
| `scope_tagger_enabled` | Goals, Implement | `true` or `false` — gates per-round scope-tagger dispatch and convergence narrowing |
| `visual_fidelity_required` | Goals, Design, Phasing, Plan, Implement | `true` or `false` — gates the visual-fidelity binding chain |
| `question_budget` | Goals, Plan, Parallelize (validators); Research (runtime consumer) | integer 1-50; present when `pipeline: quick`, absent when `pipeline: full`; caps Research specialist dispatch count |

### Fields that do NOT require validation (informational only)

`created` — ISO date, informational only; missing is not an error.

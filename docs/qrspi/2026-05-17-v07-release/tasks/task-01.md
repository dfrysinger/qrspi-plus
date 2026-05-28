---
task: 1
status: approved
pipeline: full
task_type: lightweight
model: sonnet
phase: 1
goal_ids: [G1, G5]
dependencies: []
loc_estimate: 180
sizing_exception: schema migration
---

# Task 01: Document config.md routing, providers, and validators schema in using-qrspi

- **Phase:** 1
- **Target files:**
  - `skills/using-qrspi/SKILL.md` (Modify) — author the `## Config File` subsections that define the per-run routing/providers/validators schema consumed by Slice 1 dispatch sites.
- **Dependencies:** none
- **LOC estimate:** ~180
- **Sizing exception:** schema migration
- **Description:** Extends `skills/using-qrspi/SKILL.md` with new `## Config File` subsections that document the four config blocks consumed by Slice 1 dispatch sites: `providers:` (entry per provider with `base_url`, `api_key_env`, `transport_type` of either `openai-chat-completions` or `codex-broker`, optional `supports_prompt_cache` flag defaulting to `false`, optional `emit_cache_control_markers` flag defaulting to `false` — independent of `supports_prompt_cache:` and required to be `true` for the dispatcher to actually emit `cache_control` fields (the dual-flag gate; see T03), optional `default_headers` map); `model_routing:` (role-name to provider-plus-model pair, each provider value referring to an entry in `providers:`); `trusted_path:` (flat list of agent file paths or role names that always win over `model_routing:`); and `validators:` (post-dispatch output gates including `citation_density_floor` defaulting to `0.05`). The same edit documents the one-time legacy-config warning that fires when `model_routing:` is absent on resume, per the runtime-backfill defaults contract from goals.md. The schema landing here is the authoritative source the dispatcher (T03), the per-task routing chain (T05), and the role-frontmatter resolution (T06) all consume.
- **Test expectations:**
  - The `## Config File` section in `skills/using-qrspi/SKILL.md` documents the `providers:` block with every required field, the two legal `transport_type:` values, the `supports_prompt_cache:` default (`false`), and the `emit_cache_control_markers:` default (`false`). The documentation states that `cache_control` fields are emitted by the dispatcher only when BOTH `supports_prompt_cache: true` AND `emit_cache_control_markers: true` are set on the provider entry (the dual-flag gate); a `true`/`false` mismatch on either flag suppresses emission.
  - The `model_routing:` documentation enumerates the role-name to provider-plus-model mapping and states that the provider value must exist in `providers:`.
  - The `trusted_path:` documentation states that matching agent files or role names short-circuit ahead of `model_routing:`.
  - The `validators:` documentation declares `citation_density_floor:` with its `0.05` default and names the trusted-model re-run consequence.
  - The legacy-config warning subsection documents the one-time backfill behavior when a resumed run's `config.md` predates the `model_routing:` field, and states explicitly that "one-time" is implemented purely in-memory per session — no persistent marker is written to disk to track that the warning has already fired, so there is no write-failure surface that could leave the on-disk config in an inconsistent state. The warning fires once per resumed session and re-fires on each subsequent resume of a legacy `config.md`; the on-disk config is never silently mutated by the backfill, so a resumed session always sees the backfill defaults applied in-memory without changing the file on disk.
  - The combined precedence order (per-task `model:` override > hardcoded dispatch-site `model:` > `model_routing:` role lookup > agent bundled default) is stated in the same section, with `trusted_path:` documented separately as a short-circuit that wins outside the normal chain when an agent-file path or role name matches.

---
status: approved
task: 10
phase: 1
pipeline: full
goal_ids: [G7b]
task_type: code
model: opus
---

# Task 10: Wire per-host model_routing resolution for agent tier names

- **Target files:** `docs/qrspi/2026-05-27-v071-hardening/config.md` (modify), `skills/using-qrspi/SKILL.md` (modify), `tests/unit/test-agent-frontmatter-no-model.bats` (modify)
- **Dependencies:** Task 8, Task 9
- **LOC estimate:** ~80
- **Description:** The `model_routing:` table in `docs/qrspi/2026-05-27-v071-hardening/config.md` is populated with per-host concrete model ID entries covering all four tier names (haiku, sonnet, opus, inherit) for both the `claude-code` and `copilot-cli` host values produced by the `detect_host` function from Task 6. The six versioned tier entries are: claude-code/haiku: `claude-haiku-4.5`; claude-code/sonnet: `claude-sonnet-4.6`; claude-code/opus: `claude-opus-4.7-high`; copilot-cli/haiku: `claude-haiku-4.5`; copilot-cli/sonnet: `claude-sonnet-4.6`; copilot-cli/opus: `claude-opus-4.7-high`. The `inherit` tier resolves to `claude-sonnet-4.6` for both hosts (matching Claude's resolver default for custom agents without explicit `model:`). Copilot CLI accepts fully-versioned Claude model IDs and routes them through its model proxy; using full IDs avoids the "model not available" warning that bare tier names trigger. `skills/using-qrspi/SKILL.md` gains a Model Routing section documenting how dispatcher prose resolves agent tier names against the `model_routing` table: the `detect_host` output selects the per-host column, and the tier name selects the row, yielding the concrete model ID for that dispatch. The structural lint test created in Task 9 is extended with assertions verifying that the `model_routing` table contains the exact required host/tier entries. Dispatch order: test-writer first, implementer second (RED-verification gate between).
- **Test expectations:**
  - `docs/qrspi/2026-05-27-v071-hardening/config.md` contains `claude-haiku-4.5` as the haiku-tier entry in the `model_routing` table for both the `claude-code` and `copilot-cli` host columns
  - `docs/qrspi/2026-05-27-v071-hardening/config.md` contains `claude-sonnet-4.6` as the sonnet-tier entry in the `model_routing` table for both the `claude-code` and `copilot-cli` host columns
  - `docs/qrspi/2026-05-27-v071-hardening/config.md` contains `claude-opus-4.7-high` as the opus-tier entry in the `model_routing` table for both the `claude-code` and `copilot-cli` host columns
  - `docs/qrspi/2026-05-27-v071-hardening/config.md` contains `claude-sonnet-4.6` as the inherit-tier entry in the `model_routing` table for both the `claude-code` and `copilot-cli` host columns
  - No entry in the `copilot-cli` column of the `model_routing:` table is a bare Claude tier short-form (the strings `haiku`, `sonnet`, or `opus` alone) that would trigger a Copilot CLI "model not available" warning
  - `skills/using-qrspi/SKILL.md` contains a Model Routing section that names `detect_host` output as the host-selection input and the `model_routing` table as the per-tier resolution source
  - The extended structural lint assertions in `tests/unit/test-agent-frontmatter-no-model.bats` fail in RED when the `model_routing` table is absent or missing a required host/tier entry, and pass GREEN when all required entries are present

**Manual Validation:**
- Fresh-install smoke check: a freshly installed copy of the plugin on Copilot CLI emits zero "model not available" warnings when an agent dispatch resolves through the `model_routing` table (Design Test Strategy labels this as manual).

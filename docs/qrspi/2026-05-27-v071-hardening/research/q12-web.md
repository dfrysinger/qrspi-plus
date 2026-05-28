---
status: draft
question_ids: [12]
research_type: web
---

# Q12: Multi-host AI-agent plugin projects — model selection in agent manifests

## Summary

**TL;DR:** Multi-host AI-agent plugin projects that target two or more of Claude Code, Copilot CLI, Cursor, and Codex CLI fall into two categories: (1) context-only compilers that deliberately omit model selection from their shared manifest, and (2) multi-host orchestrators (primarily `gentle-ai`) that use a three-tier Claude alias vocabulary (`haiku/sonnet/opus`) as a platform-agnostic abstraction layer, translating to native host identifiers at sync time. The only platform that defines a *formal* in-manifest model vocabulary is Claude Code, using `haiku`, `sonnet`, `opus`, and `inherit` as short tier names in agent `.md` file frontmatter. GitHub Copilot agents use an ad-hoc mix of OpenAI and Anthropic model strings with no enforced vocabulary. Codex CLI and Cursor carry model selection outside the AGENTS.md/rules files (in `config.toml` and session settings, respectively).

**Key findings:**
- **Claude Code agent frontmatter** (`model:` field in `.md` files) accepts four values: `haiku`, `sonnet`, `opus`, and `inherit`. Full versioned IDs (e.g., `claude-opus-4-5`) are also accepted as of a recent changelog fix. Source: official `anthropics/claude-code` plugin repository and CHANGELOG.
- **GitHub Copilot agents** (`*.agent.md` frontmatter in `github/awesome-copilot`) use a `model:` field with no standard vocabulary: observed values include `gpt-4o`, `GPT-5`, `gpt-4`, `GPT-4.1`, `GPT-4.1 (copilot)`, `Claude Sonnet 4.5`, `claude-sonnet-4-6`, and `GPT-5.3-Codex`. Approximately 77% of sampled agents do not specify a model field at all.
- **Kiro IDE agents** (targeted by `gentle-ai`) use a `model:` frontmatter field with native versioned IDs: `claude-opus-4.6`, `claude-sonnet-4.6`, `claude-haiku-4.5`.
- **Codex CLI** carries model selection in `config.toml` (`model = "string"` at profile level, `model_provider` for routing); AGENTS.md itself has no model field in the Codex format.
- **Cursor** does not expose a `model:` field in `.cursor/agents/` markdown files per available evidence; sub-agent dispatch relies on the `description` field for routing; model selection is a session-level setting.
- **Context-only compilers** (`guorunjie/skillpack-forge`, `parada1104/ai-specs-cli`, `obielin/agentsync`, `MonadWorks/agentify`, `madeburo/contextai`, `fernandomenuk/openspec`): These target 2–5 hosts simultaneously but include no model selection in their shared manifests. Their `targets:` or `[agents].enabled` arrays control which host files are generated, but model identity is left to each host's runtime.
- **`Gentleman-Programming/gentle-ai`** is the most explicit multi-host model-routing project: it uses `opus|sonnet|haiku` as a three-tier alias vocabulary internally (`ClaudeModelAlias` type in Go), defines named presets (`balanced`, `performance`, `economy`), maps aliases to Kiro-native IDs at sync time (`opus→claude-opus-4.6`, `sonnet→claude-sonnet-4.6`, `haiku→claude-haiku-4.5`), and routes OpenCode/Kilo Code phases via `provider/model` pairs (e.g., `anthropic/claude-haiku-3.5-20241022`). Reasoning effort levels (`low|medium|high`) are tracked separately for models that support them.
- **Per-phase dispatch** is the dominant multi-host convention: architecture/orchestration phases → `opus`; implementation/validation phases → `sonnet`; lightweight mechanical tasks (archiving, formatting) → `haiku`.

**Surprises:**
- No multi-host project targeting all four specified hosts (Claude Code, Copilot CLI, Cursor, Codex CLI) simultaneously creates a unified model-vocabulary that works at the manifest level across all four. Cross-platform model selection is handled at the tooling/sync layer, not in a shared manifest field.
- `github/awesome-copilot` agents include non-existent or speculative model names such as `GPT-5.3-Codex` and `GPT-5` alongside real ones, with no validation enforced by the schema.
- The Copilot agent schema (`.schemas/collection.schema.json` and `tools.schema.json` in `github/awesome-copilot`) does not define or validate the `model:` field — it is a free-form string with no enum constraint.
- Claude Code's `inherit` tier name — which defers to the active session model rather than pinning a specific tier — has no equivalent in the Copilot, Codex, or Cursor manifest formats observed.

**Caveats:**
- The GitHub Search API code-search results for `.cursor/agents/` model fields returned no hits, so Cursor's native sub-agent model field support could not be confirmed or denied from live examples. The `gentle-ai` documentation mentions Cursor uses `description`-based routing only.
- The Codex CLI developer documentation is hosted at `developers.openai.com` and is not publicly curl-accessible; all Codex model information is derived from the `config.schema.json` in the `openai/codex` repository and the project's own `AGENTS.md`.
- The `github/awesome-copilot` agent sample covers approximately 23 of 214 total agent files; the model-field prevalence statistics are therefore approximate.
- The Copilot CLI (the terminal `gh copilot` extension) is architecturally distinct from VS Code Copilot Agents; this report covers VS Code Copilot Agents (the `.agent.md` format in `github/awesome-copilot`), which is the plugin surface most analogous to Claude Code agents. The `gh copilot` CLI itself does not expose an agent manifest format with model selection.

---

## Full findings

### Manifest formats per platform

#### Claude Code

Claude Code agents are defined as Markdown files with YAML frontmatter. Official plugin agents live under `plugins/<plugin-name>/agents/<agent-name>.md` within the `anthropics/claude-code` repository. The canonical frontmatter fields include:

| Field | Description | Example |
|-------|-------------|---------|
| `name` | Agent identifier slug | `code-reviewer` |
| `description` | Trigger description used for routing | `"Use this agent when..."` |
| `model` | Model tier or full model ID | `sonnet` |
| `color` | Display color | `green` |
| `tools` | Allowed tool list | `["Glob", "Grep", ...]` |

The `model:` field accepts:
- **Tier names** (short aliases): `haiku`, `sonnet`, `opus` — resolved to the current model in that family
- **`inherit`** — uses whatever model the parent session is running; no independent selection
- **Full model IDs** — e.g., `claude-opus-4-5`; accepted as of a fix in CHANGELOG around build 2.1.x: "Fixed full model IDs (e.g., `claude-opus-4-5`) being silently ignored in agent frontmatter `model:` field"

Also from the CHANGELOG: "Fixed subagents with `model: opus`/`sonnet`/`haiku` being silently downgraded to older model versions on Bedrock, Vertex, and Microsoft Foundry" — confirming these tier names are the primary convention.

Source: `anthropics/claude-code` repository, `plugins/` directory and `CHANGELOG.md`.

**Observed model field values in official Anthropic plugins:**

| Agent | Plugin | `model:` |
|-------|--------|----------|
| `agent-sdk-verifier-py` | `agent-sdk-dev` | `sonnet` |
| `agent-sdk-verifier-ts` | `agent-sdk-dev` | `sonnet` |
| `code-explorer` | `feature-dev` | `sonnet` |
| `code-architect` | `feature-dev` | `sonnet` |
| `code-reviewer` (feature-dev) | `feature-dev` | `sonnet` |
| `code-reviewer` (pr-review-toolkit) | `pr-review-toolkit` | `opus` |
| `code-simplifier` | `pr-review-toolkit` | (none shown in sample) |
| `comment-analyzer` | `pr-review-toolkit` | `inherit` |
| `pr-test-analyzer` | `pr-review-toolkit` | `inherit` |
| `silent-failure-hunter` | `pr-review-toolkit` | `inherit` |
| `type-design-analyzer` | `pr-review-toolkit` | `inherit` |
| `conversation-analyzer` | `hookify` | `inherit` |
| `agent-creator` | `plugin-dev` | (not specified in sample) |

**Inline dispatch in command files (code-review.md):** The command prose references model tiers directly:
- "Launch a **haiku** agent to check if any of the following are true..." (lightweight checks)
- "Launch a **sonnet** agent to view the pull request..." (summary work)
- "Launch 4 agents in parallel... **CLAUDE.md compliance sonnet agents**... **Opus bug agent**" (compliance vs. deep bug detection)
- "Use **Opus** subagents for bugs and logic issues, and **sonnet** agents for CLAUDE.md violations" (validation step)

This confirms the tier semantics: `haiku` = cheap/fast, `sonnet` = balanced, `opus` = deep reasoning.

---

#### GitHub Copilot (VS Code Copilot Agents)

GitHub Copilot agents in `github/awesome-copilot` use `.agent.md` files with YAML frontmatter. The collection schema (`github/awesome-copilot/.schemas/collection.schema.json`) does not define or constrain the `model:` field — it is a free-form string.

**Observed `model:` values in sampled agents (23 of 214 total):**

| Agent | `model:` value |
|-------|----------------|
| `agent-governance-reviewer` | `'gpt-4o'` |
| `accessibility-runtime-tester` | `GPT-5` |
| `ai-readiness-reporter` | `'Claude Sonnet 4.5'` |
| `aws-cloud-expert` | `claude-sonnet-4-6` |
| `azure-iac-exporter` | `'Claude Sonnet 4.5'` |
| `azure-iac-generator` | `'Claude Sonnet 4.5'` |
| `azure-logic-apps-expert` | `"gpt-4"` |
| `azure-smart-city-iot-architect` | `'GPT-5.3-Codex'` |
| `terminal-helper` | `GPT-4.1 (copilot)` |
| `typescript-mcp-expert` | `GPT-4.1` |

13 of 23 sampled agents (57%) had no `model:` field. Across the 214-agent collection, the absence of a `model:` field is the majority pattern.

Observed vocabulary spans:
- **OpenAI family**: `gpt-4`, `gpt-4o`, `GPT-4.1`, `GPT-4.1 (copilot)`, `GPT-5`, `GPT-5.3-Codex`
- **Anthropic family**: `Claude Sonnet 4.5`, `claude-sonnet-4-6`

Note: capitalization and quoting style are inconsistent (e.g., `GPT-5` vs `'gpt-4o'` vs `"gpt-4"`). The schema places no validation on the field.

---

#### Codex CLI

The Codex CLI does not use AGENTS.md as a model-selection surface. Model selection in Codex is a `config.toml` concern:

From `codex-rs/core/config.schema.json`:
- `model` (top-level): `"Optional override of model selection."` — type string, no enumeration
- `model_provider`: `"Provider to use from the model_providers map."` — type string
- `model_providers`: User-defined provider entries keyed by ID
- `model_reasoning_effort`: `ReasoningEffort` ref — controls reasoning depth
- `ConfigProfile.model`: per-profile model override

The AGENTS.md file in Codex is used for project/directory-scoped instructions only — it has no model-selection field in the Codex runtime. Sub-agent spawning (`AgentsToml` in the schema) defines role descriptions and config overlays but does not have a `model:` field at the role level.

Source: `openai/codex` repository, `codex-rs/core/config.schema.json`.

---

#### Cursor

Cursor's native sub-agent system (`~/.cursor/agents/`) uses Markdown files with YAML frontmatter. From available evidence via `gentle-ai` documentation:

- Cursor sub-agent files include `name`, `description`, and `tools` in frontmatter
- The `description` field drives agent routing (Cursor Agent auto-delegates to the correct sub-agent based on description)
- No `model:` field is documented or observed in Cursor agent files in the sources reviewed
- Model selection in Cursor is a session/mode-level setting, not a per-agent manifest field

Source: `Gentleman-Programming/gentle-ai` docs (`docs/agents.md`): "Cursor uses its built-in `.cursor/agents/` system... Cursor's Agent auto-delegates to the correct subagent based on the `description` field in each file's YAML frontmatter."

---

### Multi-host projects with explicit model selection

#### `Gentleman-Programming/gentle-ai`

`gentle-ai` is the most fully developed multi-host agent orchestration framework explicitly targeting model selection across hosts. It supports 15 agents including Claude Code, VS Code Copilot, Cursor, Codex, and others.

**Internal model vocabulary** (`internal/model/claude_model.go`):
```go
type ClaudeModelAlias string

const (
    ClaudeModelOpus   ClaudeModelAlias = "opus"   // high-capability, architecture
    ClaudeModelSonnet ClaudeModelAlias = "sonnet" // balanced, most SDD phases
    ClaudeModelHaiku  ClaudeModelAlias = "haiku"  // lightweight, archiving
)
```

**Built-in presets** (`ClaudeModelPreset*`):

| Phase | Balanced | Performance | Economy |
|-------|----------|-------------|---------|
| `sdd-explore` | `sonnet` | `sonnet` | `sonnet` |
| `sdd-propose` | `opus` | `opus` | `sonnet` |
| `sdd-spec` | `sonnet` | `sonnet` | `sonnet` |
| `sdd-design` | `opus` | `opus` | `sonnet` |
| `sdd-tasks` | `sonnet` | `sonnet` | `sonnet` |
| `sdd-apply` | `sonnet` | `sonnet` | `sonnet` |
| `sdd-verify` | `sonnet` | `opus` | `sonnet` |
| `sdd-archive` | `haiku` | `haiku` | `haiku` |

**Kiro alias-to-ID translation** (`internal/model/kiro_model.go`):
```go
case ClaudeModelOpus:   return "claude-opus-4.6"
case ClaudeModelHaiku:  return "claude-haiku-4.5"
default:                return "claude-sonnet-4.6"
```

**OpenCode/Kilo Code dispatch** (CLI flag):
```bash
gentle-ai sync --profile cheap:anthropic/claude-haiku-3.5-20241022
gentle-ai sync --profile premium:anthropic/claude-opus-4-20250514
gentle-ai sync --profile-phase cheap:sdd-apply:anthropic/claude-sonnet-4-20250514
```

**`ModelAssignment` struct** (`internal/model/model_assignment.go`):
```go
type ModelAssignment struct {
    ProviderID string // e.g., "anthropic"
    ModelID    string // e.g., "claude-sonnet-4-20250514"
    Effort     string // "" | "low" | "medium" | "high"
}
```

Reasoning effort levels (`low|medium|high|xhigh`) apply to OpenAI models (e.g., `gpt-5`) that expose this API parameter.

**Multi-mode support matrix** (from `docs/agents.md`):

| Agent | Multi-mode (per-phase model) |
|-------|------------------------------|
| Claude Code | — (single-mode only) |
| OpenCode | Yes (multi-profile overlay in `opencode.json`) |
| Kilo Code | Yes (OpenCode-compatible) |
| Cursor | — (single-mode only; description routing) |
| VS Code Copilot | — (single-mode only) |
| Codex | — (single-mode only) |
| Kiro IDE | Yes (native `model:` frontmatter in agents) |

Source: `Gentleman-Programming/gentle-ai` repository, `internal/model/`, `docs/opencode-profiles.md`, `docs/agents.md`, `docs/kiro.md`.

---

### Multi-host context compilers (no model selection)

The following projects target 2+ of the named hosts and generate host-native files, but intentionally exclude model selection from their shared manifests:

**`guorunjie/skillpack-forge`** — targets `agents` (AGENTS.md), `claude` (.claude/skills/), `codex` (.codex/skills/), `cursor` (.cursor/rules/), `copilot` (.github/copilot-instructions.md). Manifest (`skillpack.yaml`) declares:
- `targets: [agents, claude, codex, cursor, copilot]`
- `skills[]` with `name`, `description`, `workflow`
- No `model:` field anywhere in the schema (`skillpack.schema.json`)

**`parada1104/ai-specs-cli`** — targets Claude, Cursor, OpenCode, Codex, Copilot, Gemini. Manifest (`ai-specs/ai-specs.toml`) fields: `[agents].enabled`, `[[deps]]`, `[mcp.*]`, `[recipes.*]`. No model selection field.

**`obielin/agentsync`** — syncs `.agentsync/rules.md` to AGENTS.md, CLAUDE.md, .cursorrules, .cursor/rules/main.mdc, .github/copilot-instructions.md, GEMINI.md, .windsurfrules. Source file is plain Markdown; no model selection.

**`MonadWorks/agentify`** — compiles OpenAPI specs to 9 agent interface formats (MCP, CLAUDE.md, AGENTS.md, .cursorrules, Skills, llms.txt, GEMINI.md, A2A, CLI). No model selection in the `AgentifyIR` intermediate representation.

**`devantler-tech/plugins`** — dual-manifest marketplace (Claude Code `.claude-plugin/marketplace.json` + Copilot CLI `plugin.json`). `plugin.json` fields: `name`, `description`, `version`, `author`, `skills`. SKILL.md frontmatter fields: `name`, `description`, `metadata.github-*`. No model field in either format.

---

### Model-tier vocabulary summary across platforms

| Vocabulary | Platform(s) | Example values |
|------------|-------------|----------------|
| Short tier names | Claude Code (native), gentle-ai (internal), Kiro (via alias) | `haiku`, `sonnet`, `opus`, `inherit` |
| Full versioned model IDs | Claude Code (also), Kiro native | `claude-opus-4-5`, `claude-sonnet-4.6`, `claude-haiku-4.5` |
| Provider-qualified IDs | OpenCode/Kilo Code (gentle-ai profiles) | `anthropic/claude-haiku-3.5-20241022`, `anthropic/claude-opus-4-20250514` |
| OpenAI model names | Copilot agents (github/awesome-copilot) | `gpt-4o`, `GPT-4.1`, `GPT-5`, `gpt-4` |
| Mixed/cross-vendor names | Copilot agents | `Claude Sonnet 4.5`, `claude-sonnet-4-6` |
| No model field | Most SKILL.md files, AGENTS.md (Codex), .cursorrules, copilot-instructions.md | N/A |

---

### Dispatch conventions observed

1. **Task-complexity routing** (Claude Code): Model tier assigned per sub-agent based on task complexity: `haiku` for mechanical checks, `sonnet` for balanced analysis, `opus` for deep reasoning. Expressed in agent `.md` frontmatter OR inline in command prose ("Launch a haiku agent...").

2. **Phase-level routing** (gentle-ai/OpenCode): Named SDD phases (`sdd-explore`, `sdd-design`, `sdd-archive`, etc.) each get an independent model assignment. Architecture phases use `opus`; implementation/validation use `sonnet`; archive uses `haiku`.

3. **Profile-level routing** (gentle-ai/OpenCode): Named profiles (`cheap`, `premium`, `balanced`) group model assignments and are switchable at runtime (Tab key in OpenCode TUI).

4. **Alias-to-native-ID translation** (gentle-ai for Kiro): Platform-agnostic `opus|sonnet|haiku` aliases written into the selection model; translated to native model IDs at sync time per-platform. No shared manifest field — the translation happens in Go code.

5. **Session-level selection** (Codex CLI): `model = "string"` in `config.toml`; `--model` and `--effort` CLI flags at invocation time; `CLAUDE_CODE_SUBAGENT_MODEL` env var for Claude Code subagents.

6. **Description-based dispatch without model pinning** (Cursor): Agent `.md` files route by `description` field content; no model pinning per sub-agent in observed Cursor examples.

7. **Ad-hoc field with no vocabulary enforcement** (Copilot agents): Authors may write any string into the `model:` field; the `github/awesome-copilot` schema does not validate or enumerate values.

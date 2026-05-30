---
status: draft
question_ids: [9]
research_type: web
---

# Q9: GitHub Copilot CLI Subprocess Environment Variables and Host-Detection Signal

## Summary

**TL;DR:** GitHub Copilot CLI (the new standalone `github/copilot-cli`, not the deprecated `gh-copilot` extension) sets `COPILOT_CLI=1` in every subprocess it spawns—explicitly documented since v0.0.421 (2026-03-03) as the mechanism for detecting Copilot CLI subprocesses. In addition, shell-tool subprocesses and MCP servers receive `COPILOT_AGENT_SESSION_ID`, and agent shell sessions receive `GITHUB_TOKEN`. Plugin hooks receive additional plugin-scoped variables. The cloud-agent sandbox provides its own distinct set.

**Key findings:**
- **`COPILOT_CLI=1`** is the primary, documented, stable host-detection signal. The changelog states explicitly: "Git hooks can detect Copilot CLI subprocesses via the `COPILOT_CLI=1` environment variable to skip interactive prompts" (v0.0.421, 2026-03-03).
- **`COPILOT_AGENT_SESSION_ID`** is set in shell-tool subprocesses and MCP servers since v1.0.29 (2026-04-16), carrying the session UUID.
- **`GITHUB_TOKEN`** is passed into agent shell sessions since v0.0.404 (2026-02-05).
- Plugin hooks receive `PLUGIN_ROOT`, `COPILOT_PLUGIN_ROOT`, `CLAUDE_PLUGIN_ROOT` (v1.0.26) and `CLAUDE_PROJECT_DIR`, `CLAUDE_PLUGIN_DATA` (v1.0.12).
- The cloud-agent sandbox sets `GITHUB_COPILOT_API_TOKEN`, `GITHUB_COPILOT_GIT_TOKEN`, and `COPILOT_AGENT_PROMPT`.
- The documented general environment-variable table for the CLI itself (not subprocess injection) lists 20+ variables including `COPILOT_GITHUB_TOKEN`, `COPILOT_HOME`, `COPILOT_MODEL`, `GH_TOKEN`, and others.

**Surprises:**
- `COPILOT_CLI=1` is the *only* env var explicitly documented as a subprocess-detection/host-identification signal. `COPILOT_AGENT_SESSION_ID` identifies the session but is secondary to `COPILOT_CLI=1` for host detection.
- The old `gh-copilot` extension (deprecated October 2025) had no documented subprocess env var for host detection; `COPILOT_CLI=1` was introduced only in the new standalone CLI.
- `NODE_ENV` was previously set in the shell tool environment but was explicitly removed in v0.0.355 (2025-11-12).

**Caveats:**
- Source is the public `github/copilot-cli` changelog and `docs.github.com` reference pages (as of 2026-05-27, latest release v1.0.54). The binary is closed-source; no source-code inspection of subprocess spawning was possible.
- "Stability" is assessed from the changelog's explicit intent language, not a formal API-stability commitment.
- The hooks reference and command reference cover cloud-agent and CLI contexts separately; some variables only apply to one context.

---

## Full findings

### Context: Two Different GitHub Copilot CLI Products

The question applies to the **new standalone GitHub Copilot CLI** (`github/copilot-cli`, installable via `npm install -g @github/copilot`, brew, or script; latest v1.0.54 as of 2026-05-24). This is distinct from the deprecated `gh-copilot` extension for GitHub CLI (`github/gh-copilot`, deprecated 2025-10-25), which only offered `suggest` and `explain` and had no documented subprocess env vars.

---

### 1. Environment Variables Set in Subprocesses When Launching an Agent

The following variables are injected by the CLI into child-process environments (not merely variables the CLI reads from its own environment).

#### 1a. `COPILOT_CLI=1` — All Subprocesses

| Attribute | Value |
|---|---|
| Variable | `COPILOT_CLI=1` |
| Introduced | v0.0.421 (2026-03-03) |
| Scope | All subprocesses (shell commands, git hooks, scripts) |
| Source | Changelog: "Git hooks can detect Copilot CLI subprocesses via the `COPILOT_CLI=1` environment variable to skip interactive prompts" |

This is the **canonical host-detection signal** for embedded shell scripts. It is set in every subprocess the CLI spawns and is the documented mechanism for third-party scripts to detect they are running inside Copilot CLI.

#### 1b. `COPILOT_AGENT_SESSION_ID` — Shell Tool Subprocesses and MCP Servers

| Attribute | Value |
|---|---|
| Variable | `COPILOT_AGENT_SESSION_ID` |
| Introduced | v1.0.29 (2026-04-16) |
| Scope | Shell tool subprocess invocations and MCP server processes |
| Source | Changelog: "Shell commands and MCP servers now receive `COPILOT_AGENT_SESSION_ID` as an environment variable" |

Contains the session UUID, allowing a subprocess to identify which session spawned it. This is a secondary signal that both identifies the host and provides session correlation.

#### 1c. `GITHUB_TOKEN` — Agent Shell Sessions

| Attribute | Value |
|---|---|
| Variable | `GITHUB_TOKEN` |
| Introduced | v0.0.404 (2026-02-05) |
| Scope | Agent shell sessions |
| Source | Changelog: "GITHUB_TOKEN environment variable now accessible in agent shell sessions" |

The CLI's authentication token is forwarded into the subprocess environment. Note: values in `GITHUB_TOKEN` and `COPILOT_GITHUB_TOKEN` are redacted from output by default (mentioned in the `--secret-env-vars` flag documentation).

#### 1d. Plugin Hook Subprocess Variables

Plugin hooks receive additional variables with the plugin's installation directory:

| Variable | Introduced | Notes |
|---|---|---|
| `PLUGIN_ROOT` | v1.0.26 (2026-04-14) | Alias for `COPILOT_PLUGIN_ROOT` |
| `COPILOT_PLUGIN_ROOT` | v1.0.26 (2026-04-14) | Plugin installation directory |
| `CLAUDE_PLUGIN_ROOT` | v1.0.26 (2026-04-14) | Same value, alternate name for Claude compatibility |
| `CLAUDE_PROJECT_DIR` | v1.0.12 (2026-03-26) | Project directory for plugin hooks |
| `CLAUDE_PLUGIN_DATA` | v1.0.12 (2026-03-26) | Plugin data directory |

Source: Changelog entries for v1.0.26 and v1.0.12.

#### 1e. Cloud-Agent Sandbox Subprocess Variables

The hooks reference page (`docs.github.com/en/copilot/reference/hooks-reference`) documents a dedicated "Available environment variables" section for the cloud-agent sandbox:

| Variable | Description |
|---|---|
| `GITHUB_COPILOT_API_TOKEN` | API token in cloud agent sandbox |
| `GITHUB_COPILOT_GIT_TOKEN` | Git token in cloud agent sandbox |
| `COPILOT_AGENT_PROMPT` | The prompt the job was invoked with |
| `HOME` | Set to `/root` in the sandbox |

Note: In the cloud-agent sandbox, `GITHUB_TOKEN` is explicitly **not** set.

---

### 2. De-Facto-Stable Signal for Host Detection

#### Primary Signal: `COPILOT_CLI=1`

The changelog for v0.0.421 (2026-03-03) explicitly states: "Git hooks can detect Copilot CLI subprocesses via the `COPILOT_CLI=1` environment variable to skip interactive prompts."

This is the only env var in the changelog that is framed as an **explicit detection mechanism** for subprocesses. The language "can detect ... subprocesses via ... `COPILOT_CLI=1`" establishes it as the canonical, intentional signal.

A shell script can test:
```sh
if [ "${COPILOT_CLI:-}" = "1" ]; then
  # running inside GitHub Copilot CLI
fi
```

#### Secondary Signal: `COPILOT_AGENT_SESSION_ID`

Present in shell-tool subprocesses and MCP servers since v1.0.29. Its presence indicates the process is running within an active agent session. However, the changelog does not use "detect" or "identify" language for this variable—it is framed as providing session correlation rather than host detection.

#### Variables Noted as Removed

- `NODE_ENV`: Removed from the shell tool's environment in v0.0.355 (2025-11-12). Cannot be used as a detection signal.

---

### 3. Full Documented Environment Variable Table (CLI Configuration)

The following variables are documented in the CLI command reference (`docs.github.com/en/copilot/reference/cli-command-reference`) as variables the CLI reads from its own environment. These are **not** specifically documented as being set in subprocess environments (except where noted above).

| Variable | Description |
|---|---|
| `COLORFGBG` | Fallback for dark/light terminal background detection |
| `COPILOT_ALLOW_ALL` | `true` to allow all permissions automatically (equiv. `--allow-all`) |
| `COPILOT_AUTO_UPDATE` | `false` to disable automatic updates |
| `COPILOT_CACHE_HOME` | Override cache directory |
| `COPILOT_CUSTOM_INSTRUCTIONS_DIRS` | Comma-separated list of additional directories for custom instructions |
| `COPILOT_EDITOR` | Editor command (checked after `$VISUAL` and `$EDITOR`) |
| `COPILOT_GH_HOST` | GitHub hostname for Copilot CLI only, overriding `GH_HOST` |
| `COPILOT_GITHUB_TOKEN` | Auth token (highest precedence over `GH_TOKEN`, `GITHUB_TOKEN`) |
| `COPILOT_HOME` | Config/state directory override (default: `$HOME/.copilot`) |
| `COPILOT_MODEL` | AI model selection |
| `COPILOT_PROMPT_FRAME` | `1`/`0` to enable/disable decorative UI frame |
| `COPILOT_SKILLS_DIRS` | Additional skill directories (comma-separated) |
| `COPILOT_SUBAGENT_MAX_CONCURRENT` | Max concurrent subagents (default: 32, range 1–256) |
| `COPILOT_SUBAGENT_MAX_DEPTH` | Max subagent nesting depth (default: 6, range 1–256) |
| `GH_HOST` | GitHub hostname for both GitHub CLI and Copilot CLI |
| `GH_TOKEN` | Auth token (takes precedence over `GITHUB_TOKEN`) |
| `GITHUB_COPILOT_PROMPT_MODE_EXTENSIONS` | `true` to load project extensions in prompt mode (`-p`) |
| `GITHUB_COPILOT_PROMPT_MODE_REPO_HOOKS` | `true` to load repository hooks in prompt mode |
| `GITHUB_COPILOT_PROMPT_MODE_WORKSPACE_MCP` | `true` to load workspace MCP in prompt mode |
| `GITHUB_TOKEN` | Auth token |
| `PLAIN_DIFF` | `true` to disable rich diff rendering |
| `USE_BUILTIN_RIPGREP` | `false` to use system ripgrep instead of bundled version |

Additional documented-but-operational variables (from changelog):

| Variable | Introduced | Purpose |
|---|---|---|
| `COPILOT_PROVIDER_BASE_URL` | — | Custom model provider API endpoint |
| `COPILOT_PROVIDER_TYPE` | — | Provider type: `openai`, `azure`, `anthropic` |
| `COPILOT_PROVIDER_API_KEY` | — | API key for custom model provider |
| `COPILOT_PLUGIN_DIR_ONLY` | v1.0.49 (2026-05-18) | Disable automatic plugin discovery |
| `COPILOT_DISABLE_TERMINAL_TITLE` | v1.0.28 (2026-04-16) | Opt out of terminal title updates |
| `COPILOT_KITTY` | v0.0.338 (2025-10-09) | Enable Kitty terminal protocol |
| `COPILOT_HOOK_ALLOW_LOCALHOST=1` | — | Allow `http://` localhost in hooks |
| `COPILOT_OTEL_ENABLED` | — | Explicitly enable OTel |
| `COPILOT_OTEL_EXPORTER_TYPE` | — | `otlp-http` or `file` |
| `COPILOT_OTEL_FILE_EXPORTER_PATH` | — | Write OTel signals to file |
| `COPILOT_OTEL_SOURCE_NAME` | — | OTel instrumentation scope name |
| `GITHUB_COPILOT_OIDC_MCP_TOKEN` | — | OIDC token injection for MCP servers |
| `GITHUB_COPILOT_OIDC_MCP_TOKEN_<SUFFIX>` | — | Per-server OIDC token variant |

---

### 4. Sources

- GitHub repository `github/copilot-cli` README: https://github.com/github/copilot-cli
- `github/copilot-cli` changelog (`changelog.md`): https://github.com/github/copilot-cli/blob/main/changelog.md
- GitHub Docs — About GitHub Copilot CLI: https://docs.github.com/en/copilot/concepts/agents/about-copilot-cli
- GitHub Docs — Copilot CLI command reference: https://docs.github.com/en/copilot/reference/cli-command-reference
- GitHub Docs — Copilot hooks reference: https://docs.github.com/en/copilot/reference/hooks-reference
- GitHub Docs — Using hooks with Copilot CLI: https://docs.github.com/en/copilot/how-tos/copilot-cli/use-hooks
- GitHub Docs — Automate with Actions: https://docs.github.com/en/copilot/how-tos/copilot-cli/automate-with-actions
- `github/gh-copilot` README (deprecated extension): https://github.com/github/gh-copilot

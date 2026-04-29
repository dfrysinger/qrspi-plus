---
status: draft
question_ids: [2]
research_type: web
---

# Q2: Claude Code subagent tool grants and nested dispatch

## Summary

**TL;DR:** Claude Code subagents are configured via Markdown files with YAML frontmatter that includes an optional `tools:` field; if `tools:` is omitted the subagent inherits all tools from the main thread (including any MCP tools), and subagents do not have access to the `Task` tool, which prevents them from dispatching further subagents.

**Key findings:**
- Subagents are defined as Markdown files (in `.claude/agents/` for project scope or `~/.claude/agents/` for user scope) with YAML frontmatter fields including `name`, `description`, `tools`, and `model`.
- The `tools` frontmatter field is optional. When omitted, the subagent inherits all tools available to the main thread, including MCP server tools.
- When `tools` is specified, it is a comma-separated list of specific tool names (e.g. `Read, Grep, Glob, Bash`).
- Tool grants can also be edited interactively via the `/agents` command, which presents a UI listing all available tools including MCP tools.
- The official docs explicitly state subagents do not have access to the `Task` tool, so subagents cannot delegate to / dispatch other subagents — only the main (top-level) Claude can invoke subagents.
- Subagents operate in their own separate context window and return a final report to the main thread.

**Surprises:** Nothing surprising; the docs are explicit that nested subagent dispatch is not supported because the `Task` tool is withheld from subagents.

**Caveats:** The Claude Code Agent SDK (separate product surface from the Claude Code CLI's built-in subagents) is documented separately and exposes programmatic control over tool allow/deny lists at a finer granularity; the SDK's "subagent" concept overlaps with but is not identical to CLI subagents. Version pinning: documentation reflects the state of `docs.claude.com` / `docs.anthropic.com` as of the 2026-04 timeframe; older or future releases may differ.

## Full findings

### Configuring subagent tool grants

The Claude Code subagents documentation describes subagents as configured via Markdown files with YAML frontmatter. The frontmatter supports the fields `name`, `description`, `tools` (optional), and `model` (optional). Source: https://docs.claude.com/en/docs/claude-code/sub-agents

Quoting the docs (paraphrased structure):
- File location: `.claude/agents/<name>.md` (project-level, takes precedence) or `~/.claude/agents/<name>.md` (user-level).
- Frontmatter `tools` field: "Optional - Specific tools the subagent can use. If omitted, inherits all tools from the main thread."
- The `tools` value is a comma-separated list of tool names, for example: `tools: Read, Grep, Glob, Bash`.

The docs further state that the recommended way to manage tool grants is through the `/agents` slash command, which "provides an interactive interface that lists all available tools, including those from connected MCP servers, making it easier to select the appropriate ones." Source: https://docs.claude.com/en/docs/claude-code/sub-agents

Tool inheritance specifics:
- If `tools` is omitted, the subagent inherits every tool the parent has, including MCP-server-provided tools.
- If `tools` is specified explicitly, only the listed tools are granted; MCP tools must be named explicitly to be included (or selected via `/agents`).

Source: https://docs.claude.com/en/docs/claude-code/sub-agents (sections "File format", "Available tools", "Managing your subagents")

### Whether subagents can dispatch further subagents

The Claude Code subagents documentation explicitly addresses this: "Subagents do not have access to the Task tool; this means they cannot delegate to or invoke other subagents." Source: https://docs.claude.com/en/docs/claude-code/sub-agents

Mechanically:
- The `Task` tool is what the main Claude Code agent uses to spawn a subagent. Source: https://docs.claude.com/en/docs/claude-code/sub-agents
- Because subagents are not granted `Task`, only the top-level (main) thread can launch subagents.
- The docs describe subagent execution as: main agent launches subagent via `Task`, subagent runs in its own isolated context window with its own (possibly restricted) tool set, then returns a single final response to the main agent.

The Claude Code Agent SDK documentation (a related but distinct product) exposes finer-grained controls including `allowedTools` / `disallowedTools` for programmatically launched agents and supports custom tools via MCP, but the SDK documentation likewise does not describe a mechanism by which a CLI-launched subagent can itself dispatch further subagents within the standard CLI subagent feature. Sources: https://docs.claude.com/en/api/agent-sdk/overview and https://docs.claude.com/en/api/agent-sdk/subagents

## Sources

- https://docs.claude.com/en/docs/claude-code/sub-agents — Primary source. Documents the Markdown+frontmatter format, the optional `tools` field, default tool inheritance behavior, the `/agents` interactive management command, and the explicit statement that subagents lack the `Task` tool and therefore cannot invoke other subagents.
- https://docs.claude.com/en/docs/claude-code/settings — Context on `permissions.allow` / `permissions.deny` lists which apply to tool gating at the Claude Code session level (related but separate from per-subagent `tools:` frontmatter).
- https://docs.claude.com/en/api/agent-sdk/overview — Background on the Agent SDK as a separate surface; clarifies that programmatic subagents in the SDK have their own tool-grant API (`allowedTools`, MCP), distinct from CLI subagent frontmatter.
- https://docs.claude.com/en/api/agent-sdk/subagents — Agent SDK's documentation on subagents; consulted to confirm the absence of any documented nested-dispatch mechanism comparable to the CLI's `Task` tool being re-exposed inside subagents.

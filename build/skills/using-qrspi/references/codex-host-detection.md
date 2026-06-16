**Codex detection (per-host second-reviewer dispatch transport).** The dispatch surface routes per detected host (`detect_host` at dispatch time):

- **Copilot CLI hosts** use the native task-tool transport, dispatching Codex with `agent_type: code-review` and `model: gpt-5.3-codex`.
- **Claude Code hosts** use the shell-pipeline transport via `scripts/dispatch-agent.sh` (with `scripts/dispatch-companion.sh` for the background-companion path).

Each branch emits a one-line `[transport: ...]` trace marker to stderr at the selecting call site. When the detected host's second-reviewer availability disagrees with `config.md`, the dispatch surface emits a warning-only single-line stderr diagnostic and continues with the configured policy — the mismatch does NOT gate dispatch. A separate short-circuit fires when an availability check reports the vendor missing while config requested it; that path propagates the non-zero exit unchanged.

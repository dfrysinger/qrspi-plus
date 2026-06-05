## Dispatch transport note

scope-codex (gpt-5.3-codex via code-review agent_type) returned the R5 finding in chat-only output:
> "I can't write files in this environment, so I'm returning findings directly."

This matches the documented OpenAI-family write-restriction pattern in Copilot CLI (plugin issue tracked in this self-host run). Orchestrator hand-persisted the finding to `scope-codex.finding-F01.md` per the §3 verifier-round protocol's chat-only fallback handling.

Sidecar will be written by the orchestrator-dispatched verifier in step 4 of the apply-fix protocol.

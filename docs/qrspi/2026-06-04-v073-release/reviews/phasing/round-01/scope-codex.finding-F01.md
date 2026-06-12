---
artifact: phasing
reviewer: scope-codex
severity: medium
change_type: scope
---

## Boundary drift: phasing gate enumerates file paths and implementation dispatch chain

In `phasing.md` lines 20–21, the end-of-phase replan criteria name concrete plugin manifest paths and implementation-level orchestration scripts:

- `.github/plugin/plugin.json`
- `.github/plugin/marketplace.json`
- `dispatch-agent.sh`
- `await-round.sh`
- `verifier-fan-in.sh`

Per Phasing DEFERS, file paths are owned by Structure, and implementation prose / dispatch verbs are owned by Implement or downstream skills. Phasing may define capability-level phase gates, but should avoid locking specific files or script-chain internals.

Suggested fix: rewrite these criteria at the capability level, e.g. "plugin metadata installs cleanly in a fresh Copilot CLI session" and "a self-host smoke run exercises the universal dispatch flow end-to-end," leaving exact paths and script names to Structure/Implement.

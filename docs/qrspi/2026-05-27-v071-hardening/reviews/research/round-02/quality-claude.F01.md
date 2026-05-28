---
artifact: research
reviewer: quality-claude
round: 2
severity: medium
change_type: correctness
file: research/summary.md
section: "## Cross-References (Q08/Q15 ↔ Q09 bullet)"
---

# F01: Q08/Q15 ↔ Q09 cross-reference bullet introduces env var names not documented in q09-web.md

## Description

The round-1 rewrite of the Q08/Q15 ↔ Q09 Cross-References bullet introduced three env var names — `COPILOT_CLI_BINARY_VERSION`, `COPILOT_LOADER_PID`, `COPILOT_RUN_APP` — that are NOT documented in q09-web.md. These names appear to have been imported from orchestrator main-chat context (the live Copilot CLI session env) and/or stored memory, rather than from the research source.

## Rule violated

Research-isolation invariant binds the orchestrator as well as subagents: facts introduced into summary.md must be grounded in the q-files, not in main-chat context, stored memory, or external knowledge.

## Evidence

- q09-web.md actually documents only `COPILOT_CLI=1` and `COPILOT_AGENT_SESSION_ID` as the subprocess host-detection signals.
- The three flagged names appear nowhere in q09-web.md.

## Recommended fix

Rewrite the bullet to cite only the two q09-grounded env vars with their changelog version stamps (v0.0.421 for `COPILOT_CLI=1`, v1.0.29 for `COPILOT_AGENT_SESSION_ID`).

## Resolution

Fixed in round 2 by rewriting the bullet to cite only the two q09-grounded env vars. The containing `## Cross-References` section was subsequently removed entirely in round 3 per cross-reviewer convergence on the verbatim-collation rule.

## Orchestrator note

This finding was returned inline by the reviewer subagent in round 2 and not materialized to disk at the time; reconstructed during round-4 commit prep for audit completeness.

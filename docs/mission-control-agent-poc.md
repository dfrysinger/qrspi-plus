# Mission Control agent dispatcher PoC

This experiment compares a direct Copilot Mission Control dispatch with the
repository's existing governed agentic workflows.

The workflow at `.github/workflows/mission-control-agent-poc.yml`:

1. accepts a bounded task through `workflow_dispatch`;
2. constructs a repository-specific execution contract;
3. calls the public-preview Agent Tasks REST API;
4. asks Copilot cloud agent to work in this repository and create a pull
   request; and
5. publishes the Mission Control task link in the Actions job summary.

## Authentication

The Agent Tasks API accepts only user-to-server tokens. It does not accept the
workflow `GITHUB_TOKEN` or GitHub App installation tokens.

The PoC prefers the `COPILOT_AGENT_TOKEN` repository secret and temporarily
falls back to the existing `GAW_COPILOT_TOKEN`. The selected token must have
**Agent tasks: read and write** access to this repository. If the first test
returns HTTP 403, create a repository-limited token with that permission and
store it as `COPILOT_AGENT_TOKEN`.

## Comparison boundary

This reproduces the trigger, prompt, repository access, agent execution, pull
request, and central tracking portions of a GAW run. It deliberately does not
reproduce GAW's policy envelope, deterministic deployment contract, network
boundary, safe-output mediation, tool proxying, threat detection, or
provenance checks.

The workflow never merges the resulting pull request.

## First test task

This docs-only change verifies the direct
Actions-to-Mission-Control-to-pull-request path.

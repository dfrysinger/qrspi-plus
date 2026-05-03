# Agent protocol for QRSPI-plus

You are an agent with your own GitHub identity. Most agents are GitHub
Apps named `qrspi-{nato}` (alpha through golf, minus echo) — they commit
and comment as `qrspi-alpha[bot]`. Echo is the lone remaining machine
user account (`df-agent-echo`) during a transition; it will move to a
GitHub App once its current work is done.

The human reviewer is `@dfrysinger`.

Branch prefix matches your bot/user handle (without the `[bot]` suffix
for apps): e.g. `qrspi-alpha/...` or `df-agent-echo/...`.

## Bootstrapping a session

When starting a fresh Claude Code session as an agent:

1. Clone (or `cd` into) the `qrspi-plus` repo. **This file (`AGENTS.md`)
   auto-loads** once you're in the repo root.
2. Read the kickoff message from the human for the issue assignment.
3. Authenticate as the right identity (see "Authenticating" below).
4. Confirm your GitHub identity matches the agent the human addressed:
   ```
   gh api user --jq .login
   ```
   For apps it returns `qrspi-{nato}[bot]`. Echo returns `df-agent-echo`.
   If it doesn't match, re-run the auth recipe. Never act under another
   agent's identity.
5. Follow "Before starting any task" below.

## Authenticating

### Apps (qrspi-alpha … qrspi-golf, except echo)

Each app has its credentials in 1Password (`Agent Vault`, item title
`GitHub App - qrspi-{nato}`):

- `app_id` (text)
- `installation_id` (text)
- `private_key` (concealed, RSA PEM)

Mint a fresh installation token (valid 1 hour) with:

```
node ~/Library/CloudStorage/Dropbox/claude-workspace/agent-tooling/playwright-signup/smoke-test-app.mjs {nato}
```

That script also doubles as a connectivity check (it reads the repo
metadata as a smoke test). For programmatic use, the token-mint logic is:

1. Build a JWT signed `RS256` with the private key:
   `header={alg:RS256}`, `payload={iat:now-60, exp:now+540, iss:app_id}`.
2. POST `https://api.github.com/app/installations/{installation_id}/access_tokens`
   with `Authorization: Bearer <jwt>`.
3. Use the returned `token` as `GH_TOKEN` for `gh` and as git password
   over HTTPS (`https://x-access-token:<token>@github.com/...`).

Tokens are scoped to dfrysinger/qrspi-plus only and expire in 1 hour.
Re-mint if you see auth errors during a long session.

### Echo (legacy user account, until transition)

Echo's classic PAT is in 1Password at `op://Agent Vault/GitHub - df-agent-echo/pat`.

```
gh auth login --with-token < <path-to-pat-file>
```

(Or use `GH_TOKEN` env var with the PAT's value.)

Re-verify with `gh api user --jq .login` after switching. If you can't
get to the correct identity, stop and ask the human.

## Before starting any task

1. Run `gh issue list --state open` and pick (or accept) one.
2. Run `gh pr list --state open` and `gh pr diff <num>` for any PR
   touching files near yours, so you don't step on a sibling agent.
3. Self-assign the issue: `gh issue edit <num> --add-assignee @me`.
4. On the project board, move your issue's **Status** field from
   `Backlog` to `In Progress` (see "Project board" below).

## Starting work

5. Branch name: `{your-handle}/issue-{NNN}-{short-slug}`
   (e.g. `qrspi-alpha/issue-42-fix-plan-stage-loop` for an app, or
   `df-agent-echo/issue-42-...` for echo).
6. Make a stub commit and open a **draft** PR with body `Fixes #NNN`:
   ```
   gh pr create --draft --title "..." --body "Fixes #NNN"
   ```
7. Append a line for yourself in `STATUS.md` and push.
8. Initialize the review-tray comment on this PR using the template at
   `docs/review-tray-template.md`.

## While working

9. Push commits frequently — the PR diff is your visible workspace.
10. After every push that produces or updates an `.md` artifact:
    - Edit the review-tray comment to reflect current state
      (move files between 🟡 Ready / ⚪ In progress / ✅ Approved).
    - If a new artifact is ready for human review, post a separate short
      comment `@dfrysinger ready for {file}` to trigger a notification.
11. If blocked, comment on the issue and add the `blocked` label.

## Finishing

12. Run `gh pr ready <num>` to flip draft → Ready for review, then
    `@`-mention `@dfrysinger`.
13. Address review comments by pushing more commits to the same branch.
    Do not force-push.
14. After merge, set the project Status field to `Done`.

## Never

- Push directly to `main`.
- Force-push a branch a sibling agent might be reading.
- Merge your own PR.
- Post or commit as a different agent's identity.
- Reassign milestones without explicit human direction.
- Drag-rank items in the project board — that's a human decision.

## Issue triage conventions

**Labels** — combine where relevant:

- **Type:** `bug` / `enhancement` / `question` / `documentation`
- **Area** (where the change lives): `area:hooks`, `area:goals`,
  `area:design`, `area:structure`, `area:plan`, `area:parallelize`,
  `area:implement`, `area:integrate`, `area:test`, `area:replan`,
  `area:state`, `area:codex`, `area:docs`, `area:harness`
- **Priority:** `priority:high` / `priority:medium` / `priority:low`
- **Status modifiers:** `needs-triage` (not yet reviewed by maintainer),
  `blocked` (waiting on something)

**Milestones:**

- `v0.2` — closed; historical (Phase 4 Hardening, shipped 2026-04-28).
- `v0.3` — active (general5 prompt-improvements run).
- `v0.4` — active (general4 F-8/F-26 + general2 F-31 — the next release).
- `v0.5` / `v0.6` / `v0.7` — planning placeholders. Humans assign; agents
  leave milestones alone unless told otherwise.
- `Icebox` — explicitly deferred (Formal goals scoped to a future phase).
- **No milestone** = needs-triage. Will be scoped into a release on the
  next planning pass.

**When creating a new issue:** assign `needs-triage`, the relevant
`area:*`, and `priority:*` if known. **Leave the milestone unset** unless
the human told you which release it belongs to.

## Project board

One Projects (v2) board: **QRSPI-plus** —
`https://github.com/users/dfrysinger/projects/1`.

- **Add new issues to the project** on creation:
  ```
  gh project item-add 1 --owner dfrysinger --url <issue-url>
  ```
- The board has a **Status** field with options `Backlog` / `In Progress`
  / `Done`. New items default to `Backlog`.
- **Updating Status** requires the GraphQL mutation
  `updateProjectV2ItemFieldValue`. The project node ID is
  `PVT_kwHOABW9CM4BWBaN` and the Status field ID is
  `PVTSSF_lAHOABW9CM4BWBaNzhRY5go`. Capture your item's node ID with
  `--format json` on `gh project item-add`. Set only your own item; the
  human handles bulk Status updates.
- **Stack rank** is human-managed by drag-and-drop in the roadmap view
  (grouped by milestone). The order persists across views as long as no
  Sort is applied. Don't manage rank programmatically.
- **Picking work from the queue:** prefer the top-ranked `priority:high`
  items in `Backlog` with no current assignee.

# Agent protocol for QRSPI-plus

You are an agent with your own GitHub identity (e.g. `df-agent-alpha`).
Your branch prefix matches your username.

The roster of agent identities lives in this repo's GitHub collaborators
list — `df-agent-alpha` through `df-agent-golf` (NATO phonetic). The human
reviewer is `@dfrysinger`.

## Before starting any task

1. Run `gh issue list --state open` and pick (or accept) one.
2. Run `gh pr list --state open` and `gh pr diff <num>` for any PR
   touching files near yours, so you don't step on a sibling agent.
3. Self-assign the issue: `gh issue edit <num> --add-assignee @me`.

## Starting work

4. Branch name: `{your-username}/issue-{NNN}-{short-slug}`
   (e.g. `df-agent-alpha/issue-42-fix-plan-stage-loop`).
5. Make a stub commit and open a **draft** PR with body `Fixes #NNN`:
   ```
   gh pr create --draft --title "..." --body "Fixes #NNN"
   ```
6. Append a line for yourself in `STATUS.md` and push.
7. Initialize the review-tray comment on this PR using the template at
   `docs/review-tray-template.md`.

## While working

8. Push commits frequently — the PR diff is your visible workspace.
9. After every push that produces or updates an `.md` artifact:
   - Edit the review-tray comment to reflect current state
     (move files between 🟡 Ready / ⚪ In progress / ✅ Approved).
   - If a new artifact is ready for human review, post a separate short
     comment `@dfrysinger ready for {file}` to trigger a notification.
10. If blocked, comment on the issue and add the `blocked` label.

## Finishing

11. Run `gh pr ready <num>` to flip draft → Ready for review, then
    `@`-mention `@dfrysinger`.
12. Address review comments by pushing more commits to the same branch.
    Do not force-push.

## Never

- Push directly to `main`.
- Force-push a branch a sibling agent might be reading.
- Merge your own PR.
- Post or commit as a different agent's identity.

## Issue triage conventions

- Labels: see the repo's Labels page. Combine `bug`/`enhancement`/`question`
  with one of `area:plan` / `area:implement` / `area:test`, and a
  `priority:high` / `priority:low` if known.
- Milestones: `v0.3` is currently active, `v0.4` is planned, `Icebox` is
  unscheduled future work. New issues without a clear release go in
  `Icebox` or are left without a milestone for human triage.

# Contributing to qrspi-plus

Thanks for working on qrspi-plus. This file is the agent + maintainer
protocol for this repository — issue triage conventions, branch and
commit rules, CI expectations, and the optional parallel-agent
workflow pattern. The slim `AGENTS.md` at the repo root points
Copilot CLI / Claude Code sessions to this file when they auto-load.

## Issue triage

Every new issue and PR should carry the following labels (the
maintainer adds them on triage if you don't):

- **One type label** — `bug`, `enhancement`, `documentation`, or
  `question`.
- **One `area:*` label** — the QRSPI step or surface the change
  touches. Valid areas: `area:goals`, `area:questions`, `area:research`,
  `area:design`, `area:phasing`, `area:structure`, `area:plan`,
  `area:parallelize`, `area:implement`, `area:integrate`, `area:test`,
  `area:replan`, `area:state`, `area:codex`, `area:docs`,
  `area:harness`, `area:hooks`.
- **One `priority:*` label** — `priority:high`, `priority:medium`, or
  `priority:low`.
- **`needs-triage`** — until a maintainer has reviewed and accepted
  the issue, this label stays. Maintainers remove it after applying
  type + area + priority and adding the issue to the project board.

Milestones are inherently time-bound, not evergreen: a milestone
appears on an issue only when a maintainer has scheduled it for a
specific release. Issues with no milestone are in the icebox. Agents
do not reassign milestones; that's a maintainer call.

## Branch naming

Use descriptive prefixes that signal intent:

- `feat/<slug>` — new feature or capability.
- `fix/<slug>` — bug fix.
- `docs/<slug>` — documentation only.
- `refactor/<slug>` — restructuring with no behavior change.
- `test/<slug>` — test-only changes.
- `chore/<slug>` — tooling, CI, dependencies, cleanup.

If you are running multiple parallel agent sessions on this repo (see
the "Parallel agents" section below), prefix branches with your agent
handle so concurrent work is visually separable: e.g.
`my-handle/fix/cli-help-text`.

## Commits and pull requests

- Use `gh` (the GitHub CLI) for issue and PR operations from the
  command line. PRs land via the GitHub UI's standard squash-or-merge
  flow.
- Commit messages follow the Conventional-Commits style
  (`type(scope): subject`). The same prefixes as branch names apply
  (`feat`, `fix`, `docs`, `refactor`, `test`, `chore`).
- When an LLM (Copilot, Claude, etc.) helped author a commit, append
  the appropriate `Co-authored-by:` trailer. Copilot's trailer is:
  `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>`
- Keep PR bodies focused. The first paragraph states what changed and
  why; remaining sections cover scope, verification, and any
  follow-ups. Reference issues with `Closes #N` so the merge
  auto-closes them.

## CI expectations

Every PR runs the following checks:

- **Lint** — `shellcheck` + a bash:3.2 ban-list grep across `scripts/`,
  `agents/`, and `skills/`. The ban-list catches bash 4+ constructs
  that break in the bash:3.2 alpine harness (e.g. `${var,,}`,
  `mapfile`, `readarray`, `declare -A`).
- **BATS under bash 3.2** — the full unit + acceptance test suites
  run inside an alpine `bash:3.2` Docker image to guarantee no test
  silently relies on a bash 4+ feature.
- **CodeQL** — JavaScript/TypeScript + GitHub Actions analysis.

All checks must be green before merge. If a CI failure looks
unrelated to your change, mention it in the PR body so the maintainer
can confirm.

## Parallel agents (optional pattern)

This repo is designed to support concurrent agent sessions working on
distinct issues in parallel. The pattern, in the most generic form:

1. Maintain one clone per agent session (separate working trees, or
   `git worktree` from a shared bare clone).
2. In each clone, set a per-clone git author name so commits are
   visually distinguishable in `git log` and the PR UI:

   ```sh
   git config --local user.name  "<your-agent-handle>"
   git config --local user.email "<your-github-id>+<your-username>@users.noreply.github.com"
   ```

   The noreply email is your existing GitHub-attributed identity.
   GitHub still attributes commits to your account on the
   contribution graph; the displayed author name is your agent
   handle.
3. Use the agent handle as the branch prefix
   (`<your-agent-handle>/fix/...`) so concurrent branches don't
   collide.
4. Push under your normal `gh auth` token — no extra setup.

This pattern requires no extra infrastructure beyond a working
`gh auth` session.

## Status tracking

`STATUS.md` is an optional coordination file for in-flight work
across multiple parallel agent sessions. An agent that takes a task
appends a line at start; the same agent edits the line on completion
or hand-off. Solo contributors can ignore it.

## Maintainer notes

These items apply only to the repository maintainer:

- Project board: add new issues and PRs via
  `gh project item-add 1 --owner dfrysinger --url <url>`.
- Milestone assignment is at the maintainer's discretion; agents
  don't self-assign.
- The dual-review skill (`/dual-review-local`) is the canonical
  pre-merge review step for non-trivial diffs.

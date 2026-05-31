# Contributing to qrspi-plus

Thanks for working on qrspi-plus. This file is the agent and
maintainer protocol for this repository: issue triage conventions,
branch and commit rules, CI expectations, and the optional
parallel-agent workflow pattern. The slim `AGENTS.md` at the repo
root points Copilot CLI and Claude Code sessions to this file when
they auto-load.

## Issue triage

Every new issue and PR should carry the following labels (the
maintainer adds them on triage if you don't):

- **One type label**: `bug`, `enhancement`, `documentation`, or
  `question`.
- **One `area:*` label**: the QRSPI step or surface the change
  touches. Valid areas: `area:goals`, `area:design`, `area:structure`,
  `area:plan`, `area:parallelize`, `area:implement`, `area:integrate`,
  `area:test`, `area:replan`, `area:state`, `area:codex`, `area:docs`,
  `area:harness`, `area:hooks`.
- **One `priority:*` label**: `priority:high`, `priority:medium`, or
  `priority:low`.
- **`needs-triage`**: applied until a maintainer has reviewed and
  accepted the issue. Maintainers remove it after applying type,
  area, priority, and adding the issue to the project board.

Milestones are inherently time-bound, not evergreen: a milestone
appears on an issue only when a maintainer has scheduled it for a
specific release. Issues with no milestone are in the icebox. Agents
do not reassign milestones; that's a maintainer call.

## Branch naming

Use descriptive prefixes that signal intent:

- `feat/<slug>`: new feature or capability.
- `fix/<slug>`: bug fix.
- `docs/<slug>`: documentation only.
- `refactor/<slug>`: restructuring with no behavior change.
- `test/<slug>`: test-only changes.
- `chore/<slug>`: tooling, CI, dependencies, cleanup.

If you are running multiple parallel agent sessions on this repo (see
the "Parallel agents" section below), prefix branches with your agent
handle so concurrent work is visually separable, e.g.
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

Every PR runs the following checks (see `.github/workflows/ci.yml`
for the source of truth):

- **Lint (shellcheck + bash32 ban-list)**: `shellcheck --severity=error`
  plus a grep ban-list applied to `*.sh` and `*.bash` files under
  `scripts/` and `tests/helpers/`. The ban-list rejects bash 4+
  constructs that break under the bash:3.2 alpine harness: `mapfile`,
  `declare -A`, `${var,,}` / `${var^^}` lowercasing/uppercasing,
  `coproc`, and `wait -n`.
- **BATS under bash 3.2**: the full unit and acceptance suites run
  inside an alpine `bash:3.2` Docker image, so no test silently
  relies on a bash 4+ feature.
- **CodeQL**: JavaScript/TypeScript and GitHub Actions analysis.

CI runs on every pull request. Pushes to feature branches do not
trigger CI; open a PR (draft is fine) to see check results. All
checks must be green before merge. If a CI failure looks unrelated to
your change, mention it in the PR body so the maintainer can confirm.

## Skill prose authoring (no design-doc anchors in runtime prose)

**Principle.** SKILL.md files and the `_shared/*.md` snippets they
`!cat`-include are loaded into a runtime agent's context with NO marker
indicating where the content came from. The agent has no tool to
dereference an arbitrary file path, no concept of "G4 solution step 1"
or "CD-2 component #11," and no way to navigate to a design.md / plan.md
section. Any reference to such anchors inside skill prose is either
redundant (the content is already in context) or dangling (the content
is unreachable from the agent's runtime view).

**The rule.** Content destined for runtime agent context — anything
inside a SKILL.md body, anything inside `skills/_shared/*.md`, anything
inside a fenced block in design.md / plan.md / docs marked "lives in
implement/SKILL.md" or similar — must use self-relative phrasing
("as described above," "per the contract below," "see the spec line
section earlier in this SKILL.md") or restate the rule inline. File-
path references and design-doc anchors belong only in design.md /
plan.md / component-spec sections that humans read.

**Anti-patterns to strip on sight.**

| Pattern | Recognize by | Rewrite as |
|---|---|---|
| `_shared/*.md` file-path inside `!cat`-included snippet body or in SKILL.md prose | tokens like `per _shared/foo.md contract`, `see _shared/bar.md` when the referenced content is the surrounding inlined text | self-relative phrasing or full restate |
| G-label / CD-label with design-doc qualifier | tokens like `per G4 solution step 1`, `see CD-2 component #11`, `per G9 layer 3` | self-relative phrasing, or restate the rule inline; the agent doesn't see G/CD labels at runtime |
| "Cross-Goal Decision X" phrasing | the literal string in skill prose | restate the contract inline |
| Forward-reference summary paragraph at the end of a runtime block | sentences like "The forward-reference to X covers Y" | drop if Y is already inline above; otherwise restate Y inline |

**Cross-skill references that ARE valid at runtime.** Sibling SKILL.md
files (`implementer-protocol/SKILL.md § Report Format`,
`reviewer-protocol/SKILL.md § Reviewer Dispatch Contract`) are real
files the agent can `Read` if it needs to. References by *file path
plus section heading* to another top-level SKILL.md are fine.
References to internal sections within the same SKILL.md
(`§ Per-Task Convergence Narrowing → Step 6`) are fine too.

**Litmus test.** For each path-or-label reference in skill prose,
ask: "Can the runtime agent open this and read it?" If yes (sibling
SKILL.md, internal heading) it stays. If no (`_shared/*.md` that is
already inlined here via `!cat`, design.md goal labels, plan.md task
IDs) it is rewritten or removed.

**Pre-push lint.** Before pushing skill changes, run:

```sh
grep -nE '\b(G[0-9]{1,2}|CD-[0-9])\s+(solution|amendment|layer|sub-rule|component)\b|_shared/[a-z-]+\.md' \
  skills/*/SKILL.md skills/_shared/*.md 2>/dev/null
```

Triage each hit:

- Inside a clearly-marked maintainer block (HTML comment `<!-- maintainer: ... -->`
  or an out-of-band `# Authoring notes` section) → leave.
- Inside runtime-loaded body → rewrite self-relative or restate inline.

This rule is qrspi-plus-internal authoring hygiene; it is NOT a
content rule applied to end-user artifacts (the `goals.md` /
`design.md` / etc. produced when a user runs qrspi on their own
project). End-user artifacts never `!cat`-include shared snippets and
never carry G/CD labels.

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
4. Push under your normal `gh auth` token, no extra setup required.

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

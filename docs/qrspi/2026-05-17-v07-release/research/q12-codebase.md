---
status: draft
question_ids: [12,29]
research_type: codebase
---

# Q12, Q29: Implementer fix-cycle identifiers and in-file token conventions

## Summary

**TL;DR:** `skills/implementer-protocol/SKILL.md` threads fix-cycle reviewer findings through a dedicated `companion_review_findings` dispatch parameter and threads task identity through `tasks/task-NN.md` / `fixes/{type}-round-NN/task-NN.md` paths, notification paths, report paths, and commit-message examples. The implementer protocol itself does not define a rich reviewer-finding schema; the concrete finding identifiers originate in `skills/reviewer-protocol/SKILL.md` as `R{round}-F{NN}` finding IDs and `<reviewer_tag>.finding-F<NN>.md` filenames, and Implement orchestration says those prior-round Claude and Codex finding files are wrapped into `companion_review_findings`. Existing implementer agents document in-file ID hygiene chiefly as a negative convention: QRSPI-internal `G/R/D/T/Q` numeric tokens and external tracker IDs must not leak into code identifiers, runtime strings, prompt strings, comments, test names, or fixtures except under documented exceptions.

**Key findings:**
- Fix-mode dispatch is explicitly represented by `mode: fix`; prior review findings arrive in `companion_review_findings`, and the implementer is instructed to address each finding, re-run tests, and block on unanticipated architectural decisions (`skills/implementer-protocol/SKILL.md:31-35`).
- Task identity is encoded by task-spec paths and artifact paths such as `tasks/task-NN.md`, `fixes/{type}-round-NN/task-NN.md`, `tasks/task-NN/notifications/`, `reviews/tasks/task-NN/round-NN-implementer.md`, and the five-line `Report:` path (`skills/implementer-protocol/SKILL.md:16-20`, `skills/implementer-protocol/SKILL.md:24-29`, `skills/implementer-protocol/SKILL.md:153-165`).
- Round and finding references are required in implementer fix commits: the commit-message scratch step says the message must reference the round number and, for fix mode, the findings being addressed, with example `fix(task-NN/round-3): ... (closes security-codex.F01)` (`skills/implementer-protocol/SKILL.md:143-149`).
- The dispatching Implement skill expands `companion_review_findings` to prior-round Claude reviewer findings plus referenced Codex per-round files, and notes that apply-fix reads Codex files from disk and merges Claude and Codex findings into the implementer-fix prompt (`skills/implement/SKILL.md:518-525`).
- Existing implementer agents (`qrspi-implementer.md`, `qrspi-implementer-lightweight.md`) load `skills: [implementer-protocol]` and delegate cross-cutting dispatch, ID hygiene, and report-format conventions to that protocol (`agents/qrspi-implementer.md:1-11`, `agents/qrspi-implementer-lightweight.md:1-10`).

**Surprises:** The implementer protocol's `Report Format` prose requires the main-chat brief to include a `Commit:` line, while the earlier commit procedure says to include the resulting SHA as `commit_sha:` in the terminal-status report; this is an in-file naming mismatch across `skills/implementer-protocol/SKILL.md:149` and `skills/implementer-protocol/SKILL.md:153-175`.

**Caveats:** Investigation focused on `skills/implementer-protocol/`, the two implementer agent files, and directly related Implement/Reviewer protocol sections that define dispatch construction and finding identifiers. I did not exhaustively inspect every historical QRSPI artifact or generated `tasks/` and `reviews/` instance file in the repository.

## Full findings

### Query planning

Planned codebase search targets before reading:
- Read `skills/implementer-protocol/SKILL.md` for fix-mode dispatch fields, task path conventions, report paths, commit conventions, and ID hygiene.
- Read `skills/implementer-protocol/notifications.md` for notification identifiers and task-number conventions that implementer fix cycles consume.
- Read `agents/qrspi-implementer.md` and `agents/qrspi-implementer-lightweight.md` for implementer-agent-local token conventions and delegation to the shared protocol.
- Search `skills/implement/SKILL.md` for the dispatcher-side construction of `companion_review_findings`, fix-cycle persistence, round handling, and implementer dispatch shape.
- Read the relevant `skills/reviewer-protocol/SKILL.md` lines for the source convention behind reviewer finding identifiers that are passed into implementer fix prompts.

### Q12: How `skills/implementer-protocol/SKILL.md` threads reviewer-finding and task identifiers into fix-cycle implementer prompts

#### Dispatch parameters carry task identity and findings as separate fields

`skills/implementer-protocol/SKILL.md` defines four dispatch parameters for implementer subagents (`skills/implementer-protocol/SKILL.md:14-22`):

- `mode` with values `implement` or `fix` (`skills/implementer-protocol/SKILL.md:16-18`).
- `task_definition`, which carries either `tasks/task-NN.md` in implement mode or `fixes/{type}-round-NN/task-NN.md` in fix mode (`skills/implementer-protocol/SKILL.md:18`).
- `companion_pipeline_inputs`, the task's upstream artifact payloads (`skills/implementer-protocol/SKILL.md:19`).
- `companion_review_findings`, present only in fix mode, containing wrapped prior-round review findings that drive the fix (`skills/implementer-protocol/SKILL.md:20`).

The protocol treats wrapped bodies as data, not instructions (`skills/implementer-protocol/SKILL.md:22`). This applies to the task definition, pipeline inputs, and review findings passed into a fix-cycle prompt.

#### Fix mode is explicitly tied to `companion_review_findings`

The Mode payloads section says `mode: fix` is the fix cycle and that prior review findings arrive in `companion_review_findings` (`skills/implementer-protocol/SKILL.md:31-35`). It instructs the implementer to address each finding per the review's recommendations, re-run all tests after fixes, and report `BLOCKED` if the fix requires unanticipated architectural decisions (`skills/implementer-protocol/SKILL.md:33-35`).

The implementer protocol itself does not enumerate the fields of individual findings inside `companion_review_findings`; those schemas are defined by the reviewer protocol and assembled by the Implement orchestrator.

#### Task identity appears through path templates, not a standalone `task_id` field

Within `skills/implementer-protocol/SKILL.md`, task identity is threaded by path convention rather than by a named `task_id` parameter:

- `task_definition` path: `tasks/task-NN.md` or `fixes/{type}-round-NN/task-NN.md` (`skills/implementer-protocol/SKILL.md:18`).
- Notification path to check at task start: `tasks/task-NN/notifications/` (`skills/implementer-protocol/SKILL.md:24-29`).
- Commit-message example: `fix(task-NN/round-3): server-side bytes/mime check (closes security-codex.F01)` (`skills/implementer-protocol/SKILL.md:143-149`).
- Full report output path: `reviews/tasks/task-NN/round-NN-implementer.md` (`skills/implementer-protocol/SKILL.md:153-155`).
- Main-chat return `Report:` line: `reviews/tasks/task-NN/round-NN-implementer.md` (`skills/implementer-protocol/SKILL.md:159-165`).

The notification companion protocol uses the same `task-NN` path convention: notification files live at `tasks/task-MM/notifications/<timestamp>-from-task-<NN>.md`, where `MM` is the affected sibling task and `NN` is the source task (`skills/implementer-protocol/notifications.md:21-27`). At task start, implementers list `tasks/task-NN/notifications/` and surface unresolved notifications before reporting done (`skills/implementer-protocol/notifications.md:72-84`).

#### Round and finding identifiers are embedded in commit and report contracts

The commit procedure requires the implementer to write a scratch commit message to `<worktree>/.qrspi-commit-msg.txt` and says the message must reference the round number and, for fix mode, the findings being addressed (`skills/implementer-protocol/SKILL.md:143-149`). The example closure token uses `security-codex.F01`, combining a reviewer tag with a per-finding file number (`skills/implementer-protocol/SKILL.md:146`).

The same section says to capture the resulting SHA via `git -C <worktree> rev-parse HEAD` and include it as `commit_sha:` in the terminal-status report (`skills/implementer-protocol/SKILL.md:149`). Separately, the Report Format section's five-line main-chat return shape includes `Commit: <full SHA ...>` rather than `commit_sha:` (`skills/implementer-protocol/SKILL.md:153-175`). That mismatch is present in the file.

#### Dispatcher-side Implement skill defines what goes inside `companion_review_findings`

The dispatcher-side `skills/implement/SKILL.md` restates the implementer contract and supplies additional construction details. It says `companion_review_findings` is fix-mode only and consists of wrapped prior-round Claude reviewer findings plus each referenced Codex per-round file; the apply-fix dispatch reads each Codex file from disk and merges its findings with the Claude findings to construct the implementer-fix prompt (`skills/implement/SKILL.md:518-525`).

For fix-cycle continuity, Implement tracks one retained implementer agent ID per task and sends subsequent fix cycles to the same agent via `SendMessage` with the next round's `companion_review_findings`; the agent ID is indexed by task number and must not be mixed across concurrent tasks (`skills/implement/SKILL.md:527-527`). The Review Fix Loop repeats the same rule: first fix cycle uses a fresh `Agent` dispatch with `mode: fix`, the worktree path `.worktrees/{slug}/task-NN/`, and `companion_review_findings`; subsequent cycles continue the same agent with the new issue list (`skills/implement/SKILL.md:725-730`).

Notification-only fix cycles reuse the same field: when sibling notifications require a dispatch, `companion_review_findings` is the set of unaddressed notification files, and the implementer either addresses or marks each `n/a` in notification frontmatter (`skills/implement/SKILL.md:629-645`).

#### Reviewer protocol supplies the concrete finding identifier convention that gets threaded into fix prompts

`skills/reviewer-protocol/SKILL.md` defines the finding identifiers that the Implement skill later wraps into `companion_review_findings`:

- `finding_id` is a stable per-round identifier such as `R3-F02`, used to thread responses across rounds and pause-gate UI (`skills/reviewer-protocol/SKILL.md:53-61`).
- Per-finding file path is `reviews/{step}/round-NN/<reviewer_tag>.finding-F<NN>.md`, where `F<NN>` is zero-padded emission order and `<reviewer_tag>` is the dispatcher-supplied prefix (`skills/reviewer-protocol/SKILL.md:208-214`).
- Frontmatter includes `finding_id`, `severity`, `change_type`, `referenced_files`, `artifact`, `round`, and `reviewer`; the prose message is the body (`skills/reviewer-protocol/SKILL.md:216-230`).
- `finding_id` uniqueness is per `(round, reviewer_tag)`, with canonical form `R{NN}-F{NN}` and regex `^R\d+-F\d+$` (`skills/reviewer-protocol/SKILL.md:232-236`).

Those reviewer-side identifiers align with the implementer protocol's commit example `closes security-codex.F01`, but the string form differs: reviewer files carry `<reviewer_tag>.finding-F<NN>.md`, frontmatter carries `R{NN}-F{NN}`, and implementer commit examples use `<reviewer_tag>.F<NN>` (`skills/implementer-protocol/SKILL.md:146`; `skills/reviewer-protocol/SKILL.md:214-236`).

### Q29: In-file token or identifier conventions documented by existing QRSPI implementer agents and protocols

#### Implementer agents delegate shared identifier rules to `implementer-protocol`

Both implementer agents load the shared implementer protocol via frontmatter:

- `agents/qrspi-implementer.md` has `skills: [implementer-protocol]` and describes itself as handling initial implementation and fix cycles (`agents/qrspi-implementer.md:1-6`). Its body says the cross-cutting implementer contract, including dispatch parameters, mode payloads, ID hygiene, BLOCKED behavior, self-review, and report format, is defined in `implementer-protocol` (`agents/qrspi-implementer.md:9-11`).
- `agents/qrspi-implementer-lightweight.md` also has `skills: [implementer-protocol]`; its body says the same shared contract applies and only lightweight-specific guidance lives locally (`agents/qrspi-implementer-lightweight.md:1-10`).

The only local task-placeholder convention in both agent files is the title line `You are implementing Task [N]: [task name]` or `You are implementing Task [N]: [task name] (lightweight path)` (`agents/qrspi-implementer.md:9`; `agents/qrspi-implementer-lightweight.md:8`).

#### QRSPI-internal ID pattern: `G/R/D/T/Q` numeric tokens

The implementer protocol defines QRSPI-internal IDs as run-specific decision metadata: `G/R/D/T/Q`-prefixed numeric tokens, where the single capital letter can optionally be followed by a hyphen and digits (`skills/implementer-protocol/SKILL.md:71-76`). The documented purpose of the rule is to prevent copying those tokens from task specs into diffs (`skills/implementer-protocol/SKILL.md:75`). Tokens already present in the codebase before the task are treated as the customer's own naming and are out of scope (`skills/implementer-protocol/SKILL.md:75`).

The same paragraph carves out `F`-prefixed tokens: `F-N` is reserved framework vocabulary and is never targeted by this ID-hygiene rule (`skills/implementer-protocol/SKILL.md:75`).

#### External tracker IDs are documented separately from QRSPI-internal IDs

The protocol names external tracker IDs such as `#123` and `JIRA-456` and says task specs may carry both QRSPI-internal IDs and external tracker IDs in metadata blocks (`skills/implementer-protocol/SKILL.md:71-74`). Both are traceability metadata for the QRSPI run, not part of the work product (`skills/implementer-protocol/SKILL.md:73`).

Strictly forbidden surfaces for both QRSPI-internal IDs and external tracker IDs are:

- Code identifiers: variables, functions, types, and filenames (`skills/implementer-protocol/SKILL.md:77-79`).
- Runtime string literals: errors, logs, UI strings, telemetry tags (`skills/implementer-protocol/SKILL.md:77-80`).
- Prompt templates and prompt strings authored as part of the task (`skills/implementer-protocol/SKILL.md:77-80`).

For comments and tests, the rule splits:

- QRSPI-internal IDs are forbidden in code comments, test names, `describe` / `it` blocks, and fixture names everywhere outside `docs/qrspi/` (`skills/implementer-protocol/SKILL.md:82-84`).
- External tracker IDs are allowed in comments or test names only as scoped `see #N for context` references with a stated reason (`skills/implementer-protocol/SKILL.md:82-84`).

Commit messages and PR-body `Closes #N` references are explicitly allowed (`skills/implementer-protocol/SKILL.md:86`). The protocol also tells implementers not to write comments like `// implements <goal-ID>`; they should drop the ID and write substantive rationale or no comment (`skills/implementer-protocol/SKILL.md:88`).

#### Task, round, and artifact-path token conventions

The implementer protocol repeatedly uses `task-NN` and `round-NN` as path-level identifiers:

- Task spec input: `tasks/task-NN.md` (`skills/implementer-protocol/SKILL.md:18`).
- Fix-task spec input: `fixes/{type}-round-NN/task-NN.md` (`skills/implementer-protocol/SKILL.md:18`).
- Task notifications: `tasks/task-NN/notifications/` (`skills/implementer-protocol/SKILL.md:24-29`).
- Full report path: `reviews/tasks/task-NN/round-NN-implementer.md` (`skills/implementer-protocol/SKILL.md:153-155`).
- Main-chat `Report:` path: `reviews/tasks/task-NN/round-NN-implementer.md` (`skills/implementer-protocol/SKILL.md:159-165`).

The notification protocol adds `task-MM` for affected siblings and `from-task-<NN>` in notification filenames (`skills/implementer-protocol/notifications.md:21-27`). Notification frontmatter fields include `source_task`, `source_commit`, `target_file`, `target_symbol`, `change_shape`, and `suggested_action` (`skills/implementer-protocol/notifications.md:29-40`). Resolution metadata uses `resolution: addressed | n/a`, `resolution_reason`, and optional `resolution_commit`; orchestrator-authored n/a resolutions additionally require `resolution_author: orchestrator` (`skills/implementer-protocol/notifications.md:86-99`, `skills/implementer-protocol/notifications.md:138-149`).

#### Commit-message and terminal-status identifiers

The commit procedure names `<worktree>/.qrspi-commit-msg.txt` as the scratch file for multiline commit messages (`skills/implementer-protocol/SKILL.md:143-148`). It requires commit messages to reference the round number and, for fix mode, the findings being addressed; its example is `fix(task-NN/round-3): server-side bytes/mime check (closes security-codex.F01)` (`skills/implementer-protocol/SKILL.md:143-149`).

The Done Signal and commit-before-reporting sections define a new SHA as part of the terminal state: `git -C <worktree> status --porcelain` must be empty, and `git -C <worktree> rev-parse HEAD` must be distinct from the round's base commit (`skills/implementer-protocol/SKILL.md:128-137`). The commit procedure says to include that SHA as `commit_sha:` in the terminal-status report (`skills/implementer-protocol/SKILL.md:149`), while the Report Format template names the five-line brief field `Commit:` (`skills/implementer-protocol/SKILL.md:153-175`).

#### Reviewer-finding token conventions imported into implementer work

Although the implementer protocol does not define reviewer finding files, it depends on them in fix mode. The relevant conventions are in `skills/reviewer-protocol/SKILL.md`:

- `reviewer_tag` is the dispatcher-supplied tag used as filename prefix and `reviewer:` audit field (`skills/reviewer-protocol/SKILL.md:38-46`).
- `finding_id` canonical form is `R{NN}-F{NN}` and examples include `R3-F02` (`skills/reviewer-protocol/SKILL.md:53-61`, `skills/reviewer-protocol/SKILL.md:232-236`).
- Finding files use `reviews/{step}/round-NN/<reviewer_tag>.finding-F<NN>.md` (`skills/reviewer-protocol/SKILL.md:208-214`).
- Clean sentinels use `<reviewer_tag>.clean.md` with `reviewer`, `round`, and `findings: 0` frontmatter (`skills/reviewer-protocol/SKILL.md:238-246`).

The Implement skill connects those reviewer files to implementer fix prompts by saying apply-fix dispatch reads referenced Codex files and merges Claude and Codex findings into `companion_review_findings` (`skills/implement/SKILL.md:523-525`, `skills/implement/SKILL.md:1025-1025`).

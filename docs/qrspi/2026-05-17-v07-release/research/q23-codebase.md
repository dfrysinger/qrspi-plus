---
status: draft
question_ids: [23]
research_type: codebase
---

# Q23: What branch-naming conventions are documented in `AGENTS.md` and `skills/implement/SKILL.md` Branch Model, and how do those namespaces appear in current scripts or templates?

## Summary

**TL;DR:** `AGENTS.md` documents an agent/issue branch namespace rooted at each bot handle, with branches shaped like `qrspi-{nato}/issue-{NNN}-{short-slug}`. `skills/implement/SKILL.md` documents the runtime implementation branch namespace rooted at `qrspi/{slug}/`, with concrete branches `main`, `task-NN`, `stage-after-W{N}`, and `task-00` under that prefix. The current `scripts/` and `templates/` files do not contain those documented namespace literals; the only script-level branch handling found is generic `--base <branch>` support in `scripts/sibling-impact.mjs`, defaulting to `main`.

**Key findings:**
- `AGENTS.md` says each agent identity is `qrspi-{nato}[bot]`, the branch prefix matches the bot handle without `[bot]`, and the start-work branch pattern is `{your-handle}/issue-{NNN}-{short-slug}` such as `qrspi-alpha/issue-42-fix-plan-stage-loop` (`AGENTS.md:3-10`, `AGENTS.md:100-101`).
- `skills/implement/SKILL.md` resolves symbolic branch bases to `qrspi/{slug}/main`, `qrspi/{slug}/task-NN`, `qrspi/{slug}/stage-after-W{N}`, and `qrspi/{slug}/task-00` (`skills/implement/SKILL.md:330-340`).
- `skills/implement/SKILL.md` requires the feature branch to be named `qrspi/{slug}/main`, not bare `qrspi/{slug}`, so task branches such as `qrspi/{slug}/task-NN` can coexist as namespace siblings (`skills/implement/SKILL.md:361-364`).
- Exact searches under `scripts/` and `templates/` found no occurrences of `qrspi/{slug}`, `stage-after-W`, `feature branch tip`, `task-NN tip`, `task-00 tip`, `qrspi-alpha`/other NATO bot branch prefixes, or `issue-{NNN}`/agent issue-branch patterns.
- `scripts/sibling-impact.mjs` exposes generic branch terminology only: usage accepts `--base <branch>` and argument parsing defaults `base` to `main` (`scripts/sibling-impact.mjs:4-6`, `scripts/sibling-impact.mjs:34-40`, `scripts/sibling-impact.mjs:51-53`).

**Surprises:** The documented branch namespaces are present in skills and AGENTS documentation but not in current `scripts/` or `templates/` literals.

**Caveats:** Investigation focused on `AGENTS.md`, `skills/implement/SKILL.md`, and all files directly under `scripts/` and `templates/`, per the question. I also checked `skills/parallelize/SKILL.md` for the Branch Model that Implement explicitly consumes, but did not exhaustively analyze all non-script/non-template documentation beyond branch-namespace search hits.

## Full findings

### Query planning

Before searching, I planned to inspect:
1. `AGENTS.md` for agent branch naming and examples.
2. `skills/implement/SKILL.md`, especially `## Branch Model — Runtime Resolution (Full Pipeline)`.
3. `scripts/` and `templates/` for appearances of the documented namespaces and branch tokens.
4. Adjacent Branch Model context in `skills/parallelize/SKILL.md` because Implement says it consumes Parallelize's symbolic Branch Map.

### `AGENTS.md` branch conventions

`AGENTS.md` defines agent identity and branch prefix together:

- It says all seven GitHub Apps are named `qrspi-{nato}` and commit/comment as `qrspi-{nato}[bot]` (`AGENTS.md:3-5`).
- It says the branch prefix matches the bot handle without the `[bot]` suffix, with example `qrspi-alpha/...` (`AGENTS.md:9-10`).

The concrete start-work branch pattern is documented later:

- `Branch name: {your-handle}/issue-{NNN}-{short-slug}` (`AGENTS.md:100`).
- Example: `qrspi-alpha/issue-42-fix-plan-stage-loop` (`AGENTS.md:101`).

So the `AGENTS.md` namespace is agent-scoped and issue-scoped:

| Convention | Shape | Evidence |
|---|---|---|
| Bot handle | `qrspi-{nato}` | `AGENTS.md:3-5` |
| Branch prefix | `qrspi-{nato}/...` | `AGENTS.md:9-10` |
| Issue branch | `{your-handle}/issue-{NNN}-{short-slug}` | `AGENTS.md:100-101` |
| Example issue branch | `qrspi-alpha/issue-42-fix-plan-stage-loop` | `AGENTS.md:101` |

### `skills/implement/SKILL.md` Branch Model conventions

`skills/implement/SKILL.md` has a section titled `## Branch Model — Runtime Resolution (Full Pipeline)` (`skills/implement/SKILL.md:330`). It states that Implement consumes the symbolic Branch Map from `parallelization.md` and resolves each `Base` value at runtime (`skills/implement/SKILL.md:332`).

The runtime resolution table documents these branch namespaces:

| Symbolic base | Runtime branch namespace | Evidence |
|---|---|---|
| `feature branch tip` | `qrspi/{slug}/main` | `skills/implement/SKILL.md:334-337` |
| `task-NN tip` | `qrspi/{slug}/task-NN` | `skills/implement/SKILL.md:337` |
| `stage-after-W{N}` | `qrspi/{slug}/stage-after-W{N}` | `skills/implement/SKILL.md:338` |
| `task-00 tip` | `qrspi/{slug}/task-00` | `skills/implement/SKILL.md:339` |

Additional Implement details:

- Stage branches are scratch infrastructure; Implement creates them on demand and Integrate deletes them after merging leaves (`skills/implement/SKILL.md:341`).
- Once a task branch exists, it is canonical; fix-round dispatches reuse it and add commits (`skills/implement/SKILL.md:343`).
- Quick-fix mode has no Branch Map; each task forks directly from feature branch tip, while the re-fork prohibition still applies (`skills/implement/SKILL.md:347`).
- Process Step 3 creates the feature branch `qrspi/{slug}/main` from the current branch if absent (`skills/implement/SKILL.md:361-363`).
- The `/main` suffix is required so task branches such as `qrspi/{slug}/task-NN` can coexist as namespace siblings; the skill explicitly says not to use bare `qrspi/{slug}` (`skills/implement/SKILL.md:363`).
- Baseline auto-fix can append `task-00 → qrspi/{slug}/task-00 (base: feature branch tip)` to the Branch Map (`skills/implement/SKILL.md:393-396`).
- Repeated baseline failures append letter-suffixed baseline branches such as `task-00b → qrspi/{slug}/task-00b` (`skills/implement/SKILL.md:400`).

### Adjacent Branch Model source consumed by Implement

Although the question names Implement's Branch Model, Implement states it consumes the symbolic Branch Map from `parallelization.md` and points to `parallelize/SKILL.md` (`skills/implement/SKILL.md:332`). The corresponding Parallelize Branch Model uses the same namespace:

- Feature branch: `qrspi/{slug}/main`, with example `qrspi/user-auth/main` (`skills/parallelize/SKILL.md:64-69`).
- Rationale: bare `qrspi/{slug}` cannot coexist with `qrspi/{slug}/...`; `qrspi/{slug}/main` makes feature `main`, `task-NN`, `task-NNa`, and `stage-after-W{N}` siblings (`skills/parallelize/SKILL.md:70`).
- Hybrid stage branch: `qrspi/{slug}/stage-after-W{N}` (`skills/parallelize/SKILL.md:75`).
- Symbolic vocabulary maps to `qrspi/{slug}/main`, `qrspi/{slug}/task-NN`, `stage-after-W{N}`, and `task-00 tip` (`skills/parallelize/SKILL.md:79-84`).
- The example Branch Map includes `qrspi/{slug}/task-01`, `qrspi/{slug}/task-02`, and `qrspi/{slug}/task-03` (`skills/parallelize/SKILL.md:140-149`).

### Appearance in current scripts and templates

I searched all files directly under:

- `/Users/dfrysinger/Documents/claude-workspace/qrspi-marketplace/qrspi-plus/scripts`
- `/Users/dfrysinger/Documents/claude-workspace/qrspi-marketplace/qrspi-plus/templates`

for these documented branch namespace tokens and variants:

- `qrspi/{slug}`
- `stage-after-W`
- `feature branch tip`
- `task-NN tip`
- `task-00 tip`
- `qrspi-alpha`, `qrspi-bravo`, `qrspi-charlie`, `qrspi-delta`, `qrspi-echo`, `qrspi-foxtrot`, `qrspi-golf`
- `issue-{NNN}` / issue-branch patterns

No exact occurrences were found in `scripts/` or `templates/`.

The only branch-related script behavior found is generic, not QRSPI-namespace-specific:

- `scripts/sibling-impact.mjs` usage accepts `[--base <branch>]` (`scripts/sibling-impact.mjs:4-6`).
- Its parsed default for `base` is the literal `main` (`scripts/sibling-impact.mjs:34-40`).
- It parses `--base` by assigning the following argument to `args.base` (`scripts/sibling-impact.mjs:51-53`).
- Later, if the target commit has no parent, it falls back to diffing against `args.base` (`scripts/sibling-impact.mjs:175-190`).

Other script/template branch-word occurrences are not branch namespaces:

- `scripts/run-codex-review.sh` comments say the wrapper may be invoked from any working directory, including a worktree, target repo, or main qrspi-plus checkout; this is about filesystem invocation context, not branch naming (`scripts/run-codex-review.sh:78-84`).
- `templates/tsc-probe.ts` uses a temporary directory prefix `qrspi-tsc-probe-...`, which is not a git branch namespace (`templates/tsc-probe.ts:39`).

### Consolidated branch-namespace inventory

| Source | Namespace/pattern | Purpose | Appears in scripts/templates? |
|---|---|---|---|
| `AGENTS.md` | `qrspi-{nato}/...` | Agent branch prefix matching bot handle | No exact occurrences found |
| `AGENTS.md` | `{your-handle}/issue-{NNN}-{short-slug}` | Agent work branch for issue tasks | No exact occurrences found |
| `AGENTS.md` | `qrspi-alpha/issue-42-fix-plan-stage-loop` | Example issue branch | No exact occurrences found |
| `skills/implement/SKILL.md` | `qrspi/{slug}/main` | Feature branch | No exact occurrences found |
| `skills/implement/SKILL.md` | `qrspi/{slug}/task-NN` | Task branch | No exact occurrences found |
| `skills/implement/SKILL.md` | `qrspi/{slug}/stage-after-W{N}` | Stage/scratch branch | No exact occurrences found |
| `skills/implement/SKILL.md` | `qrspi/{slug}/task-00`, `task-00b`, etc. | Baseline-fix branch | No exact occurrences found |
| `scripts/sibling-impact.mjs` | `--base <branch>`, default `main` | Generic diff base argument | Yes, generic only (`scripts/sibling-impact.mjs:4-6`, `scripts/sibling-impact.mjs:34-40`, `scripts/sibling-impact.mjs:51-53`) |

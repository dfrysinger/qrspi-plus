
QRSPI separates two kinds of files:

- **Artifacts** (goals, questions, research, design, structure, plan, reviews) — written under `docs/qrspi/{slug}/` by the pipeline skills.
- **Code** — lives in a separate target repository that Implement clones/forks into worktrees under `.worktrees/{slug}/task-NN/`.

The recommended layout keeps these as siblings in a single workspace directory, e.g.:

```
my-workspace/
├── docs/qrspi/{slug}/   # artifacts (this pipeline's outputs)
└── code/{repo}/         # the target git repo Implement operates on
```

Recommendation, not requirement — both locations are configurable. Skills detect the artifact directory at runtime and don't assume any particular topology.

**Greenfield (no target repo yet):** Implement assumes the target repo exists with a base branch to fork worktrees from. If starting greenfield, create and `git init` the target repo before reaching Implement (Goals/Design/Structure can still run without it). A future improvement will let `config.md` carry an explicit `code_path` and let Goals offer a greenfield bootstrap step.

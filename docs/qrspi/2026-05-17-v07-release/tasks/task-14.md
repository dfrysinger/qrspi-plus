---
task: 14
status: approved
pipeline: full
task_type: code
model: sonnet
phase: 1
goal_ids: [G17]
dependencies: []
loc_estimate: 120
sizing_exception: CI scaffolding
---

# Task 14: Author qrspi-plus GitHub Actions CI workflow with lint and bash32 jobs

- **Phase:** 1
- **Target files:**
  - `.github/workflows/ci.yml` (Create) — two-job GitHub Actions workflow that provides the four CI verification surfaces (shellcheck lint, Option B ban-list grep, unit BATS under bash 3.2, acceptance BATS under bash 3.2) for the qrspi-plus repo.
- **Dependencies:** none
- **LOC estimate:** ~120
- **Sizing exception:** CI scaffolding
- **Description:** Creates `.github/workflows/ci.yml` as the qrspi-plus CI workflow file. The workflow declares two `ubuntu-latest` jobs that together cover four verification surfaces. The `lint` job installs shellcheck and runs it across `hooks/**/*.sh`, `scripts/**/*.sh`, and `tests/helpers/**.bash`, then runs the Option B ban-list grep against the same surface to fast-fail on enumerated bash-4+ constructs (`\bmapfile\b`, `\bdeclare -A\b`, `\$\{[^}]*,,\}`, `\$\{[^}]*\^\^\}`, `\bcoproc\b`, `\bwait -n\b`). The `bash32` job launches the pinned `bash:3.2@sha256:<digest>` Docker container (immutable digest reference rather than the mutable `bash:3.2` tag, so a registry tag update cannot silently shift the runtime), installs `bats-core`, `jq`, and `yq` inside the image, then executes the unit BATS suite (`tests/unit/`) followed by the acceptance BATS suite (`tests/acceptance/`) so every assertion runs against a real bash 3.2 runtime — this job is the load-bearing version-compat gate that catches both parse-time and runtime-only bash-4+ incompatibilities. The workflow's `on:` block fires on `push` to `main`, `push` to `qrspi/**` (QRSPI feature/task branch family), `push` to `*/issue-*` (agent-handle issue-branch family), and `pull_request` targeting `main`. The `concurrency:` block is keyed on `github.ref` with `cancel-in-progress: true` so rapid pushes do not queue redundant runs. Every third-party action reference is pinned to a commit SHA. The workflow file is the canonical CI signal that the Integrate skill's CI-gate consumer (T16) reads via the `gh` CLI on the head commit of the integrate branch. **Expression-injection hardening:** all GitHub Actions context values that contain user-controlled data (`github.ref`, `github.head_ref`, `github.event.pull_request.title`, `github.event.pull_request.body`, and any `github.event.pull_request.*` field, plus any `github.event.issue.*` field) MUST NOT be interpolated directly into `run:` step shell commands via `${{ expression }}` syntax — direct interpolation enables remote code execution from attacker-controlled branch names or PR metadata. User-controlled context values are assigned to an `env:` block variable at the job or step level and referenced as `$ENV_VAR` inside the shell command, which the shell quotes safely. The `concurrency.group` field is a string field (not a shell command), so `${{ github.ref }}` interpolation there is acceptable; the prohibition applies to `run:` step bodies only.
- **Test expectations:**
  - `.github/workflows/ci.yml` parses as valid YAML.
  - The workflow defines exactly two `ubuntu-latest` jobs whose IDs match the documented `lint` and `bash32` behavioral roles.
  - The `lint` job runs shellcheck against the documented shell-script surface and runs the Option B ban-list grep as a distinct step on the same surface.
  - The `bash32` job launches the `bash:3.2@sha256:<digest>` Docker image (referenced by immutable digest, never a bare `bash:3.2` tag) and executes both the unit BATS suite and the acceptance BATS suite inside the container.
  - The `on:` triggers cover all four branch families (`main`, `qrspi/**`, `*/issue-*`, and `pull_request` to `main`).
  - The `concurrency:` block is keyed on `github.ref` with `cancel-in-progress: true`.
  - Every third-party action invoked from the workflow is pinned to a commit SHA rather than a floating tag.

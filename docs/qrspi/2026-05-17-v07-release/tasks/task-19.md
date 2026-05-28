---
task: 19
status: approved
pipeline: full
task_type: code
model: sonnet
phase: 1
goal_ids: [G17]
dependencies: [T13, T14]
loc_estimate: 200
sizing_exception: CI scaffolding
---

# Task 19: CI workflow shape pin and bash32 runtime coverage pin co-shipped against ci.yml

- **Phase:** 1
- **Target files:**
  - `tests/unit/test-ci-workflow-shape.bats` (Create) — unit BATS pin that asserts `.github/workflows/ci.yml` parses as YAML, declares the two-job lint/bash32 surface with the documented trigger families and concurrency block, and pins commit-SHA action versions.
  - `tests/unit/test-bash32-runtime-coverage.bats` (Create) — unit BATS pin that asserts the Option B ban-list remains current by executing every enumerated construct under a real `bash:3.2` runtime and observing each construct fail.
- **Dependencies:** T13, T14
- **LOC estimate:** ~200
- **Sizing exception:** CI scaffolding
- **Description:** Co-ships two unit BATS pins against the same CI-workflow contract Task 14 introduces, because both observe the workflow's bash-3.2 verification surface and the ban-list-versus-runtime relationship the workflow encodes. The first pin, `tests/unit/test-ci-workflow-shape.bats`, loads the shared markdown helper from Task 13 for `require_repo_root` and diagnostic conventions, then asserts that `.github/workflows/ci.yml` parses as valid YAML (using `yq` inside the unit BATS surface), declares exactly two `ubuntu-latest` jobs whose IDs map to the documented `lint` and `bash32` behavioral roles, that the `lint` job carries both shellcheck and Option B ban-list steps, that the `bash32` job launches the `bash:3.2` Docker image and runs both the unit and acceptance BATS suites inside the container, that the `on:` trigger block covers `push` to `main`, `push` to `qrspi/**`, `push` to `*/issue-*`, and `pull_request` to `main`, that the `concurrency:` block is keyed on `github.ref` with `cancel-in-progress: true`, and that every third-party action reference is pinned to a commit SHA rather than a floating tag. The second pin, `tests/unit/test-bash32-runtime-coverage.bats`, is the contrapositive of the ban-list-currency question: the `bash32` docker job validates ban-list currency by execution, so any ban-listed construct that runs under `bash:3.2` must fail; the test asserts every currently-listed construct (`mapfile`, `declare -A`, `${var,,}`, `${var^^}`, `coproc`, `wait -n`, and any further constructs the ban-list enumerates at test time) fails under `bash:3.2`, surfacing any new bash-4 construct authors introduce that the ban-list does not enumerate. The fixture set for the second pin is derived from the ban-list itself, parsed out of the lint job's step body so the test stays synchronized with the workflow rather than carrying an independent enumeration; each fixture is a one-line shell script invoking the construct in a way that executes the bash-4 codepath, and the pin asserts each fixture's invocation under `docker run --rm bash:3.2 bash -c '<fixture>'` exits non-zero. Both tests are bash 3.2 portable so they run cleanly inside the `bash:3.2` Docker container under the `bash32` job that they collectively observe.
- **Test expectations:**
  - `tests/unit/test-ci-workflow-shape.bats` asserts `.github/workflows/ci.yml` parses as valid YAML via `yq`.
  - `tests/unit/test-ci-workflow-shape.bats` asserts the workflow declares exactly two `ubuntu-latest` jobs whose IDs match the documented `lint` and `bash32` behavioral roles.
  - `tests/unit/test-ci-workflow-shape.bats` asserts the `lint` job carries both a shellcheck step and an Option B ban-list grep step.
  - `tests/unit/test-ci-workflow-shape.bats` asserts the `bash32` job launches the bash 3.2 Docker image referenced by immutable digest (`bash:3.2@sha256:<digest>`) — a bare `bash:3.2` tag without a `@sha256:` suffix fails the pin — and runs both the unit and acceptance BATS suites inside the container.
  - `tests/unit/test-ci-workflow-shape.bats` asserts the `on:` trigger block covers `push` to `main`, `push` to `qrspi/**`, `push` to `*/issue-*`, and `pull_request` to `main`.
  - `tests/unit/test-ci-workflow-shape.bats` asserts the `concurrency:` block is keyed on `github.ref` with `cancel-in-progress: true`.
  - `tests/unit/test-ci-workflow-shape.bats` asserts every third-party action reference in the workflow is pinned to a commit SHA rather than a floating tag.
  - `tests/unit/test-ci-workflow-shape.bats` asserts no `run:` step in the workflow body contains a direct `${{ github.event.`, `${{ github.head_ref`, or `${{ github.ref` interpolation (the literal characters `${{` followed by `github.event.`, `github.head_ref`, or `github.ref`) — user-controlled GitHub Actions context values MUST be routed through `env:` block variables rather than interpolated directly into shell commands, closing the expression-injection vector. `github.ref` in `push` events resolves to `refs/heads/<branch-name>` where the branch-name segment is attacker-controlled, so an unquoted `${{ github.ref }}` inside a `run:` shell command is an injection vector alongside `github.head_ref`. The `concurrency.group` field is exempt because it is a string field, not a shell command.
  - `tests/unit/test-bash32-runtime-coverage.bats` parses the ban-list directly out of the workflow's `lint` job step body so its fixture set stays synchronized with the workflow.
  - `tests/unit/test-bash32-runtime-coverage.bats` asserts every currently-listed ban-list construct (`mapfile`, `declare -A`, `${var,,}`, `${var^^}`, `coproc`, `wait -n`, and any further enumerated constructs) fails under `docker run --rm bash:3.2 bash -c '<fixture>'`.
  - `tests/unit/test-bash32-runtime-coverage.bats` surfaces a loud diagnostic naming any new bash-4 construct authors introduce that the ban-list does not enumerate, by detecting any construct present in the workflow's ban-list that nonetheless succeeds under `bash:3.2` — the contrapositive observation that keeps the docker job's load-bearing role honest.
  - Both pins load `tests/helpers/skill-markdown.bash` via the shared helper convention and run to completion under bash 3.2 inside the `bash:3.2` Docker image.

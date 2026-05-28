---
task: 17
status: approved
pipeline: full
task_type: code
model: sonnet
phase: 1
goal_ids: [G18]
dependencies: [T13, T14, T15]
loc_estimate: 140
---

# Task 17: Repo-wide evergreen-markdown BATS scan with path and inline carve-outs

- **Phase:** 1
- **Target files:**
  - `tests/unit/test-evergreen-markdown.bats` (Create) — unit BATS pin that scans every git-tracked `**/*.md` file for evergreen-markdown forbidden tokens, applies the path-shaped and inline carve-outs from the hygiene contract, and fails loudly with per-file diagnostics on any hit outside the carve-outs.
- **Dependencies:** T13, T14, T15
- **LOC estimate:** ~140
- **Description:** Authors `tests/unit/test-evergreen-markdown.bats` as the repo-wide regex scan that enforces the evergreen-markdown contract documented in `skills/implementer-protocol/SKILL.md` (Task 15) under the same unit BATS surface that the `bash32` job executes in the new CI workflow (Task 14, exercised through the workflow consumer in Task 16). The BATS file loads the shared markdown helper from Task 13 via `load 'helpers/skill-markdown'` to keep `require_repo_root` and diagnostic conventions consistent with the other Slice 3 pins, then iterates over every git-tracked `**/*.md` file in the repo, skipping files whose path matches the carve-out globs `docs/qrspi/YYYY-MM-DD-*/**`, `CHANGELOG.md`, and `tests/fixtures/**`. For each remaining file the test runs one regex pass per forbidden-token family (release-version tokens such as `v\d+\.\d+`, milestone wording such as "in v0.7" or "after this release", and PR or issue references used to justify current behavior). Lines containing the inline carve-out comment `<!-- evergreen-exempt -->` are skipped on that line only. Any surviving hit fails the test with a loud per-file, per-line diagnostic that names the file path, the line number, the matched regex family, and the matched text. The test is bash 3.2 portable (no `mapfile`, no `declare -A`, no `${var,,}`, no `coproc`, no `wait -n`) so it runs cleanly inside the `bash:3.2` Docker container under the `bash32` job.
- **Test expectations:**
  - A markdown file outside any path carve-out containing `in v0.6` fails the test with a diagnostic naming the file, line, and matched regex family.
  - A markdown file outside any path carve-out describing behavior by contract surface (no version tokens, no milestone wording, no PR/issue references) passes the test.
  - A markdown file under `docs/qrspi/YYYY-MM-DD-*/**` containing a release-version token does not fail the test.
  - A markdown file at `CHANGELOG.md` containing release-version tokens does not fail the test.
  - A markdown file under `tests/fixtures/**` containing a release-version token does not fail the test.
  - A markdown line containing a release-version token followed by `<!-- evergreen-exempt -->` does not fail the test even when the file is outside the path carve-outs.
  - A non-markdown file (for example a `.sh` file) containing a release-version token has no effect on the test result.
  - The test loads `tests/helpers/skill-markdown.bash` via the shared helper convention and runs to completion under bash 3.2 inside the `bash:3.2` Docker image.

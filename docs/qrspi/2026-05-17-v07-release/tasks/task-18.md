---
task: 18
status: approved
pipeline: full
task_type: code
model: sonnet
phase: 1
goal_ids: [G7, G18]
dependencies: [T13, T15]
loc_estimate: 150
---

# Task 18: Implementer pre-DONE self-check BATS pin for combined hygiene contract behavior

- **Phase:** 1
- **Target files:**
  - `tests/unit/test-hygiene-self-check.bats` (Create) — unit BATS pin that exercises the combined pre-DONE self-check defined in `skills/implementer-protocol/SKILL.md`, asserting added-line hit detection on both internal-ID and evergreen-markdown regex families, advisory commit semantics, the DONE-report acknowledgment path, and reviewer visibility for unacknowledged hits.
- **Dependencies:** T13, T15
- **LOC estimate:** ~150
- **Description:** Authors `tests/unit/test-hygiene-self-check.bats` as the BATS pin that exercises the combined pre-DONE self-check contract Task 15 codifies in `skills/implementer-protocol/SKILL.md`. The pin loads the shared markdown helper from Task 13 via `load 'helpers/skill-markdown'` to read the hygiene contract subsections from the protocol file by H2/H3 anchor, then exercises the self-check against synthesized commit-diff fixtures. The first fixture adds a line containing an internal-ID token (for example a reviewer finding ID of the round-N finding-NN form) to a `skills/foo/SKILL.md` path — the test asserts the self-check reports a hit naming the file, line, and internal-ID family. The second fixture adds the same token under `docs/qrspi/**` — the test asserts the self-check does not report a hit because of the path-shaped carve-out. The third fixture adds an evergreen-markdown token (for example `in v0.7+`) to a non-exempt markdown file — the test asserts the self-check reports a hit naming the file, line, and evergreen-markdown family. The fourth fixture adds the same token to a `.sh` file — the test asserts no hit because evergreen-markdown rules apply only to edited markdown. The fifth fixture pairs a retained hit with an explicit acknowledgment line in the DONE report — the test asserts the commit proceeds and the acknowledgment is preserved in the report for reviewer visibility. The sixth fixture pairs a retained hit with no acknowledgment — the test asserts the commit still proceeds (advisory contract) AND that the unacknowledged hit is surfaced to the reviewer through the DONE-report channel the reviewer dispatch consumes. The test is bash 3.2 portable so it runs cleanly inside the `bash:3.2` Docker container under the `bash32` job.
- **Test expectations:**
  - An added line containing an internal-ID token on a `skills/foo/SKILL.md` fixture path triggers a self-check hit naming the file, line, and internal-ID family.
  - An added line containing the same internal-ID token under a `docs/qrspi/**` fixture path does not trigger a self-check hit.
  - An added line containing an evergreen-markdown token on a non-exempt markdown fixture path triggers a self-check hit naming the file, line, and evergreen-markdown family.
  - An added line containing an evergreen-markdown token on a `.sh` fixture path does not trigger a self-check hit.
  - A retained hit accompanied by an explicit DONE-report acknowledgment proceeds to commit and the acknowledgment is preserved in the report.
  - A retained hit with no acknowledgment still proceeds to commit (advisory contract holds) and the unacknowledged hit is surfaced to the reviewer through the DONE-report channel — observably, the next per-task reviewer dispatch includes the DONE-report body as a companion parameter AND the DONE-report file path is listed in the dispatch payload so the reviewer Reads it during pre-flight.
  - The test loads `tests/helpers/skill-markdown.bash` via the shared helper convention and runs to completion under bash 3.2 inside the `bash:3.2` Docker image.

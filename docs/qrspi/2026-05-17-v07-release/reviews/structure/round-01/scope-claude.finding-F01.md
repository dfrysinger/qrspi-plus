---
finding_id: R1-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-17-v07-release/structure.md:L485-L511]
artifact: structure
round: 1
reviewer: scope-claude
---

The `## CI Pipeline` section (lines 485–511) contains literal shell commands that belong to Plan/Implement, not to Structure. Three specific sites cross the boundary:

1. **Lines 492–493** — the exact ban-list grep regex strings embedded in prose: `\bmapfile\b`, `\bdeclare -A\b`, `\$\{[^}]*,,\}`, `\$\{[^}]*\^\^\}`, `\bcoproc\b`, `\bwait -n\b`. These are the literal body of a grep command the lint job runs, not a structural declaration about what the CI file exports or what surfaces it verifies.

2. **Lines 508–509** — exact shell invocations under "Test commands invoked per job": `shellcheck $(find hooks scripts tests/helpers -type f \( -name '*.sh' -o -name '*.bash' \))` and `docker run --rm -v ${PWD}:/repo -w /repo bash:3.2 sh -c "apk add --no-cache bats jq yq && bats tests/unit tests/acceptance"`. These are step-body implementation text, not structure-level interface shapes or behavioral-signature declarations.

3. **Line 511** — the literal `gh` CLI invocation: `gh run list --branch <ref> --workflow ci.yml --json conclusion`. This prescribes the exact command the Integrate skill will use, which is Implement-level content.

The OWNS/DEFERS contract is clear: "per-task LOC, full assertion text, per-task commit ranges, line-by-line logic → Plan / Implement." The exact commands constituting each CI job's steps are "line-by-line logic" for the CI workflow and the Integrate skill's CI-gate consumer — they belong to Plan/Implement, not to structure.md.

Contrast with the correct treatment in the Interfaces section (lines 306–332), where `.github/workflows/ci.yml` is documented using comment-only stub form (`# steps: checkout (pinned SHA), install shellcheck, run shellcheck against ...`) — that is the right level of abstraction for Structure. The CI Pipeline section then re-describes the same jobs but adds literal command strings on top, which crosses the DEFERS boundary.

**Resolution.** Remove or trim the `## CI Pipeline` section to eliminate the literal command strings. The behavioral signature of the two jobs and the four verification surfaces is already captured correctly at the interface level (lines 306–332). The CI Pipeline section may retain high-level prose describing the trigger set, concurrency control, and what each job verifies — but must not specify the exact commands, regex patterns, or CLI flags the steps will execute. Those details belong in the task spec authored by Plan.

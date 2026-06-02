---
finding_id: F03
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/plan.md
artifact: docs/qrspi/2026-05-30-v072-release/plan.md
---

# Task 02 verifier-fan-in does not validate that expected reviewer tags emitted output — empty round-dir silently produces empty kept-findings + exit 0

## Where

Task 02 (G12 verifier-fan-in script with dispatch-prose include), Scope `**In:**`:

> Create `scripts/verifier-fan-in.sh` to enumerate `<round-dir>/*.finding-F*.md`, validate each finding's `change_type:`, locate the paired `<reviewer-tag>.finding-F<NN>.score.md` sidecar, …

Definition of done:

> A well-formed round exits 0, writes `kept-findings.txt` containing only absolute paths for kept finding files, and writes `.verifier-fan-in-audit.json` with scored, kept, dropped, empty `halts`, and threshold data.

Enumerated halt causes are limited to **per-finding** contract violations:

> Missing `change_type`, out-of-enum `change_type`, missing sidecar, wrong sidecar extension, and unparseable score each exit non-zero and record the matching halt cause in `.verifier-fan-in-audit.json`.

The script glob `<round-dir>/*.finding-F*.md` returns the empty set when no finding files exist, and the plan does not list "no finding files for an expected reviewer tag" as a halt cause. An empty round directory (because every reviewer subagent silently failed to emit *anything* — no finding file, no `<reviewer-tag>.clean.md` sentinel either) produces:

- `kept-findings.txt`: empty file
- `.verifier-fan-in-audit.json`: `scored: 0, kept: 0, dropped: 0, halts: []`
- exit code: 0

…which is byte-identical to a legitimate "every reviewer ran and found nothing" round.

## Why this matters

Task 03 (G6) establishes the reviewer disk-write contract:

> The first-party contract requires `<round_subdir>/<reviewer_tag>.finding-F<NN>.md` per finding or `<round_subdir>/<reviewer_tag>.clean.md` for zero findings, and states that any other channel produces zero findings for that tag with the expected loud failure surface.

Task 03 also pins the failure surface in unit tests:

> wrong-channel output reporting `expected tag produced no output` rather than silently passing.

But that test is the *unit test for the protocol contract*. At runtime, **no script in the v0.7.2 pipeline is specified to check** "every dispatched reviewer tag produced at least one finding file OR a clean sentinel." The plan dispatches reviewers via `dispatch-agent.sh` (Task 20), drains background entries via `await-round.sh` (Task 12 / Task 20), then runs `verifier-fan-in.sh` (Task 02) — none of these scripts cross-references the dispatch manifest's expected reviewer tags against the actual files on disk.

This means: under the post-T20 task-tool transport, if a reviewer subagent returns chat-only text (the v0.7.1 G6 failure mode this release is fixing) AND chat text contains no `<<<FINDING-BOUNDARY>>>` markers AND the third-party splitter therefore produces no files AND the reviewer was supposed to be a "no findings → clean.md" reviewer, the fan-in sees zero files and concludes the round is clean. The orchestrator advances to apply-fix with `kept-findings.txt` empty and ships unreviewed code.

This is the SILENT_FALLBACK class: callers cannot distinguish "empty because every reviewer found nothing and emitted clean sentinels" from "empty because every reviewer's output was lost." Goals G6 frames exactly this:

> chat-only reviewer output under task-tool transport

…as the regression to fix. The fan-in script is the most natural runtime enforcement point for "every expected tag produced *something* on disk."

## What the plan should require instead

Add to Task 02 (or to Task 12's `await-round.sh`, whichever owns the final gate before fan-in proceeds):

1. The fan-in script (or `await-round.sh`) reads the dispatch manifest's expected reviewer-tag list for the round and **asserts that each expected tag produced either ≥1 `<tag>.finding-F*.md` file OR exactly one `<tag>.clean.md` sentinel**.

2. A tag with neither produces a non-zero exit and a `.verifier-fan-in-audit.json` halt entry with `cause: reviewer_tag_produced_no_output` (or equivalent), naming the offending tag.

3. Test expectations add a fixture round where the dispatch manifest lists tag `claude-quality` but the round directory contains no `claude-quality.*` files at all; the fixture must exit non-zero with the named halt cause.

This closes the round-level silent-failure surface that Task 03's protocol contract documents but no runtime script currently enforces.

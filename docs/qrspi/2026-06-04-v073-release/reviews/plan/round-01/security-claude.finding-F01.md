---
finding_id: F01
reviewer: security-claude
reviewer_tag: security-claude
artifact: plan.md
round: 1
severity: medium
change_type: defect
category: input-validation
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md
  - skills/using-qrspi/SKILL.md  # T26 inlining sites
tasks_affected: [T03, T13, T19, T25, T26, T27]
---

# F01 — SHA-format validation missing on values read from phase-base.txt, anchor files, and report-parsed revert lists

## Summary

Multiple scripts in the plan read git SHA values from on-disk files (or report-parsed
text) and pass those values directly into `git` invocations as revisions, without
validating the value matches a well-formed object-name shape (`^[0-9a-f]{7,64}$`).
Task test expectations validate the *file shape* (missing / empty / wrong-key /
multi-line) but never validate the *value content*. A malformed-content value that
starts with `-` (e.g. `--exec=evil`, `--output=/tmp/x`) is read past the shell-quoting
boundary intact and is then interpreted by git as an **option**, not a revision —
shell quoting prevents `bash` injection but does NOT prevent git argument-injection
through option-shaped values. An implementer following the plan literally will build
scripts that fail-open on garbage SHA inputs.

## Affected surfaces

| Task | Script | Read site | Passed to |
|---|---|---|---|
| T03 | `scripts/review-prep.sh` | `reviews/<step>/round-<NN-1>-commit.txt` | `git diff "$ANCHOR" -- <artifact>` |
| T19 | `scripts/orchestration-boundary-check.sh` | `reviews/<phase>/phase-base.txt` (`integration_base_sha=<SHA>`) and `reviews/implement/wave-state/wave-W1-expected-parents.txt` | `git log <phase-base>..HEAD --format='%H %an'` |
| T25 | `scripts/validate-stage-commit-parents.sh` | wave-state sidecar (`integration_base_sha=`, `task_tip_shas=`) and `--stage-commit <SHA>` CLI flag | `git log --format='%P' -n 1 <SHA>` |
| T26 + T27 | `skills/using-qrspi/SKILL.md` § Apply-fix step 12 (the canonical Bash incantation) | `reviews/<step>/round-<NN-1>-commit.txt` via `"$(cat ...)"` | `git diff "$(cat ...)" -- <artifact-path>` |
| T13 | `revert-orchestration-drift` fix-task mode | per-commit SHA strings parsed out of `reviews/<phase>/orchestration-boundary.md` | `git revert --no-edit <SHA>` (in autopilot under T20) |

## Why this matters (concrete failure mode)

`phase-base.txt` is normally written by T21/T22 phase-start steps and contains a real
SHA — but defensive programming on internal-only inputs is exactly what failure of
**any** upstream producer demands. If a subagent buggily writes
`integration_base_sha=--output=/tmp/exfil` (or `integration_base_sha= ; ls`), the
T19 OBC script invokes `git log --output=/tmp/exfil..HEAD …` — and `--output` IS a
real git option on some plumbing commands. The minimum harm is a malformed log
range that produces wrong findings (defeating the OBC's safety property). Worse
harms (writing files at attacker-chosen paths via `--output-indicator-*`,
`--output=<path>` on the diff family) are plausible across the git CLI surface.

`git revert --no-edit <SHA>` in T13's autopilot path is the highest-impact site
because it's autonomous (cap-1 retry, no human in the loop per T20 autopilot mode)
and operates on a SHA list parsed from a freeform-ish Markdown report. The author
column upstream is `git log %an` and may legitimately contain spaces, hyphens, and
non-ASCII — column parsing alone cannot reject all malformed SHA tokens.

## Plan-spec gap

Every affected task's test expectations describe negative-direction coverage for
**file existence and structural shape** (e.g., T19: "empty file", "wrong key",
"multi-line content"; T03: "missing anchor file exits non-zero"). None describe a
negative-direction case for the **value content** — no fixture phase-base.txt
with `integration_base_sha=--exec=…`, no fixture anchor file with garbage / option-
shaped content, no fixture OBC report whose commit list contains a non-SHA token,
no test asserting `git rev-parse --verify --end-of-options` (or an equivalent
allowlist regex) gates the value before consumption.

## What the plan should require

For T03, T19, T25, T26/T27, and T13:

1. Add to the affected task's description: each consumer MUST validate every value
   read from disk or report parsing matches `^[0-9a-f]{7,64}$` (allowing both short
   and full SHA-1 / SHA-256 forms) before passing to any `git` command. Values that
   fail validation halt with a named diagnostic (`phase-base-sha-malformed:`,
   `anchor-sha-malformed:`, `revert-sha-malformed:` as appropriate) and exit non-zero
   (or, for fail-soft scripts like T19, write the diagnostic to the report —
   matching the existing fail-soft contract).

2. Add to each affected task's `Test expectations`:
   - A fixture whose SHA value begins with `--` (e.g. `--exec=x`) is rejected with
     the named diagnostic, NOT passed to git.
   - A fixture whose SHA value contains shell metacharacters (`; $ \` `) is rejected.
   - A fixture whose SHA value contains whitespace or newlines is rejected.
   - A fixture whose SHA value is a branch name (e.g. `main`, `HEAD~1`) is rejected
     — only literal object-name shapes are accepted.

3. For T13 specifically, the `revert-orchestration-drift` mode entry in
   `skills/implementer-protocol/SKILL.md` § Mode payloads must name the validation
   step explicitly — "before each `git revert --no-edit <SHA>`, validate SHA
   matches `^[0-9a-f]{40,64}$`; on validation failure halt with
   `revert-sha-malformed:` and write the diagnostic to
   `orchestration-boundary-revert.md` without performing any revert."

## Defense-in-depth rationale

This is a CLI plugin where every producer is also under our control; in *normal*
operation no malformed SHA reaches any consumer. The finding is **defense-in-depth
fail-closed**: a future bug in any phase-base writer, any sidecar writer, any OBC
report generator, or a tampered-with workspace must surface as a loud rejection at
the consumer, not as a silent option-injection into git. The cost is one regex
match per consumer; the benefit is closing an entire class of "internal trust"
failure modes that the existing test coverage cannot catch.

---
artifact: structure
round: 7
---

# Structure Round 07 — Dispositions

## KEEP (5 findings — apply fix)

### qc-F01 / sa-F02 — G31 Consumer #9 (plan-test-coverage-reviewer / Addition C)
**Action:** Add a new row to Slice 1.5 File Map (or near the existing G31 cluster):

| File | Action | Responsibility | Goal IDs |
|---|---|---|---|
| `agents/qrspi-plan-test-coverage-reviewer.md` | Modify | Add Addition C inline at the TOP of the review-procedure section (standalone — does NOT preload prompt-prose-reviewer per design CD-9 rationale). | G31 |

### qc-F02 — G31 Hook-Point materially incomplete
**Action:** Rewrite the G31 Hook-Point subsection to cover the full distribution surface. Rename subsection from "G31 prompt-prose-writer `!cat` include sites" (too narrow) to "G31 prompt-prose `!cat` include sites" (covers writer AND reviewer). Add rows for:

- **Consumer #1** — `skills/plan/SKILL.md` § Per-Task Classification: Addition A (inline) + `!cat skills/_shared/prompt-prose-detection.md` (per design G31 Consumer #1)
- **Consumer #2** — KEEP existing row (plan/SKILL.md writer-subagent dispatch payloads, 2 sites)
- **Consumer #3** — KEEP existing row (design/SKILL.md authoring step)
- **Wrapper SKILL** — `skills/prompt-prose-writer/SKILL.md` body: `!cat skills/_shared/prompt-prose-detection.md` + `!cat skills/_shared/prompt-prose-writer-addition.md` (per design File 4)
- **Wrapper SKILL** — `skills/prompt-prose-reviewer/SKILL.md` body: `!cat skills/_shared/prompt-prose-detection.md` + `!cat skills/_shared/prompt-prose-reviewer-addition.md` (per design File 5)
- **Addition C** — `agents/qrspi-plan-test-coverage-reviewer.md` body: Addition C inline at TOP of review-procedure (Consumer #9, no `!cat`)
- **Addition D** — `agents/qrspi-design-reviewer.md` body: Addition D inline AFTER `skills:` frontmatter preload triggers (Consumer #6)

### qc-F03 — Rename convention inconsistency
**Action:** Standardize the 5 rename rows in the File Map to the pre-existing convention used by `skills/_shared/codex/launch-await-pattern.md` (line 69) — keyed by OLD path in the File column, Action = "Rename → NEW". Convert the 4 R6-introduced rows from "key by NEW, Rename → NEW (from OLD)" to "key by OLD, Rename → NEW":

- File: `scripts/run-codex-review.sh` | Action: `Rename → scripts/dispatch-agent.sh` | (Responsibility unchanged) | Goal IDs unchanged
- File: `scripts/run-third-party-llm.sh` | Action: `Rename → scripts/dispatch-companion.sh`
- File: `scripts/codex-finding-splitter.sh` | Action: `Rename → scripts/third-party-finding-splitter.sh`
- File: `skills/reviewer-protocol/codex-emission-override.md` | Action: `Rename → skills/reviewer-protocol/third-party-emission.md`

This matches git's `git mv` semantics (file identity preserved at OLD path; renamed to NEW) and matches the existing precedent.

### sa-F01 — Stale test file names
**Action:** Rename the two test files to align with their script-under-test's new name, AND surface the rename in the File Map.

- File: `tests/unit/test-run-codex-review.bats` | Action: `Rename → tests/unit/test-dispatch-agent.bats` | Responsibility: Guard sanctioned-path filtering on dispatch-agent inputs. | G16
- File: `tests/unit/test-codex-review-codex-availability.bats` | Action: `Rename → tests/unit/test-dispatch-companion-availability.bats` | Responsibility: Guard host-aware second-reviewer availability probing in dispatch-companion. | G27

Rationale: Both test names describe their script-under-test which has been renamed per CD-1 rename inventory; preserving the old test names breaks the convention that test file names mirror the file-under-test.

## DROP (2 findings — no action)

### sa-F03 — §10 host/vendor untested (38 → well below 70)
Verifier judged Plan-altitude; structure pins test files that exist but does not author assertion content. No fix in R7.

### scope-codex F01 — G31 Hook-Point "Addition B verbatim" content leak (orchestrator judgment)
scope-claude (the dedicated scope reviewer) returned clean and cited "matches CD-1…G35 precedent." The G35 row at line 757 carries comparable content-leaning prose ("introducer prose precedes the include"). Two reasoned signals (scope-claude clean + G35 precedent) outweigh the lone over-conservative scope-codex finding. No fix in R7.

## Sequence

1. Apply fixes via fix-r7 (single dispatch)
2. Single commit (no anchor commit)
3. Write `round-07-commit.txt` as untracked (rides with R8 commit per protocol)
4. Re-loop or declare clean per next-round assessment

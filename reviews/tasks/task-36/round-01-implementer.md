# task-36 round-01 implementer report (lightweight)

**Status:** DONE
**Commit:** b81294208a6cef0c9fa8661b40f1383daf7b02f9
**Author:** qrspi-implementer-lightweight

## Per-file line counts

| File | Before | After | Edited? |
|---|---:|---:|:---:|
| skills/integrate/SKILL.md | 383 | 298 | ✓ |
| skills/test/SKILL.md | 431 | 298 | ✓ |
| skills/implementer-protocol/SKILL.md | 288 | 288 | – |
| skills/reviewer-protocol/SKILL.md | 287 | 287 | – |
| skills/research-isolation/SKILL.md | 77 | 77 | – |
| skills/prompt-prose-writer/SKILL.md | 17 | 17 | – |
| skills/prompt-prose-reviewer/SKILL.md | 17 | 17 | – |

All 7 spec Target files now satisfy <300 lines.

## Trim strategy

R1-R8 + cross-cutting principles applied to the two over-length files. High-leverage moves:

- Collapsed multi-line bullet lists into prose paragraphs where the bullets weren't distinct enumerations (e.g., main-chat "does NOT" list, Red Flags, dispatch parameter enumerations).
- Dropped intro sentences preceding tables (Subagent Dispatches, Reviewer Agents, Coverage Criteria, Test Types).
- Condensed Process Steps step-N OBC bodies (Orchestration Boundary Check) — preserved the load-bearing prose anchors but tightened explanatory framing.
- Condensed Batch Gate autopilot branches — preserved branch-precedence order and the three halt-marker file names verbatim.
- Merged the two-format Fix Task File templates in integrate/SKILL.md into a single template with a variant note.
- Deleted the "Worked Example — Bad" section in test/SKILL.md (R4 caps examples at 2; the inline counter-example sentence replaces it).
- Compressed Iron Laws Final Reminder, Phase Learnings Gate, Code Review Checkpoint, Model Selection Guidance table.
- Used inline-list form for Task Tracking sub-tasks (10 entries → one numbered sentence).

## Anchor preservation (load-bearing)

Verified by structural-lint scripts:

- **T24** (`check-integrate-test-skill-phase-base-write.sh`) — PASS. Both integrate and test SKILL.md retain a write-verb + `reviews/{phase}/phase-base.txt` literal-path line.
- **T24b** (`check-obc-script-absent-anchor.sh`) — PASS. implement/integrate/test SKILL.md each retain the `obc-script-absent:` token, `## Dispatch defects` heading, and same-line `obc-script-absent:` + halt + invo regex match.

Other anchors preserved by inspection:

- HARD-RULE Orchestration Boundary fenced blocks (verbatim) in integrate + test.
- HARD-GATE fenced block in test/SKILL.md (verbatim).
- Quick-fix binary gate: exact two-choice menu inside the fenced block + "The gate MUST render only the two choices above. There is no third option in quick-fix mode" prose.
- Phase-routing fail-loud `PHASE-ROUTING-VIOLATION:` anchor and bats-test reference.
- `!cat skills/_shared/reviewer-dispatch-prose.md` include line.
- `<<<UNTRUSTED-ARTIFACT-START id={name}>>>` wrapper markers.

## Files NOT edited

Five files were already <300 lines and carried high-risk anchors (implementer-protocol T13a/T13b, reviewer-protocol's four prompt-injection-defense sections, prompt-prose-writer/reviewer's tightly-scoped agent prompts, research-isolation's compact contract). Per the lightweight-path Red Flag "don't restructure beyond what the task asks for" and the spec's <300 target, these were left untouched and verified to still satisfy the line cap.

## Hygiene scan

`git diff --unified=0 | grep '^+'` scanned for internal-ID and evergreen-markdown tokens:

- `D1`, `D4` — pre-existing reference to using-qrspi BEHAVIORAL-DIRECTIVES; carried over unchanged.
- `T19` — pre-existing "plan T19" reference in integrate/SKILL.md OBC body; carried over unchanged.

No new internal-ID tokens, no version strings (v\d+\.\d+), no `see #N` tokens introduced by this trim.

## Self-review

- Scope: only spec Target files touched. ✓
- Spec fidelity: all 7 files <300 lines; load-bearing anchors preserved; lints pass. ✓
- No spurious tests: lightweight path; no test scaffolds created. ✓
- No abstraction creep: no new helpers, no new heuristics introduced. ✓
- Commit author: qrspi-implementer-lightweight. ✓
- Commit subject prefix: `implement(task-36):`. ✓

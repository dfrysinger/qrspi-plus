---
finding_id: R05-F01
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md:L224-L256
artifact: plan
round: 5
reviewer: security-claude
---

T03 (`review-prep.sh`) has no test expectation for an unknown or invalid `--step` value, and its description does not explicitly specify the failure direction for that case.

**The gap.** The description says the script has "a step-specific generation table" and that "when there is nothing to produce for a step (e.g., the artifact is not in a git working tree, or `git diff` produced no output for a step that has no diff today), the script emits no files for that step and exits 0." An unrecognised step name (e.g., `--step bogus`, or a caller typo like `--step phrasing` instead of `--step phasing`) falls through the generation table with nothing to produce — the script emits no files and exits 0. The dispatch-agent then omits `diff_file_path:` from the reviewer prompt. The reviewer receives no diff and proceeds as if there were no changes to review. The caller cannot distinguish "valid step / no diff today" from "invalid step name / complete silent miss."

**Why the existing Author Note does not cover this.** The T03 Author Note (expanded in round 5 to cite `security-codex R4-F02/R4-F03`) concerns the *empty-diff / not-in-git-tree* case — valid-but-empty inputs. An unknown `--step` value is qualitatively different: it is an invalid input (a caller error), not a valid-but-empty scenario. The CD-2 contract phrase "fail-loud-on-real-error / silent-on-no-input" targets the empty-diff shape; a misspelled step name is a "real error" under that taxonomy, not a "no-input" scenario.

**What the plan should require.** Either:
(a) A test expectation: "An unknown `--step` value halts non-zero with the `review-prep-unknown-step:` named diagnostic — no files are written, no silent exit 0." This is consistent with the fail-loud-on-real-error half of CD-2's existing contract and mirrors how T19 handles `--phase bogus` (`obc-unknown-phase:` named diagnostic, tested in T19's test expectations).
(b) An explicit Author Note documenting that unknown steps are intentionally silent (matching T01's CD-1 Acceptance bullet 2 fail-soft design decision), so the implementer and spec reviewer have guidance when the gap is otherwise ambiguous.

Currently the spec is silent on this path, which makes the implementer's default behavior (silent exit 0, since it falls through the "nothing to produce" branch) a fail-open for invalid input.

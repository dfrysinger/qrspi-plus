---
status: draft
---

# Research Questions

1. [codebase] How does the verifier sidecar pipeline currently work end-to-end? What file extension does `agents/qrspi-finding-verifier.md` specify for sidecar output, where on disk do sidecars land after a verifier dispatch, and how does the orchestrator currently consume verifier results — does it read sidecars from disk or parse the verifier's chat-side output? Trace the data path from verifier dispatch through to the apply-fix step.

2. [codebase] Do the per-reviewer agent files (`agents/qrspi-silent-failure-hunter.md`, `agents/qrspi-security-reviewer.md`, `agents/qrspi-code-quality-reviewer.md`) explicitly require `change_type:` in per-finding frontmatter by that name, and do they enumerate the allowed values? Compare those agent files against the 5-field schema in `skills/reviewer-protocol/SKILL.md` § Per-Finding Disk-Write Contract to identify any divergence in field names or allowed value sets.

3. [codebase] How does `skills/using-qrspi/SKILL.md` define the verifier filter rule (including the threshold values for each `change_type` tier), and how many distinct paraphrases or restatements of that rule exist in the file? Does `skills/implement/SKILL.md` contain the same threshold values — where exactly, and in what form?

4. [codebase] How does the task-tool transport branch for reviewer dispatch work in `skills/using-qrspi/SKILL.md` and `skills/implement/SKILL.md`? When a reviewer agent dispatched via the task tool returns findings inline in chat rather than writing them to disk, what does the orchestrator's documented protocol say to do? Is the task-tool transport branch documented at all, or is only the shell-pipeline transport branch covered?

5. [codebase] How does `scripts/run-codex-review.sh` wire Codex output to `scripts/codex-finding-splitter.sh`? Specifically: does the script invoke the splitter internally after awaiting Codex completion, or does the caller (orchestrator prose) own the pipe from stdout to the splitter? Trace the control flow from the `await` call to the emission of per-finding files in the `round-NN/` output directory.

6. [codebase] What schema does the `model_routing:` block in `config.md` follow, and how is that schema described in `skills/using-qrspi/SKILL.md` (around the dispatcher section) compared to the description in `skills/implement/SKILL.md` (around the G5 routing matrix section)? Which agents currently declare `model_role:` or `model:` in their frontmatter, and how many of the 41 agent files use `inherit` vs. a specific tier name?

7. [codebase] How does the validation table in `skills/using-qrspi/SKILL.md` (around L641-660) enumerate required `config.md` blocks? Are the fail-loud paragraphs at L470 and L526 (dispatcher-scoped and missing-block backfill) bidirectionally referenced from the validation table, or do they stand independently?

8. [codebase] What bats assertion forms does `tests/unit/test-using-qrspi-vocab.bats` use for the vocab pin tests covering `model_routing:`, `trusted_path:`, and `validators:` H4 anchors? Are all four pin tests written with the same assertion pattern, or do earlier pins (R2/R4-era) differ structurally from later pins (R5-era)? What helper functions are defined locally vs. shared across test files in `tests/unit/`?

9. [codebase] What shebang line does `tests/unit/test-codex-splitter.bats` use, and what shebangs do other `.bats` files under `tests/unit/` and `tests/integration/` use? Does the test suite currently produce any deprecation warnings on a clean `bats tests/` run?

10. [codebase] How does `skills/plan/SKILL.md` currently define the test expectations block for per-task specs, including any LOC ceiling guidance? Does the skill include any special handling for tasks whose scope covers many files of the same shape, or any requirement to enumerate test files that assert on properties being changed? Examine `docs/qrspi/2026-05-27-v071-hardening/tasks/task-09.md` and `task-10.md` as concrete examples of how broad-scope tasks were specced.

11. [codebase] How does `skills/design/SKILL.md` currently specify the required structure for design decisions — what per-decision sections, narrative depth, and quality dimensions are prescribed? What do the reviewer agents (`agents/qrspi-design-reviewer.md`, `agents/qrspi-design-scope-reviewer.md`) check for in design artifacts? Compare the design artifact template prose in `skills/design/SKILL.md` against actual design artifacts under `docs/qrspi/2026-05-27-v071-hardening/` to characterize typical section depth.

12. [codebase] How does `skills/implementer-protocol/SKILL.md` describe the handling of `.qrspi-commit-msg.txt` in the Commit-Before-Reporting step — specifically, does the prose reference the worktree-local `.git/info/exclude`, the committed root `.gitignore`, or both? Also inspect `agents/qrspi-test-writer.md` around line 28 for the same reference, and the root `.gitignore` to confirm which exclusion mechanisms are currently active.

13. [codebase] How does `scripts/run-codex-review.sh` currently resolve and validate paths passed to `--subject-code` and `--companion`? Specifically: does `resolve_path()` or any equivalent function enforce a repository-boundary check, and what does the script do when it receives an absolute path outside the project root? Compare with the `check_codex_available` / host-canonicalization logic already in the file (around line 165–180).

14. [codebase] How explicitly does `skills/implement/SKILL.md`'s per-task review section walk the orchestrator through scope-tagger dispatch, `round-NN.diff` emission, `round-NN-commit.txt` anchor capture, and ref-selection (step 12)? Does the per-task section inline or reference these steps, or does it rely on the reader having separately loaded the Standard Review Loop from `skills/using-qrspi/SKILL.md`?

15. [codebase] How does the Pipeline Mode Selection section of `skills/goals/SKILL.md` determine whether Codex reviews are available? What filesystem probe or function call does the skill specify, and how does that compare to `check_codex_available()` in `scripts/run-codex-review.sh` (around line 148)? Does the using-qrspi dispatch path invoke the same probe or a different one?

16. [codebase] How does `agents/qrspi-finding-verifier.md` define its scoring rubric? Does the rubric distinguish between findings where the premise is factually wrong (false positive), findings where the premise is correct but the reviewer chose not to demand action (informational/observational), and findings explicitly acknowledged in project documentation? Does the verifier include any step that checks whether content cited at a specific file and line actually exists at that location?

17. [web] What does bats-core upstream documentation and the project's changelog say about the BW02 deprecation warning and the recommended replacement shebang forms? Is the behavior where `[[ -n "$var" && "$var" =~ "pattern" ]]` silently passes when `$var` is empty documented in bats issues, the bats-core README, or related shellcheck rules?

18. [web] What has Anthropic published about subagent behavior regarding file-system writes — specifically, are there any documented cases where host-injected system prompts suppress subagent Write tool use, or any "contradiction-refusal" procedures described in model cards, safety papers, or API documentation? Separately, what does OpenAI's documentation say about how `gpt-5.5` or `gpt-5.3-codex` handle tool grants for file writes when dispatched as a subagent under a parent orchestrator?

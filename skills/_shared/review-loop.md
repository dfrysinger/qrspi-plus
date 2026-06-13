# Standard Review Loop (shared)

Single source of truth for the autonomous review loop. Every skill that runs reviewers `!cat`-resolves this snippet; the body below is the canonical contract. Self-contained: every rule the orchestrator must follow during a Review Round is here.

## Round-directory precondition

Before dispatching round-NN reviewers, the orchestrator confirms `reviews/<step>/round-<NN>/` either does not exist or is empty. If files pre-exist in that path, the orchestrator halts and reports a precondition violation (orchestrator state corruption or task-author tampering). Do not proceed to reviewer dispatch.

If the existence/emptiness check fails with an IO error (EACCES, EIO, ELOOP, or any other error that prevents determination), the orchestrator halts and emits this message to main-chat output:

```
IO error on round-directory check at <path>: <errno_or_exception_string>; cannot verify emptiness precondition. Resolve the IO condition and retry, or escalate to the user.
```

The message MUST contain the failing path and the IO error/exception string. Do NOT treat a failed check as "does not exist" and proceed. The orchestrator MUST NOT proceed to reviewer dispatch on an unverifiable precondition. The round directory is orchestrator-write-only by convention; reviewer dispatches Read it only via the dispatched subagents' Write outputs. A pre-existing round directory with content cannot be trusted as this round's output.

## Round body

A "review round" consists of:

1. **Orchestrator emits the round's diff file before dispatching reviewers.** The diff content never enters main-chat context. Reviewer dispatches carry `<diff_file_path>` as a string parameter and reviewers Read the diff file directly.

   The orchestrator picks `<ref>` per the convergence rule: rounds 1 and 2 always use `<ref>=<base-branch>`; round NN+1 uses `<ref>=HEAD~1` only when the convergence comparison fires "narrow" against round NN, and falls back to `<ref>=<base-branch>` otherwise (broaden, `scope_tagger_enabled: false`, missing scope-set, or after a backward-loop reset). When the artifact directory is not inside a git repository, skip the diff-file step — reviewers fall back to the wrapped artifact body in their dispatch prompt.

   **Fail-loud diff-emission contract (orchestrator preconditions).** The orchestrator MUST follow this exact sequence:

   1. **Precondition: each artifact path must be tracked in git.** When the redirect names one or more `<artifact_path>` arguments, run `git -C "<repo>" ls-files --error-unmatch -- "<artifact_path>"` for EACH path. Any non-zero exit means that path is untracked. Surface a one-line diagnostic (`artifact <path> is untracked — commit before reviewer dispatch`) and abort dispatch. Reviewer findings against an untracked artifact would be missing from the diff and produce a spurious clean. The Plan step is multi-path (`plan.md` + `tasks/`); each path must be checked. Skip this precondition only when the redirect covers the entire feature branch with no `<artifact_path>` argument (Integrate is the canonical example); the other preconditions still apply.
   2. **Create the per-round directory.** Run `mkdir -p "<ABS_ARTIFACT_DIR>/reviews/<step>"` before the redirect. Capture stderr separately, e.g. `2> "<ABS_ARTIFACT_DIR>/reviews/<step>/round-NN.mkdir.stderr"`. Check `$?`. Fail loud on non-zero exit: surface stderr to main chat as a single line (`mkdir exited <code>: <stderr>`) and abort dispatch.
   3. **Hard-overwrite any pre-existing target as a regular file.** Run `rm -f "<ABS_ARTIFACT_DIR>/reviews/<step>/round-NN.diff"`. This neutralises the leaf-file write-through hazard (a stale symlink at the diff-file path would otherwise have the redirect write through to its referent). Capture stderr separately. Fail loud on non-zero exit (`rm exited <code>: <stderr>`) and abort dispatch.
   4. **Emit the diff with all placeholders double-quoted.** Run `git -C "<repo>" diff "<ref>" -- "<artifact_path>" > "<ABS_ARTIFACT_DIR>/reviews/<step>/round-NN.diff"` and capture stderr separately. Quoting prevents tokenization on whitespace inside slugs or paths. Avoid `/tmp/...` for stderr — multi-tenant clobber across concurrent runs; not portable across all sandboxes.
   5. **Check `$?`. Fail loud on non-zero exit.** Surface stderr (`git diff exited <code>: <stderr>`) and abort dispatch. Do NOT proceed to reviewer dispatch on a non-zero exit (stale `<ref>`, unfetched ref, malformed `<artifact_path>` would otherwise produce a misleading empty diff).
   6. **A zero-byte diff file after a successful exit is a valid signal in steady state** (no changes vs `<ref>`). Do NOT abort on this case; reviewer dispatch proceeds normally.

2. **Claude review subagent runs → issues found are fixed.**
3. **If Codex enabled: Codex review runs → issues found are fixed.**
4. **If Codex errors during execution, report the error to the user and continue without blocking.**

## After round 1 — present-or-loop prompt

After the first review round completes and fixes are applied, ask ONCE:

> `1) Present for review  2) Loop until clean (recommended)`
>
> Before responding, consider running `/compact` — context may be saturated.

- **1 (Present):** Proceed to the human gate. State the review status: `Note: reviews found issues which were fixed but have not been re-verified in a clean round. The artifact may still have issues.` The user can still approve, but they make an informed choice.
- **2 (Loop — recommended):** Loop autonomously — review → fix → review → fix without re-prompting the user. Stop ONLY when a round finds zero issues across all reviewers (`Reviews passed clean`) or 10 rounds are reached (`Hit 10-round review cap — presenting for your review.`). Then proceed to the human gate.

**Default recommendation is always option 2.** Clean reviews before human review catch cross-reference inconsistencies that are hard to spot manually.

**Once the user selects option 2, do not re-prompt between rounds.** The point of this option is autonomous iteration. Only return to the user when the loop terminates (clean or cap).

**At the human gate, always state the review status** when presenting: either `Reviews passed clean in round N` or `Reviews found issues in round N which were fixed but not re-verified.` If the user approves but reviews have not passed clean, ask if they'd like a review loop before finalizing.

## Fix-altitude rule

When fixing an "X is under-specified" finding, prefer minimal additions that stay at the artifact's altitude. If the natural fix pulls content from the next pipeline step (Design content into Goals; Plan content into Design; Implementation choices into Plan), defer specification rather than over-specify. Add a one-line `[X] pinned in <next step>` note instead of pinning X exhaustively now. Reviewers who flag missing detail at the next-step altitude are misapplying their review brief — decline the finding with a one-line explanation in the round notes.

Why: pulling next-step detail upward inflates the artifact, introduces internal contradictions, and produces self-induced review churn. Minimal additions converge in 1–2 rounds; maximal additions can take 5+.

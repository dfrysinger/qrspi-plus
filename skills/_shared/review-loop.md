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

1. **Dispatch the round through dispatch-agent's high-level entry.** Run `scripts/dispatch-agent.sh --step <step> --round ${ROUND} --artifact-dir <ABS_ARTIFACT_DIR>` (plus the per-skill `--output-dir`/`--artifact`/`--agents` flags). High-level mode auto-invokes `scripts/review-prep.sh` to emit `<ABS_ARTIFACT_DIR>/reviews/<step>/round-NN.diff` atomically (temp+rename) and threads `diff_file_path:` into each reviewer prompt — the diff content never enters main-chat context. For round 01 pass `--base-ref <base-branch>`; on round ≥ 2 review-prep auto-narrows by reading `reviews/<step>/round-$((ROUND-1))-commit.txt` (named diagnostics `anchor-file-missing:` / `sha-format-invalid:` halt before the SHA reaches `git diff`). When the artifact directory is not inside a git repository, review-prep skips diff emission and `diff_file_path:` is omitted — reviewers fall back to the wrapped artifact body. Untracked-artifact and `narrow-round-empty-diff:` halts also fire from review-prep with named diagnostics; the orchestrator surfaces the script's non-zero exit and aborts dispatch.

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

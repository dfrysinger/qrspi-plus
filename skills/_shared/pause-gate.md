# Review-Loop Pause Gate (shared)

Single source of truth for the Review-Loop Pause Gate UI. Inside an autonomous review loop, reviewers may surface findings the orchestrating skill cannot safely auto-apply — for example, findings that would rewrite the artifact's contract, contradict an upstream artifact, or require user judgement about scope. When that happens, the loop **pauses** and presents a single consolidated UI message for that round. This is the **Review-Loop Pause Gate**. Self-contained: every rule the orchestrator must apply when the gate fires is below.

## BATCH-WITH-OVERRIDES UI contract

Each pause emits **one consolidated message per round** with three classes of findings:

1. **Auto-applied findings (silent)** — list silently with a count and a one-line summary. Example: `Auto-applied: 7 findings (typos, formatting, cross-reference repair).` Do not enumerate them; the user does not need to act.
2. **Proposed findings (batch approval)** — show as a numbered list, then ask once: `Apply all proposed findings? (y/n)`. A single `y` accepts the whole batch; `n` skips the whole batch. The user does not approve them individually.
3. **Paused findings (per-finding 3-option menu)** — list each one individually. Each paused finding gets the **3-option menu** below.

## 3-option menu (per paused finding)

For each paused finding, present:

```
1) Apply anyway — apply the finding to the current artifact and continue the loop
2) Skip finding — drop the finding, do not modify the artifact, continue the loop
3) Loop back to upstream artifact — cascade the change backward (W2/W3/W4 cascade per Backward Loops)
```

Before responding, consider running `/compact` — context may be saturated.

**Loop back to upstream artifact (W2/W3/W4 cascade).** The skill identifies the earliest affected upstream artifact based on the finding's `referenced_files` and the cascade map (W2 = Goals; W3 = Goals + Questions; W4 = Goals + Questions + Research + Design). The skill MUST display the resolved upstream target name in the menu BEFORE the user picks option 3 (e.g., `Loop back to: phasing.md`) and MUST request explicit confirmation (`Confirm rewind to {artifact}? (y/n)`) before initiating the cascade. If the finding's `referenced_files` resolves to ambiguous upstreams, the menu lists the candidates and asks the user to pick.

Option 3 then invokes the standard Backward Loops procedure: update the confirmed upstream artifact, re-review, re-approve, and cascade forward to the current step.

**Backward-loop persistent flag (load-bearing for the ref-selection step).** When option 3 cascades, the orchestrator MUST write a zero-byte sentinel `reviews/<step>/round-NN-backward-loop.flag` for the CURRENT step's round NN before the cascade completes. The next round's ref-selection step consumes the flag (and deletes it) to reset `<ref>` to `<base-branch>` regardless of the convergence-rule comparison. Without the on-disk flag, an in-memory cascade signal does not survive `/compact` and ref-selection would silently re-narrow against a stale `HEAD~1` anchor.

## Paused rounds do not decrement the cap

The 10-round review-loop cap **does not decrement on a paused round**. A round that triggers the Pause Gate is treated as user-interactive, not autonomous. When the user resolves the pause and the loop resumes, the round counter continues from the same value it had when the pause fired. The cap still terminates the loop at 10 autonomous rounds, but pauses are free.

**Infinite-pause escape hatch.** Although paused rounds do not decrement the autonomous cap, the skill MUST track total rounds (autonomous + paused) and ABORT after 20 total rounds OR after 5 consecutive pause-only rounds (whichever comes first). On hitting the escape hatch, the skill writes a final summary to `reviews/{artifact}-loop-escape-round-NN.md` listing all unresolved findings and surfaces to the user with the option to manually triage. This prevents pathological reviewers from generating an unbounded round count.

## Pending-findings file

When the Pause Gate fires, the orchestrating skill writes the round's pending findings to:

```
reviews/{artifact}-loop-pause-round-NN.md
```

For example: `reviews/design-loop-pause-round-03.md`. The file captures the auto-applied summary, the proposed batch, and the paused findings (with their 3-option resolutions once the user decides). This preserves an auditable record of every pause and how it was resolved.

**Write timing.** The skill MUST write the pending-findings file **before** presenting the BATCH-WITH-OVERRIDES UI to the user. The write is a fail-closed precondition: if the file write fails (permission, ENOSPC), the skill ABORTS and surfaces the error — it does NOT advance the round or present the UI without an audit trail on disk.

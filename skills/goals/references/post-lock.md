# Goals — After Goals Are Locked (Read on Trigger)

**Trigger:** Read this file AFTER all goals are locked in the on-disk draft and the user has signaled the dialogue is complete (no remaining open questions; Rule 9 stakeholder probe run; Final Coverage Review run). One-shot per Goals invocation. The Finalize Pass below is this file's first action — do NOT treat it as a precondition.

This file owns the post-lock review, human gate, and handoff steps.

## Finalize Pass (entry)

Before dispatching reviewers, validate the on-disk draft:

- Every locked goal carries the three required subsections (`Problem`, `Why we care`, `What we know so far`).
- Every locked goal carries a concrete `type` value (`known-fix` OR `exploratory`, never the alternation).
- Optionally append a top-level Purpose section if absent.

**Only proceed to the Review Round if all validations pass.** On failure, halt, surface the defect, and re-enter Defining Goals to fix it.

The finalize pass does NOT write `status: approved` — that flip happens only at the end of the Human Gate, after the user explicitly approves. Hand-edits to status before the gate are forbidden.

## Review Round

**Compaction checkpoint: pre-fanout.** Parallel reviewer dispatch (up to four) reads `goals.md` + the agent-embedded reviewer protocol; saturated context multiplies bloat across the parallel set. See using-qrspi `## Compaction Checkpoints`.

Surface a todo: title `Recommend /compact (pre-fanout) — goals`, description `pre-fanout: parallel reviewer dispatch (up to four) reads goals.md. User decides whether to /compact.`.

Apply the **Standard Review Loop** from `using-qrspi/SKILL.md`. Four reviewer dispatches run in parallel on Goals (two Claude + two Codex when `second_reviewer: true`; two Claude when disabled).

**Dispatch the round through dispatch-agent's high-level entry.** Run `scripts/dispatch-agent.sh --step goals --round ${ROUND} --artifact-dir <ABS_ARTIFACT_DIR>` (plus the per-skill `--output-dir`/`--artifact`/`--agents` flags below). High-level mode invokes `scripts/review-prep.sh` to emit `<ABS_ARTIFACT_DIR>/reviews/goals/round-${ROUND}.diff` and threads `diff_file_path:` into each reviewer prompt; the orchestrator runs no `git diff` Bash redirect of its own. When the artifact directory is not inside a git repository, review-prep skips diff emission and `diff_file_path:` is omitted — reviewers fall back to the wrapped artifact body. For round 01 pass `--base-ref <base-branch>`; on round >= 2 review-prep auto-narrows by reading `reviews/goals/round-$((ROUND-1))-commit.txt` (named diagnostics `anchor-file-missing:` / `sha-format-invalid:` halt before the SHA reaches `git diff`). Scope-tag narrowing (when active) reaches reviewers as `scope_hint:` wrapped between `<<<UNTRUSTED-SCOPE-HINT-START id=scope_hint>>>` / `<<<UNTRUSTED-SCOPE-HINT-END id=scope_hint>>>` markers per the reviewer-protocol Reviewer Dispatch Contract.

Set the per-skill dispatch parameters below, then include the shared reviewer-dispatch prose. Include `*-codex` peer tags in `REVIEW_AGENTS` only when `second_reviewer: true`.

```sh
REVIEW_STEP="goals"
REVIEW_ROUND="${ROUND}"                                  # current review round (NN)
REVIEW_OUTPUT_DIR="<ABS_ARTIFACT_DIR>/reviews/goals/round-${ROUND}/"
REVIEW_ARTIFACT="goals.md"
REVIEW_AGENTS="quality-claude=qrspi-goals-reviewer,scope-claude=qrspi-goals-scope-reviewer,quality-codex=qrspi-goals-reviewer,scope-codex=qrspi-goals-scope-reviewer"
```

For the full reviewer-dispatch contract (untrusted-input markers, prompt assembly, output schema, fan-in), read `skills/_shared/reviewer-dispatch-prose.md`.

## Human Gate

Present the synthesized `goals.md` to the user. **Always state the review status:** "Reviews passed clean in round N" or "Reviews found issues in round N which were fixed but not re-verified."

They can:

- **Approve** → if reviews have not passed clean, note this and ask if they'd like a review loop before finalizing. Then write `status: approved` in frontmatter.
- **Request changes** → write feedback to `feedback/goals-round-{NN}.md` (see using-qrspi Feedback File Format), then return to the main-session Defining Goals dialogue with the new feedback file(s) loaded as context. Update the affected goal blocks in `goals.md` via the same incremental-persistence path (overwrite-in-place by ID; never append duplicates). After the dialogue resolves and you re-enter After Goals Are Locked, present:

  > Feedback applied. How would you like to proceed?
  > 1. More feedback (I have additional changes)
  > 2. Single review round (run Claude + Codex once, see findings)
  > 3. Loop until clean (autonomous review cycles)
  > 4. Approve (I'm satisfied, skip reviews)
  >
  > Before responding, consider running `/compact` — context may be saturated.

  Omit option 2 if Codex is disabled in config.md. Omit the "fix issues" options (2 and 3) if there are no issues to fix.

## Terminal State

If the artifact directory is inside a git repository, commit the approved `goals.md`, `config.md`, and `reviews/goals/` (per-round per-reviewer files; see `using-qrspi` → "Commit after approval (when applicable)"). Otherwise skip — the approved frontmatter on disk is the durable record.

**Compaction checkpoint: pre-handoff.** Goals approved; the dialogue transcript and review-loop context are no longer load-bearing — the next skill reads `goals.md` on a fresh context. See using-qrspi `## Compaction Checkpoints`.

Surface a todo: title `Recommend /compact (pre-handoff) — goals`, description `pre-handoff: next skill reads goals.md on a fresh context; dialogue transcript no longer load-bearing. User decides whether to /compact.`.

**IRON RULE — REQUIRED:** Invoke the next skill in the `config.md` route after `goals` (typically `qrspi:questions`). Do NOT skip the handoff or invoke out of order. The route is locked at run start and the cross-skill transition is where downstream isolation begins (Questions must not see this conversation beyond `goals.md`).

# F02 — Resume-after-compaction diagnostic format is undefined for the "zero locked decisions" case

**Severity:** low
**Category:** Silent fallback / log-and-continue (malformed diagnostic that still appears successful)
**Files:**
- `skills/design/SKILL.md` — "Resume after compaction" block
- `skills/goals/SKILL.md` — "Resume after compaction" block

## What's wrong

Both skills pin the resume diagnostic verbatim:

> `"Resumed after compaction — last locked decision: GNN (M decisions locked, K remaining). Continuing from G(NN+1)."`

The format assumes at least one decision is already locked (`last locked decision: GNN`, `Continuing from G(NN+1)`). If `/compact` fires after the dialogue has started but before the first decision lock (a plausible window — dialogue opens with questions in Rule 1, walks Rule-3 grounding, and can easily traverse a context-heavy web search before the first per-goal block is written to disk), the resume path has no defined string to emit. The natural reading produces nonsense like:

> `"Resumed after compaction — last locked decision: G0 (0 decisions locked, K remaining). Continuing from G1."`

…which is technically wrong (G0 was never locked) but reads as a successful resume diagnostic. The user receives a confident-looking string and the dialogue proceeds as if state had been recovered, when in reality nothing was recovered and the agent is starting fresh. That is a silent-fallback failure: the diagnostic was supposed to be the loud signal that compaction happened, and instead it reads identically to a healthy resume.

Step 1 of the resume protocol ("Read the draft … and enumerate decisions already locked") also has no defined behavior when the file is absent (no decisions locked yet, no `goals.md`/`design.md` on disk) — same root cause.

## Required fix

Define the zero-locked-decisions branch explicitly. Either:

1. Add a separate verbatim diagnostic for `M == 0`, e.g.:

   > If no decisions were locked pre-compaction, emit instead: `"Resumed after compaction — no decisions locked yet. Restarting dialogue from the first question."`

2. Or specify that step 1 handles "no draft file / empty draft" by branching to a defined alternate path before reaching the diagnostic template.

## Why this matters

The whole simulated-compaction durability contract rests on the resume diagnostic being a reliable, loud signal. A diagnostic that silently emits malformed-but-plausible text in the early-compaction window violates the contract precisely in the case operators most need to detect (compaction during initial high-context grounding).

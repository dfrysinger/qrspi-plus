# F02 — Goals Iron Rule "one-sentence placeholder" contradicts presence-as-locked

**Severity:** high
**Category:** Contradictory contract / silent placeholder injection
**File:** `skills/goals/SKILL.md:146 vs :292`

Incremental Persistence at L146 forbids placeholders/TODO/to-be-filled in the draft artifact: a goal without all subsections populated "does not appear in the file." Artifact Synthesis Iron Rule at L292 instructs writing "a one-sentence honest placeholder" (e.g. "Impact not yet articulated — Design should probe…") rather than dropping the heading. Synthesis path (more proximal during synthesis) wins; placeholder content lands in goals.md, passes finalize validation (3 subsections present), propagates downstream as dialogue exhaust.

**Required fix:** Update Iron Rule to align with presence-as-locked: re-enter dialogue to obtain missing content before persisting OR explicitly scope Iron Rule to non-incremental path.

# Spec Review — Task 13 (G9), Round 1 — CLEAN

Reviewer: spec-claude (gate)
Verdict: PASS — no findings.

## Scope of review
Two changed files read from worktree disk:
- `skills/implement/SKILL.md` (+24/−7)
- `tests/unit/test-scope-tagger-dispatch.bats` (+261)

Plus the unmodified in-tree `scripts/round-prepare.sh` (verified to satisfy
every G9 round-prepare DoD item, per dispatch context — the absent edit is NOT
drift because the behavior is present at the task-12 base and newly pinned).

## Definition-of-Done verification (all satisfied)
1. `round-NN-commit.txt` written as `<SHA>\n` on happy path — round-prepare.sh
   L173–181 (`printf '%s\n'`, atomic mv).
2. Canonical `round-NN.diff` emission preserved — L360–373.
3. Distinct recovery codes: exit 10 missing-flag (L128–131), exit 11 within-round
   HEAD mismatch (L168–171), exit 12 across-rounds non-advance (L157–160).
4. Round-1 non-advance compares against task base and names it —
   `PRIOR_LABEL="task base commit"` (L155), diagnostic L158.
5. Later-round loud failure for missing/malformed prior commit anchor — L191–209.
6. Narrowing-eligible (NN≥3) + tagger-enabled loud failure for missing/empty
   prior scope-set — L214–224.
7. SKILL.md between-round checklist at per-task fan-out site (L1184–1192):
   scope-tagger dispatch, `commit_sha:` read, `dispatch-agent.sh
   --implementer-commit`, exit branches 0/10/11/12 all present.
8. Main-chat `rev-parse HEAD` comparison removed from Per-Task Convergence
   Narrowing section (L1194–1226 contains no `rev-parse HEAD`); ownership moved
   to round-prepare.sh step 1.

## Test-expectation coverage
All 8 end-to-end bats fixtures + 7 SKILL grep audits traced through the actual
script control flow; each asserts the documented exit code and diagnostic
language (not mere non-error execution):
- happy-path anchor + single trailing LF (`wc -l`)
- round-NN.diff G4 inheritance
- exit 10 (missing --implementer-commit), exit 11 (HEAD mismatch),
  exit 12 round-1 (names "task base commit", forbids "prior round anchor"),
  exit 12 later-round (prior-round-anchor language)
- missing prior commit anchor (non-zero + names round-01-commit.txt)
- missing scope-set when narrowing-eligible + tagger enabled (names
  round-02-scope-set.txt)
- scripts/ Task-tool boundary guard (subagent_type|Task(|Agent()
- SKILL grep audits for checklist heading, scope-tagger Task dispatch,
  commit_sha extraction, dispatch-agent.sh --implementer-commit, exit branches
  0/10/11/12, and zero rev-parse HEAD in the per-task section.

## Scope / over-engineering
None. No features beyond the spec; no unrequested files (the 2-file diff vs.
3 target files is the documented, verified no-op on round-prepare.sh).

## Advisory note (non-blocking)
Fixture "[T13] ... missing scope-set ..." relies on the bash prefix-assignment
`QRSPI_SCOPE_TAGGER_ENABLED=true run ...` exporting into the subprocess. This is
correct under bash (bats' runtime); if it failed to propagate the test would
FAIL (default `false` skips the gate, exit 0), not false-pass — so no masking
risk. Noted only for portability awareness.

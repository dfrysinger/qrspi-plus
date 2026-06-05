# Security Review — Task 13 (G9), Round 4 — CLEAN

Reviewer: security-claude
Round: 4 (final), correctness fan-out (spec-gate CLEAN)
Verdict: **CLEAN — no security findings. No regressions vs. round-1 CLEAN.**

## Scope reviewed

- `scripts/round-prepare.sh` (full file + round-04 diff)
- `skills/implement/SKILL.md` (between-rounds checklist + convergence prose)
- `tests/unit/test-scope-tagger-dispatch.bats` (T13/G9 cases)

## What changed this round

The round-04 diff is a single behavioral change in `round-prepare.sh`: the
per-task commit-anchor write (`round-NN-commit.txt`) was moved out of Step 1
(HEAD-correctness checks, lines 126-177) to a new block (lines 228-237)
positioned *after* the Step 10 prior-artifact presence assertions (lines
186-219). The accompanying SKILL.md prose and bats cases document/pin the
"failed verification leaves no `round-NN-commit.txt` on disk" invariant. The
remaining edits are documentation (SKILL.md ownership reattribution) and test
additions — no production-logic injection surfaces introduced.

## Per-category verification

1. **Injection.** No new sinks. The relocated anchor write uses
   `printf '%s\n' "$IMPLEMENTER_COMMIT"` into a `$$`-suffixed temp file, then
   atomic `mv`. `IMPLEMENTER_COMMIT` is validated against a leading-`-` reject
   (line 88-90) and reconciled equal to `git rev-parse HEAD` (line 168) before
   the write is ever reached, so its content is a verified 40-char SHA, not
   attacker-controlled text. Git invocations retain quoted vars and `--`
   path separators (lines 378/380). Option-shaped-ref rejection (lines 77-93)
   for `BASE_REF`/`ARTIFACT`/`TASK_BRANCH`/`IMPLEMENTER_COMMIT`/`WORKTREE`
   is unchanged and intact.

2. **Auth/authz.** N/A — local deterministic CLI primitive; no auth surface.

3. **Data exposure.** Diagnostics echo SHAs and file paths only; no secrets,
   no credentials. Unchanged from round 1.

4. **Input validation.** Round-NN integer guard (lines 96-105), python3 regex
   anchor validation (lines 194-203) unchanged. The relocation does not weaken
   any boundary check; it strengthens fail-closed behavior (no stray anchor on
   prior-artifact failure), which is a defensive improvement, not a risk.

5. **Dependencies.** None added.

6. **Cryptography.** N/A — SHAs are git identifiers, compared by string
   equality, not used as security tokens.

7. **Race conditions.** Anchor and diff/sidecar writes all use the
   `tmp.$$` + `mv` atomic pattern. The reorder does not introduce a
   TOCTOU window: Step 10 reads prior-round artifacts and the new anchor
   write targets the *current* round's file — no check-then-act on the same
   path.

## Conclusion

The round-04 change is a fail-closed hardening of file-state ordering with no
new attacker-controllable path to a dangerous sink. Round-1 security verdict
(CLEAN) holds; no regression introduced.

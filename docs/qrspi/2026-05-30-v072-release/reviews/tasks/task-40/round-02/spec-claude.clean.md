# Spec Reviewer (claude) — Task 40, Round 2 — CLEAN

Round-2 fix-cycle 1 addresses sf-F01 from round-1 (vacuous C1-enforcement
assertion that only ran when `.git/hooks/pre-commit` existed on disk).

## Verification

**Diff scope:** Only `tests/unit/test-ci-workflow-shape.bats` lines 380–395
were modified (32 LOC, single test). Matches the dispatch report.

**Fix correctness:**
- Old: conditional on `[ -f "$REPO_ROOT/.git/hooks/pre-commit" ]` → vacuous on
  clean CI checkouts (the file is not tracked, so it is absent).
- New: iterates `git ls-files | grep -E '^(scripts|\.husky|\.githooks|lefthook)'`
  and greps each tracked file for `body-guard|bats-body-assertion`. Index-based,
  so the assertion fires on a clean CI checkout.
- Load-bearing confirmed: `scripts/` is densely tracked in the worktree (14+
  files), so the loop iterates real content. No residual vacuity.
- Self-exclusion holds: the lint file (`tests/lint/...`) and the workflow-shape
  file (`tests/unit/...`) are not under the filtered roots.

**Spec alignment:** Task-40 DoD line "no shellcheck rule and no pre-commit hook
are added" and target file `tests/unit/test-ci-workflow-shape.bats` are both
respected. The renamed test name ("no tracked hook script wires body-guard or
bats-body-assertion (C1 enforcement)") accurately describes the new, broader,
and actually-enforced check.

**Scope / interpretation / coverage:** No changes outside sf-F01's surface.
No extra features, no scope creep, no other DoD lines touched.

**Target-files deviation:** None — sole edit is in a target file.

No findings.

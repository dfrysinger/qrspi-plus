---
reviewer: coverage-claude
finding_id: F03
artifact: plan.md
round: 2
severity: minor
change_type: behavioral
category: Error Conditions
task_refs: [T25]
---

## Finding

T25 (`scripts/validate-stage-commit-parents.sh`) Test expectations
cover SHA-format-invalid content inside the runtime sidecar but do
not cover the "sidecar missing or unreadable at --validate time"
failure mode. The Description says `--validate` "reads it
(validating every SHA against the well-formed git object-name shape
before any `git` invocation)" but is silent on the missing-file case.

This matters because the wrap is the load-bearing seam between
Wave Dispatch's `git merge --no-ff` step and the symbolic-only branch-map
invariant. Failure-mode coverage:

- T20a's lightweight Wave Dispatch wrap calls `--capture` pre-merge
  and `--validate` post-merge. If `--capture` silently failed to write
  the sidecar (e.g., disk-full, permission error) and `--validate`
  silently treated the missing file as "no constraints captured →
  pass," the wrap collapses into a no-op and the invariant goes
  unenforced — exactly the silent-skip class G5/G6 were designed to
  close.
- T25 also doesn't cover "`--validate` called without prior `--capture`"
  (out-of-order invocation), which is the same observable shape as
  missing-sidecar.

Compare with T19, which explicitly covers missing/malformed
`phase-base.txt` as a dispatch defect with non-zero exit.

## Tests that cannot be written deterministically

1. "`--validate` called when the runtime sidecar does not exist exits
   non-zero with diagnostic `<X>:`; no `git log` runs against the
   resulting HEAD" — not covered by any current bullet.
2. "`--validate` called when the runtime sidecar exists but is empty
   or truncated exits non-zero with diagnostic `<Y>:`" — not covered.

The Test skill cannot author either case from the current expectations.

## Recommended fix

Add Test-expectation bullets to T25 mirroring T19's
missing/malformed phase-base.txt coverage. Suggested:

> `--validate` called when the runtime sidecar at
> `reviews/implement/wave-state/<wave>.json` (or equivalent path) does
> not exist exits non-zero with the `stage-commit-sidecar-missing:`
> named diagnostic; no `git log --format='%P'` is run.

> `--validate` called when the sidecar is present but empty,
> truncated, or unparseable exits non-zero with the
> `stage-commit-sidecar-malformed:` named diagnostic.

(Diagnostic names illustrative; what matters is that the missing- and
malformed-sidecar paths are pinned with literal tokens the Test skill
can grep for.)

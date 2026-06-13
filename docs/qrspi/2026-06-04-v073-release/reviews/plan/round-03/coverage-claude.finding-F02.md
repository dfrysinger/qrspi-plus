---
reviewer: coverage-claude
finding_id: F02
artifact: plan.md
round: 3
severity: minor
change_type: behavioral
category: Error Conditions
task_refs: [T25]
---

## Finding

Round 3 added a new `sidecar-schema-mismatch:` named diagnostic and
test expectation to T25 (`scripts/validate-stage-commit-parents.sh`),
addressing part of coverage-claude F03 from round 02. The new
description and test bullet enumerate four schema-mismatch cases:

  > missing `integration_base:` field, missing `task_tips:` list,
  > malformed key/value structure, or extra unknown top-level fields

All four assume the **sidecar file exists** but has structural
defects. The two failure modes raised in round-02 F03 that remain
uncovered are:

1. `--validate` called when the runtime sidecar file does not exist
   at all (e.g., disk-full at `--capture` time silently failed to
   write the sidecar, or the sidecar path was deleted between capture
   and validate).
2. `--validate` called without any prior `--capture` invocation
   (out-of-order invocation; observably identical to "file does not
   exist").

These are distinct from schema-mismatch: a file with all four
enumerated schema defects still exists on disk and is openable.

This matters because the wrap is the load-bearing seam between Wave
Dispatch's `git merge --no-ff` step and the symbolic-only branch-map
invariant (G6). If `--capture` silently failed to write the sidecar
and `--validate` silently treated the missing file as "no constraints
captured → pass" (or as an unmatched schema-mismatch class), the wrap
collapses into a no-op and the invariant goes unenforced — exactly
the silent-skip class G5/G6 were designed to close.

Compare with the symmetric coverage T19 now carries: T19's
description distinguishes "missing" from "malformed" for both the
wave-1 sidecar and the phase-base.txt cases (separate named
diagnostics: `wave-1-sidecar-missing:` vs `wave-1-sidecar-malformed:`,
`phase-base-missing:` vs `phase-base-malformed:`). T25 has only the
malformed-shape side.

## Tests that cannot be written deterministically

1. "`--validate` called when the runtime sidecar at
   `reviews/implement/wave-state/<wave>.json` does not exist exits
   non-zero with diagnostic `<X>:`; no `git log --format='%P'` is
   run against the resulting HEAD" — not covered.
2. "`--validate` called when no prior `--capture` invocation wrote
   any sidecar in the wave-state directory exits non-zero with
   diagnostic `<Y>:`" — not covered (observably the same as #1).

The Test skill cannot author either case from the current
expectations. A reviewer auditing the wrap cannot tell whether a
silent-skip regression was caught.

## Recommended fix

Add Test-expectation bullets to T25 mirroring T19's missing/malformed
distinction. Suggested:

> `--validate` called when the runtime sidecar at the expected
> wave-state path does not exist exits non-zero with the
> `sidecar-missing:` named diagnostic — distinct from
> `sidecar-schema-mismatch:` (which assumes the file exists but has
> structural defects). No `git log --format='%P'` runs against HEAD.

> `--validate` called without any prior `--capture` invocation in the
> same wave (no sidecar present in the wave-state directory) exits
> with the same `sidecar-missing:` named diagnostic — out-of-order
> invocation is observably file-missing and produces the same
> failure direction.

(Diagnostic name illustrative; what matters is that the file-missing
and out-of-order cases are pinned with a literal token the Test skill
can grep for, and that the T25 Description names the failure direction
in spec so it isn't implementation-defined.)

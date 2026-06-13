---
finding_id: F01
reviewer: security-claude
reviewer_tag: security-claude
artifact: plan.md
round: 2
severity: medium
change_type: defect
category: input-validation
referenced_files:
  - docs/qrspi/2026-06-04-v073-release/plan.md
tasks_affected: [T03]
prior_round_references: [security-claude.finding-F01.md (round 1)]
---

# F01 — T03 review-prep.sh still missing SHA-format validation on anchor file (round-01 F01 carryover)

## Summary

Round-01 finding security-claude.F01 named **five** consumers that read git SHA
values from on-disk files and pass them directly into `git` invocations without
validating the value matches a well-formed object-name shape: T03, T13, T19,
T25, T26/T27. Round-02 closed the gap on **four** of those — T13b, T19, T25,
T26/T27 all now carry explicit `sha-format-invalid:` halt prose with object-name
shape validation (`lowercase hex, 7–64 characters`) before any `git` invocation.

**T03 (`scripts/review-prep.sh`) is the one consumer that did NOT get the
validation prose.** T03's description and Test expectations remained
unchanged in the round-02 diff for this surface; it still reads the anchor
SHA from `reviews/<step>/round-<NN-1>-commit.txt` and passes it directly to
`git diff` with no shape check.

## Where the gap is, verbatim from plan.md round-02

T03 § Description (plan.md lines ~200–208):

> Diff narrowing follows the existing per-round anchor-file convergence rule
> (G7) — the script reads `reviews/<step>/round-<NN-1>-commit.txt` rather than
> using `HEAD~1`. The script emits no files for a step with nothing to produce
> and exits 0; on corrupt artifact-dir it halts non-zero with a named
> diagnostic.

T03 § Test expectations:

> - Diff narrowing in round ≥ 2 reads `reviews/<step>/round-<NN-1>-commit.txt`
>   for the narrowing ref; a fixture proves the resulting diff matches round
>   (N-1)'s per-round commit content (traces G7 Acceptance bullet 3, sub-bullet
>   1).
> - A corrupt artifact-dir surfaces a named diagnostic and non-zero exit
>   (CD-2 Acceptance bullet 1, second half — "fail-loud on a corrupt
>   artifact-dir").

Neither passage names a SHA-format validation step or a `sha-format-invalid:`
diagnostic on malformed anchor-file content. There is no negative-direction
fixture for "anchor file contains `--exec=evil`" or "anchor file contains a
branch name like `main`".

## Asymmetry with the round-02 sibling tasks

The four other tasks identified in round-01 F01 received parallel prose. For
reference, here is the round-02 prose for T26 (the canonical SKILL surface
that does the **same** anchor-file lookup that T03 does):

> The new incantation prose names a SHA-format validation step: the SHA read
> from `reviews/<step>/round-<NN-1>-commit.txt` is validated against the
> well-formed git object-name shape (lowercase hex, 7–64 characters) BEFORE
> being passed to the `git diff` invocation; a malformed anchor file triggers
> the named `sha-format-invalid:` diagnostic and halts non-zero.

T19 (lines 449–465) carries the parallel sentence:

> Every SHA read from disk (from either the sidecar or the phase-base.txt
> file) is validated against the well-formed git object-name shape (lowercase
> hex, 7–64 characters) BEFORE being passed to any `git` invocation …

T25 (lines 599–612) carries:

> `--validate` reads it (validating every SHA against the well-formed git
> object-name shape before any `git` invocation) …

T13b (lines 381–395) carries the equivalent for SHAs parsed from the OBC
violation report.

T03 — which is the **load-bearing place** where the anchor-file `cat` actually
turns into the `git diff` invocation under high-level dispatch (the SKILL-side
T26 surface is exercised by humans following Apply-fix step 12) — has no
corresponding sentence.

## Concrete failure mode (re-stated from round 1 for completeness)

`reviews/<step>/round-<NN-1>-commit.txt` is normally written by a per-round
post-implementation step and contains a real SHA. If any upstream writer is
buggy (or the file is hand-edited or corrupted) so the content is
`--output=/tmp/exfil` or `--exec=evil`, T03 invokes:

```
git diff "--output=/tmp/exfil" -- <artifact-path>
```

Shell quoting prevents bash injection, but does NOT prevent **git
argument-injection through option-shaped values** — `--output` is a real flag
on parts of the git CLI surface, and `--exec` is a real flag on `git rev-list
--filter` and other plumbing. The minimum harm is a malformed diff that
silently produces wrong reviewer input; the worst harm crosses into
attacker-influenced file writes via option-shaped values.

T03 is the **highest-throughput** consumer of the anchor file — every review
round on every artifact step routes through it via T04a's high-level dispatch.
The defense at T26 (the SKILL surface) does not cover the T03 codepath; the
defense must live in T03 itself.

## What the plan should require

Update T03 § Description to add (mirroring the T26 sentence verbatim):

> The SHA read from `reviews/<step>/round-<NN-1>-commit.txt` is validated
> against the well-formed git object-name shape (lowercase hex, 7–64
> characters) BEFORE being passed to the `git diff` invocation; a malformed
> anchor file triggers the named `sha-format-invalid:` diagnostic and halts
> non-zero.

Update T03 § Test expectations to add:

- A fixture anchor file whose content starts with `--` (e.g. `--exec=x`,
  `--output=/tmp/x`) triggers the `sha-format-invalid:` named diagnostic and
  a non-zero exit; no `git diff` runs against the malformed value.
- A fixture anchor file containing a branch name (e.g. `main`, `HEAD~1`) or
  whitespace/newlines is rejected with the same diagnostic — only literal
  object-name shapes are accepted.
- A fixture anchor file containing a valid full-SHA (40 hex chars) and one
  containing a valid abbreviated SHA (7 hex chars) both proceed normally
  (boundary case for the `[0-9a-f]{7,64}` allowlist).

## Why this matters

The round-01 finding was accepted and four of five tasks now carry the
validation. Leaving the fifth task (the highest-traffic consumer) without the
validation breaks the symmetry the round-01 fix established. A future
implementer surveying the five sibling tasks for the validation pattern will
find one outlier and either (a) implement T03 with validation by analogy
(undocumented behavior, hard to test for) or (b) implement T03 without
validation (silent option-injection vector). The plan should not depend on
implementer charity.

## Severity

Medium — same level the original F01 was filed at; this is the
unresolved-remainder slice of that finding.

---
severity: medium
change_type: correctness
category: inappropriate-error-transformation
file: agents/qrspi-plan-reviewer.md
lines: 102-109
---

# F01 — Missing-script-file is silently reclassified as "non-structural diff content"

## What the contract now says

Round-2 reframes `structural_lint:` from an inline bash command to a repo-relative
path under `scripts/structural-lints/`. Step 2 validates the value as a **string**
(prefix `scripts/structural-lints/`, no `..`, not absolute) but does **not**
require that the named file exists, is a regular file, or is readable. Step 3
then says:

> Then run `bash <validated-path>` from the repository root with no spec-controlled
> arguments. **Interpret the result by exit code only:** if the script exits
> non-zero, emit a `severity: high, change_type: correctness` finding: the
> structural lint failed — **the claimed mechanical-only migration contains
> non-structural diff content**; the LOC/file-count exemption is denied.

(`agents/qrspi-plan-reviewer.md:109`, emphasis added.)

## The silent failure

`bash` exits non-zero for many reasons that are **not** "the diff contains
non-structural content":

- The script path is well-formed but the file does not exist (e.g., the spec
  author named `scripts/structural-lints/check-model-key-removal.sh` but never
  checked it in, or mistyped the filename). `bash` exits **127** with
  `No such file or directory`.
- The file exists but is unreadable (permissions). `bash` exits **126/127**.
- The script has a syntax error or a bug independent of the diff (e.g., `set -u`
  on an unset env var). Exits non-zero for an infrastructure reason.

Under the round-2 rule "Interpret the result by exit code only," **all of these
infrastructure failures are reported with the same diagnostic as a real
mechanical-only violation**: "the claimed mechanical-only migration contains
non-structural diff content; the LOC/file-count exemption is denied."

This is exactly the inappropriate-error-transformation pattern from the rubric
("Wrapping specific errors in generic ones … original error context lost"):
a missing-script defect (configuration / not-yet-checked-in) is masked as a
content defect (the migration is impure). The plan author will chase
non-existent non-structural diff content in their migration while the real
problem is that `scripts/structural-lints/<name>.sh` doesn't exist on disk.

The earlier (round-1) wording "command exits non-zero **or produces output
indicating non-structural diff content is present**" had the same risk for
inline commands, but inline commands at least failed in obvious ways
(`command not found` printed to stderr from the validating shell). The
named-script regime concentrates the failure mode behind a single
`bash <path>` invocation whose exit code is now the **only** signal the
reviewer is allowed to use.

## Why this is reachable in practice

The contract explicitly anticipates that the script lives in the repo as a
checked-in artifact ("a checked-in script under `scripts/structural-lints/`",
`skills/plan/SKILL.md:101`). But Plan-spec review runs against a **task spec**
that may be authored before the implementer creates the script — or against a
spec that names a typo'd filename. There is no Step-2 check of the form
"the file exists at the named path and is readable." The skill-side defect
list (`skills/plan/SKILL.md:114-120`) likewise enumerates "value is not a valid
repo-relative path" but does not list "named script does not exist on disk" as
a defect category, so the spec contract is silent on it too.

## Recommendation

In Step 2 (path validation), add an existence/readability check before Step 3
runs `bash`, and emit a distinct diagnostic when it fails. Concretely:

- After string-shape validation, verify the named path exists as a regular
  readable file relative to the repository root.
- If it does not, emit a `severity: high, change_type: correctness` finding
  with a diagnostic that names the **real** defect — "the `structural_lint`
  script `<path>` does not exist (or is not readable) at the repository root;
  check in the script or fix the path. The LOC/file-count exemption is
  denied" — and do **not** proceed to Step 3.
- Mirror the new defect in `skills/plan/SKILL.md` § Plan-spec defects so the
  contract and the reviewer rubric stay in sync (the round-2 prose already
  promises "all five conditions" — this would become a sixth, or fold into
  the existing path-validation bullet with explicit existence wording).

Optionally, distinguish exit 127/126 from other non-zero exits in Step 3 to
avoid the same conflation if the file is removed between Step 2 and Step 3
(race) or if the script `exec`s a missing helper.

## Scope note

This finding is inside the `scope_hint` surface (both touched files). No
out-of-scope findings observed in this round's diff.

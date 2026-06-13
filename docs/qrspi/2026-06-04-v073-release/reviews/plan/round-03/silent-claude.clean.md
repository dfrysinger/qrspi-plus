---
artifact: plan
round: 3
reviewer: silent-claude
status: clean
---

No silent-failure findings for round 3.

Round-03 diff was reviewed end-to-end against the four silent-failure
categories (swallowed errors, silent fallbacks, partial state on failure,
log-and-continue). All three round-02 silent-claude findings are
substantively resolved in this round, and no new silent-failure surface
was introduced.

## R02 → R03 closure verification

### R2-F01 — T03 `scripts/review-prep.sh` silent-on-no-input → CLOSED

The "emits no files and exits 0 on artifact-not-in-git-repo" silent
fallback has been replaced with a production-default fail-loud contract
plus an explicit opt-in carve-out for the fixture case.

- T03 description (diff L143) now states: "The default branch on
  'artifact-dir not in a git repo' or 'git diff produced no output when
  a diff was expected' is fail-loud: the script exits non-zero with the
  named diagnostic `review-prep-no-diff-source:` (artifact-dir not a git
  working tree) or `review-prep-empty-diff:` (git diff returned no
  output for a step that requires one). The legitimate fixture-only
  'silent empty output' shape is opt-in via an explicit
  `--allow-empty-no-diff` flag — without that flag, the production-
  default direction halts loud."
- T03 test expectations (diff L155–156) cover both fail-loud branches
  and the opt-in fixture branch.
- T04a description (diff L170) commits: "the high-level entry never
  sets `--allow-empty-no-diff` so the production-default fail-loud
  direction from T03 is the only path through review-prep in a real
  review round."
- T04a test expectations (diff L177) add a paired-coverage assertion:
  "A production-default high-level invocation against an artifact-dir
  not in a git repo halts non-zero with review-prep's
  `review-prep-no-diff-source:` named diagnostic on stderr —
  dispatch-agent does NOT silently proceed with a missing diff path."

The three semantically distinct conditions the original finding
enumerated (genuine not-in-git, review-prep never invoked, transient
git-no-output) now surface distinguishably via the two named
diagnostics on the non-opt-in path. T04a's "review-prep failure
propagates verbatim" contract now carries operational meaning that
the prior silent-zero branch had nullified.

### R2-F02 — Plan-step plan-spec-reviewer `absorption_map_path:` silent gap → CLOSED

The Plan-step is now explicitly named in the dispatch-defect contract
alongside the Design step.

- T16 description (diff L329) now states: "The plan-spec reviewer body
  gains (a) a clause asserting no plan task carries an absorbed-goal ID
  […]; a violation surfaces as a `change_type: scope` finding — and
  (b) a dispatch-defect contract clause: at the Plan step, an absent
  `absorption_map_path:` parameter is a dispatch defect; the reviewer
  halts with a `dispatch-defect:` named diagnostic and exits non-zero
  rather than silently proceeding with an empty absorbed-ID set (which
  would silently produce zero absorption findings and false-satisfy
  the G3 acceptance — silent-claude R2-F02 fail-loud direction)."
- T16 (diff L329) also pins the optional/mandatory partition:
  "The `absorption_map_path:` parameter is mandatory at exactly two
  steps — Plan and Design — and is optional only at goals/research/
  phasing/structure/parallelize steps."
- T16 test expectations (diff L333) add: "The plan-spec reviewer's
  dispatch-defect clause names absent `absorption_map_path:` at the
  Plan step as a dispatch defect […] — the plan-spec reviewer does
  not proceed with an empty absorbed-ID set."
- T17 was decomposed into T17a/T17b/T17c. T17a (diff L348, L354)
  carries the Plan-step dispatch-defect bats fixture: "A Plan-step
  plan-spec-reviewer dispatch with `absorption_map_path:` absent halts
  the reviewer with a `dispatch-defect:` named diagnostic and non-zero
  exit — the reviewer does not silently produce a zero-finding pass
  (silent-claude R2-F02 fail-loud direction)."

The G3 meta-acceptance at plan.md L149 ("zero plan-spec-reviewer
absorption findings") can no longer be silently false-satisfied by an
absent map producing a vacuous zero-finding pass — the dispatch-defect
halt strictly precedes the rubric evaluation.

### R2-F03 — T19 OBC asymmetric fail-loud across implement vs integration/test → CLOSED

The implement-phase wave-1 sidecar now carries symmetric dispatch-defect
direction with its own named diagnostics.

- T19 description (diff L401) now states: "Missing or malformed
  `phase-base.txt` (integration/test phases) is itself a dispatch
  defect — the script writes a violation entry under a distinct
  `## Dispatch defects` section of the report and exits non-zero with
  `phase-base-missing:` or `phase-base-malformed:` named diagnostics.
  Missing or malformed wave-1 sidecar (implement phase) is
  symmetrically a dispatch defect — the script writes a violation
  entry under `## Dispatch defects` with the `wave-1-sidecar-missing:`
  or `wave-1-sidecar-malformed:` named diagnostics and exits non-zero
  (silent-claude R2-F03 symmetrization direction — implement phase
  wave-1 sidecar is treated identically to integration/test
  phase-base.txt)."
- T19 test expectations (diff L412) add the symmetric coverage bullet:
  "For `--phase implement`, a missing or malformed wave-1 sidecar at
  `reviews/implement/wave-state/` writes a violation entry under
  `## Dispatch defects` with the `wave-1-sidecar-missing:` or
  `wave-1-sidecar-malformed:` named diagnostic and exits non-zero —
  symmetric with the integration/test `phase-base.txt` dispatch-defect
  direction."

The two silent-default branches the original finding enumerated
(empty-left-side `git log ..HEAD` exploding the report with full
history, and the autopilot's undefined-branch combination of clean
report + non-zero exit) are both eliminated: the script now writes an
explicit `## Dispatch defects` entry that the T20b autopilot's
documented branch keys on.

## R01-F03 carry-forward (T01 fail-soft unknown-step) — disposition recorded, not re-raised

The round-03 diff (L111) adds an explicit Author note on T01:

> silent-claude R01-F03 raised a silent-degrade concern about the
> unknown-step fail-soft branch […]. Addressing it would require a
> design.md amendment changing CD-1 Acceptance bullet 2 from fail-soft
> to fail-loud; the approved design currently mandates the fail-soft
> direction (CD-1 Acceptance bullet 2 + structure.md row 17). This
> plan honours the design contract and does not introduce a plan-side
> workaround. Re-opening the contract is a Design-phase decision,
> not a Plan-phase one.

I verified the upstream contract by reading design.md (status:
approved):

- CD-1 Acceptance bullet (design.md L25): "Unknown step name returns
  the always-appended SKILL paths + exit 0 (covered by a bats case)."
- CD-1 edge case (design.md L20): "Edge case: a step name not in the
  table (e.g. `plan` today) returns the always-appended SKILL paths
  only. The script must handle unknown step names by printing the
  always-appended set and exiting 0, not by erroring — orchestrator
  failure on an absent step would be a regression vs. today's prose
  behavior."

The plan is correctly faithful to its approved upstream design. The
silent-fallback concern remains valid in the abstract but the Plan
phase has no authority to overrule an approved design contract; the
proper escalation surface is a Design-phase review (which could be
opened as a re-plan/replan if the operator considers the design-level
disposition wrong). I do not re-raise this concern at the plan level
in round 3 — re-raising would constitute reviewer noise against an
already-acknowledged-and-dispositioned author note.

## New surfaces in round-03 — all fail-loud, none silent

I audited every new behavior added in round-03 against the four
silent-failure categories. None introduce a silent-failure shape:

- T03 SHA-format validation pre-`git` (diff L143, L153) — fail-loud
  with named `sha-format-invalid:`.
- T16 mandatory-at-Plan-and-Design partition (diff L329) — explicit
  fail-loud at both mandatory steps.
- T19 `obc-author-name-malformed:` for control-byte author records
  (diff L401, L413) — fail-loud with named diagnostic, surfaces under
  `## Dispatch defects`.
- T19 `phase-base-missing:` / `phase-base-malformed:` for
  integration/test phases (diff L401, L411) — promoted from
  un-named to explicitly-named diagnostics.
- T25 `sidecar-schema-mismatch:` (diff L424, L432) — fail-loud with
  named diagnostic, halts before any SHA read or comparison.
- T28 semver allowlist `version-source-malformed:` (diff L453, L461)
  — fail-loud with explicit allowlist regex, distinct from the
  structural `version-source-missing-or-malformed:` diagnostic.
- T37 `footprint-snippet-unresolvable:` and `footprint-snippet-cycle:`
  (diff L545, L551–552) — fail-loud with named diagnostics, replacing
  the prior un-named "named diagnostic" prose with explicit
  diagnostic-name pinning.
- T04a byte-equality paired-coverage assertion (diff L174) — tightens
  the existing equivalence check from "identical in content" to
  "byte-identical," eliminating ambiguity that could mask drift.

Every fail-soft branch that remains in the plan is either (a) the T19
"commit/workspace entries remain fail-soft because the batch gate
inspects the report" pattern — an explicit separation-of-
responsibilities where the report-consumer (T20b autopilot) is the
named failure-signal owner, not a silent swallow — or (b) the T01
unknown-step branch dispositioned above.

Clean.

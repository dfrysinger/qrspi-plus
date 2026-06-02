---
finding_id: F02
artifact: plan.md
reviewer_tag: test-coverage-claude
round: 4
severity: medium
change_type: correctness
location: "Phase 1 Acceptance Criteria bullet 2 vs Task 16 / Task 19 Test Expectations"
---

## Summary

Phase 1 AC bullet 2 commits the release to a specific fail-loud invariant:

> `_resolve-lib.sh` halt when CD-1 dispatch resolves `tier: none` against an
> unknown vendor

But no surviving task's **Test Expectations** block exercises the
"unknown vendor" branch of `_resolve-lib.sh`. T16 covers the `tier: none`
operator-opt-in branch (`extra-low: none`), and T19 covers unknown-vendor
behavior in the `second-reviewer-available.sh` *probe* — but the AC bullet
names the underlying `_resolve-lib.sh` resolver, not the probe. The bullet
will be unverifiable at phase end unless one of the tasks pins the
unknown-vendor-against-`_resolve-lib.sh` halt explicitly.

## Evidence

**Phase 1 AC bullet 2** (plan.md ### Phase 1 Acceptance Criteria, bullet 2):
> `_resolve-lib.sh` halt when CD-1 dispatch resolves `tier: none` against an
> unknown vendor

**T16 Test expectations** (plan.md ### Task 16, **Test expectations**) cover:
- `_resolve-lib.sh` precedence chain
- "Verify a dispatch resolving to a tier configured as `none` halts with a
  diagnostic naming the unresolved tier and does not fall back."
- Missing / malformed `model_routing:` via config-validation procedure
- Agent-frontmatter sweep, reviewer `DISPATCH_FILE=<path>` instruction, prose
  cleanup, `tests/unit/test-config-model-routing.bats` and
  `tests/unit/test-routing-matrix-application.bats` extensions.

No test expectation names **unknown vendor** as an input class for
`_resolve-lib.sh`. T16's DoD does mention "host/vendor routing lookup" as a
resolver responsibility, but the Test Expectations never enumerate the
unknown-vendor-against-the-matrix failure mode.

**T19 Test expectations** (plan.md ### Task 19) cover:
> Executability and behavior tests for `scripts/second-reviewer-available.sh`:
> Copilot CLI and Claude Code default paths exit 0; unknown host, missing
> default vendor, **unknown vendor**, and unavailable vendor exit non-zero
> with one `[second-reviewer-unavailable]` diagnostic containing host and
> vendor.

This is unknown-vendor coverage for the *probe*, not for `_resolve-lib.sh`
directly. The probe consumes `_resolve-lib.sh` matrix helpers, but the test
asserts the probe's `[second-reviewer-unavailable]` diagnostic shape, not
`_resolve-lib.sh`'s halt shape under direct invocation by the dispatch path.

## Why this is a Plan-altitude problem

The AC bullets enumerate the *behaviors the Test phase must verify before the
release PR opens*. The Plan tells reviewers (line 35): *"Per-task criteria
live in each `tasks/task-NN.md`'s ## Test Expectations block; the per-phase
block above captures cross-task observable behavior at phase end."* That
contract requires each AC sub-clause to either (a) be visibly covered by one
or more tasks' test expectations, or (b) carry its own seed/fixture guidance
at the AC level.

Bullet 2's "splitter on adversarial Codex stdout", "dispatch on misrouted
`model_routing` entries", "validation table on missing `model_routing:`",
"reviewer-protocol against fabricated procedural-authority outputs", and
"path-filter exfil guard in `scripts/dispatch-agent.sh`" all map to surviving
tasks' Test Expectations (T20, T16, T17, T35, T21 respectively). The
"`_resolve-lib.sh` halt … against an unknown vendor" sub-clause is the
odd one out: it names a specific component and a specific input class, but
no task's Test Expectations pin that pair.

This is precisely the "AC bullet maps to deliverables of surviving tasks"
check the dispatcher asked me to run.

## Recommended fix

Pick one of:

- **(a) Add an unknown-vendor halt assertion to T16 Test Expectations.**
  Concretely: a new bullet under T16 reading something like —
  *"Verify a dispatch resolving against a vendor absent from `model_routing:`
  halts with a `[…]` diagnostic naming the unknown vendor, and does not fall
  back to `default_tier` or a neighboring vendor's matrix row."*
  This is the most direct fix because the AC bullet names `_resolve-lib.sh`.

- **(b) Move the unknown-vendor halt assertion to T19 Test Expectations and
  rewrite the AC bullet** to say "`second-reviewer-available.sh` halt …
  against an unknown vendor" (since T19 already covers this in the probe).
  This requires updating AC bullet 2's wording to match the actual component
  under test.

- **(c) Add a seed fixture / acceptance-test pointer at the AC bullet itself**
  naming `tests/unit/test-routing-matrix-application.bats` (or similar) and
  the specific input/output the Test phase should seed. This keeps T16/T19
  unchanged but makes the AC bullet self-sufficient.

Option (a) is preferred — it keeps the resolver as the load-bearing fail-loud
seam and preserves the AC's component-level wording.

## Why this isn't suppressed by F-5

This is not a per-task happy-path-only complaint and not an
implement-altitude RED-fixture complaint. It is a **Phase 1 AC ↔ task Test
Expectations mapping gap** — the same category as round-03's F04
("Phase 1 AC stale deliverables") which was kept. F04 caught AC sub-clauses
that named dead deliverables; this finding catches a live AC sub-clause that
names a behavior no task's test plan covers. The fix is symmetric: keep the
AC and task expectations in lock-step.

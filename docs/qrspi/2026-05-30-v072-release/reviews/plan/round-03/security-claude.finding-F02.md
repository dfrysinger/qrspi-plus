---
finding_id: F02
reviewer: security-claude
round: 3
artifact: plan.md
change_type: correctness
severity: medium
task_refs: [T21]
---

# F02 — T21 companion-dispatcher audit is fail-OPEN; no regression test pins the path-input invariant

## Summary

Task 21 (G16 path-filter exfil hardening) installs a hard
`assert_path_under_repo_root` guard in `scripts/dispatch-agent.sh` for the four
known path-family flags (`--subject-code`, `--artifact-body`, `--companion`,
`--diff-file`). For `scripts/dispatch-companion.sh` — the SECOND sanctioned-channel
entry point — the task takes a different shape:

> "Audit `scripts/dispatch-companion.sh`: if it accepts raw file paths directly,
> share the same repo-boundary guard; otherwise document that it receives
> assembled prompt data rather than arbitrary file paths." (plan.md line 1256)

> DoD: "`scripts/dispatch-companion.sh` is audited for direct raw-file-path
> inputs and either shares the guard for any such inputs or documents that it
> receives assembled prompt data rather than arbitrary file paths." (line 1272)

> Test expectations: "Audit inspection confirms `scripts/dispatch-companion.sh`
> either uses the shared boundary guard for direct raw-file-path inputs or
> carries the documented no-raw-path comment." (line 1283)

This is **fail-open against future regression**:

1. If the audit's conclusion is "no raw paths today, ship a documentation
   comment," nothing in v0.7.2 enforces that the invariant **stays true** under
   future edits. A v0.7.3+ change adding a `--companion-input` or `--prompt-from`
   flag to `dispatch-companion.sh` will pass the test (the doc comment is still
   present), pass G16's existing tests (which only exercise `dispatch-agent.sh`),
   and silently re-open the exfil surface.

2. The "audit inspection" test expectation is satisfied by **finding a comment
   string** — it does not actually verify the runtime behavior. A
   string-presence test on a doc comment is a weak proxy for "no raw-file-path
   inputs are accepted" and will not catch a new flag that was added without
   updating the comment.

3. The two reviewer-relevant exfil dispatchers (`dispatch-agent.sh` and
   `dispatch-companion.sh`) end up with **two different security postures**:
   one with executable guards plus regression tests, one with at most a doc
   comment. Operators relying on the G16 invariant cannot distinguish from the
   outside which dispatcher carries which posture.

## Why this matters at plan level

The Phase 1 Acceptance Criteria block calls out "the path-filter exfil guard in
`scripts/dispatch-agent.sh`" as one of the seeded fail-loud invariants
(line 22). The same surface in `dispatch-companion.sh` is conspicuously absent
from that release-level criterion. The G16 deferral note (line 1260) accepts
that "broader all-`scripts/` sanctioned-channel exfil sweeps... [are] deferred
to v0.7.3+", but the **companion script is not one of the deferred ones** —
T21 explicitly puts it in scope and then degrades the contract into a
doc-comment check.

The implementer will read T21 as written and (rightly) conclude that emitting a
"this dispatcher receives assembled prompt data" comment satisfies the
contract. The next round of changes loses the invariant silently.

## Recommended remediation (do not require any specific wording)

Either:

- **Symmetrize.** Require `scripts/dispatch-companion.sh` to install the same
  `assert_path_under_repo_root` guard on **every** path-shaped argument it
  accepts now or in the future, with the same fail-closed semantics. The DoD
  then becomes "no raw-file-path argument is accepted without canonicalization"
  rather than "a comment is present."

- **Or pin the invariant executably.** Replace the doc-comment audit with a
  unit-test fixture that drives `dispatch-companion.sh` with every known
  argument family and asserts: either (a) the flag is rejected as unknown, or
  (b) the flag's value goes through the shared
  `assert_path_under_repo_root` guard. Future additions of path-shaped flags
  then have to extend the fixture to land, which prevents silent
  re-introduction of the exfil surface.

## Files / sections to update

- `plan.md` Task 21 → **Definition of done** bullet on `dispatch-companion.sh`
  (line 1272).
- `plan.md` Task 21 → **Test expectations** bullet on `dispatch-companion.sh`
  audit (line 1283).
- Consider adding `dispatch-companion.sh` to the Phase 1 Acceptance fail-loud
  list (line 22) so it gets release-level coverage.

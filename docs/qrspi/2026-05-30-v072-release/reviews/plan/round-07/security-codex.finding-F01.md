---
reviewer: codex
role: plan-security-reviewer
round: 7
artifact: plan.md
severity: medium
change_type: correctness
finding_id: F01
referenced_files: [docs/qrspi/2026-05-30-v072-release/plan.md]
---

# Finding F01 — AC #2 omits T39 absolute/path-traversal halt class

## Location

- `plan.md` Phase 1 AC #2, **L22**
- `plan.md` T39 DoD **L2246**, Test Expectations **L2261**

## What's wrong

Phase Acceptance Criteria #2 now includes the 4 added T39 halts, but it is
still not byte-aligned with T39's full fail-loud set: T39 explicitly
requires halting on **absolute-path attempts** and
**path-traversal/escaping attempts** as their own resolver failure class.
AC #2 only names `resolves outside repository` (symlink/outside-root
canonicalization), which does not fully cover the stricter "absolute
path attempt must fail" invariant.

## Evidence

- AC #2 list at L22 includes: `resolves outside repository`, include-cycle,
  malformed `!cat`, missing-target, `${CLAUDE_SKILL_DIR}`.
- T39 DoD L2246 and Test Expectations L2261 require failure on: malformed
  directives, missing targets, include cycles, **absolute/path-traversal
  attempts**, outside-root includes, `${CLAUDE_SKILL_DIR}`.

## Suggested fix

Extend AC #2 to explicitly include the absolute/path-traversal halt class
(matching T39 wording), so phase-level acceptance cannot pass while that
resolver guard regresses.

## Note

Round-06 sec-claude.F01 (kept via scope-bypass) explicitly said: "Absolute /
path-traversal includes and outside-root includes are subsumable under the
symlink-escape canonicalization halt — same boundary check — so I'm not
flagging those." Verifier should adjudicate whether absolute/path-traversal
is a distinct invariant requiring its own enumeration or subsumable under
the canonicalization halt.

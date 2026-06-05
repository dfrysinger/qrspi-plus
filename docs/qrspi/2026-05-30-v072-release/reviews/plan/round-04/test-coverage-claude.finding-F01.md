---
finding_id: F01
artifact: plan.md
reviewer_tag: test-coverage-claude
round: 4
severity: medium
change_type: clarity
location: "Task 38 — Test expectations bullet 5 (Mental-replay check)"
---

## Summary

T38's fifth Test Expectations bullet is a "Mental-replay check" that asserts a
hypothetical `structure.md` would not trigger a Structure scope finding under
the updated reviewer prompts. Combined with T38's Scope-Out clause —
*"Adding lint tests or test-code files — existing task text explicitly keeps
this reviewer-prompt task to prompt-prose surfaces"* — the expectation cannot
be operationalized into a deterministic acceptance test.

## Why this is a Plan-altitude problem

The Test skill consumes each task's Test Expectations to generate acceptance
tests. The other four bullets in T38 are grep/inspection audits that the Test
skill can mechanically translate into bats fixtures. The mental-replay bullet,
by contrast, describes an LLM-judgment outcome ("would not trigger a Structure
scope finding") without naming a fixture file, an agent-invocation harness, or
an assertion target. Two failure modes follow:

1. **Test skill cannot write a deterministic test.** The only way to verify the
   bullet is to dispatch `qrspi-structure-scope-reviewer` against a real
   fixture `structure.md` and assert zero findings — but that *is* a test-code
   file, which T38's Scope-Out forbids.
2. **No falsification path.** Because no fixture or harness is named, any
   future implementation that quietly weakens the reviewer prose could still
   "pass" mental-replay through reviewer charity. The bullet has no
   `expected = actual` shape.

The first four bullets already operationalize the same intent:
"Inspect for positive obligations that treat `unified system architecture` and
`## Test Architecture` as expected Structure content; confirm stale pre-G35
anomaly/drift framing is absent." The mental-replay bullet is redundant once
those greps land — or, if it is intended to add behavioral coverage beyond the
greps, the prose-only scope clause and the bullet contradict each other.

## Recommended fix

Pick one of:

- **(a) Demote the mental-replay sentence** from Test Expectations to a Why /
  Definition-of-Done rationale paragraph (it already documents the intent that
  the four grep assertions enforce). Test Expectations should contain only
  bullets the Test skill can mechanize.
- **(b) Lift T38's Scope-Out** for one minimal fixture + one bats test that
  dispatches `qrspi-structure-scope-reviewer` against a fixture `structure.md`
  containing the Mermaid + `## Test Architecture` content and asserts zero
  scope findings. Then keep the mental-replay bullet but anchor it to that
  fixture/test by path.
- **(c) Replace** the mental-replay bullet with an explicit grep assertion
  pair: (i) presence of the new "expected content" prose anchors in
  `agents/qrspi-structure-reviewer.md`; (ii) absence of the old anomaly/drift
  trigger prose. Both are already implied by bullets 1 and 3 — make them
  explicit and drop mental-replay.

Either (a) or (c) preserves the prose-only scope; (b) trades that scope for
real behavioral coverage. The current state is the worst of both worlds: a
Test Expectation that nothing can write.

## Why this isn't suppressed by F-5

This is not a per-task happy-path-only complaint, not a missing-RED-fixture
complaint, and not a request to specify implementation detail. It is a
**Plan-altitude verifiability** complaint: the Test Expectations block contains
a bullet the Test skill cannot translate into any test (deterministic or
otherwise) given the task's own Scope-Out constraint. That is exactly the
"vague/unfalsifiable test expectation" pattern the reviewer's category 4
(Test Expectation Quality) is meant to catch.

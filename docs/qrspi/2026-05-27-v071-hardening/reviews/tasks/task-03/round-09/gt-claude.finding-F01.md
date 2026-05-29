---
reviewer: gt-claude
round: 9
task: task-03
finding_id: F01
change_type: correctness
severity: medium
file: tests/unit/test-helpers-skill-markdown.bats
---

# F01 — Whitespace-only test does not assert error-path identity

## Traceability anchor

**Goal:** G3 — Reusable fence-tracking helper migrated into shared skill-markdown library  
**Task spec expectation (task-03.md line ~23):**
> A region containing only whitespace (blank lines, spaces, tabs) between anchor heading and next heading triggers the 'no content found' error path (treated as empty).

## Finding

The test `[fence-aware-extractor] whitespace-only region between anchor and next heading triggers no-content error path` asserts:

```bash
[ "$status" -ne 0 ]
[[ "$output" == *"extract_section_fence_aware:"* ]]
[[ "$output" == *"### Target Section"* ]]
```

It does **not** assert `[[ "$output" != *"not found"* ]]`.

The task spec specifically says the whitespace-only region must trigger the **empty-region** path, not the missing-anchor path. The missing-anchor path emits `"not found"` in the message body; the empty-region path does not. Without the negative assertion, a regression in `has_content` detection that causes the implementation to emit the missing-anchor message would leave this test **silently passing** with the wrong error path.

## Spec-to-test chain gap

```
G3
  → plan.md Phase 1 Criterion 7 (unit coverage pins helper behavior)
    → task-03.md "whitespace-only region triggers 'no content found' error path"
      → test "[fence-aware-extractor] whitespace-only region…"
          ASSERTS: non-zero exit + correct prefix + anchor text
          MISSING: [[ "$output" != *"not found"* ]]  ← error-path identity
```

## Broader context

The distinguishability contract IS tested by `[fence-aware-extractor] missing-anchor and empty-region error messages are distinguishable by message body`, so the overall behavior is correct and tested. However, the whitespace-specific spec bullet makes a claim about *which* path is taken, and that claim is not directly asserted in the whitespace test. If `has_content` detection ever regressed for whitespace-only input, the whitespace test would not catch it.

## Suggested fix

Add one assertion to the whitespace test:

```bash
# Empty-region path — must NOT say "not found" (anchor was located).
[[ "$output" != *"not found"* ]]
```

This makes the test directly verifiable against the spec bullet without relying on indirect coverage from the distinguishability test.

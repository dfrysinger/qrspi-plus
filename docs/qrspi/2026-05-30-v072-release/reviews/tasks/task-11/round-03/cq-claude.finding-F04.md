---
finding_id: R3-F04
reviewer: cq-claude
severity: med
change_type: correctness
referenced_files:
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats
---

# F04 — AC9 dropped `(keys | length == 4)` exact-shape guard; test name + comment now lie about what's checked

**Novel finding.** AC9 was previously a defense-in-depth security pin asserting manifest entries have EXACTLY 4 keys `{tag, host, vendor, model}`, no extra/injected keys. T11 diff removed `(keys | length == 4)` and replaced with `has("tag") and has("agent") and has("mode") ... and has("split_cmd")` (8 keys present-only). NO `(keys | length == 8)` count guard added.

**Three compound problems:**

1. **Defense-in-depth regressed.** The test name says "with exactly tag/host/vendor/model keys (no extra/injected keys)." The section comment explains this is "injection-prevention." That property is no longer verified — a manifest entry with 9 or 10 keys (e.g., an injected `"is_admin": true`) would pass the test.

2. **Misleading test name.** Reader sees `"with exactly tag/host/vendor/model keys"` and will not notice the field list changed silently to 8 different fields.

3. **Self-refuting comment.** Section comment's security rationale ("structural-shape assertion would still trip on key-count drift") contradicts the impl — assertion was updated to not check key count.

**Fix:** (a) update `@test` name + section comment to describe current schema (8 contracted T11 keys + dispatch_spec subshape). (b) Restore a `(keys | length == 8)` outer count guard + equivalent guard on dispatch_spec's 4 fields, OR explicitly state in the comment that count-pin was deliberately dropped and document the new injection threat model.

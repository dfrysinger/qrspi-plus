---
finding_id: R4-F03
severity: low
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L1082-L1091, docs/qrspi/2026-05-17-v07-release/plan.md:L1119-L1122]
artifact: plan
round: 4
reviewer: test-coverage-claude
---

T35 anchor-refresh script and T36 `test-section-anchor-narrow-read.bats` do not exercise a heading nesting scenario where the H2 section span includes nested H3 sub-headings.

T35's test expectations (line 1082–1087) define `line_end` as "the line before the next same-or-higher-level heading" but do not include a test fixture exercising what happens with H3 headings nested under an H2. Specifically, T36's `test-section-anchor-narrow-read.bats` (line 1119) exercises "one near the start... one from the middle... one at the FINAL section" but none of the three required sample headings is specifically an H2 whose span contains nested H3 sub-headings.

The correct behavior is: an H2's `line_end` should be the line before the NEXT H2 (same-level), spanning across any intervening H3 headings (which are lower-level, not same-or-higher). This is the standard reading of "same-or-higher-level heading" but could be implemented incorrectly as "any heading" — a bug that would truncate the H2 section at its first H3 child.

Since `reviewer-protocol/SKILL.md`, `using-qrspi/SKILL.md`, and `plan/SKILL.md` all have nested H3s under H2s (they are large, deeply structured skill files), the actual production index files in T34 will contain mixed-depth sections. The narrow-read pin should exercise at least one H2 whose slice spans multiple H3 sub-headings to confirm the nesting boundary is computed correctly.

Fix: Add to T36's `test-section-anchor-narrow-read.bats` test expectations: "For at least one indexed artifact, the pin exercises an H2 heading whose indexed `{line_start, line_end}` span includes at least one nested H3 sub-heading, and asserts the returned slice (via `Read(offset, limit)`) is byte-identical to the full H2 section including its H3 children — confirming that `line_end` is bounded by the NEXT same-or-higher-level heading (another H2 or the file end), not by the first H3."

---
finding_id: R2-F01
severity: low
change_type: style
referenced_files: ["tests/unit/test-change-type-partition.bats:60-61"]
artifact: code
round: 2
reviewer: code-quality-claude
---

**QRSPI-internal task ID (`T05`) leaked into code comments inside a test file (two occurrences).**

The new orient-comment block added at L58-68 mentions `T05` twice:

```bash
# _test_mirror_partition_finding — test-local mirror of the schema-guard
# contract documented in skills/reviewer-protocol/SKILL.md ## Finding Schema.
# The production schema guard that enforces this contract is added in T05
# (scripts/verifier-fan-in.sh); until T05 lands, these tests pin only the
# contract shape, not its enforcement in production routing.
```

Per the ID-hygiene rule in the code-quality rubric (§11): QRSPI-internal IDs matching `\b[GRDFTQ]-?[0-9]+[A-Za-z]?\b` are *forbidden in code comments*, test names, describe/it blocks, and fixture names — "flag every occurrence outside `docs/qrspi/`, regardless of how scoped the comment is." `T05` matches that pattern (`T` + digits). The file is `tests/unit/test-change-type-partition.bats`, which is outside `docs/qrspi/`.

**Context (does not change the verdict, but worth noting for triage):** The R1 finding sf-claude R1-F01 explicitly prescribed wording that included `"...added in T05"`, and the implementer applied it literally. The R1 reviewer's prescription violated the rule the R2 reviewer enforces; the fix here is on the *current* surface, not retroactive blame.

**Why the rule matters even when the cross-reference is scoped:** Run-specific task tokens get stale (T05 may be renumbered, merged, or split before this comment is next read), and the surrounding text already conveys all the load-bearing meaning — the script path `scripts/verifier-fan-in.sh` is the durable referent. The `T05` token adds no signal a future reader of test code can use.

**Fix (minimal):** Drop the two `T05` tokens; lean on the already-present script reference and the contract-boundary phrasing.

```bash
# _test_mirror_partition_finding — test-local mirror of the schema-guard
# contract documented in skills/reviewer-protocol/SKILL.md ## Finding Schema.
# The production schema guard that enforces this contract lives in
# scripts/verifier-fan-in.sh (added in the dependent verifier-fan-in
# hardening task); until that script lands, these tests pin only the
# contract shape, not its enforcement in production routing.
```

Severity is `low` because there is no behavioral or correctness impact — the comment is purely orientational and the violation is a documentation-hygiene leak, not a defect in what the test exercises.

---
finding_id: R2-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/structure.md:L475-L476]
artifact: structure
round: 2
reviewer: quality-claude
---

The `G14Consumers` node in the Mermaid architectural diagram (lines 475-476) lists six BATS test files that consume `tests/helpers/skill-markdown.bash`, but omits `tests/unit/test-test-writer-dual-mode.bats`, which the file map (Slice 2, line 45) explicitly tags as `G6, G14` and annotates "Uses `skill-markdown.bash`."

The current G14Consumers node reads:

```
G14Consumers["tests/unit/test-parallelize-owns-defers.bats\ntests/unit/test-parallelize-vocab.bats\ntests/unit/test-replan-boundary-with-goals.bats\ntests/unit/test-ui-task-fields.bats\ntests/unit/test-wave-context-shape.bats\ntests/unit/test-quick-tier-wording.bats"]
```

`tests/unit/test-test-writer-dual-mode.bats` should appear in this list. Its omission makes the diagram an inaccurate representation of the G14 dependency graph — a reader trying to trace which test files consume the shared helper would miss this consumer and undercount the surface guarded by the helper's own self-tests.

Fix: add `tests/unit/test-test-writer-dual-mode.bats` to the `G14Consumers` node label alongside the six already listed.

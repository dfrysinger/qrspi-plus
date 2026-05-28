---
finding_id: R8-F01
severity: low
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/structure.md:L485]
artifact: structure
round: 8
reviewer: quality-claude
---

The R7-F01 fix was applied to the file map (structure.md line 90 now correctly lists `test-wave-context-shape.bats` with goal `G11` only, without the G14 tag), but the architectural diagram's G14Consumers node at line 485 was not updated. The node still lists `tests/unit/test-wave-context-shape.bats` as one of the G14 helper consumers:

```
G14Consumers["tests/unit/test-parallelize-owns-defers.bats\ntests/unit/test-parallelize-vocab.bats\ntests/unit/test-quick-tier-wording.bats\ntests/unit/test-replan-boundary-with-goals.bats\ntests/unit/test-test-writer-dual-mode.bats\ntests/unit/test-ui-task-fields.bats\ntests/unit/test-wave-context-shape.bats"]
```

The file map and the diagram are now inconsistent: the file map correctly removes the G14 tag from `test-wave-context-shape.bats`, but the diagram still depicts that test as a `skill-markdown.bash` consumer. The fix is to remove `\ntests/unit/test-wave-context-shape.bats` from the G14Consumers node string on line 485, leaving the remaining six tests in the list.

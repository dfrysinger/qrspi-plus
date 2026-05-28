---
finding_id: R9-F01
severity: low
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/structure.md:L44-L46, docs/qrspi/2026-05-17-v07-release/structure.md:L484-L486]
artifact: structure
round: 9
reviewer: quality-claude
---

The architectural diagram's `G14Consumers` node (line 485) lists six `skill-markdown.bash` consumers but omits `tests/unit/test-helpers-skill-markdown.bats`, which the file map (line 45) explicitly identifies as "first consumer of the helper itself."

The file map entry reads:

> Helper-self tests: happy path, empty-extract, missing-anchor, end-of-file boundary, diagnostic content; **first consumer of the helper itself** (validates helper alongside Slice 2 use).

Because the helper self-test sources `skill-markdown.bash` just like the other six tests in the node, it belongs in the `G14Consumers` node. The diagram comment on line 484 says "BATS test files in Slices 2, 4, 5, 10" — `test-helpers-skill-markdown.bats` is in Slice 2 and is a direct consumer of the helper, so its omission contradicts both the comment and the file map.

The fix is to add `\ntests/unit/test-helpers-skill-markdown.bats` to the G14Consumers node string on line 485, making the node list seven entries:

```
G14Consumers["tests/unit/test-helpers-skill-markdown.bats\ntests/unit/test-parallelize-owns-defers.bats\ntests/unit/test-parallelize-vocab.bats\ntests/unit/test-quick-tier-wording.bats\ntests/unit/test-replan-boundary-with-goals.bats\ntests/unit/test-test-writer-dual-mode.bats\ntests/unit/test-ui-task-fields.bats"]
```

(Order is not load-bearing; prepending the Slice 2 self-test groups it logically near its slice origin.)

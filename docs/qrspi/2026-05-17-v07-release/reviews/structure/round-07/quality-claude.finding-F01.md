---
finding_id: R7-F01
severity: low
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/structure.md:L90-L91, docs/qrspi/2026-05-17-v07-release/design.md:L619-L622]
artifact: structure
round: 7
reviewer: quality-claude
---

`tests/unit/test-wave-context-shape.bats` is tagged with goal IDs `G11, G14` in the Slice 5 file map (structure.md line 90-91). However, the test's stated responsibility is: "`wave_context:` payload contains wave identifier + per-task entries (task ID, task name, `allowed_files` glob, sibling findings) wrapped between `<<<UNTRUSTED-ARTIFACT-START id=wave_context>>>` / `<<<UNTRUSTED-ARTIFACT-END id=wave_context>>>` markers." This is a plain-text wrapping-marker assertion — it verifies a runtime-assembled JSON/markdown payload's structure and its `UNTRUSTED-ARTIFACT` fence markers. It does not perform skill-markdown section extraction or use the `extract_section` / `assert_section_contains` functions from `tests/helpers/skill-markdown.bash`.

The G14 tag implies this test consumes the shared BATS helper. That claim is load-bearing in two ways: (1) the scope-tagger and parallelize-reviewer use G14 consumption to reason about which tests depend on the helper being present; (2) design Decision 7 gives the canonical G14 dependent set as {G8, G9, G11, G15}, and G11 is included because the Slice 5 tests are expected to use the helper — but `test-wave-context-shape.bats` is the test that does not fit that expectation. Design line 619-622 describes the wave-context test as checking: "(a) the parameter exists on the dispatch and (b) its body contains the required content sections" wrapped in the markers — none of which requires `extract_section` or heading-scoped search.

The fix is to drop `G14` from the goal-IDs column of `test-wave-context-shape.bats` and update the diagram's G14Consumers node (structure.md line 483) to remove this test file from the list. If the test does in fact use `skill-markdown.bash` (for example, to extract a section of an output file to assert content shape), the responsibility description should be updated to say so explicitly so the G14 link is justified.

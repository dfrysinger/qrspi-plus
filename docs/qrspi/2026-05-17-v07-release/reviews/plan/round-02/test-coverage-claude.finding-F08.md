---
finding_id: R2-F08
severity: low
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L1090-L1098]
artifact: plan
round: 2
reviewer: test-coverage-claude
---

T36's `test-cache-hit-rate.bats` test expectation is path-conditional — it reads the T33 spike report to choose between Path A and Path B fixture sets. The test expectations specify both paths well. However, the test expectations for `test-section-anchor-narrow-read.bats` at T36 state "for each indexed artifact, selects one indexed heading" — the word "one" leaves the test count underdetermined. If the implementer exercises only one heading per artifact (the minimum) the test is technically satisfied but provides weak coverage.

The design.md § G4 test strategy requires "verify that agents using the section-anchor index Read only the expected line ranges and that the assembled content is byte-identical to the corresponding source slice." A single sample heading per artifact is sufficient to demonstrate byte-identity for that heading but does not establish coverage for headings at the beginning, middle, and end of each artifact (boundary conditions matter for line-range arithmetic — an off-by-one in the `line_end` computation could cause a heading at the last H2 to return one extra line from the next artifact boundary).

Add specificity to the T36 `test-section-anchor-narrow-read.bats` expectation: it should assert byte-identity for at least three sample headings per artifact — one near the start (small `line_start`), one from the middle of the artifact, and one at the final section (where `line_end` equals the artifact's last line, not the line before the next heading). Alternatively, specify that the test exercises the final-section boundary case explicitly (the section whose `line_end` was computed as the last line of the source, not as the line before the next same-or-higher heading), since this is the boundary condition the T35 description calls out as a special case ("where the range ends at the last line of the source for the final section").

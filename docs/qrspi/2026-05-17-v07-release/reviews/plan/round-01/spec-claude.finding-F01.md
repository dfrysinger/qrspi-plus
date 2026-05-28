---
finding_id: R1-F01
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:291]
artifact: plan
round: 1
reviewer: spec-claude
---

Task 07's frontmatter carries `loc_estimate: 0` (plan.md line 291), but the task body describes authoring five distinct BATS test files: `test-run-third-party-llm.bats`, `test-config-model-routing.bats`, `test-citation-density-validator.bats`, `test-routing-matrix-application.bats`, and `test-g5-telemetry-emission.bats`. The description for each file runs to several sentences and pins multiple behavioral cases. Other comparable test-only tasks in this plan carry explicit LOC estimates: T13 at ~220, T17 at ~140, T18 at ~150, T32 at ~150, and T36 at ~200.

`loc_estimate: 0` is factually wrong — it cannot mean "zero lines of code" for a task that creates five BATS test files. The convention used elsewhere for unmetered test LOC is to write `loc_estimate: <N>` in frontmatter (since there is no zero-LOC task with real output) or to write `test files (unmetered)` in the body. T07 uses neither convention correctly.

The consequence is that the plan's sizing budget is understated for Slice 1, and an implementer reading T07's frontmatter cannot trust the LOC estimate field. The apply-fix LOC-budget rule that flags tasks above 200 LOC cannot fire on a 0 estimate even if the actual test file set exceeds the threshold.

**Fix:** Replace `loc_estimate: 0` with the correct estimate for five BATS files. Based on the description detail (each file pins multiple cases across multiple fixture shapes), an estimate in the range of ~200 is consistent with comparable test-bundle tasks in this plan. If the plan intends these test files to be unmetered, document that convention in the body (as T30 does) and use a non-zero frontmatter placeholder, or use the `sizing_exception: reusable primitives` exception with the rationale that five co-shipped pins are one primitive — but either way, 0 is wrong and must be corrected to a defensible value.

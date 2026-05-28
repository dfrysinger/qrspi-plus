---
finding_id: R2-F07
reviewer: test-coverage-claude
score: 65
verdict: drop
---

T31 task_type is `lightweight`. Cross-reference to T32 is reasonable, but T32 already declares the BATS pin and shares dependencies. Per round-2 calibration, drop for lightweight task without specific behavioral test that's appropriate. T32 pin already locks the behavior end-to-end across both files.

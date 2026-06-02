---
reviewer_tag: silent-failure-codex
change_type: correctness
severity: medium
artifact: plan.md
location: Task 11 — Definition of done + Test expectations for .dispatch-manifest.json provenance
referenced_files: [plan.md]
---

# F02 — Dispatch-manifest provenance lacks explicit fail-loud contract for missing/malformed required fields

Task 11 requires provenance fields to be present and says the manifest should remain well-formed (`plan.md` lines 707–717), but it does not specify fail-loud behavior when required `dispatch_spec` fields are missing/malformed at write/read time, nor does it require a negative test that seeds malformed/missing provenance and asserts halt.  
Given this manifest is the audit surface used to detect missed/mis-routed dispatches, permitting parse/shape drift without an explicit abort path can silently degrade detection (i.e., skip expected-tag integrity checks rather than fail fast).  
As written, the task is mostly positive-path validation and can pass while still allowing log-and-continue behavior on provenance corruption.

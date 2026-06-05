---
reviewer_tag: test-coverage-codex
change_type: correctness
severity: high
artifact: plan.md
location: Task 11 → Test expectations
referenced_files: [plan.md]
---

# F01 — Task 11 coverage only checks happy-path presence, not fail-loud/schema-strict behavior

Task 11's Test Expectations (bullets under "### Task 11") verify that `dispatch_spec` fields are present and that manifest JSON remains well-formed, but they do not require tests that fail when a required provenance field is missing, nor tests that reject malformed field values/types.  
Given this task is defining manifest schema contract (`dispatch_spec.subagent_type/host/vendor/model/prompt_file`), absence of negative-path expectations leaves a coverage hole where regressions can pass by emitting partial or malformed `dispatch_spec` objects without detection.

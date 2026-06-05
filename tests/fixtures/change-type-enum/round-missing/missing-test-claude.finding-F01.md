---
finding_id: R1-F01
severity: medium
referenced_files: ["foo.md:L10-L12"]
artifact: foo
round: 1
reviewer: missing-test-claude
---

Reviewer omitted the required change_type field entirely. The fan-in script
must halt with cause `missing_change_type` (T04's distinct schema failure),
NOT `change_type_out_of_enum`.

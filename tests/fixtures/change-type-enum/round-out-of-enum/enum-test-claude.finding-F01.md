---
finding_id: R1-F01
severity: medium
change_type: madeup-value
referenced_files: ["foo.md:L10-L12"]
artifact: foo
round: 1
reviewer: enum-test-claude
---

Reviewer emitted an out-of-enum change_type value (`madeup-value`). The fan-in
script must halt loudly with cause `change_type_out_of_enum` rather than silently
default-keep, silently keep, or silently drop the finding.

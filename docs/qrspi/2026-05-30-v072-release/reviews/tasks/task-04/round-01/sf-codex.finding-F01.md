---
finding_id: R1-F01
severity: medium
change_type: correctness
referenced_files: ["tests/unit/test-change-type-partition.bats:62-71"]
artifact: code
round: 1
reviewer: silent-failure-codex
---

**`_partition_finding` reads `change_type:` from body text, not frontmatter only.**

The awk in `_partition_finding` (`awk -F': *' '/^change_type:/ {print $2; exit}' "$f"`) scans the entire file. A malformed finding missing frontmatter `change_type:` but containing `change_type:` in body prose would falsely route — masking exactly the failure mode the test claims to detect.

**Fix:** Restrict parsing to the frontmatter block (between the first two `---` markers) before grepping `^change_type:`.

Materialized from chat-only Codex output.

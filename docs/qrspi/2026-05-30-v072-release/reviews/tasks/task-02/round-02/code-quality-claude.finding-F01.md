---
finding_id: R2-F01
reviewer_tag: code-quality-claude
severity: medium
change_type: correctness
referenced_files:
  - scripts/verifier-fan-in.sh
---

**F01 — Halt-cause naming mismatch for unreadable finding files.**

`scripts/verifier-fan-in.sh` line 201 records `missing_change_type` as the halt cause when a finding file is unreadable. `missing_change_type` is documented as "frontmatter omits `change_type:`" — a completely different failure mode. Audit-JSON consumers will misdirect their debugging toward frontmatter authoring instead of filesystem permissions. The companion test (fix F05) asserts only the stderr message, so the semantic mismatch in the JSON is untested.

**Recommendation:** introduce a new halt cause `io_error` (or `unreadable_finding_file`), record it in the audit JSON, and add a test asserting the JSON's `halt_cause` matches the new cause for chmod-000 fixtures.

---
finding_id: R2-F02
reviewer_tag: silent-failure-claude
round: 2
task: 02
severity: low
change_type: correctness
referenced_files:
  - scripts/verifier-fan-in.sh
  - tests/unit/test-verifier-fan-in-script.bats
---

## F02 — Unreadable finding file records `missing_change_type` in audit JSON; halt cause misattributes I/O error

`scripts/verifier-fan-in.sh` lines 198–203; test line 363–365.

The R1 codex-F01 fix correctly emits `"cannot read finding file: ..."` to stderr. However, it records `missing_change_type` as the audit JSON halt cause — a cause whose documented meaning is "finding frontmatter omits `change_type:`". An I/O failure is a distinct root cause; the file may contain a valid `change_type:` field that was never readable.

An operator querying `.verifier-fan-in-audit.json` sees `missing_change_type` and investigates frontmatter omissions rather than file permissions, wasting diagnostic time.

The fix F05 bats test (lines 354–365) only asserts `"cannot read"` appears on stderr; it does not assert the JSON halt cause, so the misattribution is undetected by the test suite.

(Note: overlaps with cq-claude R2-F01 — same defect class, addressable jointly.)

Fix options (either):
1. Add `finding_unreadable` / `sidecar_unreadable` to the halt-cause taxonomy and update `record_halt` call sites. Update tests to assert JSON cause.
2. Document in the header that `missing_change_type` covers I/O failures; strengthen tests to assert `.halts[0].cause == "missing_change_type"` explicitly.

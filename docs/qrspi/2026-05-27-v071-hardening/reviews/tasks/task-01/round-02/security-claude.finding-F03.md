---
reviewer: security-claude
task: 1
round: 2
finding: F03
severity: low
change_type: correctness
status: pending
model: claude-sonnet-4.6
persistence_note: Claude returned findings inline. Orchestrator manually persisted.
referenced_files:
  - scripts/run-third-party-llm.sh
---

## `_control_char_check` Flags Non-ASCII Bytes (0x80–0xFF) Outside Spec Scope

**Category:** Input Validation — Over-strict rejection
**Line:** 221

**Description:** The `tr` invocation deletes only printable-ASCII bytes (0x20–0x7E):
```bash
| LC_ALL=C tr -d '\040-\176' \
```

Bytes in the range 0x80–0xFF (UTF-8 continuation bytes, Latin-1 extended characters, C1 control characters) are **outside** the deleted range. They survive deletion and are counted as "control characters", causing `die` for header values containing any non-ASCII byte.

Task spec explicitly documents: *"Covered byte ranges: C0 (0x00–0x1F) and DEL (0x7F)."* 0x80–0xFF are not in scope.

**Attack scenario:** Denial-of-service via false positive — a legitimate `default_header` value containing UTF-8 bytes causes spurious abort. Not an injection bypass (over-rejection is safe direction).

**Mitigation:** Add 0x80–0xFF to deleted range:
```bash
| LC_ALL=C tr -d '\040-\176\200-\377' \
```

**T1 scope assessment:** IN SCOPE for T1 — this is a spec-deviation in T1's own added code. The spec said "C0 + DEL"; the implementation rejects "C0 + DEL + 0x80-0xFF". Fix to match spec.

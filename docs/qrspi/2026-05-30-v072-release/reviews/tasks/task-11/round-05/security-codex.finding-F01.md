---
finding_id: R5-SEC-F01
reviewer: security-codex
severity: med
change_type: correctness
referenced_files:
  - scripts/run-codex-review.sh
at_cap: false
escalate: false
duplicate_of: R5-SF-F01
---

# F01 — Manifest-write failure can be silently ignored (audit bypass)

**Introduced by R5 FIX-B (mktemp tmp path).**

## Location

`scripts/run-codex-review.sh:307-313, 399-422, 921-923, 991-993`

## Attack scenario

An attacker who can influence runtime conditions (for example, filling the `OUTPUT_DIR` filesystem so `mktemp "${manifest}.tmp.XXXXXX"` fails) triggers the `_append_manifest_entry` mktemp-failure path, which does `return 1` instead of exiting (`307-313`). That nonzero return is not enforced by callers: first-party path still does `emit_first_party_manifest_entry ...; exit 0` (`921-923`), and third-party success path similarly does `emit_dispatch_manifest_entry ...; exit 0` (`991-993`).

Result: dispatch appears successful but `.dispatch-manifest.json` is not updated, letting provenance/audit records be silently dropped. From a security perspective this is an audit-bypass primitive — an attacker who can engineer disk-pressure (or any other mktemp-failure condition) can dispatch reviewers and have their dispatch escape the manifest record.

## Cross-reference

This is the security framing of the SAME underlying defect as `silent-failure-codex.finding-F01.md` (R5-SF-F01). Both findings have the same root-cause fix: change `return 1` to `exit 1` in the mktemp failure path. Tracked as duplicate-of for triage purposes — single fix addresses both.

## Recommended fix

Change `return 1` to `exit 1` in `_append_manifest_entry`'s mktemp failure path (lines 307-313). Matches the function's other failure paths (jq, mv, lock timeout) which all use `exit 1`.

(Persisted by orchestrator — gpt-5.3-codex returned chat-only per stored memory.)

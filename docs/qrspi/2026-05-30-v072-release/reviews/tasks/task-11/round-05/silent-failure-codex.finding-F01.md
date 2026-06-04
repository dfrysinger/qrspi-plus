---
finding_id: R5-SF-F01
reviewer: silent-failure-codex
severity: med
change_type: correctness
referenced_files:
  - scripts/run-codex-review.sh
at_cap: false
escalate: false
---

# F01 — mktemp-failure path in `_append_manifest_entry` uses `return 1` (silent) while other failure paths use `exit 1` (loud)

**Introduced by R5 FIX-B (mktemp tmp path).**

## Location

`scripts/run-codex-review.sh:307-313` (the mktemp failure path), with impact at call sites `:921` (`emit_first_party_manifest_entry`) and `:992` (`emit_dispatch_manifest_entry`).

## Failure mode

`_append_manifest_entry` now does `return 1` on `mktemp` failure, but:

- Other failure branches in the same function (jq failure, mv failure, lock timeout) use `exit 1`.
- The callers `emit_first_party_manifest_entry` and `emit_dispatch_manifest_entry` invoke `_append_manifest_entry` without checking its return value (they rely on the function's old `exit 1` semantics for all failures).
- Main success paths still `exit 0`.

Result: when `mktemp` fails (disk full, permissions, /tmp unmounted), `_append_manifest_entry` returns 1, control returns to the caller which proceeds normally, and the dispatch reports success even though the manifest entry was never written.

## Recommended fix

Either:
- Change `return 1` to `exit 1` in the mktemp failure path (matches the rest of the function and the original sf-claude F01 fix philosophy of "fail loud, don't silently degrade").
- OR explicitly propagate at call sites: `emit_first_party_manifest_entry "$_fp_prompt_file" || exit 1` and `emit_dispatch_manifest_entry "$_dispatch_stdout" "<status>" || exit 1`.

The former is the minimal-diff fix and consistent with the function's existing failure-handling discipline. The latter is more flexible but requires touching every call site.

(Persisted by orchestrator — gpt-5.3-codex returned chat-only per stored memory.)

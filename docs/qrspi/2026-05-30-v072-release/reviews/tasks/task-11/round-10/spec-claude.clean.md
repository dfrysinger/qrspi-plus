---
reviewer_tag: spec-claude
round: 10
status: clean
---

CLEAN — all 5 R10 fixes verified.

- FIX-X: bats ~2783 AC5 comment; `T11` token dropped, text is "the dispatch-manifest spec requires this field; AC2 covers the helper-function path"
- FIX-Y: bats ~1743 AC12; `'/tmp/foo bar/round-01'` → `"$TMP_DIR/foo bar/round-01"`; space preserved; double-quotes for expansion
- FIX-Z: bats AC2 (~2519/2522) + AC5 (~2787/2791); both `length == 5` pins replaced with `(keys | sort) == [...]`; key sets match `emit_first_party_manifest_entry` jq template at scripts/run-codex-review.sh:427-428 exactly
- FIX-AA: scripts/run-codex-review.sh lines 248-257 (helper), 336/343/347/352/355 (call sites); helper handles empty-relay (mktemp branch) safely; accesses `_lock_dir`/`_saved_opts` via bash dynamic scoping; lock-acquisition-failure branch (323-327) untouched per spec
- FIX-AB: scripts/run-codex-review.sh lines 911-925 (helpers), 930-948 (call sites); 3 separate traps preserved; INT→130, TERM→143 retained (FIX-O); mktemp-branch ordering correct; success-path comment retained

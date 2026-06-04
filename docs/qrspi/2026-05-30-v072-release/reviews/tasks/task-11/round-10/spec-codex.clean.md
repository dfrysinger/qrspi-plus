---
reviewer_tag: spec-codex
round: 10
status: clean
---

CLEAN — all 5 R10 fixes verified line-by-line against the diff.

- FIX-X (drop `T11` token): bats lines 2784-2786 updated to generic phrasing.
- FIX-Y (hermetic AC12 outdir): bats lines 1742-1744 use `"$TMP_DIR/foo bar/round-01"`.
- FIX-Z (exact key-set pins): all 4 jq checks replaced at bats 2518-2523 and 2788-2792. Key sets verified against `emit_first_party_manifest_entry` jq template at scripts/run-codex-review.sh:427-428.
- FIX-AA (`_append_manifest_fail` helper): helper added at scripts/run-codex-review.sh:244-257; called at 335-337, 342-343, 346-347, 351-353, 354-356 for the 5 post-trap-install branches; lock-acquisition-failure branch (323-326) intentionally untouched.
- FIX-AB (`_install_fp_traps` + `_cleanup_fp_tmp` helpers): added at 907-925; preserves 3 separate traps with INT exit-130 / TERM exit-143 at 912-915 (FIX-O semantics intact); call sites updated at 930-933, 936-943, 948.

Target-files check: changes confined to `scripts/run-codex-review.sh` and `tests/acceptance/v07-phase1/test-phase1-acceptance.bats`.

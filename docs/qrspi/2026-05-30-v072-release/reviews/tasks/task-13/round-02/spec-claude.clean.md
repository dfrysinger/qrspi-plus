# spec-claude — Task 13 (G9) round 2 — CLEAN

Re-review after round-1 fixes. No spec-compliance findings.

## Verified

1. **Anchor relocation (round-1 Fix A) preserves all anchor-write paths and adds fail-closed behavior.**
   `scripts/round-prepare.sh`: the round-commit anchor write was moved out of the
   Step 1 block (former L172 site) to L222–237, *after* the Step 10 prior-artifact
   presence assertions (L186–219), still gated on `PER_TASK -eq 1`.
   - Round 1: Step 10 is a no-op (`ROUND_NUM >= 2` false) → anchor still written.
   - Happy-path round ≥ 2: Step 10 assertions pass → anchor written.
   - Fail-closed: any Step 10 `exit 1` (missing/malformed prior anchor L190/L202;
     missing/empty prior scope-set L213/L217) fires before the write → no stray
     `round-NN-commit.txt`.

2. **SHA-correctness exits 10/11/12 remain in Step 1.** exit 10 (L130, required-flag
   pair / orchestrator bug), exit 12 (L159, across-rounds advance), exit 11 (L170,
   within-round HEAD equality) — all still in the Step 1 block (L126–177).

3. **SKILL.md prose accurate.** Between-rounds checklist (L1184–1192): step-1 HALT
   branch on pending `mode: background` entries (L1186); exit-branch enumeration
   0/10/11/12 (L1189). Exit-1 invariant prose (L1198, L1205) correctly states
   exits 11/12/1 all halt before the anchor write, leaving no anchor on disk —
   matches the relocated code. No residual main-chat `rev-parse HEAD` prose in the
   Per-Task Convergence Narrowing section.

4. **Bats coverage pins all G9 behaviors incl. the new no-stray-anchor test.**
   `tests/unit/test-scope-tagger-dispatch.bats`: happy-path SHA+LF (L181), round-NN.diff
   inheritance (L210), exits 10/11/12 (L234/247/266/287), missing prior anchor (L308),
   missing scope-set (L360), script-side Task-tool boundary guard (L388), and the new
   fail-closed no-stray-anchor regression test (L330–358).

## Scope / Target files

Only the three Target-files entries were modified (`scripts/round-prepare.sh`,
`skills/implement/SKILL.md`, `tests/unit/test-scope-tagger-dispatch.bats`). No
out-of-scope files, no over-engineering, no unrequested features.

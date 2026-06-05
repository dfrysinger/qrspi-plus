# Code-Quality Review — Task 16, Round 08 (fix-7 increment)

**Reviewer:** code-quality-claude  
**Scope:** fix-7 increment only — `[ -f ]` regular-file guards added at `_resolve-lib.sh` L85, L99, L142, plus one hermetic bats regression test (`test-config-model-routing.bats` L506–519)  
**Verdict:** ✅ Approved — no new code-quality regressions

---

## Checklist summary

### Guard sites (`_resolve-lib.sh` L85, L99, L142)

**Correctness of placement:** All three sites follow the canonical shell-guard idiom: `[ -f ]` (regular-file) before `[ -r ]` (readable). This is the right order — checking type before permission is conventional and prevents a directory or special file from reaching `grep`.

**Symmetry:** The positive forms at L85 (`agent_file` guard) and L99 (`CONFIG_MD` layer-3 guard) are structurally mirrored by the negated form at L142 (`CONFIG_MD` layer-in-`resolve_model` guard). All three are logically consistent with each other.

**No change to warning messages:** The change narrows the positive guard at L99 so a directory-typed CONFIG_MD sets `config_present=0` and emits the "CONFIG_MD unset/missing" layer-4 warning. The wording is slightly imprecise for the directory case but not harmful — the operator is told CONFIG_MD is problematic. This is a pre-existing limitation of the message format, not a regression introduced by fix-7.

**No dead code / no YAGNI:** The three one-line additions are minimal and do exactly what the fix requires. No speculative generalisation.

### Regression test (`test-config-model-routing.bats` L506–519)

**Hermetic:** Uses `BATS_TEST_TMPDIR` (BATS auto-cleans); no network, clock, or shared-state dependencies.

**Targets the right path:** The test covers `resolve_model` at L142 — the path where a directory-typed CONFIG_MD would previously pass the `[ -r ]`-only guard, reach `grep` on a directory, produce an empty row, and emit an *unconfigured-tier* halt rather than the *config-path* halt. That wrong-diagnostic scenario is exactly what the `[ -f ]` fix addresses.

**Assertions are sufficient:** `[ "$status" -eq 1 ]` (hard exit 1, not just non-zero) + `[[ "$stderr" == *"not a readable file"* ]]` + `[[ "$stderr" != *unconfigured* ]]`. The negative assertion on `*unconfigured*` pins the diagnostic identity, not just that something failed.

**Comment quality:** The inline comment explains *why* `[ -r ]`-only is insufficient and names the failure mode precisely. The WHY is non-obvious (the wrong-diagnostic consequence of a directory satisfying `[ -r ]`); the comment is justified.

**Coverage of L85 / L99 directory paths:** No additional test needed. If `agent_file` is a directory, `[ -f ]` returns false and the code silently skips to the next precedence layer (correct behaviour). If CONFIG_MD is a directory in `resolve_tier`'s L99 path, `config_present=0` and layer-4 fires (also correct). Neither path produces a wrong diagnostic, so no pinning test is required.

**ID hygiene:** `R7-F01` in the test name — `R` is not in the QRSPI-internal `[GRDFTQ]` pattern; `F01` is reserved framework vocabulary (`F-N` in the reviewer protocol). No flag.

---

No findings. The fix-7 increment is clean, minimal, and well-targeted.

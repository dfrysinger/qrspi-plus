---
reviewer_tag: spec-claude
round: 7
task: task-16
verdict: clean
---

# Spec-gate CLEAN — task-16 round-07 (fix-6 delta verification)

Verified the fix-6 increment against the six round-06 KEPT findings. Every kept
finding is resolved; nothing beyond the kept set was changed. Additive-only,
bash 3.2 portable.

## Kept-finding resolution (all PASS)

1. **Empty-value guard (silent-failure-claude/codex F01)** — `_resolve-lib.sh`
   L167-176: after key-strip + `_normalize_tier_value`, a `[ -z "$value" ]` guard
   HALTs with a DISTINCT malformed-row diagnostic ("...row is present in
   model_routing but carries no value (malformed/empty row); refusing to emit an
   empty result..."). Placed BEFORE the none-check (L180) — so a present-but-empty
   row gets the malformed message, not the "resolves to none" message. No
   fall-through to the success emit. ✓

2. **`-f`→`-r` at the 3 guard sites (code-quality-codex F01 / silent-failure-codex
   F03)** — agent-file L85 `[ -n "$agent_file" ] && [ -r "$agent_file" ]`;
   CONFIG_MD in resolve_tier L99 `[ -n "${CONFIG_MD:-}" ] && [ -r "${CONFIG_MD:-}" ]`;
   CONFIG_MD in resolve_model L142 `[ -z "${CONFIG_MD:-}" ] || [ ! -r "${CONFIG_MD:-}" ]`.
   All three are readability checks now; the `-n`/`-z` unset guards are intact, so
   diagnostics ("unset or not a readable file") are truthful. ✓

3. **`_normalize_tier_value` comment reword (code-quality-claude F01)** — L43-48
   now reads "...strips a whitespace-preceded inline `#` comment, then ALL
   whitespace (both surrounding AND internal)..." matching the `tr -d '[:space:]'`
   behavior. Body unchanged (`sed -E 's/[[:space:]]+#.*$//' | tr -d '[:space:]'`).
   Comment-only. ✓

4. **DRY helper extraction (code-quality-claude F02)** — `_halt_unconfigured_tier`
   defined L50-59 as the single source of the byte-identical none/absent diagnostic;
   called from the absent-row branch (L155) AND the explicit-`none` branch (L181).
   The empty-value/malformed diagnostic (item 1) is correctly kept SEPARATE inline,
   not folded into the shared helper. ✓

5. **F02 de-mask test reworked to use the helper (code-quality-claude F03)** —
   test L421-430 now calls `run --separate-stderr _exec_resolve_tier "" "$agent" ""`
   (the helper unsets CONFIG_MD for the empty-config arg). The fragile
   `bash -c '...'"$agent"'...'` string-interpolation and `2>&1 1>/dev/null` plumbing
   are gone; asserts `status -eq 0` + `stderr == *CONFIG_MD*`. ✓

6. **Two new behavioral tests** — (a) present-but-EMPTY tier row L467-488: asserts
   `status -ne 0`, empty stdout, and `stderr == *HALT* && *medium* && *"no value"*`
   (pins the distinct malformed message). (b) present-but-UNREADABLE CONFIG_MD
   L490-504: `chmod 000`, asserts `status -ne 0` + `stderr == *CONFIG_MD*`, with a
   root-skip guard (`EUID==0 → skip`) since root bypasses permission bits, and a
   `chmod 644` restore for teardown. ✓

## Deferred / declined items correctly NOT touched

- **trusted_path** — header L9-12 still documents it as a dispatch-site concern NOT
  enforced in this library; no enforcement code added. Correctly deferred. ✓
- **Layer-4 medium fallback** — L111-123 unchanged; the config_present cause-naming
  (from fix-5) is intact, `medium` emitted with the LOUD WARN. No behavior change. ✓
- **Duplicate-tier-row detection (deferred D4)** — row lookup still `grep ... | head -1`
  (L151), first-win, no match-counting added. Correctly NOT implemented. ✓
- **Design-ID comments (declined code-quality-codex F03)** — header provenance refs
  (G22, design.md CD-1, §G27 D5, etc.) remain. Correctly NOT removed. ✓

## Scope / portability

- All edits trace to a kept finding; no new files, flags, config options, or
  abstractions beyond the requested guard + helper + comment + tests.
- bash 3.2 portable throughout (`sed -E`, `tr`, `grep -E`, `printf`, POSIX test
  operators, `case`). No bashisms outside 3.2.
- Target-files check: only `scripts/_resolve-lib.sh` and
  `tests/unit/test-config-model-routing.bats` touched — both in scope.
- The 4 known pre-existing bats failures are out of this task's surface; not
  introduced or affected by the fix-6 delta.

No findings. Gate PASS — downstream reviewers may proceed.

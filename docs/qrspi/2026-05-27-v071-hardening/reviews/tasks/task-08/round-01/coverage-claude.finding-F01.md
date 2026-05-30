---
finding_id: F01
reviewer: coverage-claude
round: 1
task: 8
severity: low
category: coverage-hygiene
file: tests/unit/test-run-third-party-llm.bats
lines: 46-62
---

# F01 — Stale `_write_config_openai` helper retains retired cache-mechanism field names in fixture config.md emissions

## Observation

After the Task 8 retirement, the local helper `_write_config_openai`
(tests/unit/test-run-third-party-llm.bats lines 46–62) still accepts the
`$5=supports_prompt_cache` / `$6=emit_cache_control_markers` parameters in
its signature comment and still writes both keys into every fixture
`config.md` it emits:

```bash
_write_config_openai() {
  # $1=artifact_dir $2=provider_name $3=base_url $4=api_key_env
  # $5=supports_prompt_cache  $6=emit_cache_control_markers
  cat > "$1/config.md" <<EOF
  ...
    supports_prompt_cache: $5
    emit_cache_control_markers: $6
EOF
}
```

Every call site in the file continues to pass `false false` as positional
args 5 and 6 (e.g. lines 116, 144, 156, 166, 178, 192, 208, 216, 224, 232,
239, 246, 255, 263). The post-T8 dispatcher's `rec_key` case statement
(scripts/run-third-party-llm.sh lines ~543) only matches `base_url`,
`api_key_env`, `transport_type` — unknown provider keys are silently
dropped, so tests still pass.

## Why this matters for coverage

1. **Absence-assertion scope gap.** TE6 and TE7 grep `skills/using-qrspi/SKILL.md` and `scripts/run-third-party-llm.sh` for the retired literals, but neither absence assertion is scoped to `tests/unit/test-run-third-party-llm.bats` itself. The retired literals `supports_prompt_cache` and `emit_cache_control_markers` continue to live in the repository at lines 48, 56–57 of this test file. A future maintainer searching the repo for `supports_prompt_cache` will find live references in fixture YAML and reasonably assume the field is still load-bearing.

2. **Silent-tolerance load-bearing on dispatcher behavior.** The tests pass only because the dispatcher's parse loop silently ignores unknown provider keys. If a future hardening task adds strict unknown-key validation to the provider parser (a plausible hardening direction given v0.7.1's fail-loud thesis), every test in this file that exercises `_write_config_openai` will fail with a confusing diagnostic about `supports_prompt_cache` rather than an obvious "tests need to be updated alongside the parser". The coupling is fragile and undocumented.

3. **Asymmetry with the broker helper.** `_write_config_broker` (lines 64–77) was correctly authored without these fields — the openai helper should match.

## Severity

Low. No current test fails; no production-behavior coverage is lost; the core absence-assertion envelope on production surfaces (TE1–TE9) is sound. The finding is coverage-hygiene only — closing the loop on the retirement across all surfaces that mention the retired literals.

## Suggested fix

Drop `$5` and `$6` from `_write_config_openai`'s signature, the comment block, and the heredoc; mechanically remove the trailing `false false` arguments from every call site. The set of call sites is bounded and greppable: `grep -n '_write_config_openai' tests/unit/test-run-third-party-llm.bats`.

If keeping the surface-area invariant tight, also add a seventh absence assertion to the T8 / TE7 cluster targeting `tests/unit/test-run-third-party-llm.bats` itself for the three retired literals — though dropping the helper params makes that assertion redundant.

---

**Verifier verdict:** scored 72 — below 80 clarity/style KEEP threshold per Hotfix B. DROPPED. Residue retained as known/acceptable; future cleanup pass may revisit.

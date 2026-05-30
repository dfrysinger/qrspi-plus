---
finding_id: quality-claude-F01
severity: minor
change_type: style
referenced_files:
  - tests/unit/test-run-third-party-llm.bats:7-9
  - tests/unit/test-run-third-party-llm.bats:46-62
  - tests/unit/test-run-third-party-llm.bats:343-356
artifact: task-08
round: 1
reviewer: quality-claude
---

# F01 — Test-fixture helpers still emit the retired `supports_prompt_cache:` / `emit_cache_control_markers:` YAML keys; ~14 callers still pass the now-inert `false false` params

T8's framing is an atomic close of the prompt-cache mechanism across five surfaces. The implementation correctly removes the production branch from `scripts/run-third-party-llm.sh` (lines 484-488, 497-505, 517-518, 526-527 in the diff) and the prose + YAML example from `skills/using-qrspi/SKILL.md`. Grep-based absence assertions (TE5/TE6/TE7) lock those two surfaces.

But the test infrastructure that previously supported the dual-flag gate still carries the dead keys forward, unchallenged by any absence assertion:

**(1) `_write_config_openai` helper signature still includes the retired params and emits the retired YAML keys.**

`tests/unit/test-run-third-party-llm.bats:46-62`:

```bash
_write_config_openai() {
  # $1=artifact_dir $2=provider_name $3=base_url $4=api_key_env
  # $5=supports_prompt_cache  $6=emit_cache_control_markers
  cat > "$1/config.md" <<EOF
---
providers:
  $2:
    base_url: $3
    api_key_env: $4
    transport_type: openai-chat-completions
    supports_prompt_cache: $5
    emit_cache_control_markers: $6
---
...
```

The post-T8 dispatcher's provider-block field switch (`scripts/run-third-party-llm.sh:543-548`) no longer has `case` arms for `supports_prompt_cache` or `emit_cache_control_markers`, so the awk parser hands them to the field-dispatch loop, which silently drops them. The keys are pure noise in the fixture YAML; the `$5 $6` parameter slots are unobservable.

**(2) Every caller still threads `false false` through the dead slots.**

Approximately 14 call sites in the same file pass `false false` as the last two arguments — e.g. lines 116, 125, 144, 156, 166, 178, 192, 208, 216, 224, 232, 239, 246, 255, 263. Each call wastes two literals and obscures the actually-load-bearing fixture state.

**(3) Sibling helper `_write_ctrl_config` hardcodes the same retired keys.**

`tests/unit/test-run-third-party-llm.bats:343-356` writes both `supports_prompt_cache: false` and `emit_cache_control_markers: false` into its control-character-test fixture config.md, identically inert under the post-T8 dispatcher.

**(4) File-level docstring still describes the deleted gate as if it were live.**

`tests/unit/test-run-third-party-llm.bats:7-9`:

> "...the exit-code matrix (0/1/10/11/13/14/15), `<artifact-dir>/config.md` resolution, transport-type branching, environment-variable key resolution (unset AND empty-string), **the dual-flag cache_control emission gate (all four cells of supports_prompt_cache: x emit_cache_control_markers:)**, the SSRF host-shape carve-out..."

The four cells were deleted from this file in the same diff (lines 1343-1385 of the round-01.diff). The docstring now lies about what the suite covers — a future reader scanning the header for the suite scope will infer a feature that no longer exists.

## Why this matters for T8 specifically

The task description states: "the cache mechanism boundary closes atomically across all five surfaces." The retirement is complete on three of the five surfaces touched by the implementer (the dispatcher script, the SKILL.md, the deleted/created acceptance pins), but the test-fixture helpers in the fourth surface (`test-run-third-party-llm.bats`) leak the retired vocabulary right back into the fixtures the post-T8 dispatcher consumes. The grep-based TE6/TE7 absence assertions deliberately scope to the dispatcher script and SKILL.md — that scope intentionally does not cover the test fixtures, which means this residue is invisible to CI and will sit indefinitely as a fossil of the deleted mechanism unless cleaned now.

## Recommendation

In `tests/unit/test-run-third-party-llm.bats`:

1. Drop the `$5` and `$6` parameters from `_write_config_openai`; remove the `supports_prompt_cache:` and `emit_cache_control_markers:` lines from the heredoc.
2. Update ~14 call sites to drop the trailing `false false` arguments.
3. Remove the `supports_prompt_cache: false` and `emit_cache_control_markers: false` lines from `_write_ctrl_config` (lines 351-352).
4. Remove the "dual-flag cache_control emission gate (all four cells of supports_prompt_cache: x emit_cache_control_markers:)" clause from the file header docstring at lines 7-9.

A follow-up that would harden the boundary further (out of scope for this finding): extend the TE6/TE7 absence-grep pattern to also cover `tests/unit/test-run-third-party-llm.bats` so future regressions of this kind fail CI. Not requesting that change here — the immediate cleanup above is sufficient to close the residue.

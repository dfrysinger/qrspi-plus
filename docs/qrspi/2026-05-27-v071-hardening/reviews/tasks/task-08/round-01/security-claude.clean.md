---
reviewer: security-claude
task: task-08
round: 1
verdict: clean
---

# Security review — CLEAN

Task 8 retires the prompt-cache mechanism: removes the dual-flag
`emit_cache` branch from `_dispatch_openai_chat`, drops two provider-block
config bindings (`supports_prompt_cache`, `emit_cache_control_markers`),
and deletes the G4 cache-probe script, its stub markdown, and two unit
suites that exclusively covered the truth-table behavior of the now-deleted
gate.

## Surfaces reviewed

1. **`scripts/run-third-party-llm.sh` `_dispatch_openai_chat`** — node argv
   shifts from `(emit_cache, MODEL, prompt)` to `(MODEL, prompt)`; the
   message-object `cache_control` injection is gone. `--` separation,
   `JSON.stringify` marshaling, and the curl/auth/header assembly paths
   are byte-untouched. No injection or credential regression.
2. **Provider-block parser** — silently ignores leftover
   `supports_prompt_cache` / `emit_cache_control_markers` keys in stale
   configs. UX/correctness concern at worst (operator believes caching
   is active when it isn't); no security boundary depends on validating
   either flag.
3. **Deleted `scripts/g4-cache-probe.sh`** — operator-invoked probe;
   never wired into any auth/token path beyond the dispatcher's normal
   env-key resolution. Removal strictly reduces attack surface (one fewer
   path-validated writer under `docs/qrspi/`, one fewer `--provider`
   surface consumer). No credentials were embedded; no production code
   path consumed it.
4. **Deleted unit suites (`test-cache-control-capability-gate.bats`,
   `test-cache-hit-rate.bats`)** — read both files line-by-line. Both
   suites exclusively assert cache-control emission, cache-hit-rate, and
   spike-report freshness invariants. Neither contains credential-leak,
   path-traversal, auth-header, STDIN-validation, or any other
   security-invariant assertion. Nothing security-relevant becomes
   uncovered.
5. **Deleted Slice-7 acceptance gates + `SPIKE=` export** — purely
   measurement-mechanism gating. No security property gated.
6. **New `test-cache-retirement-invariants.bats` + TE6/TE7 absence pins**
   — additive grep-based assertions; no new sinks, no new validation
   gaps.

## Per-category result

- **Injection**: no new sinks; node argv pattern preserved with safe
  marshaling.
- **Auth/authorization**: `_API_KEY`, `HEADER_NAMES`, `HEADER_VALUES`,
  and `Authorization` resolution unchanged. The retired branch never
  touched credentials.
- **Data exposure**: no logging/error-message changes; one less
  trusted-but-now-removed flag in the node process-table args (strict
  improvement).
- **Input validation**: STDIN size/control-char check and timeout
  handling untouched. Silent-ignore of removed config keys is a UX
  concern, not a security one.
- **Dependency risks**: no dependency changes.
- **Cryptography**: N/A.
- **Race conditions**: probe's lock-file race surface removed with the
  probe; dispatcher's atomic-write path unchanged.

No findings. Verdict: clean.

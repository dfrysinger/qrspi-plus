# Silent-Failure Review — Task 39, Round 3 — CLEAN

Reviewer: silent-failure-claude
Round: 3
Subject: tools/build-plugin.mjs

## Verdict

CLEAN — no silent failures introduced by the R3 diff.

## Scope of review

R3 diff is small and surgical:
1. Dead-code removal.
2. New `MAX_EXPAND_BYTES = 4 * 1024 * 1024` per-cache-entry materialized-output cap.
3. `MAX_INCLUDE_DEPTH` lowered to 8.

## Byte-cap path analysis

- `expand()` lines 233–240: when `out.length > MAX_EXPAND_BYTES` after appending a child expansion, code throws `BuildError` carrying `${relPath}:${lineNo}:` prefix, the cap value, the actual size, and the full include chain. Fail-loud, propagated through `main()`'s catch (lines 534–540) to stderr + `process.exit(1)`. No swallow, no fallback, no log-and-continue.
- Check fires after every `!cat` child append, so cumulative growth via cached child entries (each itself ≤ cap) cannot exceed cap silently — the next append that crosses the threshold throws.
- Plain (non-`!cat`) line accumulation is intentionally not cap-checked; bounded by source file size on disk with no amplification path. Not a silent failure.
- Cache population (line 245) happens only after a fully-validated under-cap expansion completes. Cycle and depth checks (lines 190–199) still run *before* the cache lookup, so cached entries cannot be served while bypassing structural guards.

## Depth-cap change (10 → 8)

Diagnostic at line 197 unchanged in shape: prints max value and full chain. Still fail-loud.

## Dead-code removal

No error-handling sites or fallback paths altered.

## Categories scanned (all clear)

1. Swallowed errors — none. All `catch` blocks either rethrow non-ENOENT or convert ENOENT into a `BuildError` with file:line context.
2. Silent fallbacks — none. No `|| []`, no `??` masking, no empty-array returns on failure.
3. Missing error paths — none new. `fs.readFileSync` at line 204 will throw on EACCES/EISDIR; uncaught here propagates to `main()` and is rethrown (line 539) since it isn't a `BuildError`. That's fail-loud-with-stack, not silent.
4. Inappropriate error transformation — none. Original error preserved when not ENOENT (lines 166, 272, 308, 334, 352, 388, 412, 492); ENOENT-to-BuildError conversions add context without losing actionability.
5. Log-and-continue — none. Every error path exits non-zero.
6. Partial state on failure — `outDirAbs` is wiped+recreated before `copyManifest`; failure mid-copy leaves a partial build tree but the next run wipes it. Acceptable for a build tool, and unchanged by R3.

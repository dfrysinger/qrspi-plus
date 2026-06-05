# security-claude.finding-F01: depth-cap + memoization don't bound expanded output size under intra-file fan-out

**File:** `tools/build-plugin.mjs:180-230` (`expand`)
**Severity:** medium
**Score:** 45
**Category:** Input Validation / DoS (continuation of R1 sec-F01)

## Summary

The R1 fix for billion-laughs (MAX_INCLUDE_DEPTH=16 + `expandCache` memoization)
bounds **graph traversal time** but does **not** bound **expanded output size**
when a single source file contains multiple `!cat` directives that target the
same descendant. The cache stores each file's fully-expanded text once, but
that stored text can be exponentially large because every `!cat <X>` line in a
parent appends another full copy of `expandCache.get(X)` to the parent's `out`
string (line 223: `out += expandedChild`). With memoization keyed per-file,
each level multiplies output by the per-file fan-out factor, not by 1.

Concretely, for files F0…F15 where each Fi contains N copies of
`!cat F{i+1}` and F16 is one byte:

- `expand(F16)` returns 1 byte
- `expand(F15)` returns N bytes (cached)
- `expand(F14)` returns N² bytes (cached, materialized as a single string)
- …
- `expand(F0)` returns N¹⁶ bytes

For N=2 this is 64 KB (harmless). For N=10 (which the strict grammar permits —
nothing forbids 10 identical `!cat` lines in one file) this is 10¹⁶ bytes
≈ 10 PB. Even at depth 8 with N=10 each cache entry is ~100 MB, and the
final `fs.writeFileSync(dstAbs, expanded)` at line 348 / 412 will OOM the CI
runner or fill its disk.

The R1 review accepted the fix on the assumption that memoization prevents
billion-laughs; that's only true for **traversal time** (each file is
parsed once). The text of each cached expansion is itself unbounded, so
memoization actually *helps* the attack by hiding work that would otherwise
hit a CPU/wall-clock limit before producing output.

## Concrete attack scenario

1. A contributor opens a PR from a fork. CI on `pull_request` runs
   `node tools/build-plugin.mjs` per `.github/workflows/ci.yml:123`.
2. The PR adds 16 chained files under `skills/x/`, each containing 10
   `!cat skills/x/lvl{i+1}.md` lines and lvl16.md a single byte.
3. CI build allocates ~10¹⁶ bytes when materializing `expand(lvl0.md)`'s
   cache entry, OOM-killing the bash32 job and exhausting GitHub Actions
   minutes for the repo.
4. Even at a more conservative N=4, depth=16 yields 4¹⁶ ≈ 4 GB, which
   exceeds the 7 GB GitHub-hosted runner RAM after string-builder overhead
   (`out += expandedChild` doubles transiently in V8).

The attacker needs only PR-fork access (no merge rights, no secrets); the
attack lands as a CI denial-of-service. PR reviewers would notice 16
files of obviously-templated `!cat` lines, but a more subtle variant
(N=4 across 8 normal-looking SKILL.md files in a refactor PR) is
plausibly mistakable for legitimate fan-in.

## Why the R1 mitigations don't catch it

- **Cycle stack** (line 181): only catches an Fi appearing twice on the
  current call stack; the chain F0→F1→…→F16 is acyclic.
- **MAX_INCLUDE_DEPTH=16** (line 185): bounds **levels**, not
  per-level fan-out. 16 is also generous: with N=10, depth=8 already
  yields 100 MB cached strings.
- **expandCache** (line 191): caches the text *after* it has been
  materialized, so it doesn't prevent the materialization. It only
  prevents re-materialization of the same key.

## Recommended fix

Pick one of (cheapest first):

1. Lower `MAX_INCLUDE_DEPTH` to 6–8. With N=10 and depth=6 the worst-case
   output is 1 MB, which is recoverable from real source patterns.
2. Add a cumulative output-size cap: track total bytes written into any
   single cache entry and `throw new BuildError` past, e.g., 4 MB. This
   catches both deep-nesting and wide fan-out variants regardless of
   shape.
3. Cap the number of `!cat` directives per file (e.g., refuse > 32
   directives in a single source file), which closes the per-level
   multiplier without changing depth budgets.

Option 2 is the most robust — it bounds the actual resource (memory/disk
the build can consume) rather than a structural proxy that attackers can
rebalance around.

## Out of scope / accepted residual

- Attacker must have PR-author rights on a public fork. CI uses
  `pull_request` (not `pull_request_target`), so secrets are not exposed
  — impact is limited to CI-time DoS / minute exhaustion.
- The strict grammar and outside-root checks (resolveTarget) remain
  sound; this finding is purely about resource bounds inside legitimate
  in-root content.

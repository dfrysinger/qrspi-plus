---
reviewer: security-claude
artifact: plan.md
round: 7
verdict: clean
---

# Security Review — plan.md round 7 — clean

## Scope of this review

Broaden-vs-main review of `docs/qrspi/2026-05-30-v072-release/plan.md` round 7. Round 6 applied the AC #2 extension at L22 covering T39's four additional build-pipeline release-integrity halts (include-cycle, malformed `!cat`, missing-target, `${CLAUDE_SKILL_DIR}` shipped-file), addressing the prior round-06 finding `sec-claude.F01`. This review verifies byte-alignment with T39's DoD/Test and checks for any remaining release-integrity halts omitted from the AC.

## Verification

The four newly-enumerated build halts in AC #2 are byte-aligned with T39's DoD (L2240–2253) and Test Expectations (L2255–2268):

| AC #2 (L22) | T39 DoD/Test source | Alignment |
|---|---|---|
| `tools/build-plugin.mjs` include-cycle halt with the full cycle printed | T39 Scope L2224, DoD L2246, Test L2261, Test L2267 ("deliberate include-cycle failure with the required diagnostics") | ✅ byte-aligned including "full cycle printed" clause |
| `tools/build-plugin.mjs` malformed `!cat` directive and missing-target halts with `file:line` diagnostics | T39 Scope L2224, DoD L2246, Test L2261 | ✅ byte-aligned including `file:line` diagnostic surface |
| `tools/build-plugin.mjs` `${CLAUDE_SKILL_DIR}` shipped-file halt when any built file under `build/` still contains the legacy resolver token | T39 Scope L2224, DoD L2247, Test L2262/L2267 | ✅ byte-aligned |
| `tools/build-plugin.mjs` `resolves outside repository` halt (symlink-escape, carried over) | T39 DoD L2253 + Test L2268 | ✅ byte-aligned (verified in prior rounds) |

## Completeness — release-integrity halts not enumerated in AC #2

T39 DoD L2246 lists two additional D3 fail-loud conditions that AC #2 does not name explicitly:

- Absolute-path attempts (e.g., `!cat /any/path`)
- Path-traversal attempts (e.g., `!cat ../../foo`)

These are strict-grammar / portability enforcement halts. Their security-relevant failure mode — inlining content sourced from outside the repository — is fully captured by the already-enumerated `resolves outside repository` canonicalization halt at L22:

- An absolute path or traversal that escapes the repo canonicalizes outside `$REPO_ROOT/` and triggers the canonicalization halt before any byte enters `build/`.
- An absolute path or traversal that stays inside the repo is a portability/style defect, not a security exfil surface.

The AC #2 fail-loud-invariant clause therefore preserves the security property (no shipped content sourced from outside `$REPO_ROOT`) without separately enumerating these defense-in-depth grammar halts. This is not a security gap.

## Other categories

- **Fail-closed requirements** — Apply-fix sub-threshold instrumentation (AC #3) and verifier fan-in halt enumeration (AC #2, T02, T05, T06, T07) remain fail-loud across rounds 1–7; no regressions introduced by the round-07 diff.
- **Input validation** — T16 model_routing schema, T17 validation table, T20 splitter rename, T21 path-filter exfil guard, T34 plan post-approval split block-hash audit, and T39 resolver grammar all carry malformed-input rejection in DoD and Test Expectations. No new external-input surface introduced.
- **Auth/authz** — T19 second-reviewer-available check and T20 splitter rename collapse continue to gate dispatch on `_resolve-lib.sh` halts (`tier: none`, second-reviewer-same-vendor, second-reviewer-unavailable). All paths require explicit configuration; no permissive defaults.
- **No insecure defaults** — T22/T23 require explicit `model_routing:` (no silent default), T19 fails loud when second reviewer is requested but unavailable (no silent fallback to single reviewer), T39 fails loud on missing/malformed `!cat` includes (no silent skip). Round-07 introduces no new defaults.

## Verdict

Clean. The round-06 AC #2 extension is byte-aligned with T39's DoD and Test Expectations, and the security-relevant property of the build pipeline (no shipped content from outside `$REPO_ROOT`, no silent legacy-token leakage) is fully enumerated as an end-to-end-observable fail-loud invariant at phase boundary. Prior finding `sec-claude.F01` is resolved.

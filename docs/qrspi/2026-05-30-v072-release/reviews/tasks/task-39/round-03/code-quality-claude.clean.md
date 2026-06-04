# Code Quality Review — Task 39, Round 3 (claude)

**Verdict: clean — no new findings.**

## Scope

Round 3 diff against `<base-branch>` for the two subject artifacts under review:

- `tools/build-plugin.mjs`
- `tests/unit/test-build-gate.bats`

## R2 carry-over

- **cq-F01 (R2, dead code `outRelFromRoot`)** — addressed. Verified the local
  is no longer present in `recurseDir` (file lines 300–371). The .md branch
  now computes `relForward` directly from `rel` and feeds `expand` without an
  intermediate root-relative variable.
- **cq-F02 (R1, DRY of outside-root canonical guard)** — deferred (score 45)
  per dispatch instruction. Not re-flagged.

## Re-review against criteria

Walked the production file end-to-end and the new T39 block of the bats file:

- **Single responsibility / decomposition** — Functions remain small and
  single-purpose: `parseArgs`, `resolveTarget`, `expand`, `copyFilePreservingMode`,
  `recurseDir`, `copyManifest`, `assertBuildTreeFreeOfLegacyToken`,
  `canonicalizeMaybeMissing`, `main`. No god-functions; `main` orchestrates
  parse → guard → wipe → copy → final-scan in a readable top-to-bottom shape.
- **Structure compliance / file size** — `tools/build-plugin.mjs` is 543 lines;
  large but proportional to the documented D1–D4 responsibilities and within
  the task's `sizing_exception: CI scaffolding`. Comment density (manifest
  rationale, depth/byte caps, cycle-vs-cache ordering, --out-equals-root
  guard) accounts for a meaningful fraction.
- **Naming** — Names describe what things are (`MAX_INCLUDE_DEPTH`,
  `MAX_EXPAND_BYTES`, `assertNoClaudeSkillDir`, `canonicalizeMaybeMissing`,
  `MANIFEST_PATH_EXCLUSIONS`). `ctx.rootReal` / `outDirAbs` distinguish
  canonical vs lexical clearly.
- **Cleanliness / comments** — Header comments orient (resolver grammar, D3
  fail-loud list); inline comments capture non-obvious WHY (cycle check
  before cache because cache is only populated post-completion; depth+byte
  caps are layered defenses against billion-laughs and N^D fan-out;
  `--out` ancestor-of-root guard is load-bearing because `force: true`
  would silence the wipe error). No restate-the-code noise. No dead code
  remaining after R2 cleanup.
- **DRY** — Only the known F02 canonical-prefix guard duplication remains;
  per dispatch, not re-flagged.
- **YAGNI** — No speculative knobs. CLI surface is minimal (`--root`,
  `--out`, `--help`). Manifest is data, not pluggable.
- **Self-consistent defenses (§12)** — Verified the load-bearing defenses
  remain coherent: (a) `--out == rootReal` and `rootReal startsWith outDirAbs + sep`
  guards run BEFORE the `rmSync(force:true)`; (b) cycle check precedes cache
  read in `expand` (line 190 vs 200); (c) symlink-escape canonical-prefix
  check on .md sources (lines 354–361) runs before `expand` reads bytes;
  (d) `assertBuildTreeFreeOfLegacyToken` final pass catches non-.md leaks
  that the per-file expand path skips. All four defenses route correctly
  even when their guarded condition is false (i.e., they don't depend on
  the failure mode they defend against to reach the decision point).
- **ID hygiene** — `${CLAUDE_SKILL_DIR}` references are framework
  vocabulary the resolver explicitly forbids in shipped output; not a
  QRSPI run-token. Comments mention `T21`/`v0.7.2`/`G32`/`D3` — `T21`
  is a cross-task reference and `G32`/`D3` are reserved framework
  vocabulary per the ID-hygiene exemption list. No QRSPI run-tokens
  copied into code, comments, test names, or runtime strings.
- **Test quality (bats)** — T39 block uses descriptive `@test` names
  tied to D3 conditions; awk-bounded grep in the build-verification test
  (lines 26–28) is a good tightening over loose range-grep that could
  match unrelated "non-zero exit" prose elsewhere.

No new findings.

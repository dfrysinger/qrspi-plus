---
reviewer: scope-claude
artifact: docs/qrspi/2026-05-30-v072-release/plan.md
round: 07
verdict: clean
---

# Plan scope/boundary review — clean

Broaden-vs-main diff (round 07, full file). All 38 task specs evaluated against `skills/plan/owns-defers.md`.

## OWNS coverage (complete)

- **Ordered task specs.** 38 tasks in nine slice headings (1.1–1.7), sparse numbering (1–44 with documented gaps 18/22/23/41/42/43) and per-gap disposition rationales in Overview (L17). Cross-slice ordering perturbations (G4→G9, T11/T13/T09→T20) explicitly enumerated in Dependency Graph (L104–116).
- **Test expectations.** Plain-language behavioral bullets per task. No assertion code (`expect(...)`, `assert.*`, `toBe(...)`) encountered.
- **Dependencies.** Each task declares `Dependencies:` plus a reverse-edge `Blocks:` annotation; no forward dependencies detected.
- **LOC estimates.** Present on every task. Sizing exceptions declared and named (`reusable primitives`, `schema-migration`, `CI scaffolding`) — T12/T16/T19/T20/T25/T39 all carry the named exception per the closed exception set.

## DEFERS compliance (no leakage)

| DEFERS class | Lexical scan | Result |
| --- | --- | --- |
| Function signatures / parameter lists → structure.md | `fn(`, `=>`, parenthesized param lists | clean |
| `expect(`, `assert.`, `toBe(`, `assertEqual` → Implement-TDD | grep in Test Expectations | clean |
| `if/else`, `for`, `while`, line-numbered logic walkthroughs → Implement | scan of all Scope/Definition-of-done bullets | clean |
| "trade-off", "we considered", "alternative approach" → design.md | scan | clean (Out-of-scope deferrals point at design.md, do not re-argue) |
| "phase 2 will", "future phases", forward roadmap refs → phasing.md | scan | clean (forward deferrals named as design.md disposition pointers, not roadmap-style speculation) |

## Round-06 fix surfaces verified clean

- **T19 dep edge (L65 / L980 / L1109).** T19 declares `Dependencies: Task 16` at task header (L1109); T16 `Blocks:` line names T19 with rationale for the `_resolve-lib.sh` matrix extension (L980); dep-graph item 4 narrative is consistent (L65 region). No new drift.
- **AC #2 T39 enumeration extension (L22 = diff L28).** Fail-loud-invariant list extended with four build-pipeline halts: `tools/build-plugin.mjs` `resolves outside repository` (symlink-escape), include-cycle, malformed `!cat` / missing-target, and `${CLAUDE_SKILL_DIR}` shipped-file. Each is an observable halt with named diagnostic surface — appropriate cross-task acceptance behavior, not function signature or algorithm prose.

## Borderline cases (intentionally not flagged)

- **T39 DoD bullet on `fs.realpathSync` (L2259).** Names a Node stdlib facility with the `(or equivalent)` qualifier and frames the rule as "canonicalize BEFORE reading bytes." This is a behavioral ordering constraint plus a defensive-implementation pointer, not a function signature. Matches T21's parallel `assert_path_under_repo_root <label> <abs-path>` mention from prior rounds.
- **T40 lint detection patterns (L2310–2312).** The `[[ "$body" ... ]]` / `[ -n "$body" ]` / `^@test "..." \{` strings are the *content the lint detects*, i.e., the contract surface this task lands. Not pseudocode of the lint walker.
- **T34 sha256 normalization wording (L1953–1956).** Block-hash header format, position, and normalization rule are the contract Plan is documenting (post-approval-split-contract.md), surfaced as observable test expectations. Not Implement-layer logic.

## Length

2401 lines for 38 tasks (~63 lines/task aggregate). At the upper edge of the 1000–2000 soft band but not "well outside" (the rule's drift threshold is 4000 lines for over-spec). Proportional to a 35-goal release; acceptable for a single-phase hardening drop with cross-cutting CD-1/CD-4 anchors.

## Verdict

No scope/boundary findings. Round-06 fixes integrate cleanly without introducing drift into Structure, Implement, Implement-TDD, Design, or Phasing territory.

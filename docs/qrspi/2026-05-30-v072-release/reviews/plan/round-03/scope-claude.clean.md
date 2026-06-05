---
reviewer_tag: scope-claude
artifact: plan.md
round: 3
ref: main (broaden)
---

# Scope review — clean

Plan.md passes the 3-check scope procedure against `skills/plan/owns-defers.md`.

## Plan OWNS coverage
- **Ordered task specs:** T01–T44 with documented gaps at T18/T22/T23/T41/T42/T43, all gaps explained as moot/absorbed (Overview line 17; Cross-slice notes line 102).
- **Test expectations:** every task carries a `**Test expectations**` block in plain language; no `expect(...)` / `assert.` / `assertEqual` / `toBe(` code.
- **Dependencies:** each task block carries explicit `Dependencies:` and `Blocks:` declarations; no forward dependencies (all `Dependencies:` reference earlier-numbered tasks).
- **LOC estimates:** every task has `~N` LOC; oversized tasks (T12 ~280, T16 ~320, T19 ~210, T20 ~260, T25 ~340, T39 ~360) all carry explicit `sizing_exception:` markers (`reusable primitives`, `schema-migration`, `CI scaffolding`).

## Plan DEFERS — respected
- No function signatures with typed parameter lists or return-type arrows authored in task specs.
- No line-by-line algorithm pseudocode, control-flow walkthroughs, or `if/else/for/while` constructs.
- No design-altitude trade-off prose in task descriptions; "Why: see design.md ## GNN" pointer pattern keeps rationale in design.md.
- No phasing/roadmap re-authoring; `v0.7.3+` references appear only in `Out:` bullets as deferral markers, which is correct DEFERS bookkeeping.
- Structure-altitude file-responsibility detail is consistently pointed to via `structure.md ###` references rather than re-authored in plan.

## Borderline items conservatively cleared (per user F-5 guidance)
- T11 lines 694–696 name JSON manifest field shape (`dispatch_spec.subagent_type/host/vendor/model/prompt_file`). The schema is already locked in `design.md ## CD-1 → "Dispatch manifest schema"` and authored canonically in `structure.md ### 10. Dispatch manifest schema`; plan is consuming the locked schema to scope the task, not re-authoring it.
- T21 line 1251 + T39 line 2252 mirror reference the helper `assert_path_under_repo_root <label> <abs-path>`. The helper name is an established CD-1 vocabulary anchor (already pinned in `structure.md ### scripts/run-codex-review.sh` G16 responsibility), and the `<label> <abs-path>` placeholder syntax is usage-shape rather than a typed function signature.
- T39 line 2252 references `fs.realpathSync` but explicitly hedges with `(or equivalent)`, preserving Implement-altitude negotiation room as the INVEST Negotiable framing requires.
- T40 / T44 cite literal bash test patterns (`[ -n "$body" ]`, `[[ "$body" != *...* ]]`, `^@test "..." \{`, `run --separate-stderr`). These are the central subject of the lint/regex-hardening contract — naming the patterns is unavoidable to make the contract testable, not gratuitous Implement-TDD code leakage.
- T12 / T13 pin exit codes 10/11/12 in DoD and Test Expectations — observable contract values appropriate for plan ownership.
- Exact diagnostic strings in T32 (line 1817), T34 (lines 1949–1950), T36 (line 2055) — user-visible observable behavior, plan-owned.

Each borderline item is anchored to already-locked design.md / structure.md content rather than pre-empting downstream skill choice, so none rise to a Structure-layer or Implement-layer DEFERS violation under the user-supplied conservative F-5 reading.

## Round-03 specific verification — post-moot-goals surgery cross-references clean

The round-03 broaden focus was verifying that round-02's moot-goals surgery left no stale cross-references. Verified clean:

- **T11 [G29]→[G3] re-label:** header line 679 and body line 689 both carry `[G3]`; Overview at line 689 explicitly explains "G29 — the formerly-planned large-artifact escape-hatch goal — is moot per design.md ## G29 (absorbed by CD-1, no separate task ships)". `Out:` bullets at 702–703 also acknowledge the G29 absorption. References block (line 724) names "design.md ## G29 — locked disposition that G29 is moot/absorbed by CD-1".
- **T40 absorbs G26:** header line 2288 `[G21, G26]`; body line 2297 "incl. G26 BW02/minimum-version rule"; `Out:` line 2309 explains the G26 absorption; References line 2337 carries "goals.md ### G26 — problem framing for the BW02/minimum-version regression class (absorbed into this task's lint surface)".
- **T44 dep re-pointing:** header line 2354 `Dependencies: [Task 17, Task 40]` matches round-02 brief; `Out:` line 2370 documents F01/F02/F03/F04 as moot with disposition rationale.
- **Dropped task slots:** Slice 1.4 listing (lines 67–74) shows T18/T22/T23 gaps; Slice 1.7 listing (lines 96–100) shows T41/T42/T43 gaps; Slice 1.3 note (line 60) explains T12 placement under Slice 1.4. Overview line 17 enumerates all six gaps with rationale.
- **No live dependency edges** in any remaining task point at dropped T18/T22/T23/T41/T42/T43. Cross-slice notes line 102 explicitly documents that "G24-F02 prose consolidation and G25 top-level invariant — originally planned as T22 / T18 in this chain — were dropped per design.md ## G24 and ## G25 absorbing those goals into CD-1 with no separate v0.7.2 task".
- **T17 (G23) Out: bullet** at line 1068 explicitly explains the dropped top-level dispatch-routing invariant: "dropped per design.md ## G25 (absorbed by CD-1; no separate v0.7.2 task ships under G25)".

No stale cross-references to deleted tasks or absorbed goals remain in any live dependency edge, body bullet, or References block.

## Result

No scope findings. Plan.md scope and OWNS/DEFERS boundary are clean for round-03 broaden review.

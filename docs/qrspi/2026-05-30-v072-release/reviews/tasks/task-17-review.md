---
task: 17
terminal_status: clean-after-cap-bend
cap_bends: 0
fix_cycles: 3
accepted_with_issues: false
---

# Task 17 Review

**Goal:** G23 — documentation hardening of the `model_routing:` schema in
`skills/using-qrspi/SKILL.md`: add the `model_routing:` row to the
"Fields that affect pipeline behavior (must be validated)" validation table,
and add fail-loud back-pointer sentences from the two enforcement paragraphs
(none-halt para, missing-block para) back to that validation table by literal
heading text. Pinned by bats. Doc-only task (no production logic, no new types).

**Code artifacts:**
- `skills/using-qrspi/SKILL.md` (THE production subject). At terminal HEAD `1d0778b`
  (UNCHANGED since impl `99bbe46` — all three fixes are test-only):
  - Validation-table `model_routing:` row (L615) under
    `### Fields that affect pipeline behavior (must be validated)` — names the
    per-vendor five-tier map shape (per CD-1), cross-refs the schema heading
    `` `model_routing:` `` block and the fail-loud heading
    `Missing `model_routing:` block in `config.md``.
  - Two back-pointer sentences: none-halt paragraph (L466) and missing-block
    paragraph (L512), each appending "This required block is enumerated in the
    validation table at `### Fields that affect pipeline behavior (must be
    validated)`."
- `tests/unit/test-config-model-routing.bats` (THE test surface). New block
  "Validation-table model_routing: row + fail-loud back-pointer cross-links"
  (~L728–792): 6 bats assertions covering TE-1..TE-4 + delegating TE-5 to the
  pre-existing missing-block test. 68/68 GREEN at `1d0778b`.

**Dual reviewers:** Claude (`claude-sonnet-4.6`) + Codex (`gpt-5.3-codex`) every
round. Per-round verbatim findings + `.clean.md` sentinels persisted under
`reviews/tasks/task-17/round-NN/`. Codex is chat-only (cannot write to disk via
Task dispatch) — its findings/sentinels are orchestrator-persisted; some Claude
reviewers also returned chat-only and were orchestrator-persisted (verified disk
each round). This log summarizes convergence; the round dirs are the verbatim record.

## SHA chain

Per-task base commit = `f42e4a7` (task-16 terminal tip / stage-after-W11 line).
All rounds broaden-default the diff against `f42e4a7` (per-task worktree-relative).

| Stage | Commit | Note |
|-------|--------|------|
| RED | `eab0380` | Failing tests authored |
| impl | `99bbe46` | Initial implementation (SKILL.md doc changes — FROZEN hereafter) |
| fix-1 | `93153a61` | round-01 — pin the none-halt back-pointer paragraph (test-only) |
| fix-2 | `e511d033` | round-02 — table-row anchoring of the count/extraction greps (test-only) |
| fix-3 | `1d0778b` | round-03 — first-column anchor (F-01 adoption); FINAL, current HEAD |

(round-04 was a clean review pass on fix-3 — no fix-4. Cap respected: 3 fix cycles.)

## Round summary

Each of the three fan-out rounds caught a distinct, successively-deeper robustness
gap in the *test pinning* that the prior gate missed — the production doc change
(SKILL.md) was correct from impl and never needed a fix.

- **R1 — spec gate caught a test-coverage gap.** The spec-reviewer fan-out found
  the none-halt back-pointer paragraph (SKILL.md L466) was added but NOT pinned by
  any bats assertion (only the missing-block paragraph was). fix-1 added the
  TE-4 assertion that pins the none-halt paragraph's back-link by literal heading
  text. Test-only.
- **R2 — dual-Codex correctness fan-out caught unanchored row greps.** Both Codex
  correctness reviewers (cq-codex, sf-codex) independently flagged that the
  row-matching greps used `^[[:space:]]*\|.*model_routing:` (a bare row-grep that
  could match across the whole row). fix-2 anchored to the table row. Test-only.
- **R3 — thoroughness (tc-claude) caught the next-level any-column gap (F-01).**
  After R2's anchoring, tc-claude (thoroughness) raised F-01 (LOW): the anchored
  grep still matched `model_routing:` in ANY column of the row, so a future
  value-cell mention of `model_routing:` could break the count==1 invariant
  (false-negative/false-positive latent risk). ADOPTED as fix-3: all four greps
  tightened to the first-column anchor
  `^[[:space:]]*\|[[:space:]]*\`?model_routing:\`?[[:space:]]*\|` (optional
  backticks + required trailing first-cell pipe). Verifier scored F-01 = 45
  (sidecar valid; HARD-GATE condition (a) presence-only — satisfied). Refined the
  anchor via rubber-duck before adopting; empirically: matches exactly 1 production
  row, rejects value-cell mentions. **F-02 (COSMETIC) DECLINED** — `.` wildcard vs
  literal `-` in the TE-2 shape regex; no functional benefit, falls under the
  user's "no substantive refactors" directive. Test-only.
- **R4 — final confirmatory pass (NO fix), unanimous CLEAN.** Full depth-required
  set: spec gate (both families) → correctness cq/sf/sec (both families) →
  thoroughness gt/tc/cs (both families). All 14 reviewers CLEAN, zero new findings.
  tc-claude explicitly confirmed F-01 (the R3 adoption) RESOLVED. gt-claude
  confirmed the unbroken G23 → task-17 DoD/TE → SKILL.md doc → bats chain.

## Terminal disposition

- **No accepted-with-issues findings.** Every kept finding (R1 coverage gap, R2
  row-grep, R3 F-01) was fixed; F-02 was an explicit declined-cosmetic.
- **tda SKIPPED** every round — doc-only task, no new types (no type declarations
  in Markdown prose or bats string assertions).
- **Cap respected — 0 cap-bends.** 3 fix cycles used (R1→fix-1, R2→fix-2,
  R3→fix-3), then a clean round-04 review pass. The standard 3-round fix cap held;
  no bend needed.

## Process findings (logged to plugin_issues backlog)

1. **Three successive fan-out rounds each caught a distinct robustness gap the
   prior gate missed** (R1 spec-gate: unpinned none-halt paragraph; R2 dual-Codex
   correctness: unanchored row grep; R3 thoroughness tc-claude: any-column
   anchoring gap). Strong validation of the layered spec-gate → correctness →
   thoroughness fan-out as *distinct* safety nets rather than redundant passes —
   each layer's blind spot was covered by the next.
2. **The implementer self-check + test-writer both missed the R1 none-halt
   coverage gap** — the task added two back-pointer paragraphs but the initial
   tests pinned only one. Caught by the spec gate. Plugin gap: test-writer /
   implementer self-check did not enumerate both DoD back-pointer sentences as
   separate assertions.
3. **R3 F-01 was a thoroughness-only catch on test robustness, not production
   correctness** — the production doc (SKILL.md) was correct from impl; all three
   fixes hardened the *test pinning*. Confirms thoroughness reviewers add value
   even on doc-only tasks where the production surface is trivially correct.
4. **Codex (and intermittently Claude) reviewers returned chat-only** — cq-claude
   and cs-claude in round-04 did not self-write their `.clean.md` sentinels despite
   `tools: Read, Write`. Orchestrator verified disk each round and persisted the
   missing sentinels manually. Consistent with the known ~50% Claude sentinel-write
   reliability pattern.

---
change_type: scope
severity: medium
score: 3
artifact: plan.md
location: "## Phase 1: v0.7.2 release → ### Phase 1 Acceptance Criteria, AC #2 (master fail-loud enumeration); ### Task 39 Definition of done + Test expectations"
---

## Summary

The round-05 AC #2 enumeration extension added T39's symlink-escape canonicalization halt and T19's `[second-reviewer-same-vendor]` halt, but AC #2 still omits **four other build-pipeline fail-loud halts that T39 explicitly requires in its own DoD and Test Expectations**. These are precisely the kind of seeded-regression invariant AC #2 is meant to bill — and one of them (the `${CLAUDE_SKILL_DIR}` halt) is already named as an acceptance fixture inside T39 itself. The master enumeration is therefore incomplete relative to the build-pipeline surface it claims to cover.

## Per-task DoD halts vs. AC #2 master enumeration

Cross-walking T39's `## Definition of done` against AC #2:

| T39 DoD fail-loud halt | T39 DoD line | T39 test fixture | AC #2 enumerated? |
|---|---|---|---|
| `!cat` target canonicalizes outside `$REPO_ROOT/` (symlink-escape) | "canonicalizes every `!cat` target path with `fs.realpathSync` … fails non-zero with a `resolves outside repository` diagnostic" | "Symlink-escape regression" | **Yes** (round-05 addition) |
| Include cycle with full cycle printed | "fail non-zero with file:line plus reason for … include cycles with full cycle printed" | "a deliberate include-cycle failure with the required diagnostics" | **No** |
| Malformed `!cat` directive | "fail non-zero with file:line plus reason for malformed `!cat` lines" | "Unit-test resolver failure cases for malformed `!cat` lines" | **No** |
| Missing `!cat` target | "fail non-zero with file:line plus reason for … missing targets" | "Unit-test resolver failure cases for … missing targets" | **No** |
| `${CLAUDE_SKILL_DIR}` occurrence in shipped files | "fail non-zero … for … any `${CLAUDE_SKILL_DIR}` occurrence in shipped files" | "a legacy `${CLAUDE_SKILL_DIR}` directive failure … with the required diagnostics" | **No** |

(Absolute / path-traversal includes and outside-root includes are subsumable under the symlink-escape canonicalization halt — same boundary check — so I'm not flagging those.)

AC #4 (the build-pipeline AC) covers the **positive** outputs ("all `!cat` directives are expanded", "`${CLAUDE_SKILL_DIR}` does not appear anywhere in the shipped tree", `git diff --exit-code` is empty) but does not assert that adversarial inputs are halted with diagnostics. AC #2 is the criterion that says "Every fail-loud invariant in the release fires loud on a seeded regression input", with an explicit enumeration. The four halts above are exactly that shape — adversarial input → non-zero exit + diagnostic — and one of them (`${CLAUDE_SKILL_DIR}`) is even called out as a release-level acceptance fixture in T39's own test expectations.

## Why this matters (security framing)

These four halts protect build-time integrity of the shipped plugin tree. Silent fallback on any of them is a release-integrity failure:

- **`${CLAUDE_SKILL_DIR}` halt**: prevents the legacy resolver token from shipping to hosts that won't expand it. Silent ship → runtime `!cat` directives reference a non-existent path on Copilot CLI → load-bearing skill content silently goes missing in production. This is the *primary* invariant that protects every other Slice 1.5 prompt-prose edit from regressing at install time.
- **Include-cycle halt**: prevents non-terminating expansion at build time, but more importantly prevents a partially-expanded ambiguous artifact from being committed. Silent fallback → build emits unexpected content or hangs CI.
- **Malformed `!cat` / missing-target halt**: prevents typo'd or stale include directives from being silently dropped or partially expanded. Silent fallback → reviewer-protocol or dispatch-prose snippet quietly vanishes from a shipped skill and the on-disk-write contract degrades to chat-only fallback at runtime (the exact failure G3/G6/G12 are designed to prevent).

These are fail-closed boundaries at the same security tier as the symlink-escape halt that round-05 *did* add. The release verification machinery shouldn't ship the symlink halt with a regression seed but ship the `${CLAUDE_SKILL_DIR}` halt without one in the AC #2 master list — the Test phase reads AC #2 as the bill of materials for seeded-regression coverage at phase boundary. If AC #2 is the authoritative cross-task seed list, a Test-phase implementer can mark AC #2 green without ever firing the `${CLAUDE_SKILL_DIR}` or include-cycle seed.

## Suggested AC #2 extension

Extend AC #2 (after the existing `tools/build-plugin.mjs` `resolves outside repository` clause, since these four halts live in the same script and surface the same diagnostic discipline) with the missing build-pipeline halts. Suggested wording, slotted at the end of the AC #2 bullet:

> … and `tools/build-plugin.mjs` `resolves outside repository` halt when a `!cat` target canonicalizes outside `$REPO_ROOT/` (symlink-escape exfiltration surface), `tools/build-plugin.mjs` include-cycle halt with the full cycle printed, `tools/build-plugin.mjs` malformed `!cat` directive and missing-target halts with `file:line` diagnostics, and `tools/build-plugin.mjs` `${CLAUDE_SKILL_DIR}` shipped-file halt when any built file under `build/` still contains the legacy resolver token — each produce non-zero exit with a diagnostic, never silent fallback.

(T39's Test Expectations already cover all four with regression fixtures, so no per-task DoD changes are needed — only the AC #2 master enumeration needs to be made consistent with what T39 already requires.)

## Out of scope for this finding (verified covered)

- T20 splitter halts ("missing flags / missing raw output / missing boundaries / write errors"): AC #2 item 1 ("splitter on adversarial Codex stdout") subsumes the missing/malformed-boundaries case, which is the canonical adversarial-input scenario. The other three are minor edge cases acceptable at per-task altitude.
- T19's "unknown host / missing default vendor / unknown vendor" halts: all share the `[second-reviewer-unavailable]` diagnostic prefix already enumerated by AC #2 item 6, so a single regression seed covers all four entry conditions.
- T12 / T13 round-prepare exit codes 10/11/12 and prior-round bookkeeping halts: operational-orchestration scoped, properly at per-task altitude rather than the AC #2 cross-task list.
- T24 invalid-`QRSPI_INTERACTION_MODE` halt: per-task scoped, no cross-task observability requirement.
- T16/T17 schema/validation-table halts: AC #2 already covers items 3 ("validation table on missing `model_routing:`") and 4 (`tier: none`).

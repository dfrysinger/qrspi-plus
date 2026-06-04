# Task 09 — Round 1 Fan-In Disposition

**Base commit:** `f5e5e2a` (T09 R1 implementer)
**Round:** 1
**Reviewers dispatched:** spec-claude (sonnet-4.6), spec-codex (gpt-5.3-codex)
**Gate status:** NOT CLEAN — fix-cycle required
**Fix-cycle budget:** R1 = 1 of 3 (this round)

## Findings

| Reviewer | ID | Severity | Class | Summary |
|----------|----|----|---|---|
| spec-codex | F01 | high | correctness | AC1-AC4 are doc-text greps only — verifier sidecar/clean-sentinel end-to-end flow is not actually exercised |
| spec-codex | F02 | medium | correctness | AC6 lacks "no aggregate verified-file header introduced" grep-absence assertion |
| spec-codex | F03 | medium | scope | `subagent_type` written to manifest though G3 (T11) owns it |
| spec-claude | F01 | medium | scope | Same scope overreach as codex F03 — broader scope concern (also `dispatch_spec`/`agent`/`mode`/`status` fields) |

## Convergence

- **codex F03 + claude F01:** Same defect — manifest entry exceeds T09 scope. Both reviewers flag `subagent_type` as G3/T11 territory. Claude additionally flags `dispatch_spec` nesting, `agent`, `mode`, `status` as overreach. Take Claude's broader fix.
- **codex F01 / F02:** Independent — claude did NOT raise either. On careful read of T09 spec lines 42-50, codex F01 is substantive: AC1-AC4 grep doc text; AC5 exercises manifest path only; the verifier sidecar end-to-end fixture test required by line 42 is genuinely absent.

## Disposition (3 fixes for R1 fix-cycle)

### Issue A — End-to-end verifier sidecar fixture coverage (codex F01)

Add a fixture-driven acceptance test under `tests/acceptance/v07-phase1/`:
1. Write a finding file `*.finding-F01.md` with frontmatter `actual_model: claude-opus-4.6` to a temp round-dir
2. Write the corresponding `*.finding-F01.score.yml` sidecar via the verifier prose contract (or simulate verifier behavior)
3. Assert sidecar frontmatter contains `actual_model: claude-opus-4.6` (verbatim copy)
4. Repeat with finding file omitting `actual_model:` → assert sidecar contains `actual_model: unknown`
5. Add `*.clean.md` sentinel variants (same two cases)

The intent is to verify the actual_model flow is enforceable, not just documented.

### Issue B — Aggregate verified-file header absence (codex F02)

Add to AC6 (or a new AC test): grep-absence assertion that `verified.md` (or any aggregate-header file) does NOT appear:
- In `agents/qrspi-finding-verifier.md` as an output path
- In `scripts/verifier-fan-in.sh` as an output target

This pins the unchanged-behavior contract.

### Issue C — Narrow manifest entry to T09 scope (codex F03 + claude F01)

In `scripts/run-codex-review.sh`'s `emit_dispatch_manifest_entry()`:
- Remove `subagent_type`, `agent`, `mode`, `status`, `dispatch_spec` nesting
- Keep only: `host`, `vendor`, `model` (the T09 in-scope authorised metadata)
- Acceptable to keep function name and `.dispatch-manifest.json` filename
- T11 will add the broader G3 provenance fields when it lands

Update AC5 (manifest test) to assert the narrowed payload shape.

## Budget tracking

- R1 fix-cycle: 1 of 3
- Remaining: 2 fix-cycles before terminal escalation

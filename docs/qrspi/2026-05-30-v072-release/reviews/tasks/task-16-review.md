---
task: 16
terminal_status: clean-after-cap-bend
cap_bends: 5
accepted_with_issues: false
---

# Task 16 Review

**Goal:** G22 — `scripts/_resolve-lib.sh` config-schema model_routing resolver
hardening: tier parse / precedence / lookup / fail-loud-on-malformed-config
(none-halt, empty-value-halt, non-readable-config-halt). The largest task in the
v0.7.2 release (model: opus).

**Code artifacts:**
- `scripts/_resolve-lib.sh` (G22 resolver). Guard sites at terminal HEAD `f42e4a7`
  (production frozen since fix-7 `89dac63`):
  - `agent_file` resolution (L85): `[ -n ] && [ -f ] && [ -r ]`
  - `resolve_tier` CONFIG_MD (L99): `[ -n ] && [ -f ] && [ -r ]`
  - `resolve_model` negated-halt (L142): `[ -z ] || [ ! -f ] || [ ! -r ]`
  - `_halt_unconfigured_tier` helper (~L50–59); empty-value HALT (~L167–176);
    `_validate_tier` (~L64–69); Layer-4 medium fallback (~L111–123).
  - Header notes: `trusted_path` enforcement is dispatch-site-owned (deferred D1);
    bash-3.2 compatible.
- `tests/unit/test-config-model-routing.bats` (~62 hermetic exec tests,
  BATS_TEST_TMPDIR + --separate-stderr; all GREEN at `f42e4a7`).

**Dual reviewers:** Claude (`claude-sonnet-4.6`) + Codex (`gpt-5.3-codex`) every
round. Per-round verbatim findings + `.clean.md` sentinels persisted under
`reviews/tasks/task-16/round-NN/`. Codex is chat-only (cannot write to disk via
Task dispatch) — its findings/sentinels are orchestrator-persisted. This log
summarizes convergence; the round dirs are the verbatim record.

## SHA chain

Per-task base commit = `2bb8d60` (stage-after-W11).

| Stage | Commit | Note |
|-------|--------|------|
| RED | `9949426` | Failing tests authored |
| impl | `4788c3a` | Initial implementation |
| fix-1 | `76c1873` | round-01 correctness |
| fix-2 | `5c6742e` | round-02 |
| fix-3 | `c148d78` | round-03 |
| fix-4 | `a43f95c` | round-04 |
| fix-5 | `fe25f09` | round-05 (cap-bend #1) |
| fix-6 | `ccc3d0a` | round-06 (cap-bend #2) |
| fix-7 | `89dac63` | round-07 (cap-bend #3) — `-f`/`-r` regression repair |
| fix-8 | `f42e4a7` | round-08 (cap-bend #4) — ID-hygiene test-name/comment; FINAL |

(round-09 was a clean review pass on fix-8 — no fix-9.)

## Round summary

Severity has been monotonically shrinking across the convergence tail:
round-05 CRITICAL → round-06 High/medium → round-07 Medium → round-08 Low →
round-09 CLEAN.

- **R1–R4:** initial implementation + spec/correctness convergence.
- **R5 (cap-bend #1) — CRITICAL caught by the spec-gate→correctness fan-out:**
  the `none`-tier halt path. The same-round fan-out after a CLEAN spec gate
  surfaced the critical none-halt bug; fixed in fix-5.
- **R6 (cap-bend #2) — dual-family empty-value:** both families independently
  flagged the empty `model:` value path falling through instead of halting.
  Fixed in fix-6 (added empty-value HALT ~L167–176).
- **R7 (cap-bend #3) — `-f`/`-r` regression INTRODUCED by fix-6:** fix-6's own
  guidance ("replace `-f` with `-r`") dropped the regular-file guarantee, letting
  a readable DIRECTORY pass the config guard (resolve_model halted with a
  misleading "unconfigured tier" diagnostic; resolve_tier fell to Layer-4 medium
  with a wrong cause). Single-family catch (sf-codex F01, verifier=70), but valid
  — root cause was the prior fix. fix-7 set `[ -f ] && [ -r ]` at all 3 guard
  sites + added 1 hermetic directory-as-CONFIG_MD regression test.
- **R8 (cap-bend #4) — ID-hygiene:** sf-codex confirmed R7's regression RESOLVED.
  cq-codex raised an ID-hygiene violation: the fix-7 regression test NAME embedded
  the literal forbidden reviewer-finding-ID token `R7-F01` (forbidden `R\d+-F\d+`
  family per implementer-protocol/SKILL.md:100; test-name surface per line 83).
  Cross-family disagreement: cq-claude false-cleared the same token. Adjudicated
  KEEP via the authoritative rule (cq-codex correct; verifier=97). fix-8 renamed
  the `@test` to drop `R7-F01` and reworded the comment's RED/GREEN narration to
  behavior-focused prose. Test-string only; zero production code.
- **R9 (final review pass, NO fix) — CLEAN:** proportionate convergence check on
  the fix-8 string increment. spec + cq, both families (4 reviewers). sf/sec
  WAIVED for this increment — see waiver rationale below. All 4 CLEAN: R8-F01
  (the `R7-F01` token) confirmed gone by the original raiser (cq-codex); rename
  confirmed cosmetic (assertions/logic unchanged) by both spec reviewers.

## Round-09 reviewer waiver (logged, not silent drift)

fix-8 is a pure test-name/comment string change (zero production code, zero
behavior/security surface). The round-09 convergence check dispatched spec
(both families) + code-quality (both families) = 4 reviewers. **silent-failure
and security reviewers were explicitly WAIVED for this increment** — there is no
error-handling or security surface in a test-name rename for them to assess. This
waiver is proportionate-rigor, not a skip of the P0 spec-gate→fan-out rule: the
spec gate cleared and triggered the cq fan-out in the same round. Production code
was last touched in fix-7 (`89dac63`), which received the full correctness
fan-out (sf + sec, both families) in round-08 — all CLEAN.

## Terminal disposition

- **No accepted-with-issues findings.** Every kept finding across R5–R8 was fixed.
- **tda SKIPPED** every round — the task introduces no new types (shell library;
  no type declarations).
- **Deferred to v0.7.3 backlog (NOT fixed this task):**
  - **D1** — `trusted_path` enforcement in the lib (dispatch-site-owned; the lib
    header documents this boundary explicitly).
  - **D2** — full block-scoped YAML parsing (current parse is line-oriented).
  - **D3** — sf-codex round-05 "remove `2>/dev/null`" (declined; covered by F02).
  - **D4** — duplicate-tier-row detection.

## Cap-bend record

Fix cycles bent to 5 (R5 critical, R6 dual-family empty-value, R7 regression
repair, R8 ID-hygiene; R9 was a review-only pass with no fix). Cap was 3. Each
bend justified by a genuine dual-family or definitive single-family finding with
monotonically shrinking severity. Authorized under the user's blanket "cap bend
as needed to get good quality final result," caveated by "substantive refactors
doesnt sound good" — every fix was additive guard / test-only / string / comment,
no refactor.

## Process findings (logged to plugin_issues backlog)

1. **The spec-gate-CLEAN → correctness-fan-out rule caught issues across FOUR
   consecutive rounds** (R5 CRITICAL, R6 dual-family empty-value, R7 `-f`/`-r`
   regression, R8 ID-hygiene). Very strong validation of the P0 rule.
2. **fix-6's own `-f`→`-r` fix INTRODUCED the R7 regression**, caught by the
   same-round fan-out — validates running the fan-out even on small additive
   fixes.
3. **fix-7's implementer ID-hygiene self-check missed an `R\d+-F\d+` token it
   authored in a test name** (implementer-protocol pre-DONE self-check, line 153,
   should have caught it). Plugin gap.
4. **cq-claude false-cleared the same ID-hygiene token cq-codex caught** — the
   dual-family review prevented a miss; cq-claude missed that `R\d+-F\d+` is its
   own forbidden family distinct from the F-N framework-vocab carve-out.

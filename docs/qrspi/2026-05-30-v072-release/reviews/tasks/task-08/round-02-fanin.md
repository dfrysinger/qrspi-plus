# T08 Round 02 — Fan-In Disposition

**Status:** FINDINGS — dispatching R2 fix-cycle (2 of 3 budget)
**Findings:** 13 across 6 reviewers (4 HIGH, 6 MEDIUM, 3 LOW)
**Pattern:** R2 broadened beyond R1's spec-tautology defect. R1 fix successfully unblocked spec gates (CLEAN R2). R2 fan-out uncovered substantive structural issues in the verifier prose, the fan-in script, and the fixture realism — none would block tests, but several have real security implications.

## Convergence Map

| Issue | Reviewers | Disposition |
|---|---|---|
| **A: Citation grammar mismatch** (`path:line` in verifier prose vs. `#L` in reviewer-protocol + fixtures) | sec-codex F02, sf-codex F01, sf-codex F02 | **Fix in R2** — update verifier prose to canonical `#L` syntax (matches reviewer-protocol contract) |
| **B: Fixture-reason inconsistency** (TC5/TC6/TC7 reason strings reference old fake files) | cq-claude F01, cq-codex F01 | **Fix in R2** — ~6 LOC update to 3 reason strings |
| **C: Informational carve-out scope ambiguity** ("patterns below" ambiguous re: Cite Check) | sec-claude F01 | **Fix in R2** — disambiguate prose |
| **D: Prompt-injection via referenced_files reads** (no untrusted-data guard on cited file contents) | sec-codex F01 | **Fix in R2** — add untrusted-data guard to verifier prose |
| **E: Fan-in scope/intent arm has no HALLUCINATED gate** (score:0 findings slip through to kept-findings.txt) | sf-claude F01 | **Fix in R2** — promote `score==0` drop above the change_type case (verified against `scripts/verifier-fan-in.sh:260-285`); add regression test |
| **F: `reason:` field absent from step-6 success-template** (only in prose, breaks greppability assurance) | sf-claude F02 | **Fix in R2** — add `reason:` to the YAML template |
| **G: Tests don't invoke verifier** (architectural; same concern raised + accepted in R1) | sec-codex F03, sec-claude F02 | **Defer to v0.7.3** — verifier behavioral contract test requires LLM-stub framework not in v0.7.2 scope. The accepted architectural compromise from R1 still holds. |
| **H: `printf` format-string latent risk** (currently safe; risk only on future refactor) | sec-claude F03 | **Defer to v0.7.3** — add comment when touching the helper |
| **I: Bare bash assertions cryptic on empty input** (test diagnostic UX) | sf-claude F03 | **Defer to v0.7.3** — low severity, doesn't affect correctness |

## R2 Fix-Cycle Scope

Touch:
1. `agents/qrspi-finding-verifier.md` — three prose updates:
   - Citation grammar: `path:line` → `path#Lstart-Lend` (matches reviewer-protocol)
   - Informational carve-out: scope-disambiguate to exclude Cite Check
   - Step 3.5 Cite Check: add untrusted-data guard for `referenced_files`/`upstream_paths` reads
   - Step 6 success template: add `reason:` field
2. `scripts/verifier-fan-in.sh` — promote `score==0` HALLUCINATED drop above the change_type case
3. `tests/acceptance/v07-phase1/test-phase1-acceptance.bats`:
   - Update TC5/TC6/TC7 reason strings to match new README.md citations
   - Update TC5 citation: `README.md#L99999-L99999` (already canonical `#L` after fix-A)
   - **Add TC9** (HALLUCINATED scope/intent regression — covers Issue E)

## v0.7.3 Backlog Additions

- **Verifier behavioral contract test** (Issue G): a "spec-shape" test that asserts step-3.5 prose is present in `agents/qrspi-finding-verifier.md` and matches a contract template. End-to-end LLM dispatch testing is out of scope; spec-shape pin closes the regression vector for accidental prose deletion.
- **`printf` format-string defensive comment** (Issue H): when next refactoring `_t8_write_finding_pair`, document the body-as-argument-not-format-string invariant.
- **Bash test assertion diagnostics** (Issue I): refactor TC5/TC6/TC7 to use the same `|| { echo "..."; return 1; }` pattern as TC4.

## Budget Status

- R1 fix-cycle: 1 of 3 consumed (spec-tautology fix)
- R2 fix-cycle: dispatching now → 2 of 3 consumed
- Remaining: 1 fix-cycle. If R3 has any findings, R3 fix-cycle hits the cap.

## Dispatching

R2 fix-cycle implementer dispatched via fresh `Agent({ subagent_type: "qrspi-implementer", model: "claude-sonnet-4.6" })` with consolidated findings A-F + new TC9 spec.

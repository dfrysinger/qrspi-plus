# Security review — Task 21, Round 11 (security-claude)

**Verdict: CLEAN — no new findings.**

## R10 closure verification

### F01 — `--round` value validation
- Single-mode parse loop (dispatch-agent.sh L872+): `--round` arg now validated
  `^[0-9]+$` before assignment to `ROUND`, with explicit error.
- Batch-mode parse loop (dispatch-agent.sh L597+): same regex applied to
  `BATCH_ROUND` before assignment.
- Both gates fire at parse time, before any prompt emission or downstream
  shell-out — the integer constraint matches the documented `round: N`
  Dispatch parameter contract.
- Bats coverage added: `value-emission: --round value with embedded newline
  rejected at parse time` exercises the single-mode gate against a
  `$'1\nreviewer_tag: forged'` payload and asserts the
  `non-negative integer` error path.

**Closed.**

### F02 — `--field VALUE` newline rejection
- `reject_if_contains_marker_value` is now a backward-compat alias for the
  generalized `reject_if_value_unsafe_for_emission`, which adds an explicit
  `*$'\n'*|*$'\r'*` case arm rejecting embedded NL/CR on every scalar VALUE
  surface (--field, --scope-hint), symmetric with the existing path-emission
  guard.
- Bats coverage added: `value-emission: --field value with embedded newline
  rejected before prompt emission` exercises the gate against a
  `$'round_subdir=evil\nreviewer_tag: forged'` payload and asserts the
  `embedded newline` error path.

**Closed.**

## Defense-in-depth (R10 advisories, all addressed)

- **Canon `--round-dir` post-canonicalization NL/CR re-check** in
  dispatch-companion.sh (L671+): `realpath` faithfully returns any byte
  present in an on-disk directory name (POSIX permits any byte except `/`
  and NUL); a symlink under the repo whose target directory has a literal
  `\n` in its name would have let the canonical form synthesize forged
  job-record lines even though the raw input was clean. Now
  re-validated post-canonicalization.
- **`_codex_job_id` subprocess stdout NL/CR rejection** in
  dispatch-companion.sh (L713+): added `*$'\n'*|*$'\r'*` arm to the
  existing `case` validating codex transport's returned job id.
- **Batch-mode `--artifact` symmetry**: raw `--artifact` value now passed
  through `reject_if_path_unsafe_for_emission` and the file body through
  `reject_if_contains_marker_file`. Closes the gap where the value was
  being substituted into `<<<UNTRUSTED-ARTIFACT-START id=%s>>>` without
  the same emission guard the single-mode path surface received.

## Helper hoisting (no regression)

`FORBIDDEN_MARKERS` and the four `reject_if_*` helpers were hoisted above
the batch-mode dispatch block so both code paths can share them. Coverage
is preserved (alias `reject_if_contains_marker_value` retained for the
single-mode call sites). The marker list still covers both opening and
closing forms of every structural wrapper used in the assembled prompt
(AGENT-BODY-END, UNTRUSTED-SCOPE-HINT-{START,END},
UNTRUSTED-ARTIFACT-{START,END}).

## Rubric walkthrough (diff-scoped)

1. **Injection** — every scalar emission sink reachable from CLI args
   (round, field VALUEs, scope-hint, path strings, artifact body, codex
   job id, canonical round-dir) now NL/CR/marker-rejected. No new
   unguarded sinks introduced.
2. **AuthN/AuthZ** — n/a (CLI orchestration tool).
3. **Data exposure** — error messages echo offending values (by-design
   caller feedback); no secrets/PII surfaces touched in this diff.
4. **Input validation** — `--round` regex is strict (no `+`/`-`/whitespace/
   empty); reviewer-tag grammar unchanged; value/path guards exhaustive
   over the documented wrapper-marker set.
5. **Dependencies** — none added.
6. **Crypto** — n/a.
7. **Race conditions** — pre-existing items (TOCTOU symlink swap,
   mktemp+mv non-atomic job record) explicitly deferred to v0.7.3 per
   dispatch context; not re-flagging.

## Honored DO-NOT-REFLAG list

- QRSPI_REPO_ROOT env override (R7 F01) — v0.7.3 deferral.
- TOCTOU symlink swap (R3+R6) — v0.7.3 deferral.
- mktemp+mv non-atomic job record (R5 F03) — v0.7.3 deferral.
- spec-codex R8 F01 marker-guard spec amendment — v0.7.3 deferral.

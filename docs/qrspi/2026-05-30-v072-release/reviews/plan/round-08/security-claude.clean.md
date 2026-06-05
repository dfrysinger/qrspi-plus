# Plan Security Review — Round 08 (broaden vs main)

**Reviewer:** security-claude
**Artifact:** docs/qrspi/2026-05-30-v072-release/plan.md
**Scope:** full diff against main (broaden mode)

## Verdict

**CLEAN — no security findings.**

## Surface traced

This round is a broaden-vs-main full-diff review. I traced every task whose
spec touches a security-relevant surface (error handling, external input,
provenance, exfil boundaries, config validation, fail-loud invariants):

- T02 (verifier-fan-in.sh) — fail-closed on missing/out-of-enum `change_type`,
  missing sidecar, wrong sidecar extension, unparseable score; named audit
  halt cause per failure mode.
- T03 (reviewer disk-write contract) — wrong-channel emits
  `expected tag produced no output`; no silent acceptance of chat-only output.
- T04/T05 (`change_type` field + enum drift) — distinct `missing_change_type`
  vs `change_type_out_of_enum` halts; explicit prohibition on
  silently-default-kept / silently-kept / silently-dropped behavior.
- T11 (dispatch-manifest provenance) — records resolved
  `subagent_type/host/vendor/model/prompt_file`; atomic + append-safe under
  repeated invocations and multiple reviewer tags.
- T12 (round-prepare.sh + await-round.sh) — distinct exit codes 10/11/12 for
  SHA failures; non-git workspace returns documented no-diff status
  `without fabricating a diff path or scope hint` (callers can distinguish
  no-diff from failed-diff); `await-round.sh` never echoes captured reviewer
  payloads or prompt bodies — bounded output is a tested DoD.
- T13 (per-task review orchestration) — prior-round bookkeeping validation
  rejects missing/malformed `round-(NN-1)-commit.txt` and missing/empty
  prior scope set; reviewer dispatch cannot proceed from stale bookkeeping.
- T16 (`model_routing` schema + `_resolve-lib.sh`) — `tier: none` halts loud;
  missing/malformed `model_routing:` fails through shared
  config-validation-procedure with repair-or-abort guidance; the
  hardcoded-medium-with-loud-warning fallback is defense-in-depth behind
  the validation surface (unreachable in normal operation; warning surfaces
  the abnormal bypass — not raising as a finding).
- T19 (second-reviewer-available.sh + _host-detect.sh) — unknown host /
  missing default vendor / unknown vendor / unavailable vendor all halt with
  `[second-reviewer-unavailable]`; same-vendor collision halts with
  `[second-reviewer-same-vendor]` at matrix-lookup time.
- T20 (dispatch script rename + splitter) — `third-party-finding-splitter.sh`
  fails loud for missing flags, missing raw output, missing boundaries, or
  write errors; companion `await` writes raw output to `<round-dir>/.dispatch/`
  without echoing payload to stdout/stderr.
- T21 (G16 path-filter exfil hardening) — canonicalizes `--subject-code`,
  `--artifact-body`, `--companion`, `--diff-file` with `realpath`/`readlink -f`
  before any `cat` read or prompt emission; symlink-out-of-repo and
  readable-out-of-repo `--companion` regression tests required; implementer
  allowlist for `scripts/dispatch-agent.sh` and `scripts/dispatch-companion.sh`.
- T24 (detect-interaction-mode.sh) — invalid `QRSPI_INTERACTION_MODE` exits
  non-zero and `does not silently coerce`; stdout-only (no file writes);
  encapsulation rule restricts host literals to the script + its dedicated
  tests.
- T34 (Plan post-approval split) — hash mismatch / missing header /
  malformed header all halt with exact diagnostics; existing
  `tasks/task-NN.md` files untouched on conflict; hand-edit preservation
  when stored hash still matches current plan.md block.
- T35 (G10 reviewer-protocol anti-fabrication) — `CONTRACT-CONFLICT:` single-
  line exit routes to operator intervention; conflict-prefix path
  `does not parse findings, synthesize a clean sentinel, fire the
  schema-violation guard, auto-repair, consume a tag emission budget, or
  advance the round counter`.
- T39 (G32 plugin build pipeline) — strict whole-line bare-relative `!cat`
  grammar; cycle detection with full cycle printed; canonicalize-with-
  `fs.realpathSync`-before-byte-read symlink-escape guard mirroring T21
  shape; `${CLAUDE_SKILL_DIR}` in shipped files halts; symlink-escape
  regression fixture required with `resolves outside repository` diagnostic.
- T40 (G21 bats short-circuit) — body-assertion-guard lint with `file:line`
  diagnostics; BW02 minimum-version rule shares the corpus walk.
- T44 (G24-F05 anti-pattern pin regex hardening) — semantic regex family
  replaces brittle literal pins for silent-fallback prose; same-`@test`
  `$body` presence guard required.

## Authz scope

No endpoint, request-handling, or auth-gated resource surface in this
release. Auth/Authz category N/A.

## Defaults

No insecure defaults found. The one borderline case (T16
hardcoded-medium-with-loud-warning) is gated behind T16's shared
config-validation-procedure that fails loud on missing/malformed
`model_routing:`, making the fallback an unreachable defense-in-depth path
in normal operation rather than a primary substitution behavior.

## Round-07 E1 follow-up

Round-07's E1 fix was a test-expectations addition to T25 (one grep audit
bullet pinning that rules-file references use the exact anchor phrase
`skills/_shared/prompt-design-rules.md (resolved from the installed plugin
path per host convention)`). Pure test-coverage strengthening; introduces
no security surface change and no defect.

## Dropped-finding hygiene

Per priming, I did not re-raise sec-codex.F01 (absolute/path-traversal
halt on `!cat`). T39's DoD already requires canonicalize-before-byte-read
and an explicit symlink-escape regression with the `resolves outside
repository` diagnostic — matching my prior r7 defense that path-traversal
escaping the repo trips canonicalization before any byte enters `build/`,
and traversal that stays inside the repo is not security-relevant.

The build-time bulk copy operation (non-`!cat` file copy into `build/`) is
symmetric to the dropped finding's threat model: a malicious contributor
would have to commit a symlink in the source tree, visible in PR review.
Holding to the prior dropped-finding defense rather than re-raising.

## Net

No new security findings.

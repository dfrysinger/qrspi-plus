# Security review — Task 39, round 4 (security-claude)

**Verdict: clean.**

## Scope

Tests-only diff (+138/-12). Production code (`tools/build-plugin.mjs`,
`tools/g4-section-anchor-refresh.sh`, etc.) is unchanged from R3. Changes
are confined to:

- `tests/acceptance/v07-phase1/test-cache-retirement-invariants.bats`
  (tightened `grep -RF` → `grep -RnE` invocation-form regex; dropped
  `--exclude-dir=docs`)
- `tests/acceptance/v07-phase1/test-phase1-acceptance.bats` (two new
  resolver-against-fixture acceptance tests)
- `tests/unit/test-build-gate.bats` (replaced GNU-only `grep -U $'\r'`
  CR check with portable `tr -d '\r'` size-diff; three new denylist
  tests)
- Three doc files under `docs/qrspi/2026-05-27-v071-hardening/fixes/...`
  changed `scripts/g4-section-anchor-refresh.sh` → `tools/...` (path
  rename docs-sync, no executable surface).

## Attacker-reachability assessment

**Fixture "secrets" are non-credentials.** The denylist tests plant:
- `SECRET=value` into `$root/skills/sample/.env`
- The literal string `BEGIN OPENSSH PRIVATE KEY\n` (no actual key
  material) into `$root/scripts/id_rsa`
- The literal header `-----BEGIN CERTIFICATE-----\n` (no key material)
  into `$root/.claude-plugin/server.pem`

These are basename-only triggers for `isSecretBasename()` — the file
*content* is decorative. Nothing exploitable was committed to the repo;
the bytes are written at test runtime under `$BATS_TEST_TMPDIR`
(per-test ephemeral, cleaned by bats), never under `$REPO_ROOT`.

**Shell-construction in new tests is closed.** The `bash -c` invocations
interpolate `$REPO_ROOT`, `$root`, `$fixture`, `$fa`, `$fb` — all
test-controlled paths derived from `$BATS_TEST_TMPDIR` or static
`tests/fixtures/...` paths. No attacker channel reaches these
substitutions. Single-quoting around the interpolated paths inside the
double-quoted `bash -c` argument is the standard bats pattern and is
safe given the controlled inputs.

**Grep regex tightening is a safety improvement, not a regression.** The
new pattern `(bash[[:space:]]+|\./)scripts/render-skill\.sh` is stricter
than the prior literal `grep -F`, reducing false negatives for stale
callers (the security-relevant direction). Dropping `--exclude-dir=docs`
*increases* coverage against retired-path references in shipped docs.

**`tr -d '\r'` portability fix is purely a test-correctness improvement.**
The previous `grep -U` was vacuously passing on BSD grep, masking
potential CR-byte leakage in built artifacts. The new size-diff check
genuinely asserts the property.

## Categories reviewed (all clean for this diff)

1. Injection — no new attacker-reachable sinks.
2. AuthN/AuthZ — N/A (no auth surface).
3. Data exposure — fixture "secrets" are placeholder strings under
   tmpdir; no real credentials introduced.
4. Input validation — tests assert resolver rejects malformed input
   (cycles, legacy tokens, denylisted basenames); strengthens posture.
5. Dependency risks — no new deps.
6. Cryptography — N/A.
7. Race conditions — `$BATS_TEST_TMPDIR` is per-test-isolated.

No findings.

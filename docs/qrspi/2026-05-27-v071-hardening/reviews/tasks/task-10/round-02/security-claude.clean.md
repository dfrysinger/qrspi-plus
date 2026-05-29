# Security review — Task 10 round 02 — CLEAN

**Reviewer:** security-claude
**Round:** 02
**Verdict:** CLEAN (no security findings)

## Scope reviewed

R2 is a doc-only fix to the R1 schema contradiction in
`skills/using-qrspi/SKILL.md`:

- `skills/using-qrspi/SKILL.md` L448–460: replaced the legacy
  `role → <provider-name>/<model-id>` schema example + opener with the
  v0.7.1 host→tier→model shape (`claude-code:` / `copilot-cli:` sub-mappings,
  four tier rows each, versioned model IDs).
- `skills/using-qrspi/SKILL.md` L494 (Precedence chain step 3): renamed
  "role lookup" → "host/tier lookup" with `detect_host` + tier-name
  resolution wording.
- `skills/using-qrspi/SKILL.anchors.json`: line-range regen reflecting the
  +9-line shift downstream of the schema replacement.
- `tests/unit/test-config-model-routing.bats`: two assertion updates —
  precedence-chain wording flip + retirement of the fail-loud
  unknown-provider doc assertion (replaced with absence-pins for the
  retired phrases).
- `tests/unit/test-using-qrspi-vocab.bats` (new): pins the schema
  vocabulary against future regression to the old role-based shape.

## Security analysis

### 1. Retired "fail-loud unknown provider" contract — silent-failure surface?

The retired doc sentence asserted that an unknown `<provider-name>` in a
`<provider-name>/<model-id>` value triggers a config-validation error. In
the new schema, `model_routing` **values are concrete versioned model IDs**
(`claude-haiku-4.5`, etc.), not `<provider>/<model>` tuples. The unknown-
provider failure mode has no syntactic representation in the new shape:
there is no provider name to validate inside `model_routing:` values, so
no downstream validator can silently accept-or-reject one. The
`providers:` block remains a separate concern handled elsewhere. The
fix-task's claim that the retired contract "has no surface in the new
schema" is correct. No new silent-failure surface is introduced by the
doc change.

### 2. New pin test — over-permissive matches that could mask regressions?

`tests/unit/test-using-qrspi-vocab.bats` uses `grep -F` fixed-string
assertions:

- **Negative pins** (`Maps role names to provider-plus-model pairs`,
  `` `model_routing:` role lookup ``) — full-phrase, tightly scoped. Hard
  to false-negative around.
- **Positive pins** (`claude-code:`, `copilot-cli:`, `haiku: claude-haiku-4.5`)
  — presence-anywhere greps. Intentionally loose to survive incidental
  wording polish. In the worst case, a future regression could keep these
  strings present in a "deprecated, do not use" notice while reverting the
  actual schema body — but the companion precedence-chain assertion in
  `test-config-model-routing.bats` and the negative pins here would still
  catch that scenario. No security-relevant masking risk.

### 3. Auth / secrets / injection / path traversal

None of these surfaces are touched. No code paths, no shell, no network,
no user input, no filesystem writes. Test-harness `grep` against a
repo-internal file is guarded by `require_repo_root` and operates on a
known-path constant (`$REPO_ROOT/skills/using-qrspi/SKILL.md`); no
attacker-controllable path component.

### 4. Dependency / cryptography / race conditions

Not applicable to a doc + test diff.

## Verdict

CLEAN — no security findings.

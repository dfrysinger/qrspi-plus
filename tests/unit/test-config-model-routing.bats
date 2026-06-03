#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
#
# T07 Slice 1 unit pin — config model_routing precedence + trusted_path
# short-circuit + legacy-config warning + fail-loud provider-resolution +
# role-resolution chain (consumes T06 `model_role:` agent frontmatter).
#
# Pin shape: the runtime resolution logic lives across the orchestrator and
# the dispatcher (T03). The user-observable contract is documented prose in
# skills/using-qrspi/SKILL.md (precedence chain, trusted_path short-circuit,
# legacy-config warning, fail-loud provider lookup, validators contract).
# This file pins that prose so a silent rewrite of the contract fails loud,
# AND verifies the layer-1a/1b tie-break + role-resolution fallback via
# co-located fixture pairs that exercise both resolution outcomes in one
# observable test so the tie-break cannot silently pass with split fixtures.
#
# Bash 3.2 portable.

load '../helpers/skill-markdown'

# ---------------------------------------------------------------------------
# H4 section extractor — the shared helper supports H2/H3 only, but the
# routing/trusted_path/legacy-config/validators/precedence-chain prose lives
# under H4 headings. Extract the lines between an H4 anchor and the next
# H1-H4 boundary. Fails loud on missing anchor or empty extract.
# ---------------------------------------------------------------------------
_extract_h4() {
  local file="$1" text="$2"
  local target="#### $text"
  local out
  out="$(awk -v target="$target" '
    BEGIN { inside=0; found=0 }
    {
      if (inside == 1) {
        # H1-H4 boundary terminates the section.
        if ($0 ~ /^#{1,4} /) { inside=0; next }
        print $0
        next
      }
      if ($0 == target) { inside=1; found=1; next }
    }
    END { if (found == 0) exit 1 }
  ' "$file")" || { echo "h4 anchor not found: $target in $file" >&2; return 1; }
  if [ -z "$out" ]; then
    echo "h4 extract empty: $target in $file" >&2
    return 1
  fi
  printf '%s\n' "$out"
}

setup_file() {
  require_repo_root
  USING="$REPO_ROOT/skills/using-qrspi/SKILL.md"
  IMPLEMENT="$REPO_ROOT/skills/implement/SKILL.md"
  # G22 / T16 additions
  CONFIG_MD="$REPO_ROOT/docs/qrspi/2026-05-30-v072-release/config.md"
  RESOLVE_LIB="$REPO_ROOT/scripts/_resolve-lib.sh"
  VALIDATION_PROC="$REPO_ROOT/skills/_shared/config-validation-procedure.md"
  export USING IMPLEMENT CONFIG_MD RESOLVE_LIB VALIDATION_PROC
}

# ---------------------------------------------------------------------------
# Tier-precedence chain: the four tier-resolution layers named in order in
# using-qrspi prose (G22 / design.md CD-1; mirrors scripts/_resolve-lib.sh
# resolve_tier). The retired per-task/host-tier model: chain is gone.
# ---------------------------------------------------------------------------

@test "precedence chain: layer 1 (--tier-override) named in using-qrspi" {
  out="$(_extract_h4 "$USING" "Precedence chain")"
  [[ "$out" == *"--tier-override"* ]]
}

@test "precedence chain: layer 2 (agent tier: frontmatter) named in using-qrspi" {
  out="$(_extract_h4 "$USING" "Precedence chain")"
  [[ "$out" == *"tier:"* ]]
  [[ "$out" == *"frontmatter"* ]]
}

@test "precedence chain: layer 3 (default_tier:) named in using-qrspi" {
  out="$(_extract_h4 "$USING" "Precedence chain")"
  [[ "$out" == *"default_tier:"* ]]
}

@test "precedence chain: layer 4 (hardcoded medium with loud warning) named in using-qrspi" {
  out="$(_extract_h4 "$USING" "Precedence chain")"
  [[ "$out" == *"medium"* ]]
  [[ "$out" == *"warning"* ]]
}

@test "precedence chain: retired per-task model: / host-tier layers are gone" {
  # G22 migration: the old per-task model: → hardcoded dispatch-site model: →
  # model_routing: host/tier lookup → agent-bundled default chain is replaced
  # by the tier-precedence chain. Residue of the retired chain fails CI here.
  out="$(_extract_h4 "$USING" "Precedence chain")"
  c=$(grep -c "Per-task" <<<"$out" || true)
  [ "$c" -eq 0 ]
  c=$(grep -c "host/tier lookup" <<<"$out" || true)
  [ "$c" -eq 0 ]
  c=$(grep -c "Hardcoded dispatch-site" <<<"$out" || true)
  [ "$c" -eq 0 ]
}

# ---------------------------------------------------------------------------
# trusted_path short-circuit: short-circuit semantics + both forms
# (agent-file path AND role-name string) documented.
# ---------------------------------------------------------------------------

@test "trusted_path: short-circuit semantics documented" {
  out="$(_extract_h4 "$USING" '`trusted_path:` block')"
  [[ "$out" == *"short-circuit"* ]]
}

@test "trusted_path: agent-file-path form documented" {
  out="$(_extract_h4 "$USING" '`trusted_path:` block')"
  [[ "$out" == *"agent"*".md file"* ]] || [[ "$out" == *"agent-file path"* ]]
}

@test "trusted_path: role-name form documented" {
  out="$(_extract_h4 "$USING" '`trusted_path:` block')"
  [[ "$out" == *"role name"* ]] || [[ "$out" == *"Role name"* ]]
}

# ---------------------------------------------------------------------------
# Missing-model_routing: fail-loud repair-or-abort when the block is absent
# from config.md (G22 / design.md CD-1) — consistent with the shared
# config-validation procedure (missing AND malformed both fail loudly).
# ---------------------------------------------------------------------------

@test "missing-model_routing: documented as a loud validation failure (not a one-time warning)" {
  out="$(_extract_h4 "$USING" 'Missing `model_routing:` block in `config.md`')"
  [[ "$out" == *"fails loudly"* ]] || [[ "$out" == *"fail loudly"* ]] || [[ "$out" == *"validation fail"* ]]
}

@test "missing-model_routing: repair-or-abort guidance present, no backfill/one-time-warning language" {
  out="$(_extract_h4 "$USING" 'Missing `model_routing:` block in `config.md`')"
  [[ "$out" == *"Repair"* ]] || [[ "$out" == *"repair"* ]]
  [[ "$out" == *"Abort"* ]] || [[ "$out" == *"abort"* ]]
  c=$(grep -ci "one-time\|once per session\|backfill\|in-memory" <<<"$out" || true)
  [ "$c" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Fail-loud provider resolution: unknown provider in model_routing: halts.
# ---------------------------------------------------------------------------

@test "provider resolution: unknown provider name no longer documented under model_routing: (schema retired)" {
  # T10 R1 fix (schema replacement): the v0.7-era model_routing: schema
  # used `<provider-name>/<model-id>` values, and that schema's doc body
  # carried a fail-loud "config validation error / halts and reports the
  # unknown provider" sentence for unknown-provider references. v0.7.1
  # retired the role→provider/model schema entirely in favor of the
  # host→tier→model shape; provider names are no longer keyed off
  # model_routing: values, so that specific fail-loud contract has no
  # surface to assert on in the new schema doc.
  #
  # Pin the absence of the retired wording so a future revert of the
  # schema would fail loud here as well as in test-using-qrspi-vocab.bats.
  out="$(_extract_h4 "$USING" '`model_routing:` block')"
  [[ "$out" != *"halts and reports the unknown provider"* ]]
  [[ "$out" != *"<provider-name>/<model-id>"* ]]
}

# ---------------------------------------------------------------------------
# model_role: routing key retired release-wide (G22). The legacy role-keyed
# routing field no longer drives any dispatch and must not appear in the
# using-qrspi routing prose.
# ---------------------------------------------------------------------------

@test "model_role: retired — not referenced in using-qrspi routing prose" {
  c=$(grep -c "model_role:" "$USING" || true)
  [ "$c" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Tier-order observation in the SINGLE shared Precedence chain section.
#
# Contract: --tier-override (layer 1) wins; the chain falls through agent
# tier: → default_tier: → hardcoded medium. The ordering must be observable
# from the one section so a rewrite that reorders or drops a layer fails loud.
# ---------------------------------------------------------------------------

@test "tier order: --tier-override precedes default_tier: in the precedence chain" {
  out="$(_extract_h4 "$USING" "Precedence chain")"
  override_line="$(printf '%s\n' "$out" | grep -n -- "--tier-override" | head -1 | cut -d: -f1)"
  default_line="$(printf '%s\n' "$out" | grep -n "default_tier:" | head -1 | cut -d: -f1)"
  [ -n "$override_line" ]
  [ -n "$default_line" ]
  [ "$override_line" -lt "$default_line" ]
}

@test "tier order: all four tier layers co-located in the precedence chain section" {
  out="$(_extract_h4 "$USING" "Precedence chain")"
  [[ "$out" == *"--tier-override"* ]]
  [[ "$out" == *"default_tier:"* ]]
  [[ "$out" == *"medium"* ]]
}

# ---------------------------------------------------------------------------
# Tier-to-(vendor,model) co-location: the resolved tier is looked up in the
# model_routing: block. Both halves (tier resolution + model_routing: lookup)
# must be observable so a regression cannot silently pass.
# ---------------------------------------------------------------------------

@test "precedence-chain co-location: tier resolution AND model_routing: lookup co-located in precedence chain" {
  out="$(_extract_h4 "$USING" "Precedence chain")"
  [[ "$out" == *"model_routing:"* ]]
  [[ "$out" == *"tier"* ]]
}

# ===========================================================================
# G22 / T16 additions — five-tier vendor-neutral schema, _resolve-lib.sh
# resolver behavior, and config-validation-procedure.md.
# ===========================================================================

# ---------------------------------------------------------------------------
# config.md — five-tier vendor-neutral model_routing: schema
# Test expectation: Inspect config.md for the five-tier vendor-neutral
# model_routing: block, default_tier: medium, and explicit extra-low: none row.
# ---------------------------------------------------------------------------

@test "config.md: five-tier model_routing: block is present" {
  # Test expectation: config.md documents the five-tier vendor-neutral model_routing: block
  run grep -q "^model_routing:" "$CONFIG_MD"
  [ "$status" -eq 0 ]
}

@test "config.md: model_routing: extra-low tier row is present" {
  # Test expectation: five-tier block includes extra-low row
  run grep -q "extra-low:" "$CONFIG_MD"
  [ "$status" -eq 0 ]
}

@test "config.md: model_routing: low tier row is present" {
  # Test expectation: five-tier block includes low row
  run grep -q "low:" "$CONFIG_MD"
  [ "$status" -eq 0 ]
}

@test "config.md: model_routing: medium tier row is present" {
  # Test expectation: five-tier block includes medium row
  run grep -q "medium:" "$CONFIG_MD"
  [ "$status" -eq 0 ]
}

@test "config.md: model_routing: high tier row is present" {
  # Test expectation: five-tier block includes high row
  run grep -q "high:" "$CONFIG_MD"
  [ "$status" -eq 0 ]
}

@test "config.md: model_routing: extra-high tier row is present" {
  # Test expectation: five-tier block includes extra-high row
  run grep -q "extra-high:" "$CONFIG_MD"
  [ "$status" -eq 0 ]
}

@test "config.md: extra-low row is explicitly set to none (operator opt-in surface)" {
  # Test expectation: explicit extra-low: none row (operator opt-in; no default consumers)
  run grep -E "extra-low:[[:space:]]+none" "$CONFIG_MD"
  [ "$status" -eq 0 ]
}

@test "config.md: default_tier is set to medium" {
  # Test expectation: config.md has default_tier: medium
  run grep -E "default_tier:[[:space:]]+medium" "$CONFIG_MD"
  [ "$status" -eq 0 ]
}

@test "config.md: tier rows use vendor-neutral { vendor:, model: } shape (not per-host haiku/sonnet/opus)" {
  # Test expectation: tier rows are vendor-neutral key-value objects, not host-keyed model names
  run grep -E "vendor:[[:space:]]" "$CONFIG_MD"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# _resolve-lib.sh — tier resolution precedence chain and halt-on-none
# Test expectation: Exercise/grep _resolve-lib.sh coverage for per-dispatch
# tier override, agent tier:, default_tier:, hardcoded-medium-with-warning
# precedence; verify none-tier halt with no silent fallback.
# ---------------------------------------------------------------------------

@test "_resolve-lib.sh: file exists (created by T16)" {
  # Test expectation: scripts/_resolve-lib.sh is created by the implementer
  [ -f "$RESOLVE_LIB" ]
}

@test "_resolve-lib.sh: documents --tier-override as highest-precedence layer" {
  # Test expectation: per-dispatch/--tier-override is layer 1 in the precedence chain
  run grep -E "\-\-tier-override" "$RESOLVE_LIB"
  [ "$status" -eq 0 ]
}

@test "_resolve-lib.sh: documents agent tier: frontmatter as second-layer precedence" {
  # Test expectation: agent tier: frontmatter is layer 2 in the precedence chain
  run grep -E "agent.*tier:|tier:.*frontmatter|frontmatter.*tier:" "$RESOLVE_LIB"
  [ "$status" -eq 0 ]
}

@test "_resolve-lib.sh: documents default_tier: from config.md as third-layer precedence" {
  # Test expectation: default_tier: in config.md is layer 3 fallback
  run grep -E "default_tier" "$RESOLVE_LIB"
  [ "$status" -eq 0 ]
}

@test "_resolve-lib.sh: documents hardcoded medium fallback with loud warning as final layer" {
  # Test expectation: hardcoded medium fallback with loud warning is layer 4 (last resort)
  run grep -E "medium.*warn|warn.*medium|hardcoded.*medium|medium.*fallback" "$RESOLVE_LIB"
  [ "$status" -eq 0 ]
}

@test "_resolve-lib.sh: halt-on-none behavior — no silent fallback when tier resolves to none" {
  # Test expectation: dispatch resolving to a tier configured as none halts loudly;
  # does not fall back to a neighboring tier
  run grep -E "none.*halt|halt.*none|no.*silent.*fallback|silent.*fallback.*none" "$RESOLVE_LIB"
  [ "$status" -eq 0 ]
}

@test "_resolve-lib.sh: none-tier halt names the unresolved tier in the diagnostic" {
  # Test expectation: the halt diagnostic names the unconfigured tier so operators see
  # which tier was targeted; opaque error messages are not acceptable
  run grep -E "unconfigured.*tier|tier.*unconfigured|unresolved.*tier|tier.*name.*diag" "$RESOLVE_LIB"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# _resolve-lib.sh — BEHAVIORAL execution coverage (F08).
# The grep-only tests above pin the documented contract in the source; these
# tests SOURCE the library under QRSPI_SOURCE_ONLY=1 and EXECUTE resolve_tier /
# resolve_model against hermetic config + agent fixtures so real logic
# regressions (precedence bugs, the none-on-comment halt failure, malformed-row
# handling, tier injection) are caught at runtime rather than by keyword grep.
# ---------------------------------------------------------------------------

# Write the canonical five-tier model_routing fixture to $1. Mirrors the shipped
# config.md block, including the inline-commented `extra-low: none` opt-in row.
_write_routing_fixture() {
  cat > "$1" <<'EOF'
# fixture config.md for resolver behavioral tests

## Model routing

```yaml
model_routing:
  extra-low:  none                                              # operator opts in
  low:        { vendor: claude, model: claude-haiku-4.5 }       # cheap
  medium:     { vendor: claude, model: claude-sonnet-4.6 }
  high:       { vendor: claude, model: claude-opus-4.7 }
  extra-high: { vendor: claude, model: claude-opus-4.7-high }
default_tier: medium
```
EOF
}

# Source the resolver and run resolve_model <tier> with CONFIG_MD=<config>.
# Usage: run _exec_resolve_model <config-or-empty> <tier>
_exec_resolve_model() {
  local cfg="$1" tier="$2"
  if [ -n "$cfg" ]; then export CONFIG_MD="$cfg"; else unset CONFIG_MD; fi
  QRSPI_SOURCE_ONLY=1 source "$RESOLVE_LIB"
  resolve_model "$tier"
}

# Source the resolver and run resolve_tier <agent-file> <override> with CONFIG_MD.
# Usage: run _exec_resolve_tier <config-or-empty> <agent-file-or-empty> <override-or-empty>
_exec_resolve_tier() {
  local cfg="$1" agent="$2" override="$3"
  if [ -n "$cfg" ]; then export CONFIG_MD="$cfg"; else unset CONFIG_MD; fi
  QRSPI_SOURCE_ONLY=1 source "$RESOLVE_LIB"
  resolve_tier "$agent" "$override"
}

@test "_resolve-lib.sh [exec]: resolve_tier layer 1 — --tier-override wins over agent tier: and default_tier:" {
  local agent="$BATS_TEST_TMPDIR/agent.md"
  printf 'tier: low\n' > "$agent"
  local cfg="$BATS_TEST_TMPDIR/config.md"
  _write_routing_fixture "$cfg"
  run _exec_resolve_tier "$cfg" "$agent" "high"
  [ "$status" -eq 0 ]
  [ "$output" = "high" ]
}

@test "_resolve-lib.sh [exec]: resolve_tier layer 2 — agent tier: used when no override" {
  local agent="$BATS_TEST_TMPDIR/agent.md"
  printf 'tier: low\n' > "$agent"
  local cfg="$BATS_TEST_TMPDIR/config.md"
  _write_routing_fixture "$cfg"
  run _exec_resolve_tier "$cfg" "$agent" ""
  [ "$status" -eq 0 ]
  [ "$output" = "low" ]
}

@test "_resolve-lib.sh [exec]: resolve_tier layer 3 — default_tier: used when agent has no tier:" {
  local agent="$BATS_TEST_TMPDIR/agent.md"
  printf '# agent with no tier field\n' > "$agent"
  local cfg="$BATS_TEST_TMPDIR/config.md"
  _write_routing_fixture "$cfg"
  run _exec_resolve_tier "$cfg" "$agent" ""
  [ "$status" -eq 0 ]
  [ "$output" = "medium" ]
}

@test "_resolve-lib.sh [exec]: resolve_tier layer 4 — hardcoded medium with loud warning when neither tier nor default_tier resolves" {
  local agent="$BATS_TEST_TMPDIR/agent.md"
  printf '# agent with no tier field\n' > "$agent"
  local cfg="$BATS_TEST_TMPDIR/config-no-default.md"
  cat > "$cfg" <<'EOF'
```yaml
model_routing:
  low:    { vendor: claude, model: claude-haiku-4.5 }
  medium: { vendor: claude, model: claude-sonnet-4.6 }
```
EOF
  run --separate-stderr _exec_resolve_tier "$cfg" "$agent" ""
  [ "$status" -eq 0 ]
  [ "$output" = "medium" ]
  # The fallback must be LOUD — a warning on stderr naming the medium fallback.
  [[ "$stderr" == *WARN* ]]
  [[ "$stderr" == *medium* ]]
}

@test "_resolve-lib.sh [exec]: resolve_tier layer 4 warning names CONFIG_MD unset/missing as the cause (F02 de-mask)" {
  local agent="$BATS_TEST_TMPDIR/agent.md"
  printf '# agent with no tier field\n' > "$agent"
  # No CONFIG_MD at all → Layer 3 skipped because config is missing, not because
  # default_tier: is absent from a present config. Passing an empty config to the
  # helper unsets CONFIG_MD; the cause-naming warning lands on stderr.
  run --separate-stderr _exec_resolve_tier "" "$agent" ""
  [ "$status" -eq 0 ]
  [[ "$stderr" == *CONFIG_MD* ]]
}

@test "_resolve-lib.sh [exec]: resolve_model HALTS on none WITH inline comment (F01 regression — extra-low: none # operator opts in)" {
  local cfg="$BATS_TEST_TMPDIR/config.md"
  _write_routing_fixture "$cfg"
  run --separate-stderr _exec_resolve_model "$cfg" "extra-low"
  # MUST halt — the inline `# operator opts in` comment must NOT defeat the
  # none-detection. This test FAILS against the pre-fix code (exit 0, garbage
  # stdout) and PASSES after value normalization.
  [ "$status" -ne 0 ]
  [[ "$stderr" == *HALT* ]]
}

@test "_resolve-lib.sh [exec]: resolve_model emits a clean value for a normal commented row (no trailing #)" {
  local cfg="$BATS_TEST_TMPDIR/config.md"
  _write_routing_fixture "$cfg"
  run _exec_resolve_model "$cfg" "low"
  [ "$status" -eq 0 ]
  [[ "$output" == *claude-haiku-4.5* ]]
  # The emitted value must carry no inline comment marker.
  [[ "$output" != *"#"* ]]
}

@test "_resolve-lib.sh [exec]: resolve_model HALTS on an unconfigured/absent tier row" {
  local cfg="$BATS_TEST_TMPDIR/config-no-extra-low.md"
  cat > "$cfg" <<'EOF'
```yaml
model_routing:
  low:    { vendor: claude, model: claude-haiku-4.5 }
  medium: { vendor: claude, model: claude-sonnet-4.6 }
default_tier: medium
```
EOF
  run _exec_resolve_model "$cfg" "extra-low"
  [ "$status" -ne 0 ]
}

@test "_resolve-lib.sh [exec]: resolve_model HALTS on a present-but-EMPTY tier row (malformed row, no silent blank emit)" {
  local cfg="$BATS_TEST_TMPDIR/config-empty-medium.md"
  cat > "$cfg" <<'EOF'
```yaml
model_routing:
  low:    { vendor: claude, model: claude-haiku-4.5 }
  medium:   
high:   { vendor: claude, model: claude-opus-4.7 }
default_tier: low
```
EOF
  run --separate-stderr _exec_resolve_model "$cfg" "medium"
  # The row is PRESENT (key + trailing whitespace) but carries no value. The
  # resolver must HALT — never emit a blank line with exit 0.
  [ "$status" -ne 0 ]
  [ -z "$output" ]
  # The diagnostic must name the tier and flag the malformed/empty row — and
  # must be DISTINCT from the unconfigured-tier "resolves to none" wording.
  [[ "$stderr" == *HALT* ]]
  [[ "$stderr" == *medium* ]]
  [[ "$stderr" == *"no value"* ]]
}

@test "_resolve-lib.sh [exec]: resolve_model HALTS with the truthful config-path diagnostic on an UNREADABLE CONFIG_MD" {
  if [ "${EUID:-$(id -u)}" -eq 0 ]; then
    skip "root bypasses chmod 000 permission bits — unreadable-file path not exercisable as root"
  fi
  local cfg="$BATS_TEST_TMPDIR/config-unreadable.md"
  _write_routing_fixture "$cfg"
  chmod 000 "$cfg"
  run --separate-stderr _exec_resolve_model "$cfg" "low"
  # An existing-but-unreadable config must be classified as a config-path error
  # (readability check), not silently treated as a present config.
  [ "$status" -ne 0 ]
  [[ "$stderr" == *CONFIG_MD* ]]
  # Restore perms so BATS_TEST_TMPDIR teardown can clean up.
  chmod 644 "$cfg"
}

@test "_resolve-lib.sh [exec]: resolve_model HALTS with the config-path diagnostic when CONFIG_MD points at a DIRECTORY (readable non-regular path)" {
  # A readable DIRECTORY satisfies `[ -r ]` but is NOT a regular config file.
  # The resolver must classify it as a config-path error (naming CONFIG_MD as
  # not a readable file), NOT silently fall through to the unconfigured-tier
  # halt.
  local cfgdir="$BATS_TEST_TMPDIR/config-as-dir"
  mkdir -p "$cfgdir"
  run --separate-stderr _exec_resolve_model "$cfgdir" "medium"
  [ "$status" -eq 1 ]
  [[ "$stderr" == *"not a readable file"* ]]
  # Must be the config-path cause, NOT the unconfigured-tier message.
  [[ "$stderr" != *unconfigured* ]]
}

@test "_resolve-lib.sh [exec]: resolve_model fails with a DISTINCT config-missing diagnostic when CONFIG_MD is unset (F02)" {
  run --separate-stderr _exec_resolve_model "" "low"
  [ "$status" -ne 0 ]
  # Distinct from the none/unconfigured-tier message — must name CONFIG_MD.
  [[ "$stderr" == *CONFIG_MD* ]]
}

@test "_resolve-lib.sh [exec]: resolve_model rejects an invalid/injected tier via allowlist (F03)" {
  local cfg="$BATS_TEST_TMPDIR/config.md"
  _write_routing_fixture "$cfg"
  # Crafted ERE alternation must be rejected by the allowlist BEFORE interpolation.
  run --separate-stderr _exec_resolve_model "$cfg" 'low|medium'
  [ "$status" -ne 0 ]
  [[ "$stderr" == *invalid* ]]
}

@test "_resolve-lib.sh [exec]: resolve_tier rejects an invalid tier from --tier-override (F03 allowlist)" {
  local cfg="$BATS_TEST_TMPDIR/config.md"
  _write_routing_fixture "$cfg"
  run _exec_resolve_tier "$cfg" "" "bogus-tier"
  [ "$status" -ne 0 ]
}

@test "_resolve-lib.sh [exec]: resolve_tier rejects an invalid tier from agent frontmatter (F03 allowlist)" {
  local agent="$BATS_TEST_TMPDIR/agent-bad.md"
  printf 'tier: nonsense\n' > "$agent"
  local cfg="$BATS_TEST_TMPDIR/config.md"
  _write_routing_fixture "$cfg"
  run _exec_resolve_tier "$cfg" "$agent" ""
  [ "$status" -ne 0 ]
}

@test "_resolve-lib.sh [exec]: resolve_tier rejects an invalid tier from default_tier: (F03 allowlist)" {
  local agent="$BATS_TEST_TMPDIR/agent.md"
  printf '# no tier\n' > "$agent"
  local cfg="$BATS_TEST_TMPDIR/config-bad-default.md"
  cat > "$cfg" <<'EOF'
```yaml
model_routing:
  medium: { vendor: claude, model: claude-sonnet-4.6 }
default_tier: nonsense
```
EOF
  run _exec_resolve_tier "$cfg" "$agent" ""
  [ "$status" -ne 0 ]
}

@test "_resolve-lib.sh [exec]: residual out-of-block shadow gap is documented (deferred to v0.7.3)" {
  # KNOWN GAP: resolve_model's row grep is line-oriented and not block-scoped to
  # the `model_routing:` map. The `^[[:space:]]+${tier}:` anchor requires the row
  # be indented (rejecting a column-0 shadow), but a same-indent `<tier>:` line
  # appearing OUTSIDE the model_routing: block elsewhere in config.md could still
  # be matched. Full block-scoped YAML parsing is deferred to v0.7.3; this test
  # documents the gap rather than asserting the (not-yet-implemented) behavior.
  skip "out-of-block shadow: full block-scoped parsing deferred to v0.7.3"
}

# ---------------------------------------------------------------------------
# config-validation-procedure.md — missing / malformed model_routing: fails loud
# Test expectation: Verify missing and malformed model_routing: configurations
# fail through the shared config-validation procedure with repair-or-abort guidance.
# ---------------------------------------------------------------------------

@test "config-validation-procedure.md: file exists (created by T16)" {
  # Test expectation: skills/_shared/config-validation-procedure.md is created by implementer
  [ -f "$VALIDATION_PROC" ]
}

@test "config-validation-procedure.md: missing model_routing: block documented as a validation failure" {
  # Test expectation: missing model_routing: configuration fails through the shared procedure
  run grep -E "missing.*model_routing|model_routing.*missing|absent.*model_routing" "$VALIDATION_PROC"
  [ "$status" -eq 0 ]
}

@test "config-validation-procedure.md: malformed tier values documented as a validation failure" {
  # Test expectation: malformed model_routing: configuration fails through the shared procedure
  run grep -E "malformed|invalid.*tier|tier.*invalid|bad.*value" "$VALIDATION_PROC"
  [ "$status" -eq 0 ]
}

@test "config-validation-procedure.md: repair-or-abort guidance is present" {
  # Test expectation: procedure includes repair-or-abort guidance (not just a bare error message)
  run grep -Ei "repair|abort|fix.*config|config.*fix" "$VALIDATION_PROC"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# using-qrspi SKILL.md — old per-host haiku/sonnet/opus/inherit schema is gone
# Test expectation: Grep skill prose to confirm the old per-host schema is
# removed from the migrated surfaces.
# ---------------------------------------------------------------------------

@test "using-qrspi: old per-host haiku row is gone from model_routing: section" {
  # Test expectation: using-qrspi no longer documents the haiku/sonnet/opus per-host schema;
  # after G22 migration the model_routing: block is five-tier vendor-neutral
  out="$(_extract_h4 "$USING" '`model_routing:` block')"
  c=$(grep -c "haiku:" <<<"$out" || true)
  [ "$c" -eq 0 ]
}

@test "using-qrspi: old per-host inherit row is gone from model_routing: section" {
  # Test expectation: inherit tier name (legacy per-host schema) is not present in updated prose
  out="$(_extract_h4 "$USING" '`model_routing:` block')"
  c=$(grep -c "inherit:" <<<"$out" || true)
  [ "$c" -eq 0 ]
}

@test "using-qrspi: new five-tier vendor-neutral model_routing: shape documented" {
  # Test expectation: using-qrspi documents the new extra-low/low/medium/high/extra-high shape
  out="$(_extract_h4 "$USING" '`model_routing:` block')"
  [[ "$out" == *"extra-low"* ]]
  [[ "$out" == *"extra-high"* ]]
}

# ---------------------------------------------------------------------------
# F05 (G22 completion sweep) — the retired #### Model Routing host-column
# section and its host-keyed indexing prose must be fully removed from
# using-qrspi. Residual host-column language fails CI here.
# ---------------------------------------------------------------------------

@test "using-qrspi: #### Model Routing host-column section heading is gone" {
  c=$(grep -c "^#### Model Routing[[:space:]]*$" "$USING" || true)
  [ "$c" -eq 0 ]
}

@test "using-qrspi: host-column indexing prose (Host column selection / Tier row selection) is gone" {
  c=$(grep -c "Host column selection\|Tier row selection" "$USING" || true)
  [ "$c" -eq 0 ]
}

@test "using-qrspi: host-keyed routing-table column prose (claude-code/copilot-cli columns) is gone" {
  c=$(grep -c "copilot-cli\` column\|claude-code\`) or (\`copilot-cli\|pick the matching top-level" "$USING" || true)
  [ "$c" -eq 0 ]
}

@test "using-qrspi: bare inherit tier-row language is gone release-wide" {
  c=$(grep -c "inherit" "$USING" || true)
  [ "$c" -eq 0 ]
}

@test "using-qrspi: bare haiku/sonnet/opus tier-row request language is gone" {
  c=$(grep -c 'bare `haiku`' "$USING" || true)
  [ "$c" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Dispatch-routing-blocks umbrella intro — model_routing: carve-out.
# The umbrella intro must not describe model_routing: absence as a silent
# "falls back to agent-bundled defaults"; that contradicts the per-block
# model_routing: section (and the Missing-model_routing: section), which
# require a loud validation failure. The carve-out must name model_routing:
# as fail-loud so the two surfaces agree.
# ---------------------------------------------------------------------------

# Extract only the intro paragraph(s) of the "### Dispatch routing blocks"
# section — the lines between the H3 anchor and the first H4 subsection — so
# the assertions cannot be satisfied by fail-loud language that lives in the
# per-block #### model_routing: subsection further down.
_extract_routing_blocks_intro() {
  local file="$1"
  awk '
    BEGIN { inside=0; found=0 }
    {
      if (inside == 1) {
        if ($0 ~ /^#{1,4} /) { inside=0; next }
        print $0
        next
      }
      if ($0 == "### Dispatch routing blocks") { inside=1; found=1; next }
    }
    END { if (found == 0) exit 1 }
  ' "$file"
}

@test "using-qrspi: dispatch-routing-blocks intro does not blanket all four blocks as optional-with-fallback" {
  # Test expectation: the umbrella must not state that the absence of every block
  # (model_routing: included) means dispatch falls back to agent-bundled defaults —
  # model_routing: absence is fail-loud, not silent fallback.
  out="$(_extract_routing_blocks_intro "$USING")"
  c=$(grep -c "their absence means dispatch falls back to agent-bundled defaults" <<<"$out" || true)
  [ "$c" -eq 0 ]
}

@test "using-qrspi: dispatch-routing-blocks intro carves model_routing: out as fail-loud" {
  # Test expectation: the umbrella intro explicitly excepts model_routing: from the
  # optional-with-fallback contract and names its absence as a loud validation failure.
  out="$(_extract_routing_blocks_intro "$USING")"
  [[ "$out" == *"model_routing:"* ]]
  c=$(grep -ci "fail loud\|fails loud\|loud validation\|validation fail" <<<"$out" || true)
  [ "$c" -ge 1 ]
}

# ===========================================================================
# Validation-table model_routing: row + fail-loud back-pointer cross-links
#
# Test expectations:
#   TE-1  Validation table contains EXACTLY ONE `model_routing:` row.
#   TE-2  The row names the required per-vendor five-tier map shape AND
#         cross-references the schema-definition heading by literal heading text.
#   TE-3  The row cross-references the missing-block fail-loud enforcement
#         paragraph by literal heading text (NOT by line number).
#   TE-4  Each config-validation fail-loud paragraph back-links to the
#         validation table heading by literal heading text.
#   NOTE: Existing loud-failure path (a config missing model_routing: halts
#         loudly) is already covered by the "missing-model_routing: documented
#         as a loud validation failure" test above — no duplication here.
# ===========================================================================

@test "validation table lists exactly one model_routing: row" {
  # Test expectation: the '### Fields that affect pipeline behavior (must be validated)'
  # table contains EXACTLY ONE row for `model_routing:`.
  local section
  section="$(extract_section "$USING" "H3" "Fields that affect pipeline behavior (must be validated)")"
  local count
  count="$(printf '%s\n' "$section" | grep -cE '^[[:space:]]*\|.*model_routing:' || true)"
  [ "$count" -eq 1 ]
}

@test "validation table model_routing: row names per-vendor five-tier map shape" {
  # Test expectation: the row identifies the required per-vendor five-tier map shape
  # (e.g. 'per-vendor five-tier map', 'five-tier vendor-neutral', etc.).
  local section
  section="$(extract_section "$USING" "H3" "Fields that affect pipeline behavior (must be validated)")"
  local row
  row="$(printf '%s\n' "$section" | grep -E '^[[:space:]]*\|.*model_routing:' || true)"
  [ -n "$row" ]
  printf '%s\n' "$row" | grep -qE "five.tier|per.vendor|vendor.neutral"
}

@test "validation table model_routing: row cross-references schema-definition heading by literal text" {
  # Test expectation: the row points to the schema-definition heading
  # '#### \`model_routing:\` block' by its exact literal heading text.
  local section
  section="$(extract_section "$USING" "H3" "Fields that affect pipeline behavior (must be validated)")"
  local row
  row="$(printf '%s\n' "$section" | grep -E '^[[:space:]]*\|.*model_routing:' || true)"
  [ -n "$row" ]
  printf '%s\n' "$row" | grep -qF '`model_routing:` block'
}

@test "validation table model_routing: row cross-references fail-loud paragraph by literal heading text not line number" {
  # Test expectation: the row points to the fail-loud enforcement paragraph by
  # literal heading text 'Missing \`model_routing:\` block in \`config.md\`'
  # and NOT by a bare line number (e.g. 'line 510').
  local section
  section="$(extract_section "$USING" "H3" "Fields that affect pipeline behavior (must be validated)")"
  local row
  row="$(printf '%s\n' "$section" | grep -E '^[[:space:]]*\|.*model_routing:' || true)"
  [ -n "$row" ]
  # Must reference the fail-loud paragraph by its literal heading text.
  printf '%s\n' "$row" | grep -qF 'Missing `model_routing:` block in `config.md`'
  # Must NOT reference by a bare line number form (e.g. "line 510" or "#510").
  local c
  c="$(printf '%s\n' "$row" | grep -cE "line [0-9]{2,}|#[0-9]{2,}" || true)"
  [ "$c" -eq 0 ]
}

@test "missing-model_routing: fail-loud paragraph back-links to validation table heading by literal text" {
  # Test expectation: the '#### Missing \`model_routing:\` block in \`config.md\`'
  # section contains a one-sentence back-pointer to the literal heading text
  # '### Fields that affect pipeline behavior (must be validated)'.
  out="$(_extract_h4 "$USING" 'Missing `model_routing:` block in `config.md`')"
  printf '%s\n' "$out" | grep -qF 'Fields that affect pipeline behavior (must be validated)'
}

@test "model_routing-block none-halt fail-loud paragraph back-links to validation table heading by literal text" {
  # Test expectation: the '#### \`model_routing:\` block' section contains a
  # back-pointer to the literal heading text
  # '### Fields that affect pipeline behavior (must be validated)' for the
  # none-halt fail-loud invariant (sibling coverage to the missing-block para).
  out="$(_extract_h4 "$USING" '`model_routing:` block')"
  printf '%s\n' "$out" | grep -qF 'Fields that affect pipeline behavior (must be validated)'
}

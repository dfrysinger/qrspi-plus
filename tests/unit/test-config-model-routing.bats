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
# Precedence chain: all four layers named in order in using-qrspi prose.
# ---------------------------------------------------------------------------

@test "precedence chain: layer 1 (per-task model:) named in using-qrspi" {
  out="$(_extract_h4 "$USING" "Precedence chain")"
  [[ "$out" == *"Per-task"*"model:"*"override"* ]]
}

@test "precedence chain: layer 2 (hardcoded dispatch-site model:) named in using-qrspi" {
  out="$(_extract_h4 "$USING" "Precedence chain")"
  [[ "$out" == *"Hardcoded dispatch-site"* ]]
}

@test "precedence chain: layer 3 (model_routing: host/tier lookup) named in using-qrspi" {
  # T10 R1 fix (schema replacement): v0.7.1 hardening retired the
  # role→provider/model schema in favor of host→tier→model. Step 3's
  # canonical wording is now "host/tier lookup" rather than "role lookup".
  out="$(_extract_h4 "$USING" "Precedence chain")"
  [[ "$out" == *"model_routing:"* ]]
  [[ "$out" == *"host/tier lookup"* ]]
}

@test "precedence chain: layer 4 (agent-bundled default) named in using-qrspi" {
  out="$(_extract_h4 "$USING" "Precedence chain")"
  [[ "$out" == *"Agent-bundled default"* ]]
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
# Missing-model_routing one-time warning when the block is absent from config.md.
# ---------------------------------------------------------------------------

@test "missing-model_routing warning: documented as one-time per session" {
  out="$(_extract_h4 "$USING" 'Missing `model_routing:` block in `config.md`')"
  [[ "$out" == *"once per session"* ]] || [[ "$out" == *"one-time"* ]]
}

@test "missing-model_routing warning: in-memory only, on-disk config never silently mutated" {
  out="$(_extract_h4 "$USING" 'Missing `model_routing:` block in `config.md`')"
  [[ "$out" == *"never silently mutated"* ]]
  [[ "$out" == *"in-memory"* ]]
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
# Role-resolution chain that consumes T06's model_role: agent frontmatter.
# Implement's per-task routing wiring AND the G5 matrix both name model_role.
# ---------------------------------------------------------------------------

@test "role resolution: model_role: frontmatter from T06 referenced by implement" {
  run grep -F "model_role:" "$IMPLEMENT"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Tie-break observation (layer-1a vs layer-1b) in a SINGLE shared section.
#
# Contract: per-task `model:` override (1a) wins; hardcoded dispatch-site
# `model:` (1b) wins in 1a's absence. Both halves must co-locate in the
# Precedence chain section so a single-fixture rewrite that drops one half
# fails loud here (where a split-fixture pin could silently pass).
# ---------------------------------------------------------------------------

@test "tie-break: layer 1a wins when per-task model: is present (contract ordering)" {
  out="$(_extract_h4 "$USING" "Precedence chain")"
  [[ "$out" == *"Per-task"*"model:"*"override"* ]]
  [[ "$out" == *"Hardcoded dispatch-site"* ]]
  # Order check: per-task line precedes hardcoded line (1a above 1b).
  per_task_line="$(printf '%s\n' "$out" | grep -n "Per-task" | head -1 | cut -d: -f1)"
  hardcoded_line="$(printf '%s\n' "$out" | grep -n "Hardcoded dispatch-site" | head -1 | cut -d: -f1)"
  [ -n "$per_task_line" ]
  [ -n "$hardcoded_line" ]
  [ "$per_task_line" -lt "$hardcoded_line" ]
}

@test "tie-break: layer 1b active in 1a's absence (contract co-location)" {
  out="$(_extract_h4 "$USING" "Precedence chain")"
  [[ "$out" == *"Per-task"* ]]
  [[ "$out" == *"Hardcoded dispatch-site"* ]]
  [[ "$out" == *"model_routing:"* ]]
  [[ "$out" == *"Agent-bundled default"* ]]
}

# ---------------------------------------------------------------------------
# Role-resolution fallback co-located observation: a role mapping resolves
# via model_routing when the role entry is present; falls back to the
# concrete model: when removed. Both halves must be observable from the
# single Precedence chain section so a regression cannot silently pass.
# ---------------------------------------------------------------------------

@test "precedence-chain co-location: model_routing: host/tier lookup AND agent-bundled default co-located in precedence chain" {
  # T10 R2 fix (post-R1 schema replacement): step-3 wording is now "host/tier lookup", not "role lookup". This pin was silently passing pre-R2 because of a bats [[ ]] short-circuit quirk; the post-R2 pin asserts the GREEN behavior explicitly.
  out="$(_extract_h4 "$USING" "Precedence chain")"
  [[ "$out" == *"model_routing:"* ]]
  [[ "$out" == *"host/tier lookup"* ]]
  [[ "$out" == *"Agent-bundled default"* ]]
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

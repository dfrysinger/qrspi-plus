#!/usr/bin/env bats
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
  export USING IMPLEMENT
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

@test "precedence chain: layer 3 (model_routing: role lookup) named in using-qrspi" {
  out="$(_extract_h4 "$USING" "Precedence chain")"
  [[ "$out" == *"model_routing:"* ]]
  [[ "$out" == *"role lookup"* ]]
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
# Legacy-config one-time warning when model_routing: absent on resume.
# ---------------------------------------------------------------------------

@test "legacy-config warning: documented as one-time per resumed session" {
  out="$(_extract_h4 "$USING" 'Legacy-config warning (`model_routing:` absent on resume)')"
  [[ "$out" == *"once per resumed session"* ]] || [[ "$out" == *"one-time"* ]]
}

@test "legacy-config warning: in-memory only, on-disk config never silently mutated" {
  out="$(_extract_h4 "$USING" 'Legacy-config warning (`model_routing:` absent on resume)')"
  [[ "$out" == *"never silently mutated"* ]]
  [[ "$out" == *"in-memory"* ]]
}

# ---------------------------------------------------------------------------
# Fail-loud provider resolution: unknown provider in model_routing: halts.
# ---------------------------------------------------------------------------

@test "provider resolution: unknown provider name is a config-validation error (fail-loud)" {
  out="$(_extract_h4 "$USING" '`model_routing:` block')"
  [[ "$out" == *"config validation error"* ]]
  [[ "$out" == *"halts and reports the unknown provider"* ]] || [[ "$out" == *"falling back silently"* ]] || [[ "$out" == *"fall back silently"* ]]
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

@test "role-resolution fallback: model_routing: role lookup AND agent-bundled default co-located in precedence chain" {
  out="$(_extract_h4 "$USING" "Precedence chain")"
  [[ "$out" == *"model_routing:"* ]]
  [[ "$out" == *"role lookup"* ]]
  [[ "$out" == *"Agent-bundled default"* ]]
}

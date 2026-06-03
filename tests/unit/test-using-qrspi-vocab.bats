#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# T10 R1 fix — pin the v0.7.1 host→tier→model schema for
# `skills/using-qrspi/SKILL.md` § `#### model_routing:` block + § Precedence
# chain step 3.
#
# Background: the v0.7.1 hardening retired the v0.7-era role→provider/model
# routing schema in favor of a host→tier→model shape (see
# docs/qrspi/2026-05-27-v071-hardening/config.md and the `#### Model Routing`
# section in skills/using-qrspi/SKILL.md). T10 added the new section but left
# the pre-existing role-based schema doc + the "role lookup" precedence-chain
# entry intact, shipping the SKILL in a self-contradictory state
# (quality-claude.F01 / quality-codex.F01).
#
# These assertions pin the contract so a future regression (e.g. someone
# reintroducing the old role/provider/model wording during a merge) fails CI
# before landing.
#
# What's pinned:
#   - Absence of `Maps role names to provider-plus-model pairs` (old schema
#     doc opener)
#   - Absence of the literal precedence-chain phrase ``model_routing:` role
#     lookup`` (old step-3 wording)
#   - Presence of the host→tier→model shape inside the schema's YAML example:
#       claude-code:
#       copilot-cli:
#       haiku: claude-haiku-4.5
#
# Substring greps are intentional — they survive incidental wording polish
# while catching schema regression. Pattern follows the
# tests/unit/test-skill-md-content-patterns.bats precedent (load shared
# helper + require_repo_root in setup; per-assertion grep with loud
# diagnostics).

load '../helpers/skill-markdown'

# ---------------------------------------------------------------------------
# H4 section extractor — the shared helper supports H2/H3 only. The
# fail-loud paragraph added by T10 R2 lives at the END of the H4 section
# `#### \`model_routing:\` block`, so the R2 pins below extract the H4 body
# (between the H4 anchor and the next H1-H4 boundary) and grep within it.
# Mirrors the _extract_h4 helper defined in test-config-model-routing.bats.
# ---------------------------------------------------------------------------
_extract_h4() {
  local file="$1" text="$2"
  local target="#### $text"
  local out
  out="$(awk -v target="$target" '
    BEGIN { inside=0; found=0 }
    {
      if (inside == 1) {
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

setup() {
  require_repo_root
  USING_QRSPI_SKILL="$REPO_ROOT/skills/using-qrspi/SKILL.md"
  # T10 R2 fix: `USING` alias is the variable name the new fail-loud /
  # anti-pattern pins below use (mirrors test-config-model-routing.bats).
  USING="$USING_QRSPI_SKILL"
  export USING_QRSPI_SKILL USING
}

@test "[using-qrspi-vocab] SKILL.md exists" {
  [ -f "$USING_QRSPI_SKILL" ]
}

@test "[using-qrspi-vocab] retired role→provider/model schema doc is gone" {
  # The old v0.7 schema opener must not reappear. If this fails, someone
  # reintroduced the role-based routing description that v0.7.1 retired.
  run grep -F -- 'Maps role names to provider-plus-model pairs' "$USING_QRSPI_SKILL"
  [ "$status" -ne 0 ]
}

@test "[using-qrspi-vocab] retired precedence-chain 'role lookup' wording is gone" {
  # Old step-3 wording. The hardened version says "host/tier lookup" and
  # references detect_host + the agent's tier name.
  run grep -F -- '`model_routing:` role lookup' "$USING_QRSPI_SKILL"
  [ "$status" -ne 0 ]
}

@test "[using-qrspi-vocab] schema doc carries the medium tier row (vendor-neutral five-tier shape)" {
  # G22 / T16 migration: the host-keyed claude-code:/copilot-cli: schema was
  # retired in favor of the five-tier vendor-neutral model_routing: shape.
  # The schema doc must carry the medium tier as a { vendor:, model: } object.
  run grep -E 'medium:[[:space:]]+\{[[:space:]]*vendor:' "$USING_QRSPI_SKILL"
  [ "$status" -eq 0 ]
}

@test "[using-qrspi-vocab] schema doc carries the default_tier: medium row" {
  # G22 / T16 migration: default_tier replaces the per-host inherit row.
  run grep -E 'default_tier:[[:space:]]+medium' "$USING_QRSPI_SKILL"
  [ "$status" -eq 0 ]
}

@test "[using-qrspi-vocab] schema doc carries a versioned tier model (claude-haiku-4.5)" {
  # Versioned-ID requirement: the doc must show the full versioned ID, not
  # the bare tier short-form (Copilot CLI's proxy rejects bare names). After
  # G22 the versioned ID lives inside the low tier's { vendor:, model: } object.
  run grep -F -- 'claude-haiku-4.5' "$USING_QRSPI_SKILL"
  [ "$status" -eq 0 ]
}

@test "model_routing block: fail-loud contract pinned for partial corruption" {
  local body
  body="$(_extract_h4 "$USING" '`model_routing:` block')"
  # T10 R2 fix (restore fail-loud contract):
  # The host→tier→model schema announces three structural invariants
  # (host key matches detect_host, four tier rows present, values are
  # fully versioned IDs). The schema doc MUST carry a fail-loud rule
  # naming what the dispatcher does on partial corruption, or the
  # G7b/#204 silent-fallback class reopens one layer deeper.
  [[ "$body" == *"halts and reports"* ]]
  [[ "$body" == *"never falls back silently"* ]] || [[ "$body" == *"never fall back silently"* ]]
}

@test "model_routing block: anti-pattern wording absent (no 'silently fall back' / 'silently degrade')" {
  local body
  body="$(_extract_h4 "$USING" '`model_routing:` block')"
  # T10 R2 fix (restore fail-loud contract):
  # Pin the absence of anti-pattern wording G7b/#204 was filed
  # against. If a future edit "softens" the fail-loud rule into a
  # silent-fallback, this pin RED-fails.
  [[ "$body" != *"silently fall back to the agent-bundled default"* ]]
  [[ "$body" != *"silently degrade"* ]]
}

@test "trusted_path block: fail-loud contract pinned for empty step 4" {
  local body
  body="$(_extract_h4 "$USING" '`trusted_path:` block')"
  # R4-F01 fix (close trusted_path: silent-fallback):
  # Post-T9, agent-bundled default (precedence chain step 4) is empty
  # for every agent. The trusted_path: short-circuit routes directly to
  # step 4. Without a fail-loud rule pinned here, two of three plausible
  # dispatcher implementations reproduce the G7b/#204 silent-fallback
  # class one layer deeper than the model_routing: path.
  [[ "$body" == *"halts and reports"* ]]
  [[ "$body" == *"never falls back silently"* ]] || [[ "$body" == *"never fall back silently"* ]]
}

@test "trusted_path block: anti-pattern wording absent" {
  local body
  body="$(_extract_h4 "$USING" '`trusted_path:` block')"
  # R4-F01 fix (close trusted_path: silent-fallback):
  # Pin absence of the anti-pattern wording G7b/#204 was filed against,
  # scoped to the trusted_path: H4 body specifically. If a future edit
  # softens the trusted_path: fail-loud rule into a silent-fallback,
  # this pin RED-fails.
  [[ "$body" != *"silently fall back to the agent-bundled default"* ]]
  [[ "$body" != *"silently degrade"* ]]
}

@test "validators block: fail-loud contract pinned for empty step 4" {
  local body
  body="$(_extract_h4 "$USING" '`validators:` block')"
  # R5-F01 fix (close validators: trusted-model re-run silent-fallback):
  # The validators: H4 documents a trusted-model re-run path that
  # "bypasses model_routing: and dispatches to the agent-bundled default
  # model". Post-T9, the agent-bundled default is empty for every agent.
  # Without a fail-loud rule pinned here, the re-run path reproduces the
  # G7b/#204 silent-fallback class one layer deeper than trusted_path:.
  # Sanity: _extract_h4 returns non-empty body (else assertions below
  # would silently pass on empty string).
  [ -n "$body" ]
  [[ "$body" == *"halts and reports"* ]]
  [[ "$body" == *"never falls back silently"* ]] || [[ "$body" == *"never fall back silently"* ]]
}

@test "validators block: anti-pattern wording absent" {
  local body
  body="$(_extract_h4 "$USING" '`validators:` block')"
  # R5-F01 fix: pin absence of the anti-pattern wording G7b/#204 was
  # filed against, scoped to the validators: H4 body specifically.
  [ -n "$body" ]
  [[ "$body" != *"silently fall back to the agent-bundled default"* ]]
  [[ "$body" != *"silently degrade"* ]]
}

@test "missing model_routing block: fail-loud contract pinned for empty step 4" {
  local body
  body="$(_extract_h4 "$USING" 'Missing `model_routing:` block in `config.md`')"
  # R5-F01 fix (close missing-block backfill silent-fallback):
  # The Missing model_routing: H4 documents a backfill path that uses
  # "agent-bundled defaults for this session". Post-T9, those defaults
  # are empty for every agent. Without a fail-loud rule pinned here, the
  # backfill path reproduces the G7b/#204 silent-fallback class through
  # a different bypass.
  # Sanity: the H4 label here contains literal backticks AND a
  # multi-word + backticked subphrase. The _extract_h4 helper uses awk
  # string equality on the heading line, so backticks pass through
  # without escaping — but if that ever regresses, an empty body would
  # silently satisfy the substring-mismatch assertions. Assert non-empty
  # body first.
  [ -n "$body" ]
  [[ "$body" == *"halts and reports"* ]]
  [[ "$body" == *"never falls back silently"* ]] || [[ "$body" == *"never fall back silently"* ]]
}

@test "missing model_routing block: anti-pattern wording absent" {
  local body
  body="$(_extract_h4 "$USING" 'Missing `model_routing:` block in `config.md`')"
  # R5-F01 fix: pin absence of the anti-pattern wording scoped to the
  # missing-block H4 body specifically.
  [ -n "$body" ]
  [[ "$body" != *"silently fall back to the agent-bundled default"* ]]
  [[ "$body" != *"silently degrade"* ]]
}

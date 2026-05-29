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

setup() {
  require_repo_root
  USING_QRSPI_SKILL="$REPO_ROOT/skills/using-qrspi/SKILL.md"
  export USING_QRSPI_SKILL
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

@test "[using-qrspi-vocab] schema doc carries the claude-code: host key" {
  run grep -F -- 'claude-code:' "$USING_QRSPI_SKILL"
  [ "$status" -eq 0 ]
}

@test "[using-qrspi-vocab] schema doc carries the copilot-cli: host key" {
  run grep -F -- 'copilot-cli:' "$USING_QRSPI_SKILL"
  [ "$status" -eq 0 ]
}

@test "[using-qrspi-vocab] schema doc carries a versioned tier row (haiku: claude-haiku-4.5)" {
  # Versioned-ID requirement: the doc must show the full versioned ID, not
  # the bare tier short-form (Copilot CLI's proxy rejects bare names).
  run grep -F -- 'haiku: claude-haiku-4.5' "$USING_QRSPI_SKILL"
  [ "$status" -eq 0 ]
}

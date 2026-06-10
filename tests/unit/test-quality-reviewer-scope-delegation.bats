#!/usr/bin/env bats

# Bug 1 (v0.7.2.5 hotfix): quality reviewers must carry a Scope Delegation
# preamble naming their scope-reviewer counterpart and instructing the agent
# not to author presence/absence findings (which belong to the scope-reviewer).
#
# Quality reviewers with scope-reviewer counterparts (per canonical topology):
#   design, goals, structure, plan, parallelize, phasing, replan
# Quality reviewers WITHOUT scope-reviewer counterparts (no preamble required):
#   questions, research

setup() {
  cd "$BATS_TEST_DIRNAME/../.."
}

@test "quality reviewers with scope-reviewer counterparts carry a Scope delegation preamble" {
  for name in design goals structure plan parallelize phasing replan; do
    grep -qE '^### Scope delegation \(read first\)$' "agents/qrspi-${name}-reviewer.md" \
      || { echo "qrspi-${name}-reviewer.md missing '### Scope delegation (read first)' heading"; return 1; }
  done
  return 0
}

@test "scope-delegation preamble names the matching scope-reviewer agent" {
  for name in design goals structure plan parallelize phasing replan; do
    awk '/^### Scope delegation/{f=1;next} f && /^###|^## /{exit} f' "agents/qrspi-${name}-reviewer.md" \
      | grep -qE "\`qrspi-${name}-scope-reviewer\`" \
      || { echo "qrspi-${name}-reviewer.md preamble must reference qrspi-${name}-scope-reviewer"; return 1; }
  done
  return 0
}

@test "scope-delegation preamble instructs agent not to author presence/absence findings" {
  for name in design goals structure plan parallelize phasing replan; do
    awk '/^### Scope delegation/{f=1;next} f && /^###|^## /{exit} f' "agents/qrspi-${name}-reviewer.md" \
      | grep -qiE 'do not emit.*(missing|present|off-limits|required)' \
      || { echo "qrspi-${name}-reviewer.md preamble must instruct 'Do NOT emit' presence/absence findings"; return 1; }
  done
  return 0
}

@test "scope-delegation preamble appears before the per-artifact quality checks" {
  for name in design goals structure plan parallelize phasing replan; do
    local delegation_line checks_line
    delegation_line=$(grep -n '^### Scope delegation (read first)$' "agents/qrspi-${name}-reviewer.md" | head -1 | cut -d: -f1)
    checks_line=$(grep -nE '^### [A-Za-z]+-specific quality checks' "agents/qrspi-${name}-reviewer.md" | head -1 | cut -d: -f1)
    [ -n "$delegation_line" ] && [ -n "$checks_line" ] && [ "$delegation_line" -lt "$checks_line" ] \
      || { echo "qrspi-${name}-reviewer.md: preamble (line $delegation_line) must precede quality-checks heading (line $checks_line)"; return 1; }
  done
  return 0
}

@test "design-reviewer quality checks no longer enforce deferred test-taxonomy or unified-diagram presence" {
  # The two specific drift bullets that triggered v0.7.3 round-01 false positives:
  #   - "test types (unit, integration, contract, e2e)" — design DEFERS test taxonomy to Structure
  #   - "Mermaid system diagram" presence — design DEFERS unified system-wide diagrams to Structure
  local body
  body=$(awk '/^### .*quality checks$/{f=1;next} f && /^### |^## /{exit} f' agents/qrspi-design-reviewer.md)
  if echo "$body" | grep -qE 'unit, ?integration, ?contract, ?e2e'; then
    echo "design-reviewer still enforces deferred test taxonomy (unit/integration/contract/e2e)"
    return 1
  fi
  if echo "$body" | grep -qE 'Mermaid system diagram (present|is present)'; then
    echo "design-reviewer still enforces unified Mermaid system diagram presence (Structure's job)"
    return 1
  fi
}

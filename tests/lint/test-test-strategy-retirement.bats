#!/usr/bin/env bats
# v0.7.4 audit item #2 regression pin: the phrase "Test Strategy" / "test strategy"
# is retired across QRSPI prose. Replacements:
#   - Cross-release stitching of acceptance:  ## Test Architecture (Structure-OWNS, unchanged)
#   - Per-goal acceptance:                    Per-goal Acceptance blocks (Design-OWNS, unchanged)
#   - Visual-fidelity wireframe binding:      ## Visual-Fidelity Binding (Design-OWNS, NEW H2)
#
# This lint locks the retirement so the 3-way contradiction (design SKILL precondition
# requiring `## Test Strategy` H2 vs altitude-boundary forbidding it vs template authoring
# none) cannot reappear.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
}

# Scan returns matches that are NOT covered by a content-based exemption.
# Each line of stdout is "path:line:matched_text".
qrspi_test_strategy_retirement_audit() {
  local pattern="$1"
  cd "$REPO_ROOT"
  # Note: the lint itself owns the retirement rule prose, so it's exempted by path.
  grep -RnE "$pattern" \
    --include='*.md' --include='*.bats' --include='*.sh' \
    skills/ agents/ scripts/ tests/ README.md 2>/dev/null \
  | grep -v '^tests/lint/test-test-strategy-retirement.bats:' \
  | while IFS= read -r line; do
      # Exemption 1: this lint's own self-references (already excluded by path above; double-belt).
      if [[ "$line" == tests/lint/test-test-strategy-retirement.bats:* ]]; then
        continue
      fi
      # Exemption 2: tests/unit/test-u14-lint.bats — the U14 fixture asserts the OLD heading
      # is REJECTED post-retirement (pin tests for "missing-heading=## Test Strategy" used
      # to be the rule and now must be flipped). After the sweep, U14 should NOT mention
      # `## Test Strategy` either, so this exemption is informational only.
      # Exemption 3: docs/qrspi/2026-06-14-v074-prompt-audit/ (audit report itself documents
      # the contradiction we are fixing — historical record, not a live consumer).
      # Exemption 4: tests/fixtures/seeded-out-of-scope-design.md — deliberate altitude-boundary
      # violation seed for the scope-reviewer test suite (the fixture's whole purpose is to
      # contain forbidden patterns so the scope-reviewer can be tested against it).
      case "$line" in
        docs/qrspi/2026-06-14-v074-prompt-audit/*) continue ;;
        tests/fixtures/seeded-out-of-scope-design.md:*) continue ;;
      esac
      # Otherwise it's a stale reference.
      printf '%s\n' "$line"
    done
}

@test "test-strategy-retirement: no '## Test Strategy' H2 remains in skills/agents/scripts/tests prose" {
  hits="$(qrspi_test_strategy_retirement_audit '^##[[:space:]]+Test[[:space:]]+Strategy[[:space:]]*$' || true)"
  [ -z "$hits" ] || { printf 'STALE `## Test Strategy` H2 references:\n%s\n' "$hits" >&2; false; }
}

@test "test-strategy-retirement: no inline 'Test Strategy' / 'test strategy' phrase remains in skills/agents/scripts/README prose" {
  # Match the bare phrase anywhere on a line. Test files in tests/ may legitimately
  # quote it as a forbidden token (e.g., this lint), so we scan only skills/ + agents/ + scripts/ + README.md.
  cd "$REPO_ROOT"
  hits="$(grep -RnE 'Test[[:space:]]+Strategy|test[[:space:]]+strategy' \
            --include='*.md' --include='*.bats' --include='*.sh' \
            skills/ agents/ scripts/ README.md 2>/dev/null \
          | grep -vE '^tests/lint/test-test-strategy-retirement\.bats:' || true)"
  [ -z "$hits" ] || { printf 'STALE Test Strategy / test strategy phrase references:\n%s\n' "$hits" >&2; false; }
}

@test "test-strategy-retirement: design SKILL precondition references the H2 anchor '## Visual-Fidelity Binding'" {
  # Strict H2 match: line starts with exactly `## ` (NOT `### `, which would substring-match).
  run grep -cE '(^|[^#])##[[:space:]]+Visual-Fidelity[[:space:]]+Binding' "$REPO_ROOT/skills/design/SKILL.md"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}

@test "test-strategy-retirement: phasing visual-fidelity precondition reads from the H2 anchor '## Visual-Fidelity Binding'" {
  run grep -cE '(^|[^#])##[[:space:]]+Visual-Fidelity[[:space:]]+Binding' "$REPO_ROOT/skills/phasing/references/visual-fidelity-precondition.md"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}

@test "test-strategy-retirement: design-altitude-boundary OWNS 'Visual-Fidelity Binding' (any reference; the rule covers both states of the flag)" {
  run grep -cE 'Visual-Fidelity Binding' "$REPO_ROOT/skills/_shared/design-altitude-boundary.md"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}

@test "test-strategy-retirement: no 'binding subsection' references remain (post-retirement, the anchor is a top-level H2, not a subsection)" {
  # Defense-in-depth pin caught by Opus dual-review R1: the rename from `### Visual-Fidelity Binding`
  # subsection to `## Visual-Fidelity Binding` H2 must propagate to every consumer that names the anchor.
  cd "$REPO_ROOT"
  hits="$(grep -RnE 'binding[[:space:]]+subsection|wireframe[[:space:]]+binding[[:space:]]+subsection' \
            --include='*.md' --include='*.bats' --include='*.sh' \
            skills/ agents/ scripts/ README.md 2>/dev/null \
          | grep -vE '^tests/lint/test-test-strategy-retirement\.bats:' || true)"
  [ -z "$hits" ] || { printf 'STALE binding-subsection references (the anchor is now a top-level ## Visual-Fidelity Binding H2):\n%s\n' "$hits" >&2; false; }
}

@test "test-strategy-retirement: U14 lint required-headings list does NOT require '## Test Strategy'" {
  # Defense-in-depth: U14's required-set must drop the retired heading.
  run grep -nE '"## Test Strategy"' "$REPO_ROOT/tests/unit/test-u14-lint.bats"
  [ "$status" -ne 0 ] || { printf 'U14 lint still requires `## Test Strategy`:\n%s\n' "$output" >&2; false; }
}

#!/usr/bin/env bats

setup() {
  PROTOCOL=$(awk '
    /\*\*Apply-fix protocol\.\*\*/ { in_block=1 }
    in_block && /\*\*Diff handling between rounds/ { exit }
    in_block { print }
  ' skills/using-qrspi/SKILL.md)
}

@test "scope and intent flow to pause gate REGARDLESS of score" {
  echo "$PROTOCOL" | grep -qE 'scope.*intent.*bypass.*score|scope.*intent.*pause gate.*regardless|scope.*intent.*never.*score-filtered'
}

@test "style/clarity require >=80 and correctness requires >=70 (Hotfix B threshold split per issue #225)" {
  echo "$PROTOCOL" | grep -qE 'style.*clarity.*(>=|≥)\s*80' && \
  echo "$PROTOCOL" | grep -qE 'correctness.*(>=|≥)\s*70'
}

@test "out-of-enum change_type triggers loud failure" {
  echo "$PROTOCOL" | grep -qE 'out-of-enum.*loud failure|change_type.*loud failure|schema guard.*change_type'
}

@test "the canonical 5-value change_type enum is cited from reviewer-protocol" {
  grep -qE 'style.*clarity.*correctness.*scope.*intent' skills/reviewer-protocol/SKILL.md
}

@test "fixture-backed partition: scope/intent kept regardless of score, style/clarity/correctness filtered at >=80" {
  # Run the partition logic against the mixed-change-types fixture and assert
  # the spec routing rule: scope/intent always-keep; SCC score-filtered at 80.
  local D=tests/fixtures/issue-109/round-mixed-change-types/round-04
  shopt -s nullglob
  local kept=0 dropped=0
  for f in "$D"/*.finding-*.md; do
    local sc="${f%.md}.score.yml"
    local ct score
    ct=$(awk -F': *' '/^change_type:/ {print $2; exit}' "$f")
    score=$(awk -F': *' '/^score:/ {print $2; exit}' "$sc")
    if [[ "$ct" == "scope" || "$ct" == "intent" ]]; then
      kept=$((kept + 1))
    elif (( score >= 80 )); then
      kept=$((kept + 1))
    else
      dropped=$((dropped + 1))
    fi
  done
  [[ "$kept" -eq 4 ]] || { echo "expected kept=4, got $kept"; return 1; }
  [[ "$dropped" -eq 1 ]] || { echo "expected dropped=1, got $dropped"; return 1; }
}

# ---------------------------------------------------------------------------
# Field-name contract: change_type is the required reviewer frontmatter key.
# A finding that uses category: without change_type: is malformed and must
# be loud-failed by the schema guard, never silently accepted, dropped, or
# default-routed.
# ---------------------------------------------------------------------------

# Mirror of the schema-guard contract documented in
# skills/reviewer-protocol/SKILL.md ## Finding Schema. Returns 0 and prints
# the routed change_type on a well-formed finding; returns non-zero with a
# named-cause diagnostic on missing change_type.
_partition_finding() {
  local f="$1"
  local ct
  ct=$(awk -F': *' '/^change_type:/ {print $2; exit}' "$f")
  if [[ -z "$ct" ]]; then
    echo "schema-guard: missing required field 'change_type:' in $f" >&2
    return 2
  fi
  echo "$ct"
}

@test "schema guard halts with named cause when change_type is missing (legacy category-only finding)" {
  local fixture=tests/fixtures/change-type-required/round-01/legacy-category-claude.finding-F01.md
  [[ -f "$fixture" ]] || { echo "fixture missing: $fixture"; return 1; }

  # Confirm the fixture is the drift shape under test: category: present,
  # change_type: absent.
  grep -qE '^category:' "$fixture" || { echo "fixture should carry category:"; return 1; }
  ! grep -qE '^change_type:' "$fixture" || { echo "fixture must NOT carry change_type:"; return 1; }

  # Run the partition routine. Expect non-zero exit AND a missing-field
  # diagnostic naming change_type. The finding must NOT be routed (no
  # change_type printed on stdout) — i.e. neither silently accepted, silently
  # dropped, nor default-routed.
  local out err rc
  out=$(_partition_finding "$fixture" 2>/tmp/ct-stderr-$$.log) && rc=0 || rc=$?
  err=$(cat /tmp/ct-stderr-$$.log); rm -f /tmp/ct-stderr-$$.log

  [[ "$rc" -ne 0 ]] || { echo "expected non-zero exit, got 0 (silent acceptance)"; return 1; }
  [[ -z "$out" ]] || { echo "expected no routed change_type on stdout, got: $out"; return 1; }
  echo "$err" | grep -qE "missing required field 'change_type:'" \
    || { echo "expected named missing-field diagnostic, got: $err"; return 1; }
}

@test "well-formed change_type finding is accepted and routed by that field name" {
  local fixture=tests/fixtures/change-type-required/round-01/well-formed-claude.finding-F02.md
  [[ -f "$fixture" ]] || { echo "fixture missing: $fixture"; return 1; }

  local out rc
  out=$(_partition_finding "$fixture" 2>/dev/null) && rc=0 || rc=$?
  [[ "$rc" -eq 0 ]] || { echo "expected acceptance, got rc=$rc"; return 1; }
  [[ "$out" == "scope" ]] || { echo "expected route by change_type=scope, got: $out"; return 1; }
}

@test "reviewer protocol documents change_type: as the required schema field" {
  # Require explicit field-name-contract wording in the schema section, not
  # just incidental "required" mentions in routing prose. The schema must
  # name change_type: as the required reviewer frontmatter field.
  grep -qiE 'change_type:.*required reviewer.*frontmatter|required reviewer.*frontmatter.*change_type:' skills/reviewer-protocol/SKILL.md \
    || { echo "SKILL.md must state change_type: is the required reviewer frontmatter field"; return 1; }
}

@test "reviewer protocol documents loud-failure with named cause on missing change_type:" {
  # The schema guard must halt with a named cause naming the change_type:
  # field — not silently accept, drop, or default-route. This pins the
  # field-name drift contract documented in design.md.
  grep -qE "missing.*change_type:.*(named cause|loud failure|halt|loud-fail)" skills/reviewer-protocol/SKILL.md \
    || grep -qE "(named cause|loud failure|halt|loud-fail).*missing.*change_type:" skills/reviewer-protocol/SKILL.md \
    || { echo "SKILL.md must document loud-failure with named cause on missing change_type:"; return 1; }
  grep -qE "(not|never).*(silently|silent).*(accept|drop|default-rout)" skills/reviewer-protocol/SKILL.md \
    || { echo "SKILL.md must forbid silent acceptance/drop/default-routing of malformed findings"; return 1; }
}

@test "reviewer protocol does not present category: as an accepted synonym/alias for change_type:" {
  # Forbid wording that would soften the field-name contract — e.g.
  # "category: is accepted as a synonym/alias for change_type". The bare
  # word "category" still legitimately appears in classifier prose ("five
  # categories"); the regression here is specifically a frontmatter-field
  # alias claim.
  ! grep -qiE 'category[^a-z]+(is|may be)[^.]*(synonym|alias|accepted|equivalent).*change_type' skills/reviewer-protocol/SKILL.md \
    || { echo "SKILL.md must not present category: as a synonym for change_type:"; return 1; }
  ! grep -qiE 'change_type[^a-z]+(or|aka|alias|synonym)[^.]*category' skills/reviewer-protocol/SKILL.md \
    || { echo "SKILL.md must not present category: as a synonym for change_type:"; return 1; }
}

@test "audit: no valid finding-frontmatter example uses category: in touched files" {
  # Scope: the reviewer-protocol skill (SKILL.md and emission siblings) and
  # this test's fixtures. Historical artifacts under docs/qrspi/ are out of
  # scope for this audit per the task's touched-file framing.
  local scope=(
    skills/reviewer-protocol/SKILL.md
    skills/reviewer-protocol/first-party-emission.md
    skills/reviewer-protocol/third-party-emission.md
    skills/reviewer-protocol/codex-emission-override.md
    tests/unit/test-change-type-partition.bats
    tests/fixtures/change-type-required/round-01/well-formed-claude.finding-F02.md
  )
  local f
  for f in "${scope[@]}"; do
    [[ -f "$f" ]] || continue
    # Match a frontmatter-style field at column zero. The legacy-drift
    # fixture is intentionally excluded — it is the negative test input,
    # not a valid example.
    if grep -nE '^category:' "$f" >/dev/null; then
      echo "found category: frontmatter line in $f"
      grep -nE '^category:' "$f"
      return 1
    fi
  done
}

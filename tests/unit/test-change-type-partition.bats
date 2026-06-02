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

# _test_mirror_partition_finding — test-local mirror of the schema-guard contract
# documented in skills/reviewer-protocol/SKILL.md § Finding Schema. The production
# schema guard that enforces this contract lives in scripts/verifier-fan-in.sh
# (added in a subsequent task). Until that lands, these tests pin only the
# contract shape, not its enforcement in production routing.
#
# Returns 0 and prints the routed change_type on a well-formed finding;
# returns non-zero with a named-cause diagnostic on missing change_type.
# Parsing is restricted to the frontmatter block (between the first two
# `---` markers) so a `change_type:` token appearing only in body prose
# does not falsely route a frontmatter-malformed finding.
_test_mirror_partition_finding() {
  local f="$1"
  local ct
  ct=$(awk -F': *' '
    BEGIN { in_fm = 0; fm_count = 0 }
    /^---$/ { fm_count++; in_fm = (fm_count == 1); next }
    in_fm && /^change_type:/ { print $2; exit }
  ' "$f")
  if [[ -z "$ct" ]]; then
    echo "schema-guard: missing required field 'change_type:' in $f" >&2
    return 2
  fi
  echo "$ct"
}

@test "schema guard halts with named cause when change_type is missing (legacy category-only finding) (test-mirror)" {
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
  out=$(_test_mirror_partition_finding "$fixture" 2>"$BATS_TEST_TMPDIR/ct-stderr.log") && rc=0 || rc=$?
  err=$(cat "$BATS_TEST_TMPDIR/ct-stderr.log")

  [[ "$rc" -ne 0 ]] || { echo "expected non-zero exit, got 0 (silent acceptance)"; return 1; }
  [[ -z "$out" ]] || { echo "expected no routed change_type on stdout, got: $out"; return 1; }
  echo "$err" | grep -qE "missing required field 'change_type:'" \
    || { echo "expected named missing-field diagnostic, got: $err"; return 1; }
}

@test "well-formed change_type finding is accepted and routed by that field name (test-mirror)" {
  local fixture=tests/fixtures/change-type-required/round-01/well-formed-claude.finding-F02.md
  [[ -f "$fixture" ]] || { echo "fixture missing: $fixture"; return 1; }

  local out rc
  out=$(_test_mirror_partition_finding "$fixture" 2>/dev/null) && rc=0 || rc=$?
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
    [[ -f "$f" ]] || { echo "scope audit: required file missing: $f" >&2; return 1; }
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

# ===========================================================================
# G13 enum-drift hardening (script-side enforcement + reviewer-protocol prose)
# ---------------------------------------------------------------------------
# The six tests below pin the canonical 5-value `change_type` enum as a single
# source of truth on both sides of the fan-in boundary:
#
#   * scripts/verifier-fan-in.sh declares the enum once in its header and uses
#     that single set for membership validation.
#   * out-of-enum `change_type:` values trigger a loud halt with named cause
#     `change_type_out_of_enum`, NOT silent-default-keep / silent-keep / silent-
#     drop, and NOT collapsed into the missing-field path.
#   * the missing-field path remains a DISTINCT `missing_change_type` halt
#     cause (preserves the T04 schema-failure contract).
#   * all five canonical values flow through the same parser path on success.
#   * skills/reviewer-protocol/SKILL.md documents the same canonical enum once
#     as the reviewer emission contract and names out-of-enum emission as a
#     fan-in-consumed contract violation.
#   * no other skill / script duplicates the 5-value enum alternation.
# ===========================================================================

# _run_fan_in_on_fixture <fixture-round-dir>
# Copies a read-only fixture round to BATS_TEST_TMPDIR (the fan-in script
# writes .verifier-fan-in-audit.json + kept-findings.txt INTO the round dir,
# so the source fixture must not be mutated across runs) and invokes
# scripts/verifier-fan-in.sh on the copy. Sets RC, AUDIT (path to audit json),
# and KEPT (path to kept-findings.txt) for the caller.
_run_fan_in_on_fixture() {
  local src="$1"
  [[ -d "$src" ]] || { echo "fixture round missing: $src" >&2; return 99; }
  local name="${src##*/}"
  local dest="$BATS_TEST_TMPDIR/$name"
  rm -rf "$dest"
  cp -R "$src" "$dest"
  AUDIT="$dest/.verifier-fan-in-audit.json"
  KEPT="$dest/kept-findings.txt"
  RC=0
  bash scripts/verifier-fan-in.sh "$dest" >"$BATS_TEST_TMPDIR/fan-in.stdout" 2>"$BATS_TEST_TMPDIR/fan-in.stderr" || RC=$?
}

@test "G13: out-of-enum change_type triggers change_type_out_of_enum halt and blocks kept-findings.txt" {
  # Test expectation 1: fixture round with finding carrying a non-canonical
  # change_type value. scripts/verifier-fan-in.sh must exit non-zero, write
  # .verifier-fan-in-audit.json with a halts[] entry whose cause is
  # change_type_out_of_enum AND that identifies the offending finding, and
  # must NOT produce a successful kept-findings.txt fan-in result.
  command -v jq >/dev/null 2>&1 || skip "jq required to parse audit json"
  _run_fan_in_on_fixture tests/fixtures/change-type-enum/round-out-of-enum

  [[ "$RC" -ne 0 ]] \
    || { echo "expected non-zero exit on out-of-enum change_type, got 0"; cat "$BATS_TEST_TMPDIR/fan-in.stderr"; return 1; }
  [[ -f "$AUDIT" ]] \
    || { echo "expected audit JSON at $AUDIT"; return 1; }

  # Halt must name change_type_out_of_enum specifically — not the missing-
  # field cause, not a generic "schema" cause.
  local causes
  causes=$(jq -r '.halts[].cause' "$AUDIT")
  echo "$causes" | grep -qx 'change_type_out_of_enum' \
    || { echo "expected halts[].cause to include change_type_out_of_enum; got: $causes"; return 1; }
  ! echo "$causes" | grep -qx 'missing_change_type' \
    || { echo "out-of-enum value must not be reported as missing_change_type"; return 1; }

  # The offending finding must be identified — either by its finding_id from
  # frontmatter or by its filename stem. The fixture uses finding_id R1-F01.
  local fids
  fids=$(jq -r '.halts[] | select(.cause=="change_type_out_of_enum") | .finding_id' "$AUDIT")
  echo "$fids" | grep -qE '(R1-F01|enum-test-claude\.finding-F01)' \
    || { echo "halt entry must identify the offending finding; got finding_id=$fids"; return 1; }

  # No successful kept-findings.txt result. The script removes any stale
  # kept-findings.txt before exiting on a halt; the file must be absent.
  [[ ! -e "$KEPT" ]] \
    || { echo "kept-findings.txt must not exist on halt; found $KEPT with contents:"; cat "$KEPT"; return 1; }
}

@test "G13: all five canonical change_type values are accepted through the same parser path" {
  # Test expectation 2: a round containing one finding per canonical value
  # (style, clarity, correctness, scope, intent), each with a paired sidecar
  # whose score clears every per-change_type floor, must succeed: exit 0,
  # kept-findings.txt listing all five paths, audit JSON with empty halts[].
  command -v jq >/dev/null 2>&1 || skip "jq required to parse audit json"
  _run_fan_in_on_fixture tests/fixtures/change-type-enum/round-all-canonical

  [[ "$RC" -eq 0 ]] \
    || { echo "expected exit 0 on canonical-enum round, got $RC"; cat "$BATS_TEST_TMPDIR/fan-in.stderr"; return 1; }
  [[ -f "$KEPT" ]] || { echo "expected kept-findings.txt at $KEPT"; return 1; }
  [[ -f "$AUDIT" ]] || { echo "expected audit JSON at $AUDIT"; return 1; }

  local kept_count
  kept_count=$(grep -c . "$KEPT" || true)
  [[ "$kept_count" -eq 5 ]] \
    || { echo "expected 5 kept findings, got $kept_count"; cat "$KEPT"; return 1; }

  # Every canonical value's finding must appear in kept-findings.txt — proves
  # all five values flowed through the same parser path, not just the keepers
  # that happen to bypass the threshold filter (scope/intent).
  local ct
  for ct in style clarity correctness scope intent; do
    grep -qE "canonical-claude\.finding-F0[0-9]+\.md$" "$KEPT" \
      || { echo "kept-findings.txt missing finding files"; cat "$KEPT"; return 1; }
  done
  # Per-value presence by counting fixture files (each fixture's change_type
  # is the only differentiator); cross-check by reading each kept path and
  # confirming the set of change_type values is exactly the canonical 5.
  local seen
  seen=$(while IFS= read -r p; do
           awk -F': *' '
             BEGIN { n=0; in_fm=0 }
             /^---[[:space:]]*$/ { n++; in_fm=(n==1); next }
             in_fm && /^change_type:/ { print $2; exit }
           ' "$p"
         done <"$KEPT" | sort -u | tr '\n' ' ')
  [[ "$seen" == "clarity correctness intent scope style " ]] \
    || { echo "expected canonical 5 values in kept set; got: '$seen'"; return 1; }

  # Audit must record zero halts.
  local halts_len
  halts_len=$(jq -r '.halts | length' "$AUDIT")
  [[ "$halts_len" -eq 0 ]] \
    || { echo "expected halts=[]; got length $halts_len: $(jq -c '.halts' "$AUDIT")"; return 1; }
}

@test "G13: missing change_type is reported as missing_change_type, NOT change_type_out_of_enum" {
  # Test expectation 3: preserve the T04 distinct schema-failure path. A
  # finding whose frontmatter omits change_type: entirely must halt with
  # cause missing_change_type — never collapsed into the out-of-enum bucket.
  command -v jq >/dev/null 2>&1 || skip "jq required to parse audit json"
  _run_fan_in_on_fixture tests/fixtures/change-type-enum/round-missing

  [[ "$RC" -ne 0 ]] \
    || { echo "expected non-zero exit on missing change_type, got 0"; return 1; }
  [[ -f "$AUDIT" ]] || { echo "expected audit JSON at $AUDIT"; return 1; }

  local causes
  causes=$(jq -r '.halts[].cause' "$AUDIT")
  echo "$causes" | grep -qx 'missing_change_type' \
    || { echo "expected halts[].cause to include missing_change_type; got: $causes"; return 1; }
  ! echo "$causes" | grep -qx 'change_type_out_of_enum' \
    || { echo "missing field must not be reported as change_type_out_of_enum; got: $causes"; return 1; }
}

@test "G13: scripts/verifier-fan-in.sh declares the canonical enum once and validates against that single set" {
  # Test expectation 4: the script must expose ONE canonical enum definition
  # in its header (a single CHANGE_TYPE_ENUM array or readonly string) AND
  # the membership-check logic must reference that single source. The literal
  # enum alternation must not be duplicated elsewhere in the script body.
  local script=scripts/verifier-fan-in.sh
  [[ -f "$script" ]] || { echo "$script missing"; return 1; }

  # (a) Exactly one canonical-enum DEFINITION line. Accept either a bash
  #     array literal or a readonly string with the 5 values in any order
  #     within the alternation, but require all five values to appear in
  #     the single defining line. Use grep WITHOUT -n here so the captured
  #     text is the raw definition line (no LINENO: prefix to strip later).
  local def_line def_count
  def_line=$(grep -E '^[[:space:]]*(readonly[[:space:]]+)?[A-Z_]*CHANGE_TYPE[A-Z_]*=(\(|")' "$script" || true)
  def_count=$(printf '%s\n' "$def_line" | grep -c . || true)
  [[ "$def_count" -eq 1 ]] \
    || { echo "expected exactly 1 CHANGE_TYPE enum definition line in $script, got $def_count:"; printf '%s\n' "$def_line"; return 1; }

  # The single defining line must list all five canonical values.
  local v
  for v in style clarity correctness scope intent; do
    echo "$def_line" | grep -qw "$v" \
      || { echo "canonical enum definition is missing value '$v': $def_line"; return 1; }
  done

  # (b) Membership-check logic must REFERENCE the defined constant rather
  #     than re-listing the values inline. Extract the variable name from
  #     the definition line, then confirm at least one usage of $VAR or
  #     ${VAR[@]} appears on some OTHER line in the script.
  local var_name def_lineno usage_lines
  var_name=$(printf '%s\n' "$def_line" | sed -E 's/^[[:space:]]*(readonly[[:space:]]+)?([A-Z_]*CHANGE_TYPE[A-Z_]*)=.*/\2/')
  [[ -n "$var_name" && "$var_name" != "$def_line" ]] \
    || { echo "could not extract enum variable name from: $def_line"; return 1; }
  def_lineno=$(grep -nF "$def_line" "$script" | head -1 | cut -d: -f1)
  usage_lines=$(grep -nE "\\\$\{?${var_name}([\[}]|$|[^A-Z_])" "$script" \
                | awk -F: -v skip="$def_lineno" '$1 != skip { print }')
  [[ -n "$usage_lines" ]] \
    || { echo "validation logic must reference \$$var_name on a line other than its definition (line $def_lineno); no such reference found in $script"; return 1; }

  # (c) No duplicated literal enum alternation elsewhere in the script body.
  #     Specifically, the 5-value alternation `style|clarity|correctness|scope|intent`
  #     (in any order) must not appear as a regex alternation outside the
  #     single defining line.
  local dup_alt
  dup_alt=$(grep -nE 'style\|clarity\|correctness\|scope\|intent|intent\|scope\|correctness\|clarity\|style' "$script" || true)
  [[ -z "$dup_alt" ]] \
    || { echo "duplicated 5-value enum alternation in $script:"; printf '%s\n' "$dup_alt"; return 1; }
}

@test "G13: skills/reviewer-protocol/SKILL.md documents the canonical enum once and names out-of-enum as a fan-in-consumed contract violation" {
  # Test expectation 5: SKILL.md must document the same canonical enum once
  # as the reviewer emission contract AND describe out-of-enum emission as
  # a contract violation consumed by the fan-in script.
  local skill=skills/reviewer-protocol/SKILL.md
  [[ -f "$skill" ]] || { echo "$skill missing"; return 1; }

  # (a) The canonical 5-value enum must appear (style, clarity, correctness,
  #     scope, intent named together on one line — the classifier line).
  grep -qE 'style.*clarity.*correctness.*scope.*intent' "$skill" \
    || { echo "$skill must document the canonical 5-value change_type enum"; return 1; }

  # (b) Out-of-enum emission must be named as a contract violation consumed
  #     by the fan-in script. Accept reasonable wording variations.
  grep -qiE '(out-of-enum|out of enum|outside.*enum|not in.*enum)' "$skill" \
    || { echo "$skill must name out-of-enum change_type emission explicitly"; return 1; }
  grep -qiE '(contract violation|loud[ -]failure|halt|halts|reject)' "$skill" \
    || { echo "$skill must describe out-of-enum as a loud-failure/contract-violation"; return 1; }
  grep -qiE '(fan-?in|verifier-fan-in)' "$skill" \
    || { echo "$skill must name the fan-in script as the consumer that enforces the enum contract"; return 1; }

  # (c) The single-source requirement: the 5-value enum must not be repeated
  #     within SKILL.md across multiple separate definitional sentences. We
  #     allow at most ONE line that names all five values together (the
  #     classifier contract); additional lines that list all five values are
  #     a single-source-of-truth violation.
  local enum_line_count
  enum_line_count=$(grep -cE 'style.*clarity.*correctness.*scope.*intent' "$skill")
  [[ "$enum_line_count" -le 1 ]] \
    || { echo "$skill names the canonical 5-value enum on $enum_line_count lines; expected exactly 1 (single source of truth)"; grep -nE 'style.*clarity.*correctness.*scope.*intent' "$skill"; return 1; }
}

@test "G13: no duplicated 5-value change_type enum alternation outside SKILL.md and verifier-fan-in.sh" {
  # Test expectation 6: pin the no-duplication constraint across the
  # production surface (skills/ and scripts/). Historical docs under docs/
  # and dispositioned reviews are out of scope — they freeze the state at
  # the time they were written.
  #
  # Match the 5-value alternation `style|clarity|correctness|scope|intent`
  # in any permutation. Allow it ONLY in:
  #   - skills/reviewer-protocol/SKILL.md  (the reviewer-side source of truth)
  #   - scripts/verifier-fan-in.sh         (the script-side source of truth)
  local hits
  hits=$(grep -rEn 'style[[:space:]|,]+clarity[[:space:]|,]+correctness[[:space:]|,]+scope[[:space:]|,]+intent' skills/ scripts/ 2>/dev/null \
         | grep -vE '^(skills/reviewer-protocol/SKILL\.md|scripts/verifier-fan-in\.sh):' \
         || true)
  [[ -z "$hits" ]] \
    || { echo "duplicated 5-value change_type enum alternation found outside the canonical sources:"; printf '%s\n' "$hits"; return 1; }
}

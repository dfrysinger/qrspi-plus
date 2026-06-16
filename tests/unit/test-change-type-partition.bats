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
    [[ "$f" == *.score.md ]] && continue
    local sc="${f%.md}.score.md"
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
  # Scope: the reviewer-protocol skill (SKILL.md and the unified emission
  # contract) and this test's fixtures. Historical artifacts under
  # docs/qrspi/ are out of scope for this audit per the task's
  # touched-file framing.
  local scope=(
    skills/reviewer-protocol/SKILL.md
    skills/reviewer-protocol/emission.md
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
# Enum-drift hardening (script-side enforcement + reviewer-protocol prose)
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
#     cause (preserves the schema-failure contract pinned by the earlier
#     change_type-required tests above).
#   * all five canonical values flow through the same parser path on success.
#   * skills/reviewer-protocol/SKILL.md documents the same canonical enum once
#     as the reviewer emission contract and names out-of-enum emission as a
#     fan-in-consumed contract violation.
#   * no other skill / script duplicates the 5-value enum alternation.
# ===========================================================================

# _run_fan_in_on_fixture <fixture-round-dir>
# Copies a read-only fixture round to a fresh BATS_TEST_TMPDIR subdir (the
# fan-in script writes .verifier-fan-in-audit.json + kept-findings.txt INTO
# the round dir, so the source fixture must not be mutated across runs) and
# invokes scripts/verifier-fan-in.sh on the copy. Sets RC, AUDIT (path to
# audit json), KEPT (path to kept-findings.txt), and FIXTURE_DEST (the
# symlink-resolved copy root used by callers as a sandbox prefix bound for
# any awk path-walk over kept-findings.txt) for the caller. Every call site
# MUST check the helper's return code so an environment-setup failure
# (missing fixture, unsafe basename, copy failure, pwd-resolve failure)
# surfaces with a named diagnostic instead of being silently coerced to
# RC=0 downstream.
_run_fan_in_on_fixture() {
  local src="$1"
  [[ -d "$src" ]] || { echo "fixture round missing: $src" >&2; return 99; }
  local name="${src##*/}"
  # Reject path-traversal / empty / nested basenames before they reach mktemp
  # or cp -R. A `src` of `path/..` would otherwise yield name=".." and a
  # destination resolving outside BATS_TEST_TMPDIR.
  case "$name" in
    ''|'.'|'..'|*/*)
      echo "unsafe fixture basename derived from '$src': '$name'" >&2
      return 98
      ;;
  esac
  local dest
  dest=$(mktemp -d "$BATS_TEST_TMPDIR/fixture-${name}-XXXXXX") \
    || { echo "mktemp failed under $BATS_TEST_TMPDIR" >&2; return 97; }
  # Copy contents (not the directory itself) so the audit + kept-findings
  # outputs land directly in $dest. Trailing `/.` is the standard portable
  # form for "copy contents of src into dest". `-L` dereferences any
  # symlinks at copy time so a symlinked finding in the fixture cannot
  # survive into $dest and slip past the textual `[[ "$p" == "$FIXTURE_DEST"/* ]]`
  # prefix guard (the OS would follow the symlink target out of the sandbox
  # at awk-read time). With -L, every entry under $dest is a regular file
  # whose bytes are physically inside the sandbox.
  cp -RL "$src/." "$dest/" \
    || { echo "cp -RL failed for $src -> $dest" >&2; return 96; }
  AUDIT="$dest/.verifier-fan-in-audit.json"
  KEPT="$dest/kept-findings.txt"
  RC=0
  bash scripts/verifier-fan-in.sh "$dest" \
    >"$BATS_TEST_TMPDIR/fan-in.stdout" 2>"$BATS_TEST_TMPDIR/fan-in.stderr" \
    || RC=$?
  # Resolve symlinks (macOS /var → /private/var) so callers comparing kept
  # paths against the fixture root with a prefix match — a defense-in-depth
  # bound to keep awk parsing inside the sandbox — see the same resolution
  # the script applies internally (`pwd -P`). Guard the assignment: a
  # `VAR=$(cd … && pwd -P)` form does NOT propagate the subshell's exit
  # code on its own (a `cd` failure would silently leave FIXTURE_DEST
  # empty, and `[[ "$p" == /* ]]` with an unquoted RHS treats `*` as a
  # glob — matching every absolute path and neutering the sandbox bound).
  FIXTURE_DEST="$(cd "$dest" && pwd -P)" \
    || { echo "pwd -P failed resolving $dest" >&2; return 95; }
  [[ -n "$FIXTURE_DEST" ]] \
    || { echo "FIXTURE_DEST resolved to empty for $dest" >&2; return 95; }
}

@test "_run_fan_in_on_fixture surfaces pwd -P failure as non-zero (FIXTURE_DEST never silently empty)" {
  # Hardening rationale: a `VAR=$(cd … && pwd -P)` assignment does NOT propagate
  # the subshell's exit code to the outer shell — on failure the helper would
  # silently set FIXTURE_DEST="" and return 0, leaving the sandbox prefix
  # check (`[[ "$p" == "$FIXTURE_DEST"/* ]]`) effectively neutered (matches
  # any absolute path). Pin that the helper now surfaces this failure.
  #
  # We force `cd "$dest" && pwd -P` to fail by shadowing `pwd` with a
  # function that returns non-zero. Bash command substitution runs in a
  # subshell that inherits the caller's functions, so the override fires
  # inside the helper. (`cd` itself succeeds — `dest` is a fresh mktemp dir.)
  pwd() { return 1; }
  local helper_rc=0
  _run_fan_in_on_fixture tests/fixtures/change-type-enum/round-all-canonical \
    || helper_rc=$?
  unset -f pwd
  [[ "$helper_rc" -ne 0 ]] \
    || { echo "expected helper to fail when pwd -P fails; got rc=0 with FIXTURE_DEST='$FIXTURE_DEST'"; return 1; }
  # Be specific: helper should surface this with the named return code 95
  # so a future regression that swallows pwd-P's failure on a different
  # path (e.g. a `|| true` re-introduction) does not pass this test by
  # accidentally returning some OTHER non-zero code from a later step.
  [[ "$helper_rc" -eq 95 ]] \
    || { echo "expected helper rc=95 (named pwd-P failure code); got $helper_rc"; return 1; }
}

@test "_run_fan_in_on_fixture dereferences fixture symlinks (sandbox prefix guard cannot be bypassed via symlink)" {
  # Hardening rationale: `cp -R` (no -L) preserves symlinks. A symlinked
  # finding in the fixture would survive the copy, the textual prefix
  # guard `[[ "$p" == "$FIXTURE_DEST"/* ]]` would pass on the symlink path,
  # and `awk "$p"` would follow it OUT of the sandbox to read the target.
  # Switching to `cp -RL` dereferences symlinks at copy time, so nothing
  # under $FIXTURE_DEST can point outside the sandbox.
  local outside="$BATS_TEST_TMPDIR/outside-target.txt"
  printf 'change_type: malicious\n' >"$outside"
  local src="$BATS_TEST_TMPDIR/symlink-fixture-round"
  mkdir -p "$src"
  # Plant a regular file plus a symlink whose name matches the
  # finding-shaped pattern the fan-in script picks up.
  printf -- '---\nchange_type: style\n---\n' >"$src/regular-claude.finding-F01.md"
  ln -s "$outside" "$src/symlinked-claude.finding-F01.md"
  # No `|| true`: the helper's contract reserves rc 95-99 for setup
  # failures (missing fixture, bad basename, mktemp/cp/pwd) — those
  # MUST surface. The fan-in script's pass/fail verdict on the synthetic
  # fixture is captured internally in $RC and is not what we assert here;
  # we assert the post-copy filesystem state under $FIXTURE_DEST.
  _run_fan_in_on_fixture "$src"
  [[ -n "$FIXTURE_DEST" ]] || { echo "FIXTURE_DEST empty"; return 1; }
  [[ -e "$FIXTURE_DEST/symlinked-claude.finding-F01.md" ]] \
    || { echo "expected the symlink-named entry to land in the sandbox copy"; return 1; }
  # Post-fix: copy must NOT preserve the symlink. With `cp -RL`, the entry
  # at $FIXTURE_DEST/symlinked-... is a regular file containing the
  # target's BYTES (not a symlink to outside).
  [[ ! -L "$FIXTURE_DEST/symlinked-claude.finding-F01.md" ]] \
    || { echo "fixture copy preserved a symlink — cp must dereference (-L) to keep awk path-walks inside the sandbox"; return 1; }
}

@test "out-of-enum change_type triggers change_type_out_of_enum halt and blocks kept-findings.txt" {
  # Test expectation 1: fixture round with finding carrying a non-canonical
  # change_type value. scripts/verifier-fan-in.sh must exit non-zero, write
  # .verifier-fan-in-audit.json with a halts[] entry whose cause is
  # change_type_out_of_enum AND that identifies the offending finding, and
  # must NOT produce a successful kept-findings.txt fan-in result.
  command -v jq >/dev/null 2>&1 || skip "jq required to parse audit json"
  _run_fan_in_on_fixture tests/fixtures/change-type-enum/round-out-of-enum \
    || { echo "fixture setup failed (exit $?)"; return 1; }

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

@test "all five canonical change_type values are accepted through the same parser path" {
  # Test expectation 2: a round containing one finding per canonical value
  # (style, clarity, correctness, scope, intent), each with a paired sidecar
  # whose score clears every per-change_type floor, must succeed: exit 0,
  # kept-findings.txt listing all five paths, audit JSON with empty halts[].
  command -v jq >/dev/null 2>&1 || skip "jq required to parse audit json"
  _run_fan_in_on_fixture tests/fixtures/change-type-enum/round-all-canonical \
    || { echo "fixture setup failed (exit $?)"; return 1; }

  [[ "$RC" -eq 0 ]] \
    || { echo "expected exit 0 on canonical-enum round, got $RC"; cat "$BATS_TEST_TMPDIR/fan-in.stderr"; return 1; }
  [[ -f "$KEPT" ]] || { echo "expected kept-findings.txt at $KEPT"; return 1; }
  [[ -f "$AUDIT" ]] || { echo "expected audit JSON at $AUDIT"; return 1; }

  local kept_count
  # Don't mask grep errors with `|| true`. If $KEPT is missing or unreadable
  # that's a real failure to surface, not a "no match" condition.
  kept_count=$(grep -c . "$KEPT")
  [[ "$kept_count" -eq 5 ]] \
    || { echo "expected 5 kept findings, got $kept_count"; cat "$KEPT"; return 1; }

  # Per-value presence by reading each kept path and confirming the set of
  # change_type values is exactly the canonical 5 — proves all five values
  # flowed through the same parser path, not just the keepers that happen
  # to bypass the threshold filter (scope/intent). Bound each path to live
  # under the fixture destination so a malformed kept-findings.txt cannot
  # redirect us at files outside the test sandbox.
  local seen
  seen=$(while IFS= read -r p; do
           [[ "$p" == "$FIXTURE_DEST"/* ]] || continue
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

@test "missing change_type is reported as missing_change_type, NOT change_type_out_of_enum" {
  # Test expectation 3: preserve the distinct schema-failure path. A finding
  # whose frontmatter omits change_type: entirely must halt with cause
  # missing_change_type — never collapsed into the out-of-enum bucket.
  command -v jq >/dev/null 2>&1 || skip "jq required to parse audit json"
  _run_fan_in_on_fixture tests/fixtures/change-type-enum/round-missing \
    || { echo "fixture setup failed (exit $?)"; return 1; }

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

@test "scripts/verifier-fan-in.sh declares the canonical enum once and validates against that single set" {
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
  local def_line def_count rc
  rc=0
  def_line=$(grep -E '^[[:space:]]*(readonly[[:space:]]+)?[A-Z_]*CHANGE_TYPE[A-Z_]*=(\(|")' "$script") || rc=$?
  [[ $rc -le 1 ]] \
    || { echo "grep failed (exit $rc) scanning $script for CHANGE_TYPE definition"; return 1; }
  rc=0
  def_count=$(printf '%s\n' "$def_line" | grep -c .) || rc=$?
  [[ $rc -le 1 ]] \
    || { echo "grep -c failed counting CHANGE_TYPE definition lines (exit $rc)"; return 1; }
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

  # (c) No duplicated literal 5-value enum alternation elsewhere in the
  #     script body. Match the canonical set as a regex alternation in ANY
  #     permutation — five `(style|clarity|correctness|scope|intent)` slots
  #     joined by literal pipes — so a re-listing in any order trips the
  #     duplication check, not just the canonical-order spelling.
  local dup_alt
  rc=0
  dup_alt=$(grep -nE '(style|clarity|correctness|scope|intent)\|(style|clarity|correctness|scope|intent)\|(style|clarity|correctness|scope|intent)\|(style|clarity|correctness|scope|intent)\|(style|clarity|correctness|scope|intent)' "$script") || rc=$?
  # grep exit codes: 0 = match, 1 = no match (both OK), 2+ = real error.
  # `|| true` would mask the 2+ case and let an unreadable script slip past.
  [[ $rc -le 1 ]] \
    || { echo "grep failed (exit $rc) scanning $script for duplicated enum alternation"; return 1; }
  # Filter out the canonical defining line by line number (a definition that
  # spelled the values pipe-alternated would itself match the detector).
  if [[ -n "$dup_alt" ]]; then
    dup_alt=$(printf '%s\n' "$dup_alt" | awk -F: -v skip="$def_lineno" 'NF && $1 != skip { print }')
  fi
  [[ -z "$dup_alt" ]] \
    || { echo "duplicated 5-value enum alternation in $script:"; printf '%s\n' "$dup_alt"; return 1; }
}

@test "skills/reviewer-protocol/SKILL.md documents the canonical enum once and names out-of-enum as a fan-in-consumed contract violation" {
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

@test "no duplicated 5-value change_type enum alternation outside SKILL.md and verifier-fan-in.sh" {
  # Test expectation 6: pin the no-duplication constraint across the
  # production surface (skills/ and scripts/). Historical docs under docs/
  # and dispositioned reviews are out of scope — they freeze the state at
  # the time they were written.
  #
  # Match the 5-value alternation in ANY permutation — five
  # `(style|clarity|correctness|scope|intent)` slots joined by literal pipes
  # — so any non-canonical ordering trips the duplication detector. Allow
  # the alternation ONLY in:
  #   - skills/reviewer-protocol/SKILL.md  (the reviewer-side source of truth)
  #   - scripts/verifier-fan-in.sh         (the script-side source of truth)
  #
  # The previous spelling used `[[:space:]|,]` which is a CHARACTER class
  # (literal `|` inside `[...]`, not regex alternation), so it silently
  # accepted `style clarity correctness scope intent` — a non-pipe spelling
  # that isn't the duplication shape we care about — and missed all 119
  # non-canonical permutations.
  #
  # Cardinality note: this regex matches the SHAPE (5 pipe-joined slots,
  # each from the canonical set), not the SET (5 distinct values). It
  # therefore admits a theoretical false-positive like
  # `style|style|style|style|style`. We accept this trade-off: a 5-token
  # all-same alternation has no real production use case, while extracting
  # captures and sort -u-ing them per match would substantially complicate
  # the detector for a defect class no reviewer or developer would write.
  local hits rc=0
  hits=$(grep -rEn '(style|clarity|correctness|scope|intent)\|(style|clarity|correctness|scope|intent)\|(style|clarity|correctness|scope|intent)\|(style|clarity|correctness|scope|intent)\|(style|clarity|correctness|scope|intent)' skills/ scripts/ 2>/dev/null) || rc=$?
  # Treat exit 0 (matches) and 1 (no matches) as successful scans; exit 2+
  # means grep itself errored (e.g. unreadable file) — surface, don't mask.
  [[ $rc -le 1 ]] \
    || { echo "recursive grep failed (exit $rc) scanning skills/ scripts/"; return 1; }
  if [[ -n "$hits" ]]; then
    # Same exit-code discipline as the outer scan: exit 0 = some hits
    # remained after filtering canonical sources (real duplicates), exit 1
    # = all hits were in canonical sources (clean), exit 2+ = grep itself
    # errored — surface, don't mask. `|| true` would collapse 2+ into a
    # silent pass and a runtime regex/IO error would produce a false-clean.
    local filter_rc=0
    hits=$(printf '%s\n' "$hits" | grep -vE '^(skills/reviewer-protocol/SKILL\.md|scripts/verifier-fan-in\.sh):') || filter_rc=$?
    [[ $filter_rc -le 1 ]] \
      || { echo "grep -vE filter failed (exit $filter_rc) on dup-alt hits"; return 1; }
  fi
  [[ -z "$hits" ]] \
    || { echo "duplicated 5-value change_type enum alternation found outside the canonical sources:"; printf '%s\n' "$hits"; return 1; }
}

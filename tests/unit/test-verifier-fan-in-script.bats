#!/usr/bin/env bats
# Unit tests for scripts/verifier-fan-in.sh — the canonical fan-in filter.
# Pins the script-owned threshold rule (single source of truth per CD-4),
# the kept-findings.txt + .verifier-fan-in-audit.json output contract, and
# the loud-failure halt-cause taxonomy.

setup() {
  REPO_ROOT="$(git rev-parse --show-toplevel)"
  SCRIPT="$REPO_ROOT/scripts/verifier-fan-in.sh"
  ROUND="$BATS_TEST_TMPDIR/round-NN"
  mkdir -p "$ROUND"
}

teardown() {
  # Restore permissions so BATS tmpdir cleanup can remove chmod 000 fixtures.
  chmod -R u+r "$BATS_TEST_TMPDIR" 2>/dev/null || true
}

# --- helpers ---------------------------------------------------------------

write_finding() {
  # write_finding <round-dir> <tag> <NN> <finding_id> <change_type>
  local dir="$1" tag="$2" nn="$3" fid="$4" ct="$5"
  local f="$dir/${tag}.finding-F${nn}.md"
  cat >"$f" <<EOF
---
finding_id: ${fid}
change_type: ${ct}
artifact: goals
round: 1
reviewer: ${tag}
---

Body of finding ${fid}.
EOF
  printf '%s\n' "$f"
}

write_finding_no_change_type() {
  local dir="$1" tag="$2" nn="$3" fid="$4"
  local f="$dir/${tag}.finding-F${nn}.md"
  cat >"$f" <<EOF
---
finding_id: ${fid}
artifact: goals
round: 1
reviewer: ${tag}
---

Body.
EOF
  printf '%s\n' "$f"
}

write_sidecar() {
  # write_sidecar <finding-path> <score>
  local f="$1" score="$2"
  local s="${f%.md}.score.md"
  cat >"$s" <<EOF
---
score: ${score}
defect_class: unspecified
---

Reasoning prose for sidecar.
EOF
}

write_sidecar_unparseable() {
  local f="$1"
  local s="${f%.md}.score.md"
  cat >"$s" <<EOF
---
score: not-a-number
---

Reasoning.
EOF
}

write_sidecar_wrong_ext() {
  local f="$1" score="$2"
  local s="${f%.md}.score.yml"
  cat >"$s" <<EOF
score: ${score}
EOF
}

# --- well-formed round -----------------------------------------------------

@test "well-formed round: exit 0, kept-findings.txt absolute paths, audit halts:[]" {
  local f1 f2 f3
  f1=$(write_finding "$ROUND" quality-claude 01 R1-F01 style)
  f2=$(write_finding "$ROUND" quality-claude 02 R1-F02 correctness)
  f3=$(write_finding "$ROUND" quality-claude 03 R1-F03 scope)
  write_sidecar "$f1" 90    # style 90 -> keep
  write_sidecar "$f2" 75    # correctness 75 -> keep
  write_sidecar "$f3" 10    # scope -> keep regardless of score

  run "$SCRIPT" "$ROUND"
  [ "$status" -eq 0 ]
  [ -f "$ROUND/kept-findings.txt" ]
  [ -f "$ROUND/.verifier-fan-in-audit.json" ]

  # all kept, in absolute-path form
  run wc -l "$ROUND/kept-findings.txt"
  [[ "$output" =~ ^[[:space:]]*3 ]]
  while IFS= read -r line; do
    [[ "$line" = /* ]] || { echo "non-absolute path: $line"; return 1; }
  done <"$ROUND/kept-findings.txt"

  # audit JSON shape
  run jq -r '.scored,.kept,.dropped,(.halts|length),.thresholds.style,.thresholds.clarity,.thresholds.correctness' \
    "$ROUND/.verifier-fan-in-audit.json"
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" == "3" ]]
  [[ "${lines[1]}" == "3" ]]
  [[ "${lines[2]}" == "0" ]]
  [[ "${lines[3]}" == "0" ]]
  [[ "${lines[4]}" == "80" ]]
  [[ "${lines[5]}" == "80" ]]
  [[ "${lines[6]}" == "70" ]]
}

# --- threshold rule --------------------------------------------------------

@test "threshold rule: style/clarity below 80 dropped; correctness below 70 dropped" {
  local f1 f2 f3 f4 f5 f6
  f1=$(write_finding "$ROUND" qc 01 F01 style);       write_sidecar "$f1" 79  # drop
  f2=$(write_finding "$ROUND" qc 02 F02 style);       write_sidecar "$f2" 80  # keep
  f3=$(write_finding "$ROUND" qc 03 F03 clarity);     write_sidecar "$f3" 79  # drop
  f4=$(write_finding "$ROUND" qc 04 F04 clarity);     write_sidecar "$f4" 80  # keep
  f5=$(write_finding "$ROUND" qc 05 F05 correctness); write_sidecar "$f5" 69  # drop
  f6=$(write_finding "$ROUND" qc 06 F06 correctness); write_sidecar "$f6" 70  # keep

  run "$SCRIPT" "$ROUND"
  [ "$status" -eq 0 ]

  run jq -r '.scored,.kept,.dropped' "$ROUND/.verifier-fan-in-audit.json"
  [[ "${lines[0]}" == "6" ]]
  [[ "${lines[1]}" == "3" ]]
  [[ "${lines[2]}" == "3" ]]

  # only the keep findings appear in kept-findings.txt
  grep -q "F02.md$" "$ROUND/kept-findings.txt"
  grep -q "F04.md$" "$ROUND/kept-findings.txt"
  grep -q "F06.md$" "$ROUND/kept-findings.txt"
  ! grep -q "F01.md$" "$ROUND/kept-findings.txt"
  ! grep -q "F03.md$" "$ROUND/kept-findings.txt"
  ! grep -q "F05.md$" "$ROUND/kept-findings.txt"
}

@test "threshold rule: scope and intent kept regardless of score (above HALLUCINATED gate)" {
  local f1 f2
  # score:0 is dropped by the universal HALLUCINATED gate (added in task-08 R2)
  # regardless of change_type; scope/intent with any score > 0 are kept.
  f1=$(write_finding "$ROUND" qc 01 F01 scope);  write_sidecar "$f1" 1
  f2=$(write_finding "$ROUND" qc 02 F02 intent); write_sidecar "$f2" 5

  run "$SCRIPT" "$ROUND"
  [ "$status" -eq 0 ]
  run jq -r '.kept,.dropped' "$ROUND/.verifier-fan-in-audit.json"
  [[ "${lines[0]}" == "2" ]]
  [[ "${lines[1]}" == "0" ]]
}

@test "threshold rule: scope/intent with score:0 dropped by HALLUCINATED gate" {
  local f1 f2
  f1=$(write_finding "$ROUND" qc 01 F01 scope);  write_sidecar "$f1" 0
  f2=$(write_finding "$ROUND" qc 02 F02 intent); write_sidecar "$f2" 0

  run "$SCRIPT" "$ROUND"
  [ "$status" -eq 0 ]
  run jq -r '.kept,.dropped' "$ROUND/.verifier-fan-in-audit.json"
  [[ "${lines[0]}" == "0" ]]
  [[ "${lines[1]}" == "2" ]]
}

# --- halt: missing change_type --------------------------------------------

@test "halt: missing change_type exits non-zero and records cause" {
  local f1
  f1=$(write_finding_no_change_type "$ROUND" qc 01 F01)
  write_sidecar "$f1" 90

  run "$SCRIPT" "$ROUND"
  [ "$status" -ne 0 ]
  run jq -r '.halts[0].cause' "$ROUND/.verifier-fan-in-audit.json"
  [[ "$output" == "missing_change_type" ]]
}

# --- halt: out-of-enum change_type ----------------------------------------

@test "halt: out-of-enum change_type exits non-zero and records cause" {
  local f1
  f1=$(write_finding "$ROUND" qc 01 F01 bogus-category)
  write_sidecar "$f1" 90

  run "$SCRIPT" "$ROUND"
  [ "$status" -ne 0 ]
  run jq -r '.halts[0].cause' "$ROUND/.verifier-fan-in-audit.json"
  [[ "$output" == "change_type_out_of_enum" ]]
}

# --- halt: missing sidecar -------------------------------------------------

@test "halt: missing sidecar exits non-zero and records cause" {
  write_finding "$ROUND" qc 01 F01 style >/dev/null
  # no sidecar at all

  run "$SCRIPT" "$ROUND"
  [ "$status" -ne 0 ]
  run jq -r '.halts[0].cause' "$ROUND/.verifier-fan-in-audit.json"
  [[ "$output" == "missing_sidecar" ]]
}

# --- halt: sidecar wrong extension ----------------------------------------

@test "halt: sidecar with wrong extension exits non-zero and records cause" {
  local f1
  f1=$(write_finding "$ROUND" qc 01 F01 style)
  write_sidecar_wrong_ext "$f1" 90  # writes .score.yml not .score.md

  run "$SCRIPT" "$ROUND"
  [ "$status" -ne 0 ]
  run jq -r '.halts[0].cause' "$ROUND/.verifier-fan-in-audit.json"
  [[ "$output" == "sidecar_wrong_extension" ]]
}

# --- halt: unparseable score ----------------------------------------------

@test "halt: unparseable score exits non-zero and records cause" {
  local f1
  f1=$(write_finding "$ROUND" qc 01 F01 style)
  write_sidecar_unparseable "$f1"

  run "$SCRIPT" "$ROUND"
  [ "$status" -ne 0 ]
  run jq -r '.halts[0].cause' "$ROUND/.verifier-fan-in-audit.json"
  [[ "$output" == "score_unparseable" ]]
}

# --- halt: stderr names the first cause -----------------------------------

@test "halt: stderr emits one-line message naming the first halt cause" {
  write_finding_no_change_type "$ROUND" qc 01 F01 >/dev/null
  # no sidecar either, but missing_change_type fires first

  run "$SCRIPT" "$ROUND"
  [ "$status" -ne 0 ]
  [[ "$stderr" == *"missing_change_type"* || "$output" == *"missing_change_type"* ]]
}

# --- ignores .score.md files when enumerating findings --------------------

@test "enumeration: *.finding-F*.md glob does not treat .score.md sidecars as findings" {
  local f1
  f1=$(write_finding "$ROUND" qc 01 F01 style)
  write_sidecar "$f1" 90

  run "$SCRIPT" "$ROUND"
  [ "$status" -eq 0 ]
  run jq -r '.scored' "$ROUND/.verifier-fan-in-audit.json"
  [[ "$output" == "1" ]]
}

# --- usage error ----------------------------------------------------------

@test "missing round-dir argument exits non-zero with usage on stderr" {
  run "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage"* || "$stderr" == *"Usage"* || "$output" == *"usage"* || "$stderr" == *"usage"* ]]
}

# ===========================================================================
# Round-01 review fixes
# ===========================================================================

# --- fix F01: octal arithmetic trap (security-claude) ---------------------
# Bash interprets a leading-zero integer as octal: $((089)) crashes under
# set -e; $((070)) silently gives 56 (wrong value).  Fix: $((10#$raw_score)).

@test "fix F01: score 089 treated as decimal 89 (not crash), style finding kept" {
  # $((089)) triggers "value too great for base" under set -e → script crashes
  # before writing any audit.  After fix (10# prefix): 089 → 89 ≥ 80 → KEPT.
  local f1
  f1=$(write_finding "$ROUND" qc 01 F01 style)
  write_sidecar "$f1" "089"

  run "$SCRIPT" "$ROUND"
  [ "$status" -eq 0 ]
  run jq -r '.kept' "$ROUND/.verifier-fan-in-audit.json"
  [[ "$output" == "1" ]]
}

@test "fix F01: score 070 treated as decimal 70 (not octal 56), correctness finding kept at threshold" {
  # $((070)) = 56 under bash octal rules; 56 < 70 → incorrectly DROPPED.
  # After fix: 10#070 = 70 ≥ correctness threshold 70 → KEPT.
  local f1
  f1=$(write_finding "$ROUND" qc 01 F01 correctness)
  write_sidecar "$f1" "070"

  run "$SCRIPT" "$ROUND"
  [ "$status" -eq 0 ]
  run jq -r '.kept,.dropped' "$ROUND/.verifier-fan-in-audit.json"
  [[ "${lines[0]}" == "1" ]]
  [[ "${lines[1]}" == "0" ]]
}

# --- fix F02: halt path stderr ordering (silent-failure-claude) -----------
# write_audit ran BEFORE stderr echo; if write_audit fails under set -e the
# halt-cause message is never emitted.  Fix: echo >&2 FIRST, then
# write_audit || true.

@test "fix F02: stderr halt-cause emitted even when audit JSON cannot be written" {
  # Pre-create a directory at the audit JSON path to force write_audit failure.
  mkdir "$ROUND/.verifier-fan-in-audit.json"
  write_finding_no_change_type "$ROUND" qc 01 F01 >/dev/null

  run "$SCRIPT" "$ROUND"
  [ "$status" -ne 0 ]
  # stderr must name the halt cause even though write_audit failed
  [[ "$output" == *"missing_change_type"* || "$stderr" == *"missing_change_type"* ]]
}

# --- fix F03: jq dependency check (silent-failure-claude) ----------------
# jq absence causes a silent crash inside record_halt/write_audit under
# set -e.  Fix: upfront command -v jq check.

@test "fix F03: absent jq exits non-zero with jq-related diagnostic" {
  # Build a PATH that excludes every directory containing jq.
  local newpath="" d
  local saved_IFS="$IFS"
  IFS=':'
  for d in $PATH; do
    IFS="$saved_IFS"
    [[ -x "$d/jq" ]] && continue
    newpath="${newpath:+$newpath:}$d"
  done
  IFS="$saved_IFS"

  run env PATH="$newpath" "$SCRIPT" "$ROUND"
  [ "$status" -ne 0 ]
  [[ "$output" == *"jq"* || "$stderr" == *"jq"* ]]
}

# --- fix F04: clean-path write ordering (silent-failure-claude) -----------
# kept-findings.txt was written BEFORE write_audit; if write_audit failed,
# kept-findings.txt was left on disk without a paired audit JSON.
# Fix: write audit first (or use ERR trap to remove kept-findings.txt).

@test "fix F04: if write_audit fails on clean path, kept-findings.txt not left on disk" {
  local f1
  f1=$(write_finding "$ROUND" qc 01 F01 style)
  write_sidecar "$f1" 90
  # Block audit write by pre-creating a directory at the audit JSON path.
  mkdir "$ROUND/.verifier-fan-in-audit.json"

  run "$SCRIPT" "$ROUND"
  [ "$status" -ne 0 ]
  [ ! -f "$ROUND/kept-findings.txt" ]
}

# --- fix F05: extract_frontmatter_field I/O errors (silent-failure-codex) -
# || true collapsed real read/permission errors into field-absent, masking the
# root cause.  Fix: check file readability and emit a diagnostic.

@test "fix F05: unreadable finding file emits I/O diagnostic to stderr" {
  local f1
  f1=$(write_finding "$ROUND" qc 01 F01 style)
  write_sidecar "$f1" 90
  chmod 000 "$f1"  # make finding unreadable

  run "$SCRIPT" "$ROUND"
  [ "$status" -ne 0 ]
  # Must emit a "cannot read" (or similar) message — not silently treat as
  # missing_change_type without any I/O diagnostic.
  [[ "$output" == *"cannot read"* || "$stderr" == *"cannot read"* ]]
}

# --- fix F06: stale kept-findings.txt on halt (silent-failure-codex) ------
# Halt path did not remove an existing kept-findings.txt from a prior
# successful run; downstream consumers saw stale data.
# Fix: rm -f kept-findings.txt at start of halt path.

@test "fix F06: halt path removes stale kept-findings.txt from prior run" {
  # Simulate a prior successful run leaving kept-findings.txt.
  printf 'stale/path/finding.md\n' > "$ROUND/kept-findings.txt"
  # Trigger a halt via missing_change_type.
  write_finding_no_change_type "$ROUND" qc 01 F01 >/dev/null

  run "$SCRIPT" "$ROUND"
  [ "$status" -ne 0 ]
  [ ! -f "$ROUND/kept-findings.txt" ]
}

# --- fix F07: goal-ID hygiene (code-quality-claude) -----------------------
# G\d+ goal IDs must not appear in scripts/verifier-fan-in.sh (CONTRIBUTING.md
# prohibits self-referencing IDs in runtime-context files).

@test "fix F07: verifier-fan-in.sh contains no goal-ID tokens (G-pattern)" {
  local script="$REPO_ROOT/scripts/verifier-fan-in.sh"
  # grep -q exits 0 on match (bad), 1 on no match (good).
  ! grep -qE '\bG[0-9]+\b' "$script"
}

# ===========================================================================
# Round-02 review fixes
# ===========================================================================

# --- R2 fix 1: integer overflow bypass (security-claude R2-F01) -----------
# Bash $(()) wraps modulo 2^64; a 19-digit score string that overflows 64-bit
# arithmetic bypasses the >100 ceiling check.
# Fix: regex cap at 3 digits (max valid score 100 has 3 digits).

@test "score with > 3 digits is rejected as score_unparseable" {
  local f1
  f1=$(write_finding "$ROUND" qc 01 F01 style)
  write_sidecar "$f1" "18446744073709551706"

  run "$SCRIPT" "$ROUND"
  [ "$status" -ne 0 ]
  run jq -r '.halts[0].cause' "$ROUND/.verifier-fan-in-audit.json"
  [[ "$output" == "score_unparseable" ]]
}

@test "overflow score emits halt-cause diagnostic to stderr" {
  local f1
  f1=$(write_finding "$ROUND" qc 01 F01 style)
  write_sidecar "$f1" "18446744073709551706"

  run "$SCRIPT" "$ROUND"
  [ "$status" -ne 0 ]
  [[ "$output" == *"score_unparseable"* || "$stderr" == *"score_unparseable"* ]]
}

# --- R2 fix 2: sidecar readability guard (silent-failure-claude R2-F01) ---
# If sidecar exists but is unreadable (chmod 000), awk/extract silently fails
# and the script records score_unparseable.  Fix: explicit readability check.

@test "unreadable sidecar records halt cause sidecar_unreadable" {
  local f1
  f1=$(write_finding "$ROUND" qc 01 F01 style)
  write_sidecar "$f1" 90
  chmod 000 "${f1%.md}.score.md"

  run "$SCRIPT" "$ROUND"
  [ "$status" -ne 0 ]
  run jq -r '.halts[0].cause' "$ROUND/.verifier-fan-in-audit.json"
  [[ "$output" == "sidecar_unreadable" ]]
}

@test "unreadable sidecar emits cannot-read message to stderr" {
  local f1
  f1=$(write_finding "$ROUND" qc 01 F01 style)
  write_sidecar "$f1" 90
  chmod 000 "${f1%.md}.score.md"

  run "$SCRIPT" "$ROUND"
  [ "$status" -ne 0 ]
  [[ "$output" == *"cannot read sidecar"* || "$stderr" == *"cannot read sidecar"* ]]
}

# --- R2 fix 3: halt-cause misattribution for unreadable finding -----------
# The R1 fix recorded missing_change_type when the finding file was unreadable.
# missing_change_type means "frontmatter omits change_type:"; wrong root cause.
# Fix: record finding_unreadable for I/O permission errors on finding files.

@test "unreadable finding file records halt cause finding_unreadable" {
  local f1
  f1=$(write_finding "$ROUND" qc 01 F01 style)
  write_sidecar "$f1" 90
  chmod 000 "$f1"

  run "$SCRIPT" "$ROUND"
  [ "$status" -ne 0 ]
  run jq -r '.halts[0].cause' "$ROUND/.verifier-fan-in-audit.json"
  [[ "$output" == "finding_unreadable" ]]
}

# --- R3 fix: absent awk startup guard (silent-failure-claude R3-F02) ------
# extract_frontmatter_field calls awk.  Without an awk startup guard, awk
# failures (absent from PATH, OOM, fd exhaustion) are silently swallowed by
# "|| true" and misattributed to missing_change_type / score_unparseable.
# Fix: add command -v awk guard mirroring the existing jq guard.

@test "absent awk exits non-zero with awk-related diagnostic" {
  # Create a fake bin directory that exposes jq but not awk, so the jq guard
  # passes and only the awk guard fires.
  local fakebin="$BATS_TEST_TMPDIR/fake-bin"
  mkdir -p "$fakebin"
  ln -sf "$(command -v jq)" "$fakebin/jq"

  # Build a PATH that leads with fakebin (jq present, awk absent) and
  # excludes every directory that contains awk or a second copy of jq.
  local newpath="$fakebin" d
  local saved_IFS="$IFS"
  IFS=':'
  for d in $PATH; do
    IFS="$saved_IFS"
    [[ -x "$d/awk" ]] && continue
    [[ -x "$d/jq"  ]] && continue
    newpath="${newpath:+$newpath:}$d"
  done
  IFS="$saved_IFS"

  run env PATH="$newpath" "$SCRIPT" "$ROUND"
  [ "$status" -ne 0 ]
  [[ "$output" == *"awk"* || "$stderr" == *"awk"* ]]
}

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

@test "threshold rule: scope and intent kept regardless of score" {
  local f1 f2
  f1=$(write_finding "$ROUND" qc 01 F01 scope);  write_sidecar "$f1" 0
  f2=$(write_finding "$ROUND" qc 02 F02 intent); write_sidecar "$f2" 5

  run "$SCRIPT" "$ROUND"
  [ "$status" -eq 0 ]
  run jq -r '.kept,.dropped' "$ROUND/.verifier-fan-in-audit.json"
  [[ "${lines[0]}" == "2" ]]
  [[ "${lines[1]}" == "0" ]]
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

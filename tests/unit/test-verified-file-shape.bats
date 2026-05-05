#!/usr/bin/env bats

# This test exercises a faithful MIRROR of the Bash assembly snippet
# documented in skills/using-qrspi/SKILL.md (Apply-fix step 5). It does not
# extract or source the SKILL.md snippet directly because the snippet is
# embedded inside Markdown prose. To prevent silent drift between the
# documented protocol and the tested behavior, the test below ALSO asserts
# that the SKILL.md snippet still contains the structural markers this
# mirror depends on (nullglob, the @@FINDING/@@SCORE/@@CLEAN HTML boundary
# comments, the YAML totals header, the score < 80 + change_type partition).
# If the SKILL.md snippet drifts, the structural-marker assertion fails and
# the implementer must re-sync the mirror.

source_assembly() {
  local round_dir=$1
  local out=$2
  local cfg=$3
  local D=$round_dir
  shopt -s nullglob
  findings=( "$D"/*.finding-*.md )
  cleans=( "$D"/*.clean.md )

  scored=0; failed=0; dropped=0
  clean_count=${#cleans[@]}
  for f in "${findings[@]}"; do
    sc="${f%.md}.score.yml"
    [[ -f $sc ]] || continue
    if grep -q '^score: VERIFY_FAILED' "$sc"; then
      failed=$((failed + 1)); continue
    fi
    score=$(awk -F': *' '/^score:/ {print $2; exit}' "$sc")
    scored=$((scored + 1))
    ct=$(awk -F': *' '/^change_type:/ {print $2; exit}' "$f")
    if (( score < 80 )) && [[ $ct =~ ^(style|clarity|correctness)$ ]]; then
      dropped=$((dropped + 1))
    fi
  done
  kept=$(( ${#findings[@]} - dropped ))
  verifier_enabled_str=$(awk -F': *' '/^verifier_enabled:/ {print $2; exit}' "$cfg")

  {
    printf '%s\n' \
      '---' \
      "verifier_enabled: ${verifier_enabled_str:-true}" \
      "scored: $scored" \
      "kept: $kept" \
      "dropped: $dropped" \
      "failed: $failed" \
      "clean: $clean_count" \
      '---' \
      ''
    for f in "${findings[@]}"; do
      echo "<!-- @@FINDING: $(basename "$f" .md) @@ -->"
      cat "$f"
      sc="${f%.md}.score.yml"
      if [[ -f $sc ]]; then
        echo "<!-- @@SCORE: $(basename "$sc" .yml) @@ -->"
        cat "$sc"
      fi
    done
    for c in "${cleans[@]}"; do
      echo "<!-- @@CLEAN: $(basename "$c" .md) @@ -->"
      cat "$c"
    done
  } > "$out"
}

@test "enabled-clean fixture: scored=3, kept=2, dropped=1 (F02 clarity score 60)" {
  local out
  out=$(mktemp)
  local cfg
  cfg=$(mktemp)
  printf 'verifier_enabled: true\n' > "$cfg"
  source_assembly tests/fixtures/issue-109/round-enabled-clean/round-03 "$out" "$cfg"
  grep -qE '^scored: 3$' "$out"
  grep -qE '^kept: 2$' "$out"
  grep -qE '^dropped: 1$' "$out"
  grep -qE '^failed: 0$' "$out"
  grep -qE '^clean: 1$' "$out"
}

@test "enabled-clean fixture: assembly contains @@FINDING / @@SCORE / @@CLEAN boundary comments" {
  local out
  out=$(mktemp)
  local cfg
  cfg=$(mktemp)
  printf 'verifier_enabled: true\n' > "$cfg"
  source_assembly tests/fixtures/issue-109/round-enabled-clean/round-03 "$out" "$cfg"
  grep -qF '<!-- @@FINDING:' "$out"
  grep -qF '<!-- @@SCORE:' "$out"
  grep -qF '<!-- @@CLEAN:' "$out"
}

@test "disabled-from-start fixture: scored=0, kept=2, no sidecars referenced" {
  local out
  out=$(mktemp)
  local cfg
  cfg=$(mktemp)
  printf 'verifier_enabled: false\n' > "$cfg"
  source_assembly tests/fixtures/issue-109/round-disabled-from-start/round-01 "$out" "$cfg"
  grep -qE '^scored: 0$' "$out"
  grep -qE '^kept: 2$' "$out"
  grep -qE '^dropped: 0$' "$out"
  grep -qE '^failed: 0$' "$out"
  ! grep -qF '<!-- @@SCORE:' "$out"
}

@test "skills/using-qrspi/SKILL.md still contains the structural markers this mirror depends on" {
  # Drift guard: if any of these markers disappears from the documented
  # snippet, the in-test mirror above is no longer testing the documented
  # behavior. The implementer must either (a) update both the mirror and
  # this assertion to match the new documented snippet or (b) restore the
  # missing marker.
  local protocol
  protocol=$(awk '
    /\*\*Apply-fix protocol\.\*\*/ { in_block=1 }
    in_block && /\*\*Diff handling between rounds/ { exit }
    in_block { print }
  ' skills/using-qrspi/SKILL.md)
  echo "$protocol" | grep -qF 'shopt -s nullglob' || { echo "nullglob marker missing"; return 1; }
  echo "$protocol" | grep -qF '@@FINDING:' || { echo "@@FINDING boundary marker missing"; return 1; }
  echo "$protocol" | grep -qF '@@SCORE:' || { echo "@@SCORE boundary marker missing"; return 1; }
  echo "$protocol" | grep -qF '@@CLEAN:' || { echo "@@CLEAN boundary marker missing"; return 1; }
  echo "$protocol" | grep -qE 'verifier_enabled:|scored:|kept:|dropped:|failed:|clean:' \
    || { echo "YAML totals header markers missing"; return 1; }
  echo "$protocol" | grep -qE 'score *< *80|< *80.*style.*clarity.*correctness' \
    || { echo "score-<-80 + change_type partition logic missing"; return 1; }
}

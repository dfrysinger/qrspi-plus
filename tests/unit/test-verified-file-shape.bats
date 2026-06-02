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

# ---------------------------------------------------------------------------
# Audit-field shape pins — verifier sidecar frontmatter MUST always carry the
# audit field documented as the resolved-model record-keeping channel. The
# field is observability-only (does NOT gate keep/drop). Pinned at the doc
# layer because the verifier agent body is the contract the orchestrator
# ships to subagents — drift in the body silently breaks the audit flow even
# when the fan-in script remains green.
# ---------------------------------------------------------------------------
@test "verifier agent body documents actual_model in success-case sidecar frontmatter" {
  local body
  body="$(awk '/On success:/{flag=1} /On failure/{flag=0} flag' agents/qrspi-finding-verifier.md)"
  echo "$body" | grep -qF 'actual_model:' \
    || { echo "actual_model: not documented in success-case sidecar frontmatter"; return 1; }
}

@test "verifier agent body documents actual_model in VERIFY_FAILED-case sidecar frontmatter" {
  # The verifier emits a sidecar even on VERIFY_FAILED, and the audit field
  # MUST appear there too so downstream observability does not drop entries
  # whose verifier evaluation failed.
  local body
  body="$(awk '/On failure/{flag=1} /^7\. /{flag=0} flag' agents/qrspi-finding-verifier.md)"
  echo "$body" | grep -qF 'actual_model:' \
    || { echo "actual_model: not documented in VERIFY_FAILED-case sidecar frontmatter"; return 1; }
}

@test "verifier agent body documents verbatim copy + unknown fallback for actual_model" {
  # When finding frontmatter supplies the audit field, the sidecar copies
  # the value verbatim. When the finding omits it, the sidecar writes
  # 'unknown' rather than failing — the field is observability, not a gate.
  grep -qE 'verbatim|copied verbatim' agents/qrspi-finding-verifier.md \
    || { echo "verbatim-copy contract for actual_model not documented"; return 1; }
  grep -qE 'actual_model.*unknown|unknown.*actual_model' agents/qrspi-finding-verifier.md \
    || { echo "unknown fallback for actual_model not documented"; return 1; }
}

# ---------------------------------------------------------------------------
# Defect-class rubric pins (G28 D1).
#
# The verifier MUST emit a `defect_class:` tag classifying the finding's
# defect type — lowercase kebab-case (regex `^[a-z0-9][a-z0-9-]*$`), ≤30
# characters, with `unspecified` accepted as the documented absence-of-signal
# value. The rubric step lives AFTER scoring and BEFORE sidecar write.
# ---------------------------------------------------------------------------

@test "verifier agent body documents a Defect-class rubric step between Score and Write-sidecar" {
  # Carve a slice of the procedure between the Score step (step 5) and the
  # Write-sidecar step (step 6). The Defect-class step MUST appear inside it.
  local agent slice
  agent="agents/qrspi-finding-verifier.md"
  slice="$(awk '
    /^5\. \*\*Score\*\*/ { flag=1 }
    flag && /^6\. \*\*Write `<sidecar_path>`\*\*/ { exit }
    flag { print }
  ' "$agent")"
  echo "$slice" | grep -qiE 'defect[- ]class' \
    || { echo "Defect-class rubric step missing between Score (step 5) and Write-sidecar (step 6)"; echo "$slice"; return 1; }
  echo "$slice" | grep -qF 'defect_class:' \
    || { echo "defect_class: token missing from rubric step"; return 1; }
}

@test "verifier agent body documents defect_class shape: kebab-case, ≤30 chars, regex anchor" {
  local agent="agents/qrspi-finding-verifier.md"
  # ≤30 character cap MUST be documented.
  grep -qE '(≤|<=) ?30' "$agent" \
    || { echo "30-char cap for defect_class not documented"; return 1; }
  # kebab-case constraint MUST be documented.
  grep -qiE 'kebab[- ]case' "$agent" \
    || { echo "kebab-case shape for defect_class not documented"; return 1; }
  # Lowercase letters / digits / hyphens charset MUST be documented (the
  # regex `^[a-z0-9][a-z0-9-]*$` or the equivalent prose listing the chars).
  grep -qE '\^\[a-z0-9\]\[a-z0-9-\]\*\$|lowercase.*hyphen|letters.*digits.*hyphen' "$agent" \
    || { echo "defect_class charset (lowercase letters, digits, hyphens) not documented"; return 1; }
}

@test "verifier agent body documents 'unspecified' fallback for absence-of-signal defect_class" {
  grep -qE 'defect_class: *unspecified' agents/qrspi-finding-verifier.md \
    || { echo "'defect_class: unspecified' fallback not documented"; return 1; }
}

@test "verifier sidecar success-case example carries defect_class: in frontmatter alongside score:" {
  local body
  body="$(awk '/On success:/{flag=1} /On failure/{flag=0} flag' agents/qrspi-finding-verifier.md)"
  echo "$body" | grep -qF 'defect_class:' \
    || { echo "defect_class: not present in success-case sidecar example"; return 1; }
}

@test "verifier sidecar failure-case example carries defect_class: in frontmatter (REQUIRED on every sidecar)" {
  # Spec DoD: defect_class: is REQUIRED on every sidecar. The failure-sidecar
  # path (verifier_status: failed) is a sidecar too, so the documented
  # template MUST also carry the field — otherwise the documentation
  # contradicts the DoD's "missing field is a schema violation" rule.
  local body
  body="$(awk '/On failure/{flag=1} /^7\. /{flag=0} flag' agents/qrspi-finding-verifier.md)"
  echo "$body" | grep -qF 'defect_class:' \
    || { echo "defect_class: not present in failure-case sidecar example (REQUIRED on every sidecar per spec DoD)"; return 1; }
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

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
# Defect-class rubric pins — verifier sidecar instrumentation.
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
  # End-boundary drift guard: the slice's open-ended awk pattern would
  # silently grow if step 6's heading drifted (renumbered, reworded), and
  # downstream assertions inside the slice would degrade into vacuous passes
  # against the wrong region. Pin (a) the slice is non-empty AND (b) it does
  # NOT contain the literal step-6 marker — the latter would prove the awk
  # exit-on-step-6 guard fired too late.
  [ -n "$slice" ] \
    || { echo "awk slice between step 5 (Score) and step 6 (Write) is empty — start boundary drifted"; return 1; }
  if echo "$slice" | grep -qF '6. **Write'; then
    echo "awk slice extends past step 6 — end boundary drifted (heading renumbered or reworded)"
    return 1
  fi
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

@test "verifier agent body lists at least one canonical well-formed defect_class example tag" {
  # Spec L50 / DoD pin: the agent body MUST document examples of well-formed
  # tags so reviewers/operators have concrete reference shapes. Without this
  # pin the implementer could remove all worked examples and still pass the
  # shape/charset/cap assertions above. The four tokens below are the
  # canonical examples the spec calls out (goal-leakage, swallowed-error,
  # fabricated-citation, unanchored-claim); at least one MUST appear.
  grep -qiE 'goal-leakage|swallowed-error|fabricated-citation|unanchored-claim' \
    agents/qrspi-finding-verifier.md \
    || { echo "no canonical well-formed defect_class example tags documented"; return 1; }
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

# ── Sidecar field-ordering invariant (load-bearing security pin) ─────────
# The `score:` field (when present) MUST precede `defect_class:`, and
# `defect_class:` MUST appear LAST among the YAML frontmatter fields. The
# ordering bounds duplicate-key YAML parser drift: pyyaml-style
# "last value wins" parsers used by future cluster-analysis tooling would
# let a malformed `defect_class:` value containing an injected `score:` on a
# subsequent line silently override the real score. Putting `defect_class:`
# last bounds the blast radius.

# Helper: assert that the sidecar template fenced block whose start marker
# is "$start_marker" (e.g. 'On success:' or 'On failure') has defect_class:
# as the LAST frontmatter field. Eliminates the duplicated 7-line
# extract+frontmatter-slice+last-field sequence between the success and
# failure pins. The success pin layers an additional score-precedes-
# defect_class assertion on top via _assert_score_precedes_defect_class.
_extract_template_block() {
  local agent=$1 start_re=$2
  awk -v start_re="$start_re" '
    $0 ~ start_re { flag=1; next }
    flag && /^[[:space:]]*```markdown[[:space:]]*$/ { in_block=1; next }
    in_block && /^[[:space:]]*```[[:space:]]*$/ { exit }
    in_block { print }
  ' "$agent"
}

_assert_defect_class_last() {
  local label=$1 block=$2
  [ -n "$block" ] || { echo "could not locate $label sidecar template block"; return 1; }
  local fm
  fm=$(echo "$block" | awk '/^[[:space:]]*---[[:space:]]*$/{n++; next} n==1{print}')
  [ -n "$fm" ] || { echo "could not extract $label frontmatter"; return 1; }
  local last_field
  last_field=$(echo "$fm" | grep -E '^[[:space:]]*[a-z_]+:' | tail -1 | sed -E 's/^[[:space:]]*([a-z_]+):.*/\1/')
  [ "$last_field" = "defect_class" ] \
    || { echo "$label template's last frontmatter field is '$last_field' — must be 'defect_class' per the load-bearing field-ordering invariant"; echo "frontmatter:"; echo "$fm"; return 1; }
}

@test "sidecar field-order: success template has defect_class: as the LAST frontmatter field" {
  local block
  block=$(_extract_template_block agents/qrspi-finding-verifier.md '^[[:space:]]*On success:[[:space:]]*$')
  [ -n "$block" ] || { echo "could not locate On-success sidecar template block"; return 1; }
  # Success path layers an additional ordering assertion: score: MUST appear
  # before defect_class: in line order (not just last).
  local score_line defect_line
  score_line=$(echo "$block" | grep -nE '^\s*score:' | head -1 | cut -d: -f1)
  defect_line=$(echo "$block" | grep -nE '^\s*defect_class:' | head -1 | cut -d: -f1)
  [ -n "$score_line" ] || { echo "no score: in success template"; return 1; }
  [ -n "$defect_line" ] || { echo "no defect_class: in success template"; return 1; }
  [ "$score_line" -lt "$defect_line" ] \
    || { echo "success template field order violated: score: at line $score_line, defect_class: at line $defect_line (score MUST precede defect_class)"; return 1; }
  _assert_defect_class_last "success" "$block"
}

@test "sidecar field-order: failure template has defect_class: as the LAST frontmatter field" {
  local block
  block=$(_extract_template_block agents/qrspi-finding-verifier.md '^[[:space:]]*On failure')
  _assert_defect_class_last "failure" "$block"
}

@test "sidecar field-order: agent body documents the load-bearing invariant" {
  grep -qE 'Field.ordering invariant|score:.*MUST precede.*defect_class|defect_class:.*MUST appear LAST' \
    agents/qrspi-finding-verifier.md \
    || { echo "agent body does not document the load-bearing field-ordering invariant"; return 1; }
}

#!/usr/bin/env bats
#
# T07 Slice 1 unit pin — citation-density validator wrap (T05).
#
# Pins the contract documented in skills/implement/SKILL.md §
# "Specialist Citation-Density Validator" and the `validators.citation_density_floor:`
# default of `0.05` in skills/using-qrspi/SKILL.md § validators: block.
#
# Four cases:
#   1. Above-floor: proceeds unchanged, no re-run.
#   2. Below-floor: EXACTLY ONE trusted re-run on the agent-bundled default.
#   3. Default floor: 0.05 when validators.citation_density_floor: absent.
#   4. Second-below-floor (re-run also below floor): loud non-zero exit,
#      validator does NOT silently forward output.
#
# Bash 3.2 portable.

load '../helpers/skill-markdown'

_extract_h4() {
  local file="$1" text="$2"
  local target="#### $text"
  local out
  out="$(awk -v target="$target" '
    BEGIN { inside=0; found=0 }
    {
      if (inside == 1) {
        if ($0 ~ /^#{1,4} /) { inside=0; next }
        print $0
        next
      }
      if ($0 == target) { inside=1; found=1; next }
    }
    END { if (found == 0) exit 1 }
  ' "$file")" || { echo "h4 anchor not found: $target in $file" >&2; return 1; }
  if [ -z "$out" ]; then
    echo "h4 extract empty: $target in $file" >&2
    return 1
  fi
  printf '%s\n' "$out"
}

setup_file() {
  require_repo_root
  USING="$REPO_ROOT/skills/using-qrspi/SKILL.md"
  IMPLEMENT="$REPO_ROOT/skills/implement/SKILL.md"
  export USING IMPLEMENT
}

# ---------------------------------------------------------------------------
# 1. Above-floor result: proceeds unchanged, no re-run.
# ---------------------------------------------------------------------------

@test "above-floor: specialist report proceeds unchanged, no re-run, no telemetry increment" {
  out="$(_extract_h4 "$IMPLEMENT" 'Specialist Citation-Density Validator (post-output, trusted-model re-run)')"
  [[ "$out" == *"Above-floor result"* ]]
  [[ "$out" == *"proceeds unchanged"* ]]
  [[ "$out" == *"No re-run"* ]] || [[ "$out" == *"no re-run"* ]]
}

# ---------------------------------------------------------------------------
# 2. Below-floor result: EXACTLY ONE trusted re-run.
# ---------------------------------------------------------------------------

@test "below-floor: re-runs EXACTLY ONCE on the trusted model" {
  out="$(_extract_h4 "$IMPLEMENT" 'Specialist Citation-Density Validator (post-output, trusted-model re-run)')"
  [[ "$out" == *"re-runs the specialist EXACTLY ONCE on the trusted model"* ]]
}

@test "below-floor: rerun count is incremented in telemetry" {
  out="$(_extract_h4 "$IMPLEMENT" 'Specialist Citation-Density Validator (post-output, trusted-model re-run)')"
  [[ "$out" == *"rerun count is incremented"* ]]
}

# ---------------------------------------------------------------------------
# 3. Default floor: 0.05 when validators.citation_density_floor: absent.
# ---------------------------------------------------------------------------

@test "default floor: citation_density_floor default is 0.05" {
  out="$(_extract_h4 "$USING" '`validators:` block')"
  [[ "$out" == *"citation_density_floor"* ]]
  [[ "$out" == *"0.05"* ]]
}

# ---------------------------------------------------------------------------
# 4. Second-below-floor: loud diagnostic + non-zero exit, no silent forward.
# ---------------------------------------------------------------------------

@test "second-below-floor: emits loud diagnostic naming the below-floor density value" {
  out="$(_extract_h4 "$IMPLEMENT" 'Specialist Citation-Density Validator (post-output, trusted-model re-run)')"
  [[ "$out" == *"loud diagnostic naming the below-floor density value"* ]]
}

@test "second-below-floor: exits non-zero so orchestrator observes specialist-dispatch FAILURE" {
  out="$(_extract_h4 "$IMPLEMENT" 'Specialist Citation-Density Validator (post-output, trusted-model re-run)')"
  [[ "$out" == *"exits non-zero"* ]]
  [[ "$out" == *"specialist-dispatch FAILURE"* ]]
}

@test "second-below-floor: validator does NOT silently forward below-floor output to consumers" {
  out="$(_extract_h4 "$IMPLEMENT" 'Specialist Citation-Density Validator (post-output, trusted-model re-run)')"
  [[ "$out" == *"does NOT silently forward"* ]]
  [[ "$out" == *"NOT a zero-exit-with-empty-body"* ]]
}

# ---------------------------------------------------------------------------
# Validator wrap location: per-dispatch boundary, AFTER report write,
# BEFORE downstream collation.
# ---------------------------------------------------------------------------

@test "validator wrap: runs at per-dispatch boundary, AFTER report write, BEFORE collation" {
  out="$(_extract_h4 "$IMPLEMENT" 'Specialist Citation-Density Validator (post-output, trusted-model re-run)')"
  [[ "$out" == *"AFTER the specialist's report is written"* ]]
  [[ "$out" == *"BEFORE the report enters downstream collation"* ]]
}

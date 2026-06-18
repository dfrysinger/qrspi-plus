#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# Repo-wide internal-ID hygiene scan for PROMPT PROSE files.
#
# Companion to test-evergreen-markdown.bats. Scans skills/**/*.md and
# agents/*.md for QRSPI-internal ID forbidden tokens, applying path-shaped
# and inline carve-outs from the hygiene contract
# (skills/implementer-protocol/SKILL.md § Internal-ID forbidden tokens).
#
# Scope: prompt prose only. Scripts, tools, JSON, YAML, and code source files
# are excluded — code comments citing design.md anchors are authoring
# traceability, not operator-facing instruction. The evergreen-markdown rule
# has the same prose-file scope precedent.
#
# Carve-outs (path-shaped):
#   - agents/qrspi-*.md                       (QRSPI agent bodies document the finding-ID schema)
#   - skills/implementer-protocol/SKILL.md    (defines the ID regex contract itself)
#   - skills/reviewer-protocol/**             (defines the finding-ID schema)
#   - skills/goals/references/**              (templates + worked examples illustrating the ID convention)
#   - skills/goals/owns-defers.md             (explains the ID scheme)
#   - skills/design/references/**             (design-block ID examples)
#   - skills/plan/references/worked-examples.md  (plan examples using task IDs)
#   - skills/structure/SKILL.md               (uses `(e.g., G1, G5, CD-4)` as convention illustration)
#   - skills/research/SKILL.md                (heavy Qn convention illustration — research question naming)
#   - skills/research-isolation/SKILL.md      (Qn isolation error-message examples)
#   - skills/replan/SKILL.md                  (heavy Gn import-format convention illustration)
#   - skills/replan/references/boundary-with-goals.md  (Gn import-format convention illustration)
#   - skills/phasing/SKILL.md                 (Gn-keyed slice template + illustrative table)
#
# Inline carve-out:
#   - A line ending with <!-- id-hygiene-exempt --> OR <!-- evergreen-exempt --> is skipped.
#
# Forbidden-token families (regex):
#   - reviewer-finding-id : round-[0-9]+ finding-[0-9]+ | R[0-9]+-F[0-9]+
#   - task-id             : T[0-9]{2}[a-z]?              (T01, T14, T20a)
#   - goal-id             : G[0-9]+                      (G1, G18)
#   - question-id         : Q[0-9]+                      (Q3, Q12)
#   - future-goal-id      : F-[0-9]+                     (F-1, F-23)
#   - design-decision-id  : D[0-9]+                      (D2, D15)
#   - cross-cutting-design-id : CD-[0-9]+                (CD-1, CD-4)
#
# Word-boundary handling: POSIX awk lacks \b. The patterns use explicit
# character-class boundaries so they work in mawk, gawk, and BSD awk.

load '../helpers/skill-markdown'

_is_internal_id_path_exempt() {
  local rel="$1"
  case "$rel" in
    agents/qrspi-*.md) return 0 ;;
    skills/implementer-protocol/SKILL.md) return 0 ;;
    skills/reviewer-protocol/*) return 0 ;;
    skills/goals/references/*) return 0 ;;
    skills/goals/owns-defers.md) return 0 ;;
    skills/design/references/*) return 0 ;;
    skills/plan/references/worked-examples.md) return 0 ;;
    skills/structure/SKILL.md) return 0 ;;
    skills/research/SKILL.md) return 0 ;;
    skills/research-isolation/SKILL.md) return 0 ;;
    skills/replan/SKILL.md) return 0 ;;
    skills/replan/references/boundary-with-goals.md) return 0 ;;
    skills/phasing/SKILL.md) return 0 ;;
  esac
  return 1
}

_check_file_for_internal_id() {
  local abs_path="$1"
  local rel_path="$2"

  local hits
  hits="$(awk -v rp="$rel_path" '
    BEGIN {
      LB = "(^|[^A-Za-z0-9_-])"
      TB = "([^A-Za-z0-9_]|$)"
    }
    /<!-- id-hygiene-exempt -->/ { next }
    /<!-- evergreen-exempt -->/  { next }
    {
      line = $0
      if (match(line, "(round-[0-9]+ finding-[0-9]+|R[0-9]+-F[0-9]+)")) {
        printf "INTERNAL-ID HIT: %s:%d [reviewer-finding-id]: %s\n", rp, NR, line
        found = 1
      }
      if (match(line, LB "T[0-9][0-9][a-z]?" TB)) {
        printf "INTERNAL-ID HIT: %s:%d [task-id]: %s\n", rp, NR, line
        found = 1
      }
      if (match(line, LB "G[0-9]+" TB)) {
        printf "INTERNAL-ID HIT: %s:%d [goal-id]: %s\n", rp, NR, line
        found = 1
      }
      if (match(line, LB "Q[0-9]+" TB)) {
        printf "INTERNAL-ID HIT: %s:%d [question-id]: %s\n", rp, NR, line
        found = 1
      }
      if (match(line, LB "F-[0-9]+" TB)) {
        printf "INTERNAL-ID HIT: %s:%d [future-goal-id]: %s\n", rp, NR, line
        found = 1
      }
      if (match(line, LB "D[0-9]+" TB)) {
        printf "INTERNAL-ID HIT: %s:%d [design-decision-id]: %s\n", rp, NR, line
        found = 1
      }
      if (match(line, LB "CD-[0-9]+" TB)) {
        printf "INTERNAL-ID HIT: %s:%d [cross-cutting-design-id]: %s\n", rp, NR, line
        found = 1
      }
    }
    END { exit (found ? 1 : 0) }
  ' "$abs_path")"

  if [ -n "$hits" ]; then
    printf '%s\n' "$hits"
    return 1
  fi
  return 0
}

setup_file() {
  require_repo_root
}

@test "clean file (no internal-ID tokens) passes" {
  local fixture
  fixture="$(mktemp /tmp/intid-clean-XXXXXX.md)"
  printf '# My Feature\n\nThis documents the contract surface. No internal IDs here.\n' > "$fixture"
  run _check_file_for_internal_id "$fixture" "fake/clean.md"
  rm -f "$fixture"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "file with cross-cutting design ID (CD-1) outside carve-out fails" {
  local fixture
  fixture="$(mktemp /tmp/intid-cd-XXXXXX.md)"
  printf '# Feature\n\nPer CD-1 contract, the rename applies.\n' > "$fixture"
  run _check_file_for_internal_id "$fixture" "skills/fake/SKILL.md"
  rm -f "$fixture"
  [ "$status" -ne 0 ]
  printf '%s\n' "$output" | grep -q "cross-cutting-design-id"
}

@test "file with task-id letter-suffix (T20a) is caught" {
  local fixture
  fixture="$(mktemp /tmp/intid-task-XXXXXX.md)"
  printf '# Feature\n\nThe T20a stage-commit fence applies here.\n' > "$fixture"
  run _check_file_for_internal_id "$fixture" "skills/fake/SKILL.md"
  rm -f "$fixture"
  [ "$status" -ne 0 ]
  printf '%s\n' "$output" | grep -q "task-id"
}

@test "line with id-hygiene-exempt inline comment is skipped" {
  local fixture
  fixture="$(mktemp /tmp/intid-exempt-XXXXXX.md)"
  printf '# Feature\n\nThe T20a stage-commit fence. <!-- id-hygiene-exempt -->\n' > "$fixture"
  run _check_file_for_internal_id "$fixture" "skills/fake/SKILL.md"
  rm -f "$fixture"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "line with evergreen-exempt inline comment is also honored" {
  local fixture
  fixture="$(mktemp /tmp/intid-evexempt-XXXXXX.md)"
  printf '# Feature\n\nThe CD-1 contract. <!-- evergreen-exempt -->\n' > "$fixture"
  run _check_file_for_internal_id "$fixture" "skills/fake/SKILL.md"
  rm -f "$fixture"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "prompt-prose corpus scan (skills/**/*.md + agents/*.md) — no hits outside carve-outs" {
  require_repo_root
  local all_hits=""
  local tmp_list
  tmp_list="$(mktemp /tmp/intid-filelist-XXXXXX.txt)"

  git -C "$REPO_ROOT" ls-files 'skills/*.md' 'skills/**/*.md' 'agents/*.md' 'agents/**/*.md' 2>/dev/null > "$tmp_list"

  while IFS= read -r rel; do
    [ -n "$rel" ] || continue

    if _is_internal_id_path_exempt "$rel"; then
      continue
    fi

    local abs_path="$REPO_ROOT/$rel"
    [ -f "$abs_path" ] || continue

    local file_hits
    file_hits="$(_check_file_for_internal_id "$abs_path" "$rel")" || true
    if [ -n "$file_hits" ]; then
      all_hits="${all_hits}${file_hits}
"
    fi
  done < "$tmp_list"

  rm -f "$tmp_list"

  if [ -n "$all_hits" ]; then
    printf 'Internal-ID violations found in prompt-prose corpus:\n%s\n' "$all_hits" >&2
    return 1
  fi
}

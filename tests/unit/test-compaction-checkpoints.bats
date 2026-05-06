#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
#
# #99 Compaction Checkpoints — defends the canonical Compaction Checkpoints
# contract in skills/using-qrspi/SKILL.md and the per-skill labels that cite it.
#
# The contract collapses four legacy anchors (pre-review-loop,
# pre-large-subagent-dispatch, terminal-state, cross-skill-transition) into
# two named checkpoints (pre-fanout, pre-handoff) plus a piggyback rule that
# rides on existing user-input pauses without introducing new ones. The Iron
# Rule lives in using-qrspi (loaded once per QRSPI session via the umbrella);
# per-site labels are short pointers to that contract.

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  export REPO_ROOT
}

@test "no compaction prompt remains in legacy blockquote form" {
  local offenders
  offenders=$(grep -rE '^> \*\*IMPORTANT — Compaction recommended' "$REPO_ROOT/skills/" || true)
  if [ -n "$offenders" ]; then
    echo "legacy blockquote compaction prompts:"
    echo "$offenders"
    return 1
  fi
}

@test "no compaction prompt retains the may-exceed-50% conditional" {
  local offenders
  offenders=$(grep -rE 'if (context )?utilization may exceed' "$REPO_ROOT/skills/" || true)
  if [ -n "$offenders" ]; then
    echo "compaction prompts retain conditional form:"
    echo "$offenders"
    return 1
  fi
}

@test "every checkpoint label uses one of the two canonical types" {
  # Exclude the format-template line in the canonical contract itself
  # (it carries the literal placeholder `{type}` and is not a real label).
  local offenders
  offenders=$(grep -rE '\*\*Compaction checkpoint:' "$REPO_ROOT/skills/" \
    | grep -vE '\*\*Compaction checkpoint: (pre-fanout|pre-handoff)\.\*\*' \
    | grep -vE '\{type\}' \
    || true)
  if [ -n "$offenders" ]; then
    echo "checkpoint labels with non-canonical type:"
    echo "$offenders"
    return 1
  fi
}

@test "every named checkpoint prescribes TaskCreate within 6 lines" {
  local skills offender
  skills=$(grep -lE '\*\*Compaction checkpoint: (pre-fanout|pre-handoff)\.\*\*' "$REPO_ROOT/skills/" -r || true)
  for f in $skills; do
    offender=$(awk '
      /\*\*Compaction checkpoint: (pre-fanout|pre-handoff)\.\*\*/ {
        flag=1; n=0; found=0; line_no=NR; next
      }
      flag {
        n++
        if (/TaskCreate/) { found=1; flag=0 }
        else if (n >= 6) {
          if (!found) print FILENAME ":" line_no
          flag=0
        }
      }
      END {
        if (flag && !found) print FILENAME ":" line_no
      }
    ' "$f")
    if [ -n "$offender" ]; then
      echo "named-checkpoint sites missing TaskCreate within 6 lines:"
      echo "$offender"
      return 1
    fi
  done
}

@test "using-qrspi/SKILL.md carries the canonical Compaction Checkpoints section" {
  local f="$REPO_ROOT/skills/using-qrspi/SKILL.md"
  grep -qE '^## Compaction Checkpoints' "$f"
  grep -qE 'Iron Rule\..*Pause and recommend' "$f"
}

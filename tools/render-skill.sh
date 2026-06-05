#!/usr/bin/env bash
# render-skill.sh — offline cat-emulator for Claude Code's !cat directive.
#
# Usage: render-skill.sh <skill-dir> <SKILL.md>
#
# Resolves every recognized `!cat ${CLAUDE_SKILL_DIR}/<relpath>` directive in
# <SKILL.md> by inlining the content of <skill-dir>/<relpath> in place, and
# writes the result to stdout. <skill-dir> is the absolute path that
# ${CLAUDE_SKILL_DIR} resolves to at runtime.
#
# Behavior is locked by qrspi-shared-extraction-plan.md "Helper contract".
# This script is a cat-emulator, not a template engine. Any deviation from the
# contract is a bug, not an enhancement.

set -u
set -o pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: render-skill.sh <skill-dir> <SKILL.md>" >&2
  exit 2
fi

skill_dir="$1"
skill_md="$2"

if [ ! -f "$skill_md" ]; then
  echo "error: SKILL.md not found: $skill_md" >&2
  exit 2
fi

relpath_re='^[A-Za-z0-9_./-]+$'
inline_re='^[[:space:]]*!`cat \$\{CLAUDE_SKILL_DIR\}/([A-Za-z0-9_./-]+)`[[:space:]]*$'
fence_dir_re='^[[:space:]]*cat \$\{CLAUDE_SKILL_DIR\}/([A-Za-z0-9_./-]+)[[:space:]]*$'
fence_open='```!'
fence_close='```'

emit_target() {
  local relpath="$1"
  local line_no="$2"
  if ! [[ "$relpath" =~ $relpath_re ]]; then
    echo "error: invalid relpath '$relpath' in $skill_md:$line_no" >&2
    exit 1
  fi
  local target="$skill_dir/$relpath"
  if [ ! -f "$target" ]; then
    echo "error: target not found '$target' in $skill_md:$line_no" >&2
    exit 1
  fi
  # Strip CRs byte-faithfully; trailing-newline state of <target> is preserved.
  tr -d '\r' < "$target"
}

in_fence=0
fence_start_line=0
line_no=0

while IFS= read -r line || [ -n "$line" ]; do
  line_no=$((line_no + 1))
  line="${line%$'\r'}"

  if [ "$in_fence" -eq 1 ]; then
    if [ "$line" = "$fence_close" ]; then
      in_fence=0
      continue
    fi
    if [[ "$line" =~ $fence_dir_re ]]; then
      emit_target "${BASH_REMATCH[1]}" "$line_no"
      continue
    fi
    echo "error: mixed-content fence at $skill_md:$line_no (only cat directives allowed inside \`\`\`!)" >&2
    exit 1
  fi

  if [ "$line" = "$fence_open" ]; then
    in_fence=1
    fence_start_line=$line_no
    continue
  fi

  if [[ "$line" =~ $inline_re ]]; then
    emit_target "${BASH_REMATCH[1]}" "$line_no"
    continue
  fi

  printf '%s\n' "$line"
done < "$skill_md"

if [ "$in_fence" -eq 1 ]; then
  echo "error: unterminated fence opened at $skill_md:$fence_start_line" >&2
  exit 1
fi

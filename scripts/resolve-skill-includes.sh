#!/usr/bin/env bash
# resolve-skill-includes.sh — print a SKILL.md with every `!cat <relpath>`
# build-directive line inlined (the same expansion tools/build-plugin.mjs
# applies at plugin build time and the BATS skill-markdown helper applies
# at extract time). Paths inside `!cat` are resolved relative to the repo
# root (auto-detected via `git rev-parse --show-toplevel` from $PWD, or
# overridden with --root <abs>). H2 headings inside included content are
# demoted to H3 so downstream H2 boundary detection treats them as logical
# sub-sections rather than container boundaries.
#
# Usage: resolve-skill-includes.sh [--root <abs>] <SKILL.md>
#
# Bash 3.2 portable; macOS /bin/bash safe.

set -u

ROOT=""
FILE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --root) ROOT="${2:-}"; shift 2 ;;
    -h|--help)
      echo "usage: resolve-skill-includes.sh [--root <abs>] <SKILL.md>" ; exit 0 ;;
    *)
      if [ -z "$FILE" ]; then FILE="$1"; shift
      else echo "resolve-skill-includes: unexpected arg: $1" >&2; exit 2
      fi
      ;;
  esac
done

if [ -z "$FILE" ]; then
  echo "resolve-skill-includes: SKILL.md path required" >&2
  exit 2
fi
if [ ! -r "$FILE" ]; then
  echo "resolve-skill-includes: file unreadable: $FILE" >&2
  exit 2
fi

if [ -z "$ROOT" ]; then
  if command -v git >/dev/null 2>&1; then
    ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  fi
fi

awk -v root="$ROOT" '
  /^[ \t]*!cat[ \t]+/ {
    line = $0
    sub(/^[ \t]*!cat[ \t]+/, "", line)
    sub(/[ \t]+$/, "", line)
    path = line
    if (root != "" && substr(path, 1, 1) != "/") {
      path = root "/" path
    }
    while ((getline incl < path) > 0) {
      if (substr(incl, 1, 3) == "## " && substr(incl, 4, 1) != "#") {
        incl = "#" incl
      }
      print incl
    }
    close(path)
    next
  }
  { print }
' "$FILE"

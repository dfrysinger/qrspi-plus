# tests/helpers/skill-markdown.bash — shared BATS helper for skill-markdown introspection.
#
# Loaded from a BATS file with:
#     load 'helpers/skill-markdown'
# (Bats resolves the path relative to BATS_TEST_DIRNAME; for unit tests under
# tests/unit/, the helper lives at ../helpers/skill-markdown.bash.)
#
# Provides four behavioral helpers — three direct-call (NO `run`), one BATS-shaped (`run`):
#
#   extract_section <file> <heading_level> <heading_text>
#     - heading_level is "H2" or "H3" (case-sensitive).
#     - prints to stdout the lines BETWEEN the named heading and the next same-level
#       heading (boundary lines NOT included). Section may end at EOF.
#     - returns 1 with a loud `skill-markdown:` diagnostic on stderr when the file is
#       unreadable, the heading anchor is not found, or the extract is empty
#       (silent-pass guard).
#
#   extract_and_grep <file> <heading_level> <heading_text> <regex>
#     - runs extract_section then `grep -E -- <regex>` over the extract.
#     - returns 0 with at least one matching line on stdout; returns 1 with a loud
#       diagnostic otherwise (missing anchor, empty extract, or no match).
#
#   assert_section_contains <file> <heading_level> <heading_text> <regex>
#     - BATS-shaped assertion wrapper. On miss, emits the diagnostic
#         `assert_section_contains FAILED: <file>:<H2|H3 heading text>:<regex>`
#       on stderr and exits 1. Designed to be invoked WITHIN `run`.
#
#   require_repo_root
#     - resolves REPO_ROOT from BATS_TEST_DIRNAME + `git rev-parse --show-toplevel`
#       and exports it. Returns 1 with a loud diagnostic when neither resolution
#       succeeds.
#
# Calling convention (load-bearing — also re-asserted in the helper-self pin):
# Consumer tests MUST call `extract_section`, `extract_and_grep`, and
# `require_repo_root` WITHOUT wrapping in BATS `run`. A non-zero return from a
# direct call directly fails the enclosing `@test` block, surfacing the diagnostic.
# `assert_section_contains` is the ONLY function designed for `run` semantics —
# its diagnostic is emitted to stderr in a BATS-style shape and the wrapper sets
# the conventional `$status`/`$output` variables for the caller to assert on.
#
# Bash 3.2 portability: no associative arrays, no `mapfile`, no `${var,,}`, no
# coproc, no `wait -n`. Tested under macOS /bin/bash 3.2 and bash 5.x.

# ---------------------------------------------------------------------------
# _skill_md_die <message>
# Emit a loud diagnostic prefixed with `skill-markdown:` to stderr.
# ---------------------------------------------------------------------------
_skill_md_die() {
  printf 'skill-markdown: %s\n' "$1" >&2
}

# ---------------------------------------------------------------------------
# _skill_md_prefix_for_level <H2|H3>
# Echo the markdown heading prefix (`## ` or `### `). Returns 1 on invalid level.
# ---------------------------------------------------------------------------
_skill_md_prefix_for_level() {
  case "$1" in
    H2) printf '## ' ;;
    H3) printf '### ' ;;
    *)
      _skill_md_die "invalid heading_level '$1' (expected H2 or H3)"
      return 1
      ;;
  esac
}

# ---------------------------------------------------------------------------
# extract_section <file> <heading_level> <heading_text>
# ---------------------------------------------------------------------------
extract_section() {
  if [ "$#" -ne 3 ]; then
    _skill_md_die "extract_section: expected 3 args (file, heading_level, heading_text); got $#"
    return 1
  fi
  local file="$1"
  local level="$2"
  local text="$3"

  if [ ! -r "$file" ]; then
    _skill_md_die "extract_section: file unreadable: $file"
    return 1
  fi

  local prefix
  prefix="$(_skill_md_prefix_for_level "$level")" || return 1

  # Single-pass awk: print lines strictly between the matching heading and the
  # next same-level heading (or EOF). Boundary lines excluded.
  # Same-level heading boundary = a line that begins with exactly `prefix` and
  # whose next character is not `#` (i.e. not a deeper heading like H3 inside H2).
  local target_line="${prefix}${text}"
  local found_marker="__SKILL_MD_FOUND_ANCHOR__"
  local stderr_tmp="/tmp/skill-md-extract-stderr-$$"
  local awk_out
  awk_out="$(awk -v target="$target_line" -v prefix="$prefix" -v found_marker="$found_marker" '
    BEGIN { inside = 0; found = 0; plen = length(prefix) }
    {
      if (inside == 1) {
        if (substr($0, 1, plen) == prefix) {
          ch = substr($0, plen + 1, 1)
          if (ch != "#" && ch != "") {
            inside = 0
            next
          }
        }
        print $0
        next
      }
      if ($0 == target) {
        inside = 1
        found = 1
        next
      }
    }
    END {
      if (found == 1) {
        printf "%s\n", found_marker > "/dev/stderr"
      }
    }
  ' "$file" 2>"$stderr_tmp")"
  local awk_rc=$?

  local stderr_payload=""
  if [ -r "$stderr_tmp" ]; then
    stderr_payload="$(cat "$stderr_tmp")"
    rm -f "$stderr_tmp"
  fi

  if [ "$awk_rc" -ne 0 ]; then
    _skill_md_die "extract_section: awk failed on $file (rc=$awk_rc)"
    return 1
  fi

  case "$stderr_payload" in
    *"$found_marker"*) : ;;
    *)
      _skill_md_die "extract_section: heading anchor not found in $file: ${prefix}${text}"
      return 1
      ;;
  esac

  if [ -z "$awk_out" ]; then
    _skill_md_die "extract_section: extract is empty (silent-pass guard) in $file: ${prefix}${text}"
    return 1
  fi

  printf '%s\n' "$awk_out"
  return 0
}

# ---------------------------------------------------------------------------
# extract_and_grep <file> <heading_level> <heading_text> <regex>
# ---------------------------------------------------------------------------
extract_and_grep() {
  if [ "$#" -ne 4 ]; then
    _skill_md_die "extract_and_grep: expected 4 args (file, heading_level, heading_text, regex); got $#"
    return 1
  fi
  local file="$1"
  local level="$2"
  local text="$3"
  local regex="$4"

  local extract
  extract="$(extract_section "$file" "$level" "$text")" || return 1

  local matches
  matches="$(printf '%s\n' "$extract" | grep -E -- "$regex" 2>/dev/null)"
  if [ -z "$matches" ]; then
    local prefix
    prefix="$(_skill_md_prefix_for_level "$level")"
    _skill_md_die "extract_and_grep: regex did not match in $file section ${prefix}${text}: $regex"
    return 1
  fi
  printf '%s\n' "$matches"
  return 0
}

# ---------------------------------------------------------------------------
# assert_section_contains <file> <heading_level> <heading_text> <regex>
# BATS-shaped wrapper — designed for `run` invocation.
# ---------------------------------------------------------------------------
assert_section_contains() {
  if [ "$#" -ne 4 ]; then
    _skill_md_die "assert_section_contains: expected 4 args; got $#"
    return 1
  fi
  local file="$1"
  local level="$2"
  local text="$3"
  local regex="$4"

  if extract_and_grep "$file" "$level" "$text" "$regex" >/dev/null 2>&1; then
    return 0
  fi
  printf 'assert_section_contains FAILED: %s:%s %s:%s\n' "$file" "$level" "$text" "$regex" >&2
  return 1
}

# ---------------------------------------------------------------------------
# extract_section_fence_aware <file> <anchor-heading>
#
# Extracts from the anchor heading line (inclusive) through the last line
# before the next out-of-fence ## or ### section boundary, or EOF.
#
# Unlike extract_section, the anchor is the full heading line (e.g.
# "### Review Round") and heading-shaped lines inside open code fences are
# not treated as boundaries. Closing a fence restores boundary detection for
# subsequent lines.
#
# On success: prints anchor line + content lines to stdout, exits 0.
# On error:   prints nothing to stdout, emits a named diagnostic to stderr,
#             exits non-zero.  Error message always begins with the literal
#             prefix "extract_section_fence_aware:" and includes the anchor
#             heading value.  The two error paths are distinguishable:
#               missing anchor  -- message body contains "not found"
#               empty region    -- message body does NOT contain "not found"
#
# Bash 3.2 portable; uses awk for single-pass extraction.
# ---------------------------------------------------------------------------
extract_section_fence_aware() {
  if [ "$#" -ne 2 ]; then
    printf 'extract_section_fence_aware: expected 2 args (file, anchor-heading); got %d\n' "$#" >&2
    return 1
  fi
  local file="$1"
  local anchor="$2"

  if [ ! -r "$file" ]; then
    printf 'extract_section_fence_aware: file unreadable: %s\n' "$file" >&2
    return 1
  fi

  # Signal file: awk writes FOUND_WITH_CONTENT or FOUND_EMPTY after processing.
  # Use mktemp to generate an unguessable unique path — a predictable PID-scoped
  # name (/tmp/skill-md-fence-signal-$$) is vulnerable to TOCTOU / symlink
  # attacks by any local user who can pre-create the path in world-writable /tmp.
  # mktemp creates the file with mode 0600 and an unguessable suffix (sec.F01 fix).
  local signal_tmp
  signal_tmp="$(mktemp "${TMPDIR:-/tmp}/skill-md-fence-signal-XXXXXXXX")" || {
    printf 'extract_section_fence_aware: mktemp failed (TMPDIR=%s)\n' \
      "${TMPDIR:-/tmp}" >&2
    return 1
  }

  local awk_out
  awk_out="$(awk -v anchor="$anchor" -v signal_tmp="$signal_tmp" '
    BEGIN { fence = 0; in_b = 0; found = 0; has_content = 0 }

    /^```/ {
      fence = !fence
      if (in_b) {
        print
        has_content = 1
      }
      next
    }

    in_b && !fence && (/^## / || /^### /) {
      exit
    }

    !in_b && !fence && $0 == anchor {
      in_b = 1
      found = 1
      print
      next
    }

    in_b {
      print
      if ($0 ~ /[^[:space:]]/) has_content = 1
    }

    END {
      if (found) {
        if (has_content) {
          print "FOUND_WITH_CONTENT" > signal_tmp
        } else {
          print "FOUND_EMPTY" > signal_tmp
        }
      }
    }
  ' "$file")"
  local awk_status=$?
  if [ "$awk_status" -ne 0 ]; then
    printf 'extract_section_fence_aware: awk failed (exit %d) processing %s\n' \
      "$awk_status" "$file" >&2
    rm -f "$signal_tmp"
    return 1
  fi

  local signal=""
  if [ -r "$signal_tmp" ]; then
    signal="$(cat "$signal_tmp")"
    rm -f "$signal_tmp"
  fi

  case "$signal" in
    FOUND_WITH_CONTENT)
      printf '%s\n' "$awk_out"
      return 0
      ;;
    FOUND_EMPTY)
      printf 'extract_section_fence_aware: %s: anchor located but region contains no content lines\n' "$anchor" >&2
      return 1
      ;;
    *)
      printf 'extract_section_fence_aware: %s: not found in %s\n' "$anchor" "$file" >&2
      return 1
      ;;
  esac
}

# ---------------------------------------------------------------------------
# require_repo_root — export REPO_ROOT or fail loudly.
# ---------------------------------------------------------------------------
require_repo_root() {
  if [ -n "${REPO_ROOT:-}" ] && [ -d "$REPO_ROOT" ]; then
    export REPO_ROOT
    return 0
  fi

  # Strategy 1: walk up from BATS_TEST_DIRNAME looking for a .git directory.
  if [ -n "${BATS_TEST_DIRNAME:-}" ]; then
    local dir="$BATS_TEST_DIRNAME"
    local i=0
    while [ "$i" -lt 8 ]; do
      if [ -e "$dir/.git" ]; then
        REPO_ROOT="$dir"
        export REPO_ROOT
        return 0
      fi
      dir="$(dirname "$dir")"
      i=$((i + 1))
      if [ "$dir" = "/" ]; then
        break
      fi
    done
  fi

  # Strategy 2: ask git directly (cwd-relative).
  if command -v git >/dev/null 2>&1; then
    local git_root
    git_root="$(git rev-parse --show-toplevel 2>/dev/null)"
    if [ -n "$git_root" ] && [ -d "$git_root" ]; then
      REPO_ROOT="$git_root"
      export REPO_ROOT
      return 0
    fi
  fi

  _skill_md_die "require_repo_root: could not resolve REPO_ROOT from BATS_TEST_DIRNAME or git rev-parse --show-toplevel"
  return 1
}

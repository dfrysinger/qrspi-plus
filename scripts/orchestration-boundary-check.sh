#!/usr/bin/env bash
# orchestration-boundary-check.sh
#
# Phase-end orchestration-boundary check (OBC). Surfaces two classes of
# orchestration drift in a single per-phase report per design.md §G5(b):
#
#   1. Boundary violations — combined surface for fail-soft drift:
#                            (a) commits in <phase-base>..HEAD whose
#                                author name does NOT carry the
#                                qrspi-<agent> subagent author marker
#                                (entries prefixed `non-subagent-commit:`),
#                            (b) paths reported by `git status --porcelain`
#                                that fall outside the allowlisted
#                                `reviews/` bookkeeping tree (entries
#                                prefixed `uncommitted-edit:`).
#                            Exit code unaffected by entries here; the
#                            batch gate inspects the report directly.
#   2. Dispatch defects    — missing/malformed phase-base inputs, malformed
#                            SHAs, malformed author-name records. Fail-loud:
#                            any entry under this section produces a
#                            non-zero exit so the autopilot's unconditional
#                            dispatch-defect halt branch fires.
#
# Each section header is emitted ONLY when that section has at least one
# entry; a clean run produces a byte-empty report file.
#
# Phase-base resolution is per-phase:
#   --phase implement      reads <artifact-dir>/reviews/implement/wave-state/wave-1.txt
#                          (the wave-1 sidecar; the SHA is the value of
#                          the `integration_base:` line)
#   --phase integration    reads <artifact-dir>/reviews/integration/phase-base.txt
#   --phase test           reads <artifact-dir>/reviews/test/phase-base.txt
#
# Every SHA read from disk is validated against the well-formed git
# object-name shape (lowercase hex, 7–64 chars) BEFORE being passed to any
# git invocation; a malformed SHA produces a `sha-format-invalid:` named
# diagnostic and is not handed to `git log`.
#
# Report writes are atomic: the body is composed in a sibling temp file
# under the same directory and renamed into place at the end. POSIX
# rename(2) atomicity then guarantees the final report path either
# contains the complete report or is absent — a partial report with a
# spuriously-empty `## Dispatch defects` section can never appear on
# disk. A failed rename surfaces the `report-write-failed:` named
# diagnostic and a non-zero exit so the autopilot's absent-report
# branch never silently observes "OBC exit 0, no report".
#
# Bash 3.2 portable: no mapfile, no associative arrays, no ${var,,}.

set -u

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

VALID_PHASES_LIST="implement, integration, test"
SHA_REGEX='^[0-9a-f]{7,64}$'
SUBAGENT_AUTHOR_PREFIX="qrspi-"

# ---------------------------------------------------------------------------
# Diagnostics
# ---------------------------------------------------------------------------

emit_diag() {
  printf '%s: %s\n' "$(basename -- "${BASH_SOURCE[0]}")" "$*" >&2
}

usage() {
  cat <<EOF >&2
Usage: $(basename -- "${BASH_SOURCE[0]}") --phase <implement|integration|test> --artifact-dir <path>

Writes <artifact-dir>/reviews/<phase>/orchestration-boundary.md.
Exits 0 when ## Dispatch defects is empty (boundary-violation entries are fail-soft);
exits non-zero when any dispatch-defect entry is present.
A clean run produces a byte-empty report file (no section headers emitted).
EOF
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

phase=""
artifact_dir=""

while [ $# -gt 0 ]; do
  case "$1" in
    --phase)
      [ $# -ge 2 ] || { emit_diag "missing value for --phase"; usage; exit 2; }
      phase="$2"
      shift 2
      ;;
    --artifact-dir)
      [ $# -ge 2 ] || { emit_diag "missing value for --artifact-dir"; usage; exit 2; }
      artifact_dir="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      emit_diag "unknown argument: $1"
      usage
      exit 2
      ;;
  esac
done

if [ -z "$phase" ] || [ -z "$artifact_dir" ]; then
  emit_diag "missing required --phase or --artifact-dir"
  usage
  exit 2
fi

# Closed phase enumeration. Unknown values halt BEFORE any phase-base read
# is attempted under the bogus phase directory and BEFORE any git log runs
# against an undefined phase-base value.
case "$phase" in
  implement|integration|test) ;;
  *)
    emit_diag "obc-unknown-phase: '$phase' is not one of: $VALID_PHASES_LIST"
    exit 3
    ;;
esac

# ---------------------------------------------------------------------------
# Report path setup
# ---------------------------------------------------------------------------

report_dir="$artifact_dir/reviews/$phase"
mkdir -p "$report_dir"
final_report="$report_dir/orchestration-boundary.md"
tmp_report="$(mktemp "$report_dir/.orchestration-boundary.XXXXXX.tmp")"

# ---------------------------------------------------------------------------
# Accumulators (bash 3.2: indexed arrays only)
# ---------------------------------------------------------------------------

dispatch_defects=()
boundary_violations=()

add_defect()    { dispatch_defects[${#dispatch_defects[@]}]="$1"; }
add_boundary()  { boundary_violations[${#boundary_violations[@]}]="$1"; }

# ---------------------------------------------------------------------------
# SHA-shape validation — gate ALL on-disk SHAs before any git invocation
# ---------------------------------------------------------------------------

is_well_formed_sha() {
  local candidate="$1"
  [[ "$candidate" =~ $SHA_REGEX ]]
}

# ---------------------------------------------------------------------------
# Phase-base resolution
# ---------------------------------------------------------------------------

phase_base=""

case "$phase" in
  implement)
    sidecar="$artifact_dir/reviews/implement/wave-state/wave-1.txt"
    if [ ! -r "$sidecar" ]; then
      add_defect "wave-1-sidecar-missing: expected wave-1 sidecar at $sidecar"
      emit_diag "wave-1-sidecar-missing: $sidecar"
    else
      raw="$(awk -F'[[:space:]]*:[[:space:]]*' '$1=="integration_base"{print $2; exit}' "$sidecar" 2>/dev/null || true)"
      # Strip trailing whitespace/CR.
      raw="${raw%%$'\r'}"
      raw="${raw## }"
      raw="${raw%% }"
      if [ -z "$raw" ]; then
        add_defect "wave-1-sidecar-malformed: missing or empty integration_base: line in $sidecar"
        emit_diag "wave-1-sidecar-malformed: $sidecar"
      elif ! is_well_formed_sha "$raw"; then
        add_defect "sha-format-invalid: integration_base value '$raw' in $sidecar is not a well-formed git object name (lowercase hex, 7-64 chars)"
        emit_diag "sha-format-invalid: $raw"
      else
        phase_base="$raw"
      fi
    fi
    ;;
  integration|test)
    pbfile="$artifact_dir/reviews/$phase/phase-base.txt"
    if [ ! -r "$pbfile" ]; then
      add_defect "phase-base-missing: expected phase-base file at $pbfile"
      emit_diag "phase-base-missing: $pbfile"
    else
      raw="$(tr -d '[:space:]' < "$pbfile" 2>/dev/null || true)"
      if [ -z "$raw" ]; then
        add_defect "phase-base-malformed: empty phase-base.txt at $pbfile"
        emit_diag "phase-base-malformed: $pbfile"
      elif ! is_well_formed_sha "$raw"; then
        add_defect "sha-format-invalid: phase-base value '$raw' in $pbfile is not a well-formed git object name (lowercase hex, 7-64 chars)"
        emit_diag "sha-format-invalid: $raw"
      else
        phase_base="$raw"
      fi
    fi
    ;;
esac

# ---------------------------------------------------------------------------
# Author-name fail-loud helper
# ---------------------------------------------------------------------------
#
# Returns 0 when the author-name record carries an awk-record-breaking byte
# class (newline, multiple consecutive whitespace bytes, or any
# non-TAB/LF control byte from \x00–\x1F). Caller surfaces the
# obc-author-name-malformed: diagnostic and skips the marker filter for
# that record.

author_name_is_malformed() {
  local name="$1"
  case "$name" in
    *$'\n'*) return 0 ;;
  esac
  # Multiple consecutive whitespace bytes (covers space, tab, etc.).
  if printf '%s' "$name" | LC_ALL=C grep -Eq '[[:space:]]{2,}'; then
    return 0
  fi
  # Control bytes \x01-\x1F excluding TAB (\x09) and LF (\x0A). NUL (\x00)
  # is the record separator, so it cannot appear inside an author field.
  # Omitting \x00 also avoids the bash-3.2 issue where a literal NUL in the
  # pattern truncates the C-string argument passed to grep.
  if printf '%s' "$name" | LC_ALL=C grep -q $'[\x01-\x08\x0b-\x1f]'; then
    return 0
  fi
  return 1
}

# ---------------------------------------------------------------------------
# Commit walk and workspace status — only when phase_base is well-formed
# ---------------------------------------------------------------------------

if [ -n "$phase_base" ]; then
  # NUL-separated record stream: each record is "<sha> <author-name>".
  # NUL separation means an embedded newline in the author name does NOT
  # break record boundaries; we surface the embedded-newline case as a
  # dispatch defect rather than letting it silently slip past awk.
  # Use `read -r -d ''` against a process substitution because command
  # substitution `$(...)` truncates at the first NUL byte and would
  # silently drop every record after the first (bash 3.2 portable).
  while IFS= read -r -d '' record; do
    [ -n "$record" ] || continue

    sha="${record%% *}"
    author="${record#* }"

    if author_name_is_malformed "$author"; then
      add_defect "obc-author-name-malformed: commit $sha author-name record carries awk-record-breaking bytes (newline, multi-whitespace, or control byte)"
      emit_diag "obc-author-name-malformed: $sha"
      continue
    fi

    case "$author" in
      "$SUBAGENT_AUTHOR_PREFIX"*)
        continue
        ;;
    esac

    subject="$(git log -n 1 --format='%s' "$sha" 2>/dev/null || printf '%s' '<subject-unavailable>')"
    add_boundary "non-subagent-commit: $sha — $author — $subject"
  done < <(git log "$phase_base"..HEAD -z --format='%H %an' 2>/dev/null || true)

  # Workspace status (porcelain v1: 2 status chars + space + path).
  while IFS= read -r status_line; do
    [ -z "$status_line" ] && continue
    path="${status_line:3}"
    # Porcelain rename/copy entries take the form "R  old -> new"; use the
    # destination path for allowlist evaluation.
    case "$path" in
      *' -> '*)
        path="${path##* -> }"
        ;;
    esac
    case "$path" in
      reviews/*|'"'reviews/*)
        continue
        ;;
    esac
    add_boundary "uncommitted-edit: $status_line"
  done < <(git status --porcelain 2>/dev/null || true)
fi

# ---------------------------------------------------------------------------
# Compose report (atomic write: temp file + rename)
# ---------------------------------------------------------------------------

emit_section() {
  local heading="$1"
  shift
  local -a entries
  entries=("$@")
  # Section header is emitted ONLY when the section has at least one entry
  # (design.md §G5(b) acceptance). A clean run thus produces a byte-empty
  # report file: no header, no "Phase:" metadata, no `_None._` placeholder.
  if [ "${#entries[@]}" -eq 0 ]; then
    return 0
  fi
  printf '## %s\n\n' "$heading"
  local entry
  for entry in "${entries[@]}"; do
    printf -- '- %s\n' "$entry"
  done
  printf '\n'
}

{
  # Ordering matches design.md §G5(b): Boundary violations first, then
  # Dispatch defects. Either or both may be absent (byte-empty report on
  # a clean run).
  emit_section "Boundary violations" "${boundary_violations[@]+"${boundary_violations[@]}"}"
  emit_section "Dispatch defects"    "${dispatch_defects[@]+"${dispatch_defects[@]}"}"
} > "$tmp_report"

# Atomic rename. POSIX rename(2) supplies the "all-or-nothing" guarantee on
# the same filesystem; a SIGKILL/SIGPIPE/disk-full mid-write affects only
# the temp file, not the final report path.
#
# If the final-report path already exists as a directory, mv would silently
# move the temp file INTO it (BSD/macOS mv default) rather than failing —
# masking a genuine dispatch defect in the surrounding orchestration. Refuse
# explicitly with the report-write-failed: diagnostic so the autopilot's
# absent-report branch never observes "OBC exit 0, no report".
if [ -d "$final_report" ]; then
  emit_diag "report-write-failed: final report path '$final_report' is a directory; refusing to overwrite via mv"
  rm -f "$tmp_report" 2>/dev/null || true
  exit 5
fi

if ! mv "$tmp_report" "$final_report" 2>/dev/null; then
  emit_diag "report-write-failed: atomic rename of '$tmp_report' to '$final_report' failed"
  rm -f "$tmp_report" 2>/dev/null || true
  exit 5
fi

# ---------------------------------------------------------------------------
# Exit code direction
# ---------------------------------------------------------------------------
#
# Fail-loud only on dispatch-defects; boundary-violation entries are
# fail-soft because the batch gate inspects the report directly.

if [ "${#dispatch_defects[@]}" -gt 0 ]; then
  exit 4
fi
exit 0

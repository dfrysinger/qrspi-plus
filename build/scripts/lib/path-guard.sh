#!/usr/bin/env bash
# path-guard.sh — shared fail-closed repo-boundary guards for QRSPI dispatch
# scripts.
#
# Source this file from any dispatch script that ingests file paths from
# user-supplied flags. Two functions are exported:
#
#   assert_path_under_repo_root <label> <path>
#       canonicalizes <path> via `realpath` (with a `readlink -f` fallback)
#       and rejects any path whose canonical target is not strictly under
#       the canonical $REPO_ROOT/. Use it AFTER the existence check (so
#       missing files fail with their own clearer diagnostic) and BEFORE
#       any `cat` read or prompt-emission step that could ferry the file's
#       bytes into a sanctioned LLM channel.
#
#   assert_ancestor_under_repo_root <label> <path>
#       walks <path> upward to the deepest existing ancestor and runs the
#       canonical boundary check on that ancestor. Use it BEFORE
#       `mkdir -p <path>` whenever <path> is user-supplied and may not
#       yet exist; this prevents `mkdir` from materialising directories
#       outside the repo when the leaf would later be rejected by the
#       canonical-form check.
#
# A third helper, _qrspi_canonicalize, is used by both public functions
# above and is also called directly from dispatch-companion.sh after the
# canonical boundary check passes (to record an absolute round_dir form
# in the persisted job record). Its leading underscore is preserved for
# back-compat with downstream callers; treat it as a stable internal
# helper rather than a strictly private function.
#
# Failure modes (all exit 1, all write to stderr):
#   - $REPO_ROOT not exported, empty, or fails to canonicalize
#       → "cannot canonicalize $REPO_ROOT"
#   - <path> fails to canonicalize (broken symlink, missing parent, etc.)
#       → "cannot canonicalize path"
#   - canonical <path> is not under canonical $REPO_ROOT/
#       → "<path> resolves outside repository (canonical: ...; root: ...)"
#
# The diagnostic substring `resolves outside repository` is the cross-script
# contract that test coverage pins on.
#
# Implementation notes:
#   - macOS BSD `realpath` (10.15+) accepts a single path argument and
#     resolves the full canonical path including symlinks. GNU `realpath`
#     behaves the same. We treat any non-zero exit OR empty stdout as a
#     canonicalization failure (fail-closed).
#   - `readlink -f` is a Linux-coreutils fallback for environments where
#     `realpath` is not on PATH; on macOS it's a no-op (BSD readlink lacks
#     -f), so the realpath branch is taken on every QRSPI dev host today.
#   - The under-root check uses a trailing-slash-anchored prefix match so
#     `/repo-evil/` cannot masquerade as `/repo/`-prefixed.

# ---------------------------------------------------------------------------
# _qrspi_canonicalize <path>  →  prints canonical path on stdout, exits 0
# on success and non-zero on canonicalization failure (also empty stdout).
_qrspi_canonicalize() {
  local raw="$1"
  local out=""
  if command -v realpath >/dev/null 2>&1; then
    out="$(realpath "$raw" 2>/dev/null)" || out=""
  fi
  if [ -z "$out" ]; then
    # Fallback: GNU readlink -f. (BSD readlink on macOS lacks -f and exits
    # non-zero, leaving $out empty — fail-closed handled by caller.)
    out="$(readlink -f "$raw" 2>/dev/null)" || out=""
  fi
  if [ -z "$out" ]; then
    return 1
  fi
  printf '%s\n' "$out"
}

# ---------------------------------------------------------------------------
# assert_ancestor_under_repo_root <label> <path>
#
# Pre-mkdir guard: walks <path> upward to find the deepest existing
# ancestor, canonicalizes it, and asserts that ancestor is under $REPO_ROOT.
# Use this BEFORE `mkdir -p <path>` whenever <path> is user-supplied and
# may not yet exist. It prevents mkdir from creating directories outside
# the repository when a later realpath-based boundary check would reject
# the leaf (the partial-state-on-failure class).
#
# After mkdir, callers should still run assert_path_under_repo_root on the
# now-existing leaf to catch symlink-resolution attacks (TOCTOU).
assert_ancestor_under_repo_root() {
  local label="$1"
  local raw="$2"
  local probe="$raw"

  # Walk up to the first existing ancestor or symlink. dirname returns "."
  # for a bare filename and "/" when it can't go higher; treat self-loop as
  # fail-closed. We must terminate on symlinks (-L) as well as -e: a broken
  # symlink whose target is out-of-repo would otherwise be walked past as
  # "non-existent", letting the ancestor check pass on a higher in-repo
  # directory while the subsequent mkdir -p follows the symlink and
  # materializes a directory tree outside the repo.
  while [ ! -e "$probe" ] && [ ! -L "$probe" ]; do
    local parent
    parent="$(dirname "$probe")"
    if [ "$parent" = "$probe" ]; then
      printf 'error: %s: cannot locate any existing ancestor of %s; fail-closed.\n' \
        "$label" "$raw" >&2
      exit 1
    fi
    probe="$parent"
  done

  assert_path_under_repo_root "$label (ancestor)" "$probe"
}

assert_path_under_repo_root() {
  local label="$1"
  local raw="$2"

  if [ -z "${REPO_ROOT:-}" ]; then
    printf 'error: %s: $REPO_ROOT is unset; cannot enforce repository boundary (fail-closed).\n' \
      "$label" >&2
    exit 1
  fi

  local canon_root
  if ! canon_root="$(_qrspi_canonicalize "$REPO_ROOT")"; then
    printf 'error: %s: cannot canonicalize $REPO_ROOT (%s); fail-closed.\n' \
      "$label" "$REPO_ROOT" >&2
    exit 1
  fi
  if [ ! -d "$canon_root" ]; then
    printf 'error: %s: canonical $REPO_ROOT (%s) is not a directory; fail-closed.\n' \
      "$label" "$canon_root" >&2
    exit 1
  fi

  local canon
  if ! canon="$(_qrspi_canonicalize "$raw")"; then
    printf 'error: %s: cannot canonicalize path (%s); fail-closed.\n' \
      "$label" "$raw" >&2
    exit 1
  fi

  # Trailing-slash-anchored prefix match: /repo/ must be a strict ancestor
  # of /repo/foo, but not of /repo-evil/foo.
  case "$canon/" in
    "$canon_root"/*) : ;;
    *)
      printf 'error: %s: path %s resolves outside repository (canonical: %s; root: %s)\n' \
        "$label" "$raw" "$canon" "$canon_root" >&2
      exit 1
      ;;
  esac
}

#!/usr/bin/env bash
# scripts/measure-active-footprint.sh
#
# G9 footprint measurement. Computes per-turn footprint as
#   tokens(skills/using-qrspi/SKILL.md)
#   + tokens(skills/<active-skill>/SKILL.md, with `!cat` references resolved
#                                            transitively before tokenization)
# using a pinned deterministic tokenizer (default `tiktoken:cl100k_base`).
#
# `!cat` resolution covers BOTH `skills/_shared/*.md` (cross-skill snippets)
# AND `skills/<skill>/references/*.md` (per-skill references). This matches
# what `tools/build-plugin.mjs` ships at runtime — see issue #330 for the
# v0.7.4 honest-measurement fix.
#
# CLI surface, stdout shape, named diagnostics, and exit codes are contracted
# in docs/qrspi/2026-06-04-v073-release/structure.md § Interfaces —
# `scripts/measure-active-footprint.sh`.
#
# Resolution + tokenization both happen in a single embedded Python helper
# (Python is already on the critical path for tiktoken); this keeps byte
# semantics faithful (no shell-induced trailing-newline drift on short
# fixtures) and centralizes cycle detection.
#
# Bash 3.2 compatible (macOS /bin/bash).

set -u

# ---------- locate repo root ----------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"

# ---------- arg parsing ---------------------------------------------------
ACTIVE_SKILL=""
ALL_MODE=0
TOKENIZER="tiktoken:cl100k_base"

while [ $# -gt 0 ]; do
  case "$1" in
    --skill)
      ACTIVE_SKILL="${2:-}"; shift 2 ;;
    --all)
      ALL_MODE=1; shift ;;
    --tokenizer)
      TOKENIZER="${2:-}"; shift 2 ;;
    *)
      printf 'measure-active-footprint: unknown argument: %s\n' "$1" >&2
      exit 2 ;;
  esac
done

case "$TOKENIZER" in
  tiktoken:cl100k_base|tiktoken:o200k_base) : ;;
  *)
    printf 'measure-active-footprint: unsupported --tokenizer: %s (accepted: tiktoken:cl100k_base, tiktoken:o200k_base)\n' "$TOKENIZER" >&2
    exit 2 ;;
esac

TIKTOKEN_MODEL="${TOKENIZER#tiktoken:}"

# ---------- tokenizer probe (BEFORE any !cat resolution or skill lookup) --
# Probe (1) python3 resolvable on PATH and (2) the `tiktoken` library
# importable AND the pinned encoding loadable. Either failure surfaces
# `footprint-tokenizer-missing:` naming the tokenizer identifier and the
# resolution path attempted; no fallback to a non-pinned tokenizer.
PYBIN=""
if command -v python3 >/dev/null 2>&1; then
  PYBIN="$(command -v python3)"
fi
if [ -z "$PYBIN" ]; then
  printf 'footprint-tokenizer-missing: tokenizer=%s resolution-path=python3 (not found on PATH=%s)\n' \
    "$TOKENIZER" "${PATH:-}" >&2
  exit 3
fi
if ! "$PYBIN" -c "import tiktoken; tiktoken.get_encoding('${TIKTOKEN_MODEL}')" >/dev/null 2>&1; then
  printf 'footprint-tokenizer-missing: tokenizer=%s resolution-path=%s (tiktoken module or encoding %s not loadable)\n' \
    "$TOKENIZER" "$PYBIN" "$TIKTOKEN_MODEL" >&2
  exit 3
fi

# ---------- skill enumeration --------------------------------------------
list_all_skills() {
  # Newline-delimited skill names (basename of skills/<name>/ with SKILL.md).
  # Excludes `_shared` (snippet directory, not a skill) and `using-qrspi`
  # (the always-loaded universal dispatch chain is the formula's addend,
  # not a candidate for the "heaviest active skill" pick).
  local d name
  for d in "$REPO_ROOT"/skills/*/; do
    [ -d "$d" ] || continue
    name="$(basename "$d")"
    [ "$name" = "_shared" ] && continue
    [ "$name" = "using-qrspi" ] && continue
    [ -f "$d/SKILL.md" ] || continue
    printf '%s\n' "$name"
  done
}

# ---------- preflight: --skill must exist if specified -------------------
if [ -n "$ACTIVE_SKILL" ]; then
  if [ ! -f "$REPO_ROOT/skills/$ACTIVE_SKILL/SKILL.md" ]; then
    printf 'footprint-skill-not-found: skill=%s expected-path=%s\n' \
      "$ACTIVE_SKILL" "$REPO_ROOT/skills/$ACTIVE_SKILL/SKILL.md" >&2
    exit 6
  fi
fi

# ---------- build the per-skill measurement list -------------------------
# A newline-delimited list of skill names to measure. In --skill mode that's
# just the one skill; otherwise every skill under skills/ (excluding _shared).
SKILLS_LIST="$(mktemp -t t37skills.XXXXXX)"
if [ -n "$ACTIVE_SKILL" ]; then
  printf '%s\n' "$ACTIVE_SKILL" > "$SKILLS_LIST"
else
  list_all_skills > "$SKILLS_LIST"
fi

# ---------- run the embedded resolver + tokenizer ------------------------
# Python helper. Args:
#   $1 = repo root
#   $2 = tiktoken encoding name
#   $3 = --all flag (1 or 0)
#   $4 = skill-name to treat as the using-qrspi addend ("" if missing on disk)
#   $5 = "all" or "single" — selection mode for the per-turn (load-bearing)
#        skill: "all" picks the heaviest of the listed skills; "single" picks
#        the first listed skill.
#   $6 = path to newline-delimited list of skills to measure.
# Stdout shape: emits the contracted active_skill=, tokenizer=, total_tokens=
#   header lines. With --all=1, appends the "<TAB>" TSV breakdown and a
#   resolved-body fenced block (for transitive-resolution evidence).
# Stderr: named diagnostics on resolution failure.
# Exit: 0 on success, 4 on unresolvable, 5 on cycle, 6 on skill-not-found
#   (the using-qrspi addend skill being absent is treated as a 0-token addend,
#   not an error — exit 6 only when a listed skill is missing, which cannot
#   happen here because we built the list from disk).

USINGQRSPI_NAME=""
if [ -f "$REPO_ROOT/skills/using-qrspi/SKILL.md" ]; then
  USINGQRSPI_NAME="using-qrspi"
fi

SELECTION_MODE="all"
if [ -n "$ACTIVE_SKILL" ]; then
  SELECTION_MODE="single"
fi

"$PYBIN" - "$REPO_ROOT" "$TIKTOKEN_MODEL" "$ALL_MODE" "$USINGQRSPI_NAME" \
  "$SELECTION_MODE" "$SKILLS_LIST" "$TOKENIZER" <<'PYEOF'
import os, re, sys

repo_root      = sys.argv[1]
encoding_name  = sys.argv[2]
all_mode       = sys.argv[3] == "1"
usingqrspi     = sys.argv[4]          # "" if absent on disk
selection_mode = sys.argv[5]          # "single" or "all"
skills_list    = sys.argv[6]
tokenizer_id   = sys.argv[7]

import tiktoken
enc = tiktoken.get_encoding(encoding_name)

CAT_RE = re.compile(r'^!cat[ \t]+(skills/(?:_shared|[^/\s]+/references)/[^\s]+\.md)[ \t]*$')

def resolve_bytes(skill_or_snippet_path, visited_stack):
    """Read the file at `path` and return its resolved bytes (str) with
    every `!cat skills/_shared/...md` and `!cat skills/<skill>/references/...md`
    line replaced transitively by the
    referenced file's resolved content. `visited_stack` is the active-
    descent list of absolute paths (for cycle detection)."""
    try:
        with open(skill_or_snippet_path, 'rb') as f:
            raw = f.read()
    except FileNotFoundError:
        # Shouldn't happen at top level (we pre-validated SKILL.md exists);
        # at !cat level we check before recursing.
        sys.stderr.write(
            "footprint-snippet-unresolvable: consuming-file=<unknown> "
            "missing-path=%s\n" % skill_or_snippet_path)
        sys.exit(4)
    text = raw.decode('utf-8', errors='replace')
    # Preserve a final-byte-newline distinction so short fixtures
    # ("hello world" with NO trailing newline) tokenize as the bare string.
    if text.endswith('\n'):
        body_lines = text[:-1].split('\n')
        trailing_nl = True
    else:
        body_lines = text.split('\n')
        trailing_nl = False
    out_pieces = []
    for line in body_lines:
        m = CAT_RE.match(line)
        if not m:
            out_pieces.append(line + '\n')
            continue
        target_rel = m.group(1)
        target_abs = os.path.normpath(os.path.join(repo_root, target_rel))
        if not os.path.isfile(target_abs):
            sys.stderr.write(
                "footprint-snippet-unresolvable: consuming-file=%s "
                "reference=%s missing-path=%s\n"
                % (skill_or_snippet_path, line, target_abs))
            sys.exit(4)
        if target_abs in visited_stack:
            cyc = " -> ".join(visited_stack + [target_abs])
            sys.stderr.write(
                "footprint-snippet-cycle: cycle=%s\n" % cyc)
            sys.exit(5)
        # Recurse; snippet's resolved bytes are inlined in place of the
        # !cat line (with its own trailing-newline semantics).
        sub = resolve_bytes(target_abs, visited_stack + [target_abs])
        out_pieces.append(sub)
        # Snippet may or may not have its own trailing newline; the original
        # !cat line carried a single trailing newline (split() ate it). If
        # the snippet didn't end with \n, we add one so the next active-skill
        # line still starts on its own line.
        if sub and not sub.endswith('\n'):
            out_pieces.append('\n')
    resolved = ''.join(out_pieces)
    # Restore the source file's trailing-newline shape:
    # - source had trailing \n  → resolved already ends with \n (every line
    #   piece appended one); leave as-is.
    # - source had NO trailing \n → strip the trailing \n we added for the
    #   final line.
    if not trailing_nl and resolved.endswith('\n'):
        resolved = resolved[:-1]
    return resolved

def measure(skill_name):
    skill_path = os.path.join(repo_root, "skills", skill_name, "SKILL.md")
    if not os.path.isfile(skill_path):
        sys.stderr.write(
            "footprint-skill-not-found: skill=%s expected-path=%s\n"
            % (skill_name, skill_path))
        sys.exit(6)
    resolved = resolve_bytes(skill_path, [skill_path])
    return resolved, len(enc.encode(resolved))

# Using-qrspi addend (constant across all measured skills).
if usingqrspi:
    _, usingqrspi_tokens = measure(usingqrspi)
else:
    usingqrspi_tokens = 0

with open(skills_list) as f:
    skill_names = [s.strip() for s in f if s.strip()]

per_skill = []  # list of (name, resolved_text, tokens)
for s in skill_names:
    resolved, tokens = measure(s)
    per_skill.append((s, resolved, tokens))

# Pick the load-bearing (selected) skill.
if selection_mode == "single":
    selected_name, selected_resolved, selected_tokens = per_skill[0]
else:
    # heaviest by per-skill token count
    selected = max(per_skill, key=lambda r: r[2])
    selected_name, selected_resolved, selected_tokens = selected

total = usingqrspi_tokens + selected_tokens

out = sys.stdout
out.write("active_skill=%s\n" % selected_name)
out.write("tokenizer=%s\n"   % tokenizer_id)
out.write("total_tokens=%d\n" % total)

if all_mode:
    out.write("skill\ttokens\n")
    # Include using-qrspi as its own row for transparency.
    out.write("using-qrspi\t%d\n" % usingqrspi_tokens)
    for name, _, tokens in sorted(per_skill, key=lambda r: r[0]):
        if name == "using-qrspi":
            continue
        out.write("%s\t%d\n" % (name, tokens))
    # Evidence block: emit the resolved body of the selected skill so
    # downstream readers (and the test suite's transitive-resolution check)
    # can verify !cat substitution ran correctly.
    out.write("\n# resolved-body active_skill=%s\n" % selected_name)
    out.write(selected_resolved)
    if not selected_resolved.endswith('\n'):
        out.write('\n')

PYEOF
RC=$?
rm -f "$SKILLS_LIST"
exit $RC

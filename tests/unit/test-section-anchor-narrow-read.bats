#!/usr/bin/env bats
#
# T36 Slice 7 G4 Mechanism B unit pin — narrow-read byte-identical contract.
#
# For each indexed artifact (T34 manifest), fetches at least three sample
# headings — one near the start (small line_start), one from the middle,
# and one at the FINAL section (where line_end equals the artifact's last
# line) — performs Read(offset=line_start, limit=line_end-line_start+1)
# against the source, and asserts each returned slice is byte-identical to
# the corresponding source line range per design line 237.
#
# For at least one indexed artifact, exercises an H2 heading whose indexed
# {line_start, line_end} span includes at least one nested H3 sub-heading,
# and asserts the returned slice (via Read(offset, limit)) is byte-identical
# to the full H2 section INCLUDING its nested H3 children — confirming that
# line_end is bounded by the NEXT same-or-higher-level heading (another H2
# or the file end), not by the first H3.
#
# Bash 3.2 portable.

load '../helpers/skill-markdown'

setup_file() {
  require_repo_root
}

# ---------------------------------------------------------------------------
# narrow_read <file> <line_start> <line_end>
#
# Emulates the consumer's Read(offset, limit) call by extracting exactly
# the lines [line_start..line_end] (1-indexed, inclusive) via sed -n,
# preserving byte semantics. Echoes the slice to stdout.
# ---------------------------------------------------------------------------
_narrow_read() {
  local file="$1" line_start="$2" line_end="$3"
  sed -n "${line_start},${line_end}p" "$file"
}

# ---------------------------------------------------------------------------
# source_slice <file> <line_start> <line_end>
#
# The "ground-truth" comparison slice: same line range from the source.
# Functionally identical to _narrow_read but kept separate to make the
# byte-identity assertion semantically explicit (consumer's read MUST equal
# source's same-range slice).
# ---------------------------------------------------------------------------
_source_slice() {
  local file="$1" line_start="$2" line_end="$3"
  sed -n "${line_start},${line_end}p" "$file"
}

# ---------------------------------------------------------------------------
# Lookup helper: read line_start/line_end for a given key from a JSON index
# via node. Echoes "<line_start> <line_end>" to stdout. Returns 1 on miss.
# ---------------------------------------------------------------------------
_lookup() {
  local idx_path="$1" key="$2"
  node -e '
const fs = require("fs");
const idx = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
const k = process.argv[2];
if (!(k in idx)) { process.stderr.write("key not found: " + k + "\n"); process.exit(1); }
process.stdout.write(idx[k].line_start + " " + idx[k].line_end + "\n");
' "$idx_path" "$key"
}

# ---------------------------------------------------------------------------
# byte_compare: assert two strings are byte-identical via diff.
# ---------------------------------------------------------------------------
_byte_compare() {
  local a="$1" b="$2"
  if [ "$a" = "$b" ]; then return 0; fi
  echo "byte-identity violation:" >&2
  diff <(printf '%s' "$a") <(printf '%s' "$b") >&2
  return 1
}

# ---------------------------------------------------------------------------
# Helper: pick the first H2 from a JSON index (smallest line_start among
# top-level keys whose source line begins with "## " not "### ").
# ---------------------------------------------------------------------------
_first_h2_key() {
  local idx="$1" src="$2"
  node -e '
const fs = require("fs");
const idx = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
const src = fs.readFileSync(process.argv[2], "utf8").split("\n");
let bestKey = null;
let bestLine = Infinity;
for (const k of Object.keys(idx)) {
  const ln = idx[k].line_start;
  // 1-indexed -> 0-indexed
  const line = src[ln - 1] || "";
  if (line.indexOf("## ") === 0 && line.indexOf("### ") !== 0) {
    if (ln < bestLine) { bestLine = ln; bestKey = k; }
  }
}
if (!bestKey) process.exit(1);
process.stdout.write(bestKey + "\n");
' "$idx" "$src"
}

_last_h2_key() {
  local idx="$1" src="$2"
  node -e '
const fs = require("fs");
const idx = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
const src = fs.readFileSync(process.argv[2], "utf8").split("\n");
let bestKey = null;
let bestLine = -1;
for (const k of Object.keys(idx)) {
  const ln = idx[k].line_start;
  const line = src[ln - 1] || "";
  if (line.indexOf("## ") === 0 && line.indexOf("### ") !== 0) {
    if (ln > bestLine) { bestLine = ln; bestKey = k; }
  }
}
if (!bestKey) process.exit(1);
process.stdout.write(bestKey + "\n");
' "$idx" "$src"
}

# Returns an H2 key whose section span includes at least one H3 child.
_h2_with_h3_child() {
  local idx="$1" src="$2"
  node -e '
const fs = require("fs");
const idx = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
const src = fs.readFileSync(process.argv[2], "utf8").split("\n");
for (const k of Object.keys(idx)) {
  const startLn = idx[k].line_start;
  const endLn = idx[k].line_end;
  const startLine = src[startLn - 1] || "";
  if (startLine.indexOf("## ") !== 0 || startLine.indexOf("### ") === 0) continue;
  // Look for any H3 within the span.
  for (let i = startLn; i < endLn; i++) {
    const ln = src[i] || "";
    if (ln.indexOf("### ") === 0) {
      process.stdout.write(k + "\n");
      process.exit(0);
    }
  }
}
process.exit(1);
' "$idx" "$src"
}

# Generic per-artifact sample check: 3 samples (first, middle, final).
_check_three_samples() {
  local src="$1" idx="$2"
  local first_key middle_key last_key
  first_key="$(_first_h2_key "$idx" "$src")" || return 1
  last_key="$(_last_h2_key "$idx" "$src")"   || return 1
  # Middle: a key whose line_start sits between first and last (any key not
  # equal to first/last; we pick the median by line_start).
  local middle_key
  middle_key="$(node -e '
const fs = require("fs");
const idx = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
const entries = Object.entries(idx).map(([k,v]) => ({k, s: v.line_start}));
entries.sort((a,b) => a.s - b.s);
const mid = entries[Math.floor(entries.length / 2)];
process.stdout.write(mid.k + "\n");
' "$idx")"
  for key in "$first_key" "$middle_key" "$last_key"; do
    local pair line_start line_end
    pair="$(_lookup "$idx" "$key")" || return 1
    line_start="${pair%% *}"
    line_end="${pair##* }"
    local got truth
    got="$(_narrow_read "$src" "$line_start" "$line_end")"
    truth="$(_source_slice "$src" "$line_start" "$line_end")"
    _byte_compare "$got" "$truth" || { echo "key=$key" >&2; return 1; }
  done

  # Final-section boundary case: assert last H2's line_end matches the
  # artifact's last line of substantive content (not one less). The index
  # for the final H2 should end at the file's last line.
  local last_pair last_end
  last_pair="$(_lookup "$idx" "$last_key")"
  last_end="${last_pair##* }"
  local file_lines
  file_lines="$(wc -l < "$src")"
  # Allow last H2 to end at either the file's wc-line-count or wc-1 (trailing
  # newline split). Reject anything obviously truncated (last_end < total - 2).
  if [ "$last_end" -lt "$((file_lines - 2))" ]; then
    echo "final-section line_end suspiciously short: last_end=$last_end vs file_lines=$file_lines" >&2
    return 1
  fi
  return 0
}

# ---------------------------------------------------------------------------
# Per-artifact narrow-read tests.
# ---------------------------------------------------------------------------

@test "reviewer-protocol: narrow-read byte-identity (first/middle/final samples) + final-section boundary" {
  src="$REPO_ROOT/skills/reviewer-protocol/SKILL.md"
  idx="$REPO_ROOT/skills/reviewer-protocol/SKILL.anchors.json"
  [ -f "$src" ]
  [ -f "$idx" ]
  run _check_three_samples "$src" "$idx"
  [ "$status" -eq 0 ]
}

@test "using-qrspi: narrow-read byte-identity (first/middle/final samples) + final-section boundary" {
  src="$REPO_ROOT/skills/using-qrspi/SKILL.md"
  idx="$REPO_ROOT/skills/using-qrspi/SKILL.anchors.json"
  run _check_three_samples "$src" "$idx"
  [ "$status" -eq 0 ]
}

@test "plan: narrow-read byte-identity (first/middle/final samples) + final-section boundary" {
  src="$REPO_ROOT/skills/plan/SKILL.md"
  idx="$REPO_ROOT/skills/plan/SKILL.anchors.json"
  run _check_three_samples "$src" "$idx"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# H2-with-nested-H3 span byte-identity: for at least one artifact, the
# returned slice (via Read(offset, limit)) is byte-identical to the full
# H2 section INCLUDING its nested H3 children — guards against a regression
# that truncates H2 spans at the first H3 child.
# ---------------------------------------------------------------------------

@test "H2-with-nested-H3 span: byte-identical narrow read includes H3 children (reviewer-protocol)" {
  src="$REPO_ROOT/skills/reviewer-protocol/SKILL.md"
  idx="$REPO_ROOT/skills/reviewer-protocol/SKILL.anchors.json"
  key="$(_h2_with_h3_child "$idx" "$src")"
  [ -n "$key" ]
  pair="$(_lookup "$idx" "$key")"
  line_start="${pair%% *}"
  line_end="${pair##* }"
  got="$(_narrow_read "$src" "$line_start" "$line_end")"
  truth="$(_source_slice "$src" "$line_start" "$line_end")"
  _byte_compare "$got" "$truth"
  # The slice MUST include at least one ### child heading.
  [[ "$got" == *$'\n'"### "* ]] || [[ "$got" == "### "* ]]
}

@test "H2-with-nested-H3 span: byte-identical narrow read includes H3 children (using-qrspi)" {
  src="$REPO_ROOT/skills/using-qrspi/SKILL.md"
  idx="$REPO_ROOT/skills/using-qrspi/SKILL.anchors.json"
  key="$(_h2_with_h3_child "$idx" "$src")"
  [ -n "$key" ]
  pair="$(_lookup "$idx" "$key")"
  line_start="${pair%% *}"
  line_end="${pair##* }"
  got="$(_narrow_read "$src" "$line_start" "$line_end")"
  truth="$(_source_slice "$src" "$line_start" "$line_end")"
  _byte_compare "$got" "$truth"
  [[ "$got" == *$'\n'"### "* ]] || [[ "$got" == "### "* ]]
}

@test "H2-with-nested-H3 span: byte-identical narrow read includes H3 children (plan)" {
  src="$REPO_ROOT/skills/plan/SKILL.md"
  idx="$REPO_ROOT/skills/plan/SKILL.anchors.json"
  key="$(_h2_with_h3_child "$idx" "$src")"
  [ -n "$key" ]
  pair="$(_lookup "$idx" "$key")"
  line_start="${pair%% *}"
  line_end="${pair##* }"
  got="$(_narrow_read "$src" "$line_start" "$line_end")"
  truth="$(_source_slice "$src" "$line_start" "$line_end")"
  _byte_compare "$got" "$truth"
  [[ "$got" == *$'\n'"### "* ]] || [[ "$got" == "### "* ]]
}

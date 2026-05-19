#!/usr/bin/env bash
# g4-section-anchor-refresh.sh — G4 Mechanism B section-anchor index refresh.
#
# Reads scripts/g4-section-anchor-manifest.json, walks every (source, index)
# pair, regenerates the <source>.anchors.json file from the source artifact's
# current H2 and H3 heading layout, and writes the regenerated JSON to the
# colocated index path.
#
# The output JSON is a single object keyed by heading text whose values are
# { "line_start": <int>, "line_end": <int> } objects, where line_end is the
# line immediately before the next same-or-higher-level heading (or the last
# line of the source for the final section).
#
# Idempotent: a second invocation against an in-sync source corpus produces
# byte-identical index files. Fail-loud on duplicate H2/H3 heading text within
# a single source artifact (duplicates make narrow-read targeting ambiguous).
#
# Usage:
#   scripts/g4-section-anchor-refresh.sh
#
# Exit codes:
#   0   all indexes regenerated successfully
#   1   missing manifest, malformed manifest, missing source, duplicate
#       heading text, or write failure
#
# Bash 3.2-compatible (macOS system /bin/bash).

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"

MANIFEST_PATH="$REPO_ROOT/scripts/g4-section-anchor-manifest.json"

if [ ! -f "$MANIFEST_PATH" ]; then
  echo "g4-section-anchor-refresh: missing-manifest: $MANIFEST_PATH does not exist" >&2
  exit 1
fi

# Validate manifest JSON shape; surface parse errors with the manifest path.
if ! node -e '
const fs = require("fs");
const path = process.argv[1];
let raw;
try { raw = fs.readFileSync(path, "utf8"); }
catch (e) { process.stderr.write("manifest-read-error: " + e.message + "\n"); process.exit(1); }
let parsed;
try { parsed = JSON.parse(raw); }
catch (e) { process.stderr.write("manifest-parse-error: " + e.message + "\n"); process.exit(1); }
if (!parsed || !Array.isArray(parsed.entries)) {
  process.stderr.write("manifest-shape-error: top-level entries[] missing or not an array\n");
  process.exit(1);
}
for (const entry of parsed.entries) {
  if (!entry || typeof entry.source !== "string" || typeof entry.index !== "string") {
    process.stderr.write("manifest-shape-error: entry missing source/index string fields\n");
    process.exit(1);
  }
}
' "$MANIFEST_PATH" 2>/tmp/g4-anchor-manifest-err.$$; then
  err_msg="$(cat /tmp/g4-anchor-manifest-err.$$ 2>/dev/null)"
  rm -f /tmp/g4-anchor-manifest-err.$$
  echo "g4-section-anchor-refresh: manifest $MANIFEST_PATH is malformed: $err_msg" >&2
  exit 1
fi
rm -f /tmp/g4-anchor-manifest-err.$$

# Extract (source, index) pairs from the manifest in a parse-safe way.
PAIRS_TSV="$(node -e '
const fs = require("fs");
const parsed = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
for (const e of parsed.entries) {
  process.stdout.write(e.source + "\t" + e.index + "\n");
}
' "$MANIFEST_PATH")"

OVERALL_RC=0

# Iterate every (source, index) pair from the manifest.
while IFS=$'\t' read -r SRC IDX; do
  [ -z "$SRC" ] && continue
  SRC_ABS="$REPO_ROOT/$SRC"
  IDX_ABS="$REPO_ROOT/$IDX"

  if [ ! -f "$SRC_ABS" ]; then
    echo "g4-section-anchor-refresh: missing-source: manifest entry references $SRC but no file exists at $SRC_ABS" >&2
    OVERALL_RC=1
    continue
  fi

  # Regenerate the index JSON. The node block walks the source line-by-line,
  # records every H2 and H3 heading's start line, then computes each section's
  # end line as the line immediately before the next same-or-higher-level
  # heading (or the source's last line for the final section). Fails non-zero
  # on duplicate heading text within a single source.
  if ! node -e '
const fs = require("fs");
const src = process.argv[1];
const idxPath = process.argv[2];
const lines = fs.readFileSync(src, "utf8").split("\n");
// fs.readFileSync split("\n") yields one extra empty element when the file
// ends in a newline; treat the file as having lines.length lines for the
// terminal-section line_end calculation when the final line is empty due to
// trailing-newline split artifact.
const totalLines = lines[lines.length - 1] === "" ? lines.length - 1 : lines.length;

const headings = []; // {text, level, lineStart}
for (let i = 0; i < lines.length; i++) {
  const line = lines[i];
  const m2 = /^##\s+(.+)$/.exec(line);
  const m3 = /^###\s+(.+)$/.exec(line);
  if (m3) {
    headings.push({ text: m3[1].trim(), level: 3, lineStart: i + 1 });
  } else if (m2) {
    headings.push({ text: m2[1].trim(), level: 2, lineStart: i + 1 });
  }
}

// Duplicate detection: same heading text appearing more than once at the
// H2 or H3 level. Emit a diagnostic naming the artifact, the duplicate text,
// and every colliding line number, then exit non-zero.
const seen = new Map();
const dups = new Map();
for (const h of headings) {
  if (!seen.has(h.text)) {
    seen.set(h.text, [h.lineStart]);
  } else {
    seen.get(h.text).push(h.lineStart);
    if (!dups.has(h.text)) dups.set(h.text, seen.get(h.text));
  }
}
if (dups.size > 0) {
  for (const [text, locs] of dups) {
    process.stderr.write("duplicate-heading: in " + src + ": heading text " + JSON.stringify(text) + " appears at lines " + locs.join(", ") + "\n");
  }
  process.exit(1);
}

// Compute each heading section'"'"'s line_end as the line immediately before
// the next same-or-higher-level heading, OR totalLines for the final section.
const result = {};
for (let i = 0; i < headings.length; i++) {
  const h = headings[i];
  let lineEnd = totalLines;
  for (let j = i + 1; j < headings.length; j++) {
    if (headings[j].level <= h.level) {
      lineEnd = headings[j].lineStart - 1;
      break;
    }
  }
  result[h.text] = { line_start: h.lineStart, line_end: lineEnd };
}

// Sort keys by line_start for stable byte-identical output across runs.
const sortedKeys = Object.keys(result).sort((a, b) => result[a].line_start - result[b].line_start);
const ordered = {};
for (const k of sortedKeys) ordered[k] = result[k];

// Write atomically: stage to .tmp then rename. JSON.stringify with 2-space
// indent + trailing newline is the canonical serialization shape; idempotent
// re-runs against an in-sync source produce byte-identical files.
const tmpPath = idxPath + ".tmp." + process.pid;
fs.writeFileSync(tmpPath, JSON.stringify(ordered, null, 2) + "\n");
fs.renameSync(tmpPath, idxPath);
' "$SRC_ABS" "$IDX_ABS"; then
    echo "g4-section-anchor-refresh: regeneration failed for source $SRC" >&2
    OVERALL_RC=1
    continue
  fi

done <<MANIFEST_EOF
$PAIRS_TSV
MANIFEST_EOF

exit "$OVERALL_RC"

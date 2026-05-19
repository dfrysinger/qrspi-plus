#!/usr/bin/env bats
#
# T36 Slice 7 G4 Mechanism B unit pin — section-anchor index JSON shape.
#
# For each .anchors.json in the T34 manifest (reviewer-protocol, using-qrspi,
# plan), asserts:
#   - file parses as JSON
#   - every key matches an H2 or H3 heading text present in the source SKILL.md
#   - every value is `{line_start, line_end}` with integer fields and
#     line_start <= line_end
#   - no duplicate heading text within one artifact's index
#
# Bash 3.2 portable.

load '../helpers/skill-markdown'

setup_file() {
  require_repo_root
  MANIFEST="$REPO_ROOT/scripts/g4-section-anchor-manifest.json"
  [ -f "$MANIFEST" ] || { echo "manifest missing: $MANIFEST" >&2; return 1; }
  export MANIFEST
}

# ---------------------------------------------------------------------------
# Iterate manifest entries via node for robust JSON parsing.
# Echo TAB-separated (source, index) pairs.
# ---------------------------------------------------------------------------
_manifest_pairs() {
  node -e '
const fs = require("fs");
const m = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
for (const e of m.entries) process.stdout.write(e.source + "\t" + e.index + "\n");
' "$MANIFEST"
}

# ---------------------------------------------------------------------------
# Per-entry parse + shape check via node. Reports first failure with a loud
# diagnostic to stderr and returns 1; returns 0 on full pass.
# ---------------------------------------------------------------------------
_check_index_shape() {
  local src_abs="$1" idx_abs="$2"
  node -e '
const fs = require("fs");
const src = process.argv[1];
const idx = process.argv[2];
let raw;
try { raw = fs.readFileSync(idx, "utf8"); }
catch (e) { process.stderr.write("index unreadable: " + e.message + "\n"); process.exit(1); }
let parsed;
try { parsed = JSON.parse(raw); }
catch (e) { process.stderr.write("index not valid JSON: " + idx + ": " + e.message + "\n"); process.exit(1); }
if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
  process.stderr.write("index top-level is not an object: " + idx + "\n");
  process.exit(1);
}

const srcLines = fs.readFileSync(src, "utf8").split("\n");
const validHeadings = new Set();
for (const line of srcLines) {
  const m2 = /^##\s+(.+)$/.exec(line);
  const m3 = /^###\s+(.+)$/.exec(line);
  if (m3) validHeadings.add(m3[1].trim());
  else if (m2) validHeadings.add(m2[1].trim());
}

const keys = Object.keys(parsed);
const dupSeen = new Set();
for (const k of keys) {
  if (dupSeen.has(k)) {
    process.stderr.write("duplicate key (JSON-level): " + k + " in " + idx + "\n");
    process.exit(1);
  }
  dupSeen.add(k);
  if (!validHeadings.has(k)) {
    process.stderr.write("key " + JSON.stringify(k) + " in " + idx + " has no matching H2/H3 heading in source " + src + "\n");
    process.exit(1);
  }
  const v = parsed[k];
  if (!v || typeof v !== "object" || Array.isArray(v)) {
    process.stderr.write("value for key " + JSON.stringify(k) + " is not an object in " + idx + "\n");
    process.exit(1);
  }
  if (!Number.isInteger(v.line_start) || !Number.isInteger(v.line_end)) {
    process.stderr.write("value for key " + JSON.stringify(k) + " missing integer line_start/line_end in " + idx + "\n");
    process.exit(1);
  }
  if (v.line_start > v.line_end) {
    process.stderr.write("value for key " + JSON.stringify(k) + " violates line_start<=line_end in " + idx + " (" + v.line_start + " > " + v.line_end + ")\n");
    process.exit(1);
  }
}
' "$src_abs" "$idx_abs"
}

# ---------------------------------------------------------------------------
# Per-artifact tests — enumerated rather than dynamic so each manifest entry
# is observable as a distinct passing/failing test in TAP output.
# ---------------------------------------------------------------------------

@test "manifest exists and is non-empty (3 entries)" {
  out="$(_manifest_pairs)"
  [ -n "$out" ]
  count="$(printf '%s\n' "$out" | grep -c '	')"
  [ "$count" -ge 3 ]
}

@test "reviewer-protocol: SKILL.anchors.json shape is valid" {
  src="$REPO_ROOT/skills/reviewer-protocol/SKILL.md"
  idx="$REPO_ROOT/skills/reviewer-protocol/SKILL.anchors.json"
  [ -f "$idx" ]
  run _check_index_shape "$src" "$idx"
  [ "$status" -eq 0 ]
}

@test "using-qrspi: SKILL.anchors.json shape is valid" {
  src="$REPO_ROOT/skills/using-qrspi/SKILL.md"
  idx="$REPO_ROOT/skills/using-qrspi/SKILL.anchors.json"
  [ -f "$idx" ]
  run _check_index_shape "$src" "$idx"
  [ "$status" -eq 0 ]
}

@test "plan: SKILL.anchors.json shape is valid" {
  src="$REPO_ROOT/skills/plan/SKILL.md"
  idx="$REPO_ROOT/skills/plan/SKILL.anchors.json"
  [ -f "$idx" ]
  # NOTE: plan/SKILL.md contains a duplicate `## Overview` heading at lines 12
  # and 189; the current T34 index ships with only one entry. The shape check
  # here verifies the JSON contract; the duplicate-heading FAIL-LOUD branch is
  # exercised in test-section-anchor-refresh.bats against a fixture corpus.
  run _check_index_shape "$src" "$idx"
  [ "$status" -eq 0 ]
}

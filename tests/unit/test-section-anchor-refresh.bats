#!/usr/bin/env bats
#
# T36 Slice 7 G4 Mechanism B unit pin — anchor-refresh script contract.
#
# Against a fixture corpus where:
#   - one source has a new heading added
#   - one source has a heading removed
#   - one source has a heading renamed
# runs scripts/g4-section-anchor-refresh.sh and asserts each regenerated
# index reflects the corresponding change (new key present, removed key
# absent, renamed key replacing the prior key with the same {line_start,
# line_end} shape).
#
# Against a fixture source containing two H2 headings with identical text,
# asserts the script exits non-zero, emits a diagnostic naming the
# duplicate heading text and the colliding line numbers on stderr, and
# does not write a partial index file.
#
# Bash 3.2 portable.

load '../helpers/skill-markdown'

setup_file() {
  require_repo_root
  REFRESH_SCRIPT="$REPO_ROOT/scripts/g4-section-anchor-refresh.sh"
  [ -f "$REFRESH_SCRIPT" ] || { echo "refresh script missing" >&2; return 1; }
  export REFRESH_SCRIPT
}

setup() {
  FIXTURE_DIR="$(mktemp -d)"
  export FIXTURE_DIR
  # Build an isolated mini-repo so the script's REPO_ROOT resolution (cd .. from
  # scripts/) lands here. Copy the refresh script + a custom manifest in.
  mkdir -p "$FIXTURE_DIR/scripts" "$FIXTURE_DIR/srcs"
  cp "$REFRESH_SCRIPT" "$FIXTURE_DIR/scripts/g4-section-anchor-refresh.sh"
  chmod +x "$FIXTURE_DIR/scripts/g4-section-anchor-refresh.sh"
}

teardown() {
  rm -rf "$FIXTURE_DIR"
}

# ---------------------------------------------------------------------------
# _write_manifest <entries-as-tsv>
# Builds scripts/g4-section-anchor-manifest.json with the given (source,index)
# pairs supplied as tab-separated lines.
# ---------------------------------------------------------------------------
_write_manifest() {
  local pairs_tsv="$1"
  node -e '
const fs = require("fs");
const out = process.argv[1];
const pairs = process.argv[2].split("\n").filter(l => l.length).map(line => {
  const [s, i] = line.split("\t");
  return { source: s, index: i };
});
fs.writeFileSync(out, JSON.stringify({ version: 1, entries: pairs }, null, 2) + "\n");
' "$FIXTURE_DIR/scripts/g4-section-anchor-manifest.json" "$pairs_tsv"
}

# ---------------------------------------------------------------------------
# Test 1: add / remove / rename observable in regenerated indexes.
# ---------------------------------------------------------------------------

@test "refresh: added heading appears as new key in regenerated index" {
  cat > "$FIXTURE_DIR/srcs/add.md" <<'EOF'
# Title
## Alpha
alpha body
## Newly-Added
new body
EOF
  _write_manifest "$(printf 'srcs/add.md\tsrcs/add.anchors.json\n')"

  run bash "$FIXTURE_DIR/scripts/g4-section-anchor-refresh.sh"
  [ "$status" -eq 0 ]
  [ -f "$FIXTURE_DIR/srcs/add.anchors.json" ]
  run grep -F '"Newly-Added"' "$FIXTURE_DIR/srcs/add.anchors.json"
  [ "$status" -eq 0 ]
  run grep -F '"Alpha"' "$FIXTURE_DIR/srcs/add.anchors.json"
  [ "$status" -eq 0 ]
}

@test "refresh: removed heading is absent from regenerated index" {
  # Source has only Alpha; the pre-existing index (with both Alpha and Old)
  # is overwritten so Old disappears.
  cat > "$FIXTURE_DIR/srcs/rm.md" <<'EOF'
# Title
## Alpha
alpha body
EOF
  cat > "$FIXTURE_DIR/srcs/rm.anchors.json" <<'EOF'
{
  "Alpha":  { "line_start": 2, "line_end": 3 },
  "Removed": { "line_start": 4, "line_end": 5 }
}
EOF
  _write_manifest "$(printf 'srcs/rm.md\tsrcs/rm.anchors.json\n')"

  run bash "$FIXTURE_DIR/scripts/g4-section-anchor-refresh.sh"
  [ "$status" -eq 0 ]
  run grep -F '"Removed"' "$FIXTURE_DIR/srcs/rm.anchors.json"
  [ "$status" -ne 0 ]
  run grep -F '"Alpha"' "$FIXTURE_DIR/srcs/rm.anchors.json"
  [ "$status" -eq 0 ]
}

@test "refresh: renamed heading replaces prior key with same {line_start,line_end} shape" {
  cat > "$FIXTURE_DIR/srcs/rn.md" <<'EOF'
# Title
## Renamed-Heading
renamed body line
EOF
  cat > "$FIXTURE_DIR/srcs/rn.anchors.json" <<'EOF'
{
  "Old-Name": { "line_start": 2, "line_end": 3 }
}
EOF
  _write_manifest "$(printf 'srcs/rn.md\tsrcs/rn.anchors.json\n')"

  run bash "$FIXTURE_DIR/scripts/g4-section-anchor-refresh.sh"
  [ "$status" -eq 0 ]
  # Renamed key present
  run grep -F '"Renamed-Heading"' "$FIXTURE_DIR/srcs/rn.anchors.json"
  [ "$status" -eq 0 ]
  # Old key absent
  run grep -F '"Old-Name"' "$FIXTURE_DIR/srcs/rn.anchors.json"
  [ "$status" -ne 0 ]
  # Shape preserved: integer line_start + line_end fields.
  node -e '
const fs = require("fs");
const j = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
const v = j["Renamed-Heading"];
if (!Number.isInteger(v.line_start) || !Number.isInteger(v.line_end)) process.exit(1);
if (v.line_start > v.line_end) process.exit(1);
' "$FIXTURE_DIR/srcs/rn.anchors.json"
}

# ---------------------------------------------------------------------------
# Test 2: duplicate-heading fail-loud branch.
# ---------------------------------------------------------------------------

@test "refresh: duplicate H2 heading text causes non-zero exit + loud diagnostic + no partial index" {
  cat > "$FIXTURE_DIR/srcs/dup.md" <<'EOF'
# Title
## SameName
body 1
## SameName
body 2
EOF
  _write_manifest "$(printf 'srcs/dup.md\tsrcs/dup.anchors.json\n')"

  run bash "$FIXTURE_DIR/scripts/g4-section-anchor-refresh.sh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"duplicate-heading"* ]]
  [[ "$output" == *"SameName"* ]]
  # The colliding line numbers (2, 4) must appear in the diagnostic.
  [[ "$output" == *"2"* ]] && [[ "$output" == *"4"* ]]
  # No partial index file was written.
  [ ! -f "$FIXTURE_DIR/srcs/dup.anchors.json" ]
}

# ---------------------------------------------------------------------------
# Test 3: documented script-level contract — duplicate fail-loud is a stated
# invariant of the refresh script's source.
# ---------------------------------------------------------------------------

@test "refresh: script source documents fail-loud-on-duplicate contract" {
  run grep -F "Fail-loud on duplicate" "$REFRESH_SCRIPT"
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Test 4: pre-existing duplicate-Overview bug in plan/SKILL.md (documented
# in the T36 spec). The real source has `## Overview` on lines 12 and 189,
# which means the refresh script's fail-loud branch fires against the real
# corpus. We assert the SOURCE has the duplicate (proof the bug exists)
# rather than running the destructive refresh (which would overwrite the
# other two valid indexes mid-run as a side effect on the same invocation).
# ---------------------------------------------------------------------------

@test "refresh: real-corpus plan/SKILL.md duplicate-overview bug present (documented; not fixed in T36)" {
  src="$REPO_ROOT/skills/plan/SKILL.md"
  matches="$(grep -c '^## Overview$' "$src")"
  [ "$matches" -ge 2 ]
}

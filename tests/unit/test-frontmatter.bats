#!/usr/bin/env bats

setup() {
  TEST_DIR="$(mktemp -d)"
  export TEST_DIR
  source "$BATS_TEST_DIRNAME/../../hooks/lib/frontmatter.sh"
}

teardown() {
  rm -rf "$TEST_DIR"
}

# =============================================================================
# frontmatter_get — scalar field extraction
# =============================================================================

@test "frontmatter_get: status: approved returns 'approved'" {
  cat > "$TEST_DIR/file.md" <<'FIXTURE'
---
status: approved
---
FIXTURE
  run frontmatter_get "$TEST_DIR/file.md" "status"
  [ "$status" -eq 0 ]
  [ "$output" = "approved" ]
}

@test "frontmatter_get: status: draft returns 'draft'" {
  cat > "$TEST_DIR/file.md" <<'FIXTURE'
---
status: draft
---
FIXTURE
  run frontmatter_get "$TEST_DIR/file.md" "status"
  [ "$status" -eq 0 ]
  [ "$output" = "draft" ]
}

@test "frontmatter_get: trims whitespace from scalar value" {
  cat > "$TEST_DIR/file.md" <<'FIXTURE'
---
status:  approved
---
FIXTURE
  run frontmatter_get "$TEST_DIR/file.md" "status"
  [ "$status" -eq 0 ]
  [ "$output" = "approved" ]
}

@test "frontmatter_get: preserves case of scalar value" {
  cat > "$TEST_DIR/file.md" <<'FIXTURE'
---
status: Approved
---
FIXTURE
  run frontmatter_get "$TEST_DIR/file.md" "status"
  [ "$status" -eq 0 ]
  [ "$output" = "Approved" ]
}

@test "frontmatter_get: finds status after 5+ other fields (no line-depth limit)" {
  run frontmatter_get "$BATS_TEST_DIRNAME/../fixtures/status-after-line5.md" "status"
  [ "$status" -eq 0 ]
  [ "$output" = "approved" ]
}

@test "frontmatter_get: nonexistent field returns exit 0 with empty stdout" {
  cat > "$TEST_DIR/file.md" <<'FIXTURE'
---
status: approved
---
FIXTURE
  run frontmatter_get "$TEST_DIR/file.md" "nonexistent"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# =============================================================================
# frontmatter_get — JSON object return (no field name)
# =============================================================================

@test "frontmatter_get: no field name returns JSON object with all scalars" {
  cat > "$TEST_DIR/file.md" <<'FIXTURE'
---
status: approved
task: 3
---
FIXTURE
  run frontmatter_get "$TEST_DIR/file.md"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.status == "approved"'
  echo "$output" | jq -e '.task == "3"'
}

@test "frontmatter_get: no field name with simple list returns JSON with array" {
  cat > "$TEST_DIR/file.md" <<'FIXTURE'
---
constraints:
- Add hook
- Register in hooks.json
---
FIXTURE
  run frontmatter_get "$TEST_DIR/file.md"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.constraints == ["Add hook", "Register in hooks.json"]'
}

@test "frontmatter_get: no field name with nested list returns JSON with array of objects" {
  cat > "$TEST_DIR/file.md" <<'FIXTURE'
---
allowed_files:
- action: create
  path: src/foo.sh
- action: modify
  path: src/bar.sh
---
FIXTURE
  run frontmatter_get "$TEST_DIR/file.md"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.allowed_files[0].action == "create"'
  echo "$output" | jq -e '.allowed_files[0].path == "src/foo.sh"'
  echo "$output" | jq -e '.allowed_files[1].action == "modify"'
  echo "$output" | jq -e '.allowed_files[1].path == "src/bar.sh"'
}

@test "frontmatter_get: no field name with all three field types" {
  cat > "$TEST_DIR/file.md" <<'FIXTURE'
---
status: approved
constraints:
- Add hook
- Register in hooks.json
allowed_files:
- action: create
  path: src/foo.sh
---
FIXTURE
  run frontmatter_get "$TEST_DIR/file.md"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.status == "approved"'
  echo "$output" | jq -e '.constraints == ["Add hook", "Register in hooks.json"]'
  echo "$output" | jq -e '.allowed_files[0].action == "create"'
}

@test "frontmatter_get: no field name with status beyond line 5" {
  run frontmatter_get "$BATS_TEST_DIRNAME/../fixtures/status-after-line5.md"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.status == "approved"'
}

@test "frontmatter_get: wireframe_requested: true is string not boolean" {
  cat > "$TEST_DIR/file.md" <<'FIXTURE'
---
wireframe_requested: true
---
FIXTURE
  run frontmatter_get "$TEST_DIR/file.md"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.wireframe_requested == "true"'
}

@test "frontmatter_get: field name on simple list returns JSON array" {
  cat > "$TEST_DIR/file.md" <<'FIXTURE'
---
constraints:
- Add hook
- Register in hooks.json
---
FIXTURE
  run frontmatter_get "$TEST_DIR/file.md" "constraints"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '. == ["Add hook", "Register in hooks.json"]'
}

@test "frontmatter_get: field name on nested list returns JSON array of objects" {
  cat > "$TEST_DIR/file.md" <<'FIXTURE'
---
allowed_files:
- action: create
  path: src/foo.sh
---
FIXTURE
  run frontmatter_get "$TEST_DIR/file.md" "allowed_files"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.[0].action == "create"'
  echo "$output" | jq -e '.[0].path == "src/foo.sh"'
}

# =============================================================================
# frontmatter_get — error cases
# =============================================================================

@test "frontmatter_get: file does not exist returns exit 1 with no stdout" {
  run frontmatter_get "$TEST_DIR/nonexistent.md"
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}

@test "frontmatter_get: empty file returns exit 2 with no stdout" {
  touch "$TEST_DIR/empty.md"
  run frontmatter_get "$TEST_DIR/empty.md"
  [ "$status" -eq 2 ]
  [ -z "$output" ]
}

@test "frontmatter_get: no leading --- returns exit 2 with no stdout" {
  cat > "$TEST_DIR/file.md" <<'FIXTURE'
# Title
Some content
FIXTURE
  run frontmatter_get "$TEST_DIR/file.md"
  [ "$status" -eq 2 ]
  [ -z "$output" ]
}

@test "frontmatter_get: opening --- but no closing --- returns exit 2 with no stdout" {
  cat > "$TEST_DIR/file.md" <<'FIXTURE'
---
status: approved
some content without closing delimiter
FIXTURE
  run frontmatter_get "$TEST_DIR/file.md"
  [ "$status" -eq 2 ]
  [ -z "$output" ]
}

@test "frontmatter_get: empty frontmatter (---/---) returns exit 0, {} for no field, empty for named" {
  cat > "$TEST_DIR/file.md" <<'FIXTURE'
---
---
FIXTURE
  run frontmatter_get "$TEST_DIR/file.md"
  [ "$status" -eq 0 ]
  [ "$output" = "{}" ]

  run frontmatter_get "$TEST_DIR/file.md" "status"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# =============================================================================
# frontmatter_get_status — compatibility wrapper
# =============================================================================

@test "frontmatter_get_status: status: approved returns 'approved'" {
  cat > "$TEST_DIR/file1.md" <<'FIXTURE'
---
status: approved
---
FIXTURE
  run frontmatter_get_status "$TEST_DIR/file1.md"
  [ "$status" -eq 0 ]
  [ "$output" = "approved" ]
}

@test "frontmatter_get_status: status: draft returns 'draft'" {
  cat > "$TEST_DIR/file2.md" <<'FIXTURE'
---
status: draft
---
FIXTURE
  run frontmatter_get_status "$TEST_DIR/file2.md"
  [ "$status" -eq 0 ]
  [ "$output" = "draft" ]
}

@test "frontmatter_get_status: no frontmatter (no leading ---) returns 1 with no stdout" {
  cat > "$TEST_DIR/file3.md" <<'FIXTURE'
# Title
Some content
FIXTURE
  run frontmatter_get_status "$TEST_DIR/file3.md"
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}

@test "frontmatter_get_status: file does not exist returns 1 with no stdout" {
  run frontmatter_get_status "$TEST_DIR/nonexistent.md"
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}

@test "frontmatter_get_status: empty file returns 1 with no stdout" {
  touch "$TEST_DIR/empty.md"
  run frontmatter_get_status "$TEST_DIR/empty.md"
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}

@test "frontmatter_get_status: malformed frontmatter (opening --- but no closing ---) returns 1" {
  cat > "$TEST_DIR/malformed.md" <<'FIXTURE'
---
status: approved
some content without closing delimiter
FIXTURE
  run frontmatter_get_status "$TEST_DIR/malformed.md"
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}

@test "frontmatter_get_status: frontmatter but no status: field returns 1" {
  cat > "$TEST_DIR/no_status.md" <<'FIXTURE'
---
title: My Title
author: John
---
FIXTURE
  run frontmatter_get_status "$TEST_DIR/no_status.md"
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}

@test "frontmatter_get_status: status field after line 5 now succeeds (no line-depth limit)" {
  cat > "$TEST_DIR/status_late.md" <<'FIXTURE'
---
title: Title
author: Author
description: Some long description
other_field: value
status: approved
---
FIXTURE
  run frontmatter_get_status "$TEST_DIR/status_late.md"
  [ "$status" -eq 0 ]
  [ "$output" = "approved" ]
}

@test "frontmatter_get_status: extra whitespace 'status:  approved ' outputs trimmed 'approved'" {
  cat > "$TEST_DIR/whitespace.md" <<'FIXTURE'
---
status:  approved
---
FIXTURE
  run frontmatter_get_status "$TEST_DIR/whitespace.md"
  [ "$status" -eq 0 ]
  [ "$output" = "approved" ]
}

@test "frontmatter_get_status: mixed case 'status: Approved' outputs 'Approved' as-is" {
  cat > "$TEST_DIR/mixedcase.md" <<'FIXTURE'
---
status: Approved
---
FIXTURE
  run frontmatter_get_status "$TEST_DIR/mixedcase.md"
  [ "$status" -eq 0 ]
  [ "$output" = "Approved" ]
}

@test "frontmatter.sh starts with #!/usr/bin/env bash" {
  head -1 "$BATS_TEST_DIRNAME/../../hooks/lib/frontmatter.sh" | grep -q '^#!/usr/bin/env bash'
}

@test "frontmatter.sh has 'set -euo pipefail' as early line" {
  head -2 "$BATS_TEST_DIRNAME/../../hooks/lib/frontmatter.sh" | tail -1 | grep -q '^set -euo pipefail'
}

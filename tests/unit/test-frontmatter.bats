#!/usr/bin/env bats

setup() {
  TEST_DIR="$(mktemp -d)"
  export TEST_DIR
}

teardown() {
  rm -rf "$TEST_DIR"
}

@test "frontmatter_get_status: status: approved returns 'approved'" {
  cat > "$TEST_DIR/file1.md" <<'EOF'
---
status: approved
---
EOF
  source "$BATS_TEST_DIRNAME/../../hooks/lib/frontmatter.sh"
  run frontmatter_get_status "$TEST_DIR/file1.md"
  [ "$status" -eq 0 ]
  [ "$output" = "approved" ]
}

@test "frontmatter_get_status: status: draft returns 'draft'" {
  cat > "$TEST_DIR/file2.md" <<'EOF'
---
status: draft
---
EOF
  source "$BATS_TEST_DIRNAME/../../hooks/lib/frontmatter.sh"
  run frontmatter_get_status "$TEST_DIR/file2.md"
  [ "$status" -eq 0 ]
  [ "$output" = "draft" ]
}

@test "frontmatter_get_status: no frontmatter (no leading ---) returns 1 with no stdout" {
  cat > "$TEST_DIR/file3.md" <<'EOF'
# Title
Some content
EOF
  source "$BATS_TEST_DIRNAME/../../hooks/lib/frontmatter.sh"
  run frontmatter_get_status "$TEST_DIR/file3.md"
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}

@test "frontmatter_get_status: file does not exist returns 1 with no stdout" {
  source "$BATS_TEST_DIRNAME/../../hooks/lib/frontmatter.sh"
  run frontmatter_get_status "$TEST_DIR/nonexistent.md"
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}

@test "frontmatter_get_status: empty file returns 1 with no stdout" {
  touch "$TEST_DIR/empty.md"
  source "$BATS_TEST_DIRNAME/../../hooks/lib/frontmatter.sh"
  run frontmatter_get_status "$TEST_DIR/empty.md"
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}

@test "frontmatter_get_status: malformed frontmatter (opening --- but no closing ---) returns 1" {
  cat > "$TEST_DIR/malformed.md" <<'EOF'
---
status: approved
some content without closing delimiter
EOF
  source "$BATS_TEST_DIRNAME/../../hooks/lib/frontmatter.sh"
  run frontmatter_get_status "$TEST_DIR/malformed.md"
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}

@test "frontmatter_get_status: frontmatter but no status: field returns 1" {
  cat > "$TEST_DIR/no_status.md" <<'EOF'
---
title: My Title
author: John
---
EOF
  source "$BATS_TEST_DIRNAME/../../hooks/lib/frontmatter.sh"
  run frontmatter_get_status "$TEST_DIR/no_status.md"
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}

@test "frontmatter_get_status: status: field after line 5 returns 1 (only reads first 5 lines)" {
  cat > "$TEST_DIR/status_late.md" <<'EOF'
---
title: Title
author: Author
description: Some long description
other_field: value
status: approved
---
EOF
  source "$BATS_TEST_DIRNAME/../../hooks/lib/frontmatter.sh"
  run frontmatter_get_status "$TEST_DIR/status_late.md"
  [ "$status" -eq 1 ]
  [ -z "$output" ]
}

@test "frontmatter_get_status: extra whitespace 'status:  approved ' outputs trimmed 'approved'" {
  cat > "$TEST_DIR/whitespace.md" <<'EOF'
---
status:  approved
---
EOF
  source "$BATS_TEST_DIRNAME/../../hooks/lib/frontmatter.sh"
  run frontmatter_get_status "$TEST_DIR/whitespace.md"
  [ "$status" -eq 0 ]
  [ "$output" = "approved" ]
}

@test "frontmatter_get_status: mixed case 'status: Approved' outputs 'Approved' as-is" {
  cat > "$TEST_DIR/mixedcase.md" <<'EOF'
---
status: Approved
---
EOF
  source "$BATS_TEST_DIRNAME/../../hooks/lib/frontmatter.sh"
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

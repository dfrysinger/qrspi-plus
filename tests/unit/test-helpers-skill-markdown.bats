#!/usr/bin/env bats
#
# T13 helper-self pin for tests/helpers/skill-markdown.bash.
#
# Calling convention (load-bearing — documented here and in the helper's file
# header): extract_section, extract_and_grep, and require_repo_root are direct-
# call functions. Wrapping them in BATS `run` would swallow the non-zero return
# and bypass the loud-failure semantics. assert_section_contains is the only
# function designed for `run` semantics.

load '../helpers/skill-markdown'

setup() {
  FIXTURE_DIR="$(mktemp -d)"
  export FIXTURE_DIR
}

teardown() {
  rm -rf "$FIXTURE_DIR"
}

# =============================================================================
# Happy path: H2 section between two same-level headings (boundary excluded)
# =============================================================================

@test "extract_section: H2 happy path between two same-level headings (boundaries excluded)" {
  cat > "$FIXTURE_DIR/doc.md" <<'EOF'
# Title

## Alpha

alpha line 1
alpha line 2

## Beta

beta line 1
EOF
  out="$(extract_section "$FIXTURE_DIR/doc.md" H2 "Alpha")"
  [ "$?" -eq 0 ]
  # Boundary heading lines must NOT appear in the extract.
  [[ "$out" != *"## Alpha"* ]]
  [[ "$out" != *"## Beta"* ]]
  [[ "$out" == *"alpha line 1"* ]]
  [[ "$out" == *"alpha line 2"* ]]
  # Body of the next section must NOT appear in the extract.
  [[ "$out" != *"beta line 1"* ]]
}

# =============================================================================
# Missing-anchor: returns 1 with named stderr diagnostic
# =============================================================================

@test "extract_section: missing anchor returns 1 with skill-markdown stderr diagnostic" {
  cat > "$FIXTURE_DIR/doc.md" <<'EOF'
# Title

## Alpha
alpha body
EOF
  run extract_section "$FIXTURE_DIR/doc.md" H2 "Nonexistent"
  [ "$status" -eq 1 ]
  [[ "$output" == *"skill-markdown:"* ]]
  [[ "$output" == *"heading anchor not found"* ]]
  [[ "$output" == *"## Nonexistent"* ]]
}

# =============================================================================
# Empty-extract silent-pass guard
# =============================================================================

@test "extract_section: empty extract between adjacent same-level headings returns 1 with diagnostic" {
  cat > "$FIXTURE_DIR/doc.md" <<'EOF'
## Alpha
## Beta
beta body
EOF
  run extract_section "$FIXTURE_DIR/doc.md" H2 "Alpha"
  [ "$status" -eq 1 ]
  [[ "$output" == *"skill-markdown:"* ]]
  [[ "$output" == *"extract is empty"* ]]
  [[ "$output" == *"silent-pass guard"* ]]
}

# =============================================================================
# End-of-file boundary: section ends at EOF with no following same-level heading
# =============================================================================

@test "extract_section: section ending at EOF extracts correctly" {
  cat > "$FIXTURE_DIR/doc.md" <<'EOF'
# Title

## Final

final line 1
final line 2
EOF
  out="$(extract_section "$FIXTURE_DIR/doc.md" H2 "Final")"
  [ "$?" -eq 0 ]
  [[ "$out" == *"final line 1"* ]]
  [[ "$out" == *"final line 2"* ]]
  [[ "$out" != *"## Final"* ]]
}

# =============================================================================
# Same-level boundary detection ignores deeper headings (## Alpha contains ### child)
# =============================================================================

@test "extract_section: H3 children inside an H2 section are included, not treated as boundary" {
  cat > "$FIXTURE_DIR/doc.md" <<'EOF'
## Alpha

alpha intro

### Child

child body

## Beta
beta body
EOF
  out="$(extract_section "$FIXTURE_DIR/doc.md" H2 "Alpha")"
  [ "$?" -eq 0 ]
  [[ "$out" == *"alpha intro"* ]]
  [[ "$out" == *"### Child"* ]]
  [[ "$out" == *"child body"* ]]
  [[ "$out" != *"## Beta"* ]]
  [[ "$out" != *"beta body"* ]]
}

# =============================================================================
# assert_section_contains: BATS-shaped failure diagnostic
# =============================================================================

@test "assert_section_contains: emits file:section:regex diagnostic on miss" {
  cat > "$FIXTURE_DIR/doc.md" <<'EOF'
## Alpha
alpha body present
EOF
  run assert_section_contains "$FIXTURE_DIR/doc.md" H2 "Alpha" "absent-pattern-xyz"
  [ "$status" -eq 1 ]
  [[ "$output" == *"assert_section_contains FAILED"* ]]
  [[ "$output" == *"$FIXTURE_DIR/doc.md"* ]]
  [[ "$output" == *"Alpha"* ]]
  [[ "$output" == *"absent-pattern-xyz"* ]]
}

@test "assert_section_contains: returns 0 on regex hit" {
  cat > "$FIXTURE_DIR/doc.md" <<'EOF'
## Alpha
alpha body has present-token here
EOF
  run assert_section_contains "$FIXTURE_DIR/doc.md" H2 "Alpha" "present-token"
  [ "$status" -eq 0 ]
}

# =============================================================================
# require_repo_root: BATS_TEST_DIRNAME walk + git fallback
# =============================================================================

@test "require_repo_root: resolves REPO_ROOT from BATS_TEST_DIRNAME walk" {
  unset REPO_ROOT
  require_repo_root
  [ "$?" -eq 0 ]
  [ -n "$REPO_ROOT" ]
  [ -d "$REPO_ROOT" ]
  [ -e "$REPO_ROOT/.git" ]
}

@test "require_repo_root: fails loudly when neither resolution succeeds" {
  unset REPO_ROOT
  # Sandbox: BATS_TEST_DIRNAME points to a tmpdir with no .git, and PATH excludes git.
  local sandbox="$FIXTURE_DIR/no-git-anywhere"
  mkdir -p "$sandbox/nested"
  local saved_path="$PATH"
  local saved_bats_dirname="$BATS_TEST_DIRNAME"
  BATS_TEST_DIRNAME="$sandbox/nested"
  PATH="/usr/bin:/bin"  # remove git from PATH (assumes git isn't in /usr/bin on this runtime).
  # We additionally chdir to a directory outside any git repo so `git rev-parse` would fail.
  cd "$sandbox"
  run require_repo_root
  PATH="$saved_path"
  BATS_TEST_DIRNAME="$saved_bats_dirname"
  # When git is on PATH but cwd is not in a repo, git returns empty + non-zero, and
  # the BATS_TEST_DIRNAME walk also fails because $sandbox has no .git ancestor up
  # to /. Both strategies fail; helper must emit the loud diagnostic.
  [ "$status" -eq 1 ]
  [[ "$output" == *"skill-markdown:"* ]]
  [[ "$output" == *"require_repo_root"* ]]
  [[ "$output" == *"could not resolve REPO_ROOT"* ]]
}

# =============================================================================
# Direct-call calling convention (load-bearing)
# =============================================================================
#
# Demonstrates that a missing-anchor extract_section call WITHOUT `run` directly
# fails the @test block. The negation `!` inverts the non-zero return so the
# @test passes only when extract_section returns non-zero — observably failing
# the test block on a buggy helper that silently passed.

@test "calling convention: direct extract_section call (no run) observably fails on missing anchor" {
  cat > "$FIXTURE_DIR/doc.md" <<'EOF'
## Alpha
alpha body
EOF
  ! extract_section "$FIXTURE_DIR/doc.md" H2 "Nonexistent" 2>/dev/null
}

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

# =============================================================================
# fence-aware section extractor: extract_section_fence_aware
#
# All tests below are RED against the pre-implementation state:
# extract_section_fence_aware does not yet exist in skill-markdown.bash.
#
# Assumed signature: extract_section_fence_aware <file> <anchor-heading>
#   <anchor-heading> is the full heading line including prefix,
#   e.g. "### Review Round" or "## Artifact Gating".
#
# Covers the 10 test-expectation bullets for the fence-aware section extractor
# promoted to tests/helpers/skill-markdown.bash.
# =============================================================================

@test "[fence-aware-extractor] basic extraction: anchor line included, content up to next out-of-fence boundary" {
  # Test expectation: returns content from the anchor line (inclusive) through
  # the last line before the next out-of-fence section boundary.
  # Test expectation: the anchor line itself is included in the function output
  # (consistent with the prior extract_review_round contract).
  cat > "$FIXTURE_DIR/basic.md" <<'EOF'
# Title

### Review Round
Reviewer instruction A
Reviewer instruction B

### Next Section
Next content here
EOF
  out="$(extract_section_fence_aware "$FIXTURE_DIR/basic.md" "### Review Round")"
  [ "$?" -eq 0 ]
  [[ "$out" == *"### Review Round"* ]]
  [[ "$out" == *"Reviewer instruction A"* ]]
  [[ "$out" == *"Reviewer instruction B"* ]]
  [[ "$out" != *"### Next Section"* ]]
  [[ "$out" != *"Next content here"* ]]
}

@test "[fence-aware-extractor] H3 and H2 heading-shaped lines inside a code fence do not terminate extraction" {
  # Test expectation: a ### or ## heading line that appears inside an open
  # code fence is not treated as a section boundary and does not terminate
  # the extraction.
  cat > "$FIXTURE_DIR/fenced-headings.md" <<'EOF'
### Review Round
Preamble line
```
### Inside H3 Fence
## Inside H2 Fence
still inside fence
```
Post-fence line

### Real Boundary
Should not appear
EOF
  out="$(extract_section_fence_aware "$FIXTURE_DIR/fenced-headings.md" "### Review Round")"
  [ "$?" -eq 0 ]
  [[ "$out" == *"### Review Round"* ]]
  [[ "$out" == *"Preamble line"* ]]
  [[ "$out" == *"### Inside H3 Fence"* ]]
  [[ "$out" == *"## Inside H2 Fence"* ]]
  [[ "$out" == *"Post-fence line"* ]]
  [[ "$out" != *"### Real Boundary"* ]]
  [[ "$out" != *"Should not appear"* ]]
}

@test "[fence-aware-extractor] closing triple-backtick fence restores heading-boundary detection" {
  # Test expectation: exiting a code fence (closing triple-backtick line)
  # restores heading-boundary detection for subsequent lines in the same
  # extraction.
  cat > "$FIXTURE_DIR/fence-restore.md" <<'EOF'
### Target Section
Before the fence
```
### Shielded Heading
inside fence body
```
After the fence - should be included

### Terminating Heading
Content after terminator
EOF
  out="$(extract_section_fence_aware "$FIXTURE_DIR/fence-restore.md" "### Target Section")"
  [ "$?" -eq 0 ]
  [[ "$out" == *"### Shielded Heading"* ]]
  [[ "$out" == *"After the fence - should be included"* ]]
  [[ "$out" != *"### Terminating Heading"* ]]
  [[ "$out" != *"Content after terminator"* ]]
}

@test "[fence-aware-extractor] section extending to EOF extracts through the last line of the file" {
  # Test expectation: when the target section extends to end-of-file with no
  # subsequent section boundary, the function extracts content from the anchor
  # line through the last line of the file.
  cat > "$FIXTURE_DIR/eof.md" <<'EOF'
### Preceding Section
preceding content

### Target Section
First target line
Second target line
Third target line
EOF
  out="$(extract_section_fence_aware "$FIXTURE_DIR/eof.md" "### Target Section")"
  [ "$?" -eq 0 ]
  [[ "$out" == *"### Target Section"* ]]
  [[ "$out" == *"First target line"* ]]
  [[ "$out" == *"Second target line"* ]]
  [[ "$out" == *"Third target line"* ]]
}

@test "[fence-aware-extractor] missing anchor: exits non-zero with extract_section_fence_aware: prefix and anchor text in stderr" {
  # Test expectation: for both error paths, the function exits non-zero and
  # emits a single stderr message beginning with the literal function-name
  # prefix extract_section_fence_aware: and includes the anchor heading value
  # passed by the caller. The missing-anchor path's message body identifies
  # that the anchor heading was not found.
  cat > "$FIXTURE_DIR/present.md" <<'EOF'
### Existing Section
Some content here
EOF
  run extract_section_fence_aware "$FIXTURE_DIR/present.md" "### Absent Section"
  [ "$status" -ne 0 ]
  [[ "$output" == *"extract_section_fence_aware:"* ]]
  [[ "$output" == *"### Absent Section"* ]]
  [[ "$output" == *"not found"* ]]
}

@test "[fence-aware-extractor] empty region: exits non-zero with extract_section_fence_aware: prefix and anchor text in stderr" {
  # Test expectation: the empty-region path's message body identifies that the
  # anchor was located but no content sat between it and the next heading.
  # The message begins with extract_section_fence_aware: and includes the anchor.
  cat > "$FIXTURE_DIR/empty-region.md" <<'EOF'
### Target Section
### Immediately Following Section
Content of next section
EOF
  run extract_section_fence_aware "$FIXTURE_DIR/empty-region.md" "### Target Section"
  [ "$status" -ne 0 ]
  [[ "$output" == *"extract_section_fence_aware:"* ]]
  [[ "$output" == *"### Target Section"* ]]
  # Empty-region message must NOT say "not found" -- anchor was located,
  # the missing piece is content between it and the next heading.
  [[ "$output" != *"not found"* ]]
}

@test "[fence-aware-extractor] missing-anchor and empty-region error messages are distinguishable by message body" {
  # Test expectation: the two error paths are distinguishable by message body.
  # Missing-anchor body identifies the anchor was not found; empty-region body
  # identifies the anchor was located but no content followed it before the
  # next heading boundary.
  cat > "$FIXTURE_DIR/compare.md" <<'EOF'
### Found Section
### Immediately Next
Content
EOF
  run extract_section_fence_aware "$FIXTURE_DIR/compare.md" "### Absent Anchor"
  [ "$status" -ne 0 ]
  absent_msg="$output"

  run extract_section_fence_aware "$FIXTURE_DIR/compare.md" "### Found Section"
  [ "$status" -ne 0 ]
  empty_msg="$output"

  # Missing-anchor message body must identify the not-found condition.
  [[ "$absent_msg" == *"not found"* ]]
  # Empty-region message body must NOT say "not found" -- anchor was located.
  [[ "$empty_msg" != *"not found"* ]]
}

@test "[fence-aware-extractor] whitespace-only region between anchor and next heading triggers no-content error path" {
  # Test expectation: a region containing only whitespace (blank lines, spaces,
  # tabs) between anchor heading and next heading triggers the no-content error
  # path (treated as empty).
  cat > "$FIXTURE_DIR/whitespace-only.md" <<'EOF'
### Target Section
   
	
### Next Section
Content here
EOF
  run extract_section_fence_aware "$FIXTURE_DIR/whitespace-only.md" "### Target Section"
  [ "$status" -ne 0 ]
  [[ "$output" == *"extract_section_fence_aware:"* ]]
  [[ "$output" == *"### Target Section"* ]]
}

@test "[fence-aware-extractor] fenced-code fixture output matches parity contract (migration equivalence)" {
  # Test expectation: both migrated call sites in test-skill-md-content-patterns.bats
  # produce output identical to the prior inline extract_review_round output for
  # the same input files. Verified here against a fixture that mirrors the
  # structural pattern of the design SKILL.md Review Round section: a fenced
  # code block containing heading-shaped lines, followed by a real out-of-fence
  # boundary heading. The assertions match exactly what the two migrated tests
  # assert on the real file.
  cat > "$FIXTURE_DIR/design-like.md" <<'EOF'
# Design SKILL

## Background

### Review Round
Review instruction text
```markdown
## Approach
Content inside code fence
### Subsection inside fence
More fenced content
```
Post-fence reviewer note
Also post-fence

### Dispatch
Other section content
EOF
  out="$(extract_section_fence_aware "$FIXTURE_DIR/design-like.md" "### Review Round")"
  [ "$?" -eq 0 ]
  # Anchor line included (anchor-inclusive contract, parity with extract_review_round).
  [[ "$out" == *"### Review Round"* ]]
  # Fenced heading-shaped lines must be present (fence-shielded, parity).
  [[ "$out" == *"## Approach"* ]]
  [[ "$out" == *"### Subsection inside fence"* ]]
  # Post-fence prose included up to the real boundary (restored detection, parity).
  [[ "$out" == *"Post-fence reviewer note"* ]]
  [[ "$out" == *"Also post-fence"* ]]
  # Real boundary heading and content after it must not appear.
  [[ "$out" != *"### Dispatch"* ]]
  [[ "$out" != *"Other section content"* ]]
}

@test "[fence-aware-extractor] inline extract_review_round definition removed from test-skill-md-content-patterns.bats after migration" {
  # Test expectation: removing the inline extract_review_round definition from
  # test-skill-md-content-patterns.bats causes no test failures in that suite.
  # This test asserts the migration is complete by verifying the inline function
  # definition is absent from the file (post-migration state). Fails RED because
  # the definition is currently present.
  require_repo_root
  local patterns_file="$REPO_ROOT/tests/unit/test-skill-md-content-patterns.bats"
  [ -f "$patterns_file" ]
  # After migration, the inline function definition must be absent.
  ! grep -q "^extract_review_round()" "$patterns_file"
}

# =============================================================================
# sf.F01: awk crash produces distinct "awk failed (exit N)" diagnostic
# (NOT "not found in")
# =============================================================================

@test "[sf-F01] extract_section_fence_aware: awk crash emits 'awk failed (exit' diagnostic, not 'not found in'" {
  # sf.F01 (score 100, correctness): awk's exit status was swallowed in the
  # original implementation.  A crash (non-zero exit from awk) was reported as
  # "anchor not found", silently masking exec failures, OOM kills, etc.
  # After the fix the function must:
  #   - return 1
  #   - emit a message containing "awk failed (exit" on stderr
  #   - NOT emit the misleading "not found in" phrase
  #
  # Technique: shadow awk in PATH with a script that always exits 2.
  local fake_bin="$FIXTURE_DIR/fake-bin"
  mkdir -p "$fake_bin"
  printf '#!/bin/sh\nexit 2\n' > "$fake_bin/awk"
  chmod +x "$fake_bin/awk"

  cat > "$FIXTURE_DIR/any.md" <<'EOF'
### Some Section
content here
EOF

  # Run with the fake awk first in PATH so the real awk is never reached.
  run env PATH="$fake_bin:$PATH" bash -c '
    load_dir="'"$BATS_TEST_DIRNAME"'/../helpers"
    # shellcheck source=tests/helpers/skill-markdown.bash
    source "$load_dir/skill-markdown.bash"
    extract_section_fence_aware "'"$FIXTURE_DIR/any.md"'" "### Some Section"
  '

  # Must exit non-zero
  [ "$status" -ne 0 ]
  # Must contain the new distinct diagnostic
  [[ "$output" == *"awk failed (exit"* ]]
  # Must NOT fall through to the misleading anchor-not-found message
  [[ "$output" != *"not found in"* ]]
}

# =============================================================================
# sec.F01: predictable signal-tmp path TOCTOU/symlink attack hardening
# =============================================================================

@test "[sec-F01] extract_section_fence_aware: mktemp-generated signal-tmp does not follow pre-planted symlink (TOCTOU fix)" {
  # sec.F01 (score 78, correctness): signal_tmp was computed as
  # /tmp/skill-md-fence-signal-$$ — predictable before the process starts.
  # A local attacker can pre-create a symlink at that path pointing at an
  # arbitrary target; awk's END block then overwrites the symlink target.
  #
  # After the fix (mktemp generates an unguessable unique path), the
  # pre-planted symlink at the old predictable path is never touched, so
  # the attack target file retains its original content.
  #
  # RED rationale: pre-fix, awk writes FOUND_WITH_CONTENT to the predictable
  # path which follows the symlink and overwrites attack_target; the assertion
  # that attack_target == ORIGINAL_CONTENT therefore FAILS (RED).
  # Post-fix, mktemp creates a distinct path; the symlink is untouched;
  # the assertion PASSES (GREEN).

  # Create the attack target with known content.
  local attack_target="$FIXTURE_DIR/sec-f01-attack-target"
  printf 'ORIGINAL_CONTENT\n' > "$attack_target"

  # Plant the symlink at the predictable path (uses $$ = bats process PID;
  # extract_section_fence_aware runs in the same process so its $$ matches).
  local predictable_path="/tmp/skill-md-fence-signal-$$"
  ln -sf "$attack_target" "$predictable_path"

  # Fixture file with a valid non-empty section so awk reaches its END block
  # and writes FOUND_WITH_CONTENT to whatever signal_tmp resolves to.
  cat > "$FIXTURE_DIR/valid.md" <<'EOF'
### Some Section
content line that is not empty
EOF

  # Direct call (no `run`) so the function executes in this shell where $$
  # equals the bats PID — same value the function uses to build the
  # predictable path if it has not yet been fixed.
  extract_section_fence_aware "$FIXTURE_DIR/valid.md" "### Some Section" \
    >/dev/null 2>&1 || true

  # Remove the symlink regardless of outcome (test-level cleanup).
  rm -f "$predictable_path"

  # Post-fix: attack target must contain its original content (symlink was
  # never followed because mktemp generated a unique path).
  local content
  content="$(cat "$attack_target")"
  [ "$content" = "ORIGINAL_CONTENT" ]
}

# =============================================================================
# sf.F03: empty fenced block (delimiters only) treated as content, not FOUND_EMPTY
# =============================================================================

@test "[r7-sf.F01] mktemp failure surfaces mktemp-named diagnostic" {
  # sf.F01 (score 85, correctness): when mktemp fails (e.g. TMPDIR points to a
  # non-existent directory), signal_tmp becomes empty and the function fell
  # through to awk, which emitted a misleading "not found in" or "awk failed
  # (exit 2)" diagnostic that hid the real root cause.
  #
  # After the fix, the function must return non-zero AND write a stderr message
  # containing the literal substring "mktemp" so the operator can identify the
  # real cause without guessing.
  #
  # Technique: shadow mktemp in PATH with a script that exits 1 silently (no
  # output).  This prevents mktemp's own "mkstemp failed" message from leaking
  # into $output and making the assertion vacuous before the fix is applied.
  # Pre-fix: signal_tmp="" → awk runs → "not found in" (no "mktemp" substring).
  # Post-fix: guard fires → "extract_section_fence_aware: mktemp failed …"
  #   (contains "mktemp") → function returns 1 before awk is invoked.
  local fake_bin="$FIXTURE_DIR/fake-bin"
  mkdir -p "$fake_bin"
  printf '#!/bin/sh\nexit 1\n' > "$fake_bin/mktemp"
  chmod +x "$fake_bin/mktemp"

  cat > "$FIXTURE_DIR/doc.md" <<'EOF'
### Some Section
content here
### Next Section
EOF

  # Run with the silent fake mktemp first in PATH.
  run env PATH="$fake_bin:$PATH" bash -c '
    load_dir="'"$BATS_TEST_DIRNAME"'/../helpers"
    # shellcheck source=tests/helpers/skill-markdown.bash
    source "$load_dir/skill-markdown.bash"
    extract_section_fence_aware "'"$FIXTURE_DIR/doc.md"'" "### Some Section"
  '

  # Must exit non-zero.
  [ "$status" -ne 0 ]
  # Stderr (captured by bats run) must name mktemp as the root cause.
  [[ "$output" == *"mktemp"* ]]
}

@test "[sf-F03] extract_section_fence_aware: section containing only an empty fenced block returns 0 with fence delimiters in stdout" {
  # sf.F03 (score 88, correctness): the /^```/ rule inside the awk script set
  # fence state and printed the delimiter line but never set has_content=1.
  # A section whose body was an empty fenced code block (two ``` delimiter lines
  # with nothing between them) was therefore misclassified as FOUND_EMPTY and
  # its output silently discarded.
  #
  # After the fix, fence delimiter lines inside the target section must set
  # has_content=1, so the function returns 0 and emits both delimiter lines.
  cat > "$FIXTURE_DIR/empty-fence.md" <<'EOF'
### Target Section
```
```
### Next Section
other content
EOF

  out="$(extract_section_fence_aware "$FIXTURE_DIR/empty-fence.md" "### Target Section")"
  local rc=$?

  # Pre-fix: returns 1 (FOUND_EMPTY). Post-fix: must return 0.
  [ "$rc" -eq 0 ]
  # Both fence delimiter lines must appear in the output.
  [[ "$out" == *'```'* ]]
  # Verify the anchor line is present (anchor-inclusive contract).
  [[ "$out" == *"### Target Section"* ]]
  # The next section's content must not bleed through.
  [[ "$out" != *"other content"* ]]
}

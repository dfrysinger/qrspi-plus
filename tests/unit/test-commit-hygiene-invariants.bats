#!/usr/bin/env bats
bats_require_minimum_version 1.5.0

# T39 — G12: Commit-hygiene invariants pin.
#
# Asserts T38's three architectural invariants observably hold across a
# representative implementer commit cycle and that the worktree-setup
# edit in skills/implement/SKILL.md realizes the worktree-local-exclude
# invariant per Task 39:
#
#   1. staging-before-scratch — staging completes before .qrspi-commit-msg.txt
#      is written, so the scratch file cannot be in the commit's tree.
#   2. cleanup-after-commit — .qrspi-commit-msg.txt is removed after the
#      commit and before any subsequent staging cycle begins.
#   3. worktree-local-exclude — .qrspi-commit-msg.txt is excluded via
#      <worktree>/.git/info/exclude appended during worktree setup,
#      independent of any per-commit ordering.
#
# Also asserts:
#   - skills/implement/SKILL.md instructs the orchestrator to append the
#     entry during per-task worktree creation (both full-pipeline and
#     quick-fix paths).
#   - File-based commit-message convention (`git commit -F <scratch>`)
#     preserved; no heredoc usage in the cycle.
#   - When the worktree-local exclude is artificially emptied between
#     cycles, the cleanup-after-commit invariant still holds standalone.
#
# Bash 3.2 portable.

load '../helpers/skill-markdown'

setup_file() {
  require_repo_root
  IMPLEMENT_SKILL="$REPO_ROOT/skills/implement/SKILL.md"
  IMPLEMENTER_PROTOCOL="$REPO_ROOT/skills/implementer-protocol/SKILL.md"
  export IMPLEMENT_SKILL IMPLEMENTER_PROTOCOL
}

setup() {
  FIXTURE_DIR="$(mktemp -d)"
  export FIXTURE_DIR
  # Build a fixture git "worktree" — for unit-test scope we use a plain
  # fixture repo with the same .git/info/exclude shape Implement creates
  # via `git worktree add`. The cycle assertions are git-only and do not
  # require a real worktree linkage.
  git -C "$FIXTURE_DIR" init -q -b main
  git -C "$FIXTURE_DIR" config user.email "t39@example.com"
  git -C "$FIXTURE_DIR" config user.name "T39 Fixture"
  # Seed a base commit so the worktree has a parent.
  printf 'base\n' > "$FIXTURE_DIR/base.txt"
  git -C "$FIXTURE_DIR" add base.txt
  git -C "$FIXTURE_DIR" commit -q -m "base"
  # Implement's worktree-setup append (the T39 edit): append
  # `.qrspi-commit-msg.txt` to <worktree>/.git/info/exclude, creating the
  # file if missing.
  mkdir -p "$FIXTURE_DIR/.git/info"
  printf '.qrspi-commit-msg.txt\n' >> "$FIXTURE_DIR/.git/info/exclude"
}

teardown() {
  rm -rf "$FIXTURE_DIR"
}

# =============================================================================
# Implement SKILL documents the worktree-setup append (full pipeline + quick fix)
# =============================================================================

@test "Implement SKILL appends .qrspi-commit-msg.txt to .git/info/exclude in full-pipeline worktree setup" {
  extract_and_grep "$IMPLEMENT_SKILL" H2 "Process Steps" \
    "\\.git/info/exclude"
}

@test "Implement SKILL append names the .qrspi-commit-msg.txt entry" {
  extract_and_grep "$IMPLEMENT_SKILL" H2 "Process Steps" \
    "\\.qrspi-commit-msg\\.txt"
}

@test "Implement SKILL append fires immediately after git worktree add and before implementer dispatch" {
  extract_and_grep "$IMPLEMENT_SKILL" H2 "Process Steps" \
    "after .git worktree add. succeeds and before dispatching the implementer"
}

@test "Implement SKILL append references T38 worktree-local-exclude invariant" {
  extract_and_grep "$IMPLEMENT_SKILL" H2 "Process Steps" \
    "worktree-local-exclude invariant"
}

@test "Implementer-protocol Commit hygiene invariants section exists (T38)" {
  extract_and_grep "$IMPLEMENTER_PROTOCOL" H2 "Commit hygiene invariants" \
    "(staging-before-scratch|cleanup-after-commit|worktree-local-exclude)"
}

# =============================================================================
# Invariant 3 — worktree-local-exclude: .git/info/exclude carries the entry
#                immediately after worktree setup.
# =============================================================================

@test "worktree-local-exclude invariant holds immediately after worktree setup" {
  grep -E "^\\.qrspi-commit-msg\\.txt$" "$FIXTURE_DIR/.git/info/exclude"
}

# =============================================================================
# Representative implementer commit cycle exercised end-to-end.
# Asserts invariants 1 (staging-before-scratch) and 2 (cleanup-after-commit).
# =============================================================================

@test "Implementer commit cycle: scratch file absent from committed tree" {
  # Step 1: implementer makes a code change.
  printf 'new line\n' > "$FIXTURE_DIR/work.txt"
  # Step 2: staging-before-scratch — git add runs BEFORE the scratch file
  # is written to disk. So the scratch file does not exist when staging
  # captures the index snapshot.
  git -C "$FIXTURE_DIR" add work.txt
  # Step 3: implementer writes the commit-message scratch file.
  printf 'feat: add work\n\nLonger body.\n' > "$FIXTURE_DIR/.qrspi-commit-msg.txt"
  # Sanity: the scratch file exists at this point, but it is NOT staged
  # (the index was captured before the scratch file existed).
  [ -f "$FIXTURE_DIR/.qrspi-commit-msg.txt" ]
  # Step 4: file-based commit — `git commit -F <scratch>` honors the
  # user's global no-heredoc convention.
  git -C "$FIXTURE_DIR" commit -q -F .qrspi-commit-msg.txt
  # Step 5: cleanup-after-commit — remove the scratch file before any
  # subsequent staging cycle.
  rm -f "$FIXTURE_DIR/.qrspi-commit-msg.txt"
  # Invariant 1 (staging-before-scratch) — the committed tree does NOT
  # contain the scratch file blob. Use git ls-tree on HEAD to enumerate.
  ! git -C "$FIXTURE_DIR" ls-tree -r --name-only HEAD | grep -E "^\\.qrspi-commit-msg\\.txt$"
  # Invariant 2 (cleanup-after-commit) — scratch file absent from
  # worktree after the cycle.
  [ ! -e "$FIXTURE_DIR/.qrspi-commit-msg.txt" ]
}

# =============================================================================
# File-based commit-message convention preserved (no heredoc).
# =============================================================================

@test "File-based commit-message convention used (no heredoc)" {
  # Re-exercise the cycle and assert the commit message body matches the
  # scratch file content (proving `-F <scratch>` was used, not heredoc).
  printf 'second\n' > "$FIXTURE_DIR/work2.txt"
  git -C "$FIXTURE_DIR" add work2.txt
  printf 'feat: second commit\n\nFrom scratch file.\n' > "$FIXTURE_DIR/.qrspi-commit-msg.txt"
  git -C "$FIXTURE_DIR" commit -q -F .qrspi-commit-msg.txt
  rm -f "$FIXTURE_DIR/.qrspi-commit-msg.txt"
  # Assert the commit's full message matches the file body exactly.
  local got
  got="$(git -C "$FIXTURE_DIR" log -1 --format=%B HEAD)"
  case "$got" in
    *"feat: second commit"*"From scratch file."*) : ;;
    *)
      printf 'commit message did not match scratch file body: <<<%s>>>\n' "$got" >&2
      return 1
      ;;
  esac
}

# =============================================================================
# Worktree-local-exclude makes git status deterministic between scratch
# write and removal (no untracked entries reported).
# =============================================================================

@test "git status reports clean when scratch file exists with exclude in effect" {
  printf 'third\n' > "$FIXTURE_DIR/work3.txt"
  git -C "$FIXTURE_DIR" add work3.txt
  printf 'feat: third\n' > "$FIXTURE_DIR/.qrspi-commit-msg.txt"
  # With the worktree-local exclude in effect, git status --porcelain
  # MUST NOT report .qrspi-commit-msg.txt as an untracked file.
  ! git -C "$FIXTURE_DIR" status --porcelain | grep -E "\\.qrspi-commit-msg\\.txt"
  git -C "$FIXTURE_DIR" commit -q -F .qrspi-commit-msg.txt
  rm -f "$FIXTURE_DIR/.qrspi-commit-msg.txt"
}

# =============================================================================
# Cleanup-after-commit invariant remains load-bearing when the
# worktree-local exclude is artificially emptied between cycles.
# =============================================================================

@test "cleanup-after-commit invariant holds standalone when exclude is emptied" {
  # First cycle (exclude in effect).
  printf 'fourth\n' > "$FIXTURE_DIR/work4.txt"
  git -C "$FIXTURE_DIR" add work4.txt
  printf 'feat: fourth\n' > "$FIXTURE_DIR/.qrspi-commit-msg.txt"
  git -C "$FIXTURE_DIR" commit -q -F .qrspi-commit-msg.txt
  rm -f "$FIXTURE_DIR/.qrspi-commit-msg.txt"
  # Empty the worktree-local exclude (simulating a worktree set up by a
  # non-QRSPI mechanism, or a corruption of the exclude file).
  : > "$FIXTURE_DIR/.git/info/exclude"
  # Subsequent staging cycle: cleanup-after-commit means no stale scratch
  # file is left in the worktree, so even without the exclude there is
  # nothing to leak.
  [ ! -e "$FIXTURE_DIR/.qrspi-commit-msg.txt" ]
  printf 'fifth\n' > "$FIXTURE_DIR/work5.txt"
  git -C "$FIXTURE_DIR" add work5.txt
  # git status MUST NOT report .qrspi-commit-msg.txt because it does
  # not exist on disk — the cleanup invariant carried the load.
  ! git -C "$FIXTURE_DIR" status --porcelain | grep -E "\\.qrspi-commit-msg\\.txt"
  printf 'feat: fifth\n' > "$FIXTURE_DIR/.qrspi-commit-msg.txt"
  git -C "$FIXTURE_DIR" commit -q -F .qrspi-commit-msg.txt
  rm -f "$FIXTURE_DIR/.qrspi-commit-msg.txt"
  # Final tree does NOT contain the scratch file blob even though the
  # exclude was empty for this cycle — proving cleanup-after-commit is
  # load-bearing on its own.
  ! git -C "$FIXTURE_DIR" ls-tree -r --name-only HEAD | grep -E "^\\.qrspi-commit-msg\\.txt$"
}

# =============================================================================
# committed-gitignore invariant: .qrspi-commit-msg.txt in committed
# root .gitignore closes the fresh-clone / fresh-worktree staging gap.
# =============================================================================

@test "[commit-hygiene] committed root .gitignore contains .qrspi-commit-msg.txt verbatim" {
  # Verify REPO_ROOT is set (require_repo_root called in setup_file).
  [ -n "$REPO_ROOT" ]
  [ -f "$REPO_ROOT/.gitignore" ]
  grep -E "^\.qrspi-commit-msg\.txt$" "$REPO_ROOT/.gitignore"
}

@test "[commit-hygiene] git add -A does not stage scratch file on fresh-clone simulation (gitignore-only, no per-clone exclude)" {
  # Create a scratch git repo simulating a fresh clone with no per-clone exclude.
  local fresh_dir
  fresh_dir="$(mktemp -d)"
  trap 'rm -rf "$fresh_dir"' RETURN
  git -C "$fresh_dir" init -q -b main
  git -C "$fresh_dir" config user.email "commit-hygiene@example.com"
  git -C "$fresh_dir" config user.name "Commit-Hygiene Fixture"
  # Pre-condition: no .git/info/exclude entry for the scratch path exists.
  # A real fresh clone has an empty (or absent) info/exclude file.
  if [ -f "$fresh_dir/.git/info/exclude" ]; then
    if grep -qF ".qrspi-commit-msg.txt" "$fresh_dir/.git/info/exclude"; then
      printf 'FAIL: pre-condition violated - .git/info/exclude already contains scratch path\n' >&2
      return 1
    fi
  fi
  # Copy the committed .gitignore from the project root into the fixture,
  # simulating what a fresh clone would have checked out on disk.
  cp "$REPO_ROOT/.gitignore" "$fresh_dir/.gitignore"
  # Seed a base commit so HEAD exists.
  printf 'base\n' > "$fresh_dir/base.txt"
  git -C "$fresh_dir" add base.txt
  git -C "$fresh_dir" commit -q -m "base"
  # Simulate the implementer disk state: a code change and the scratch file both
  # present before the staging step.
  printf 'work content\n' > "$fresh_dir/work.txt"
  printf 'feat: some work\n' > "$fresh_dir/.qrspi-commit-msg.txt"
  # Execute git add -A as the implementer commit flow would.
  git -C "$fresh_dir" add -A
  # Capture staged index contents.
  local staged
  staged="$(git -C "$fresh_dir" diff --cached --name-only)"
  # Positive guard: staging must have captured work.txt, proving git add -A ran.
  printf '%s\n' "$staged" | grep -qE "^work\.txt$" \
    || { printf 'FAIL: staging captured nothing - test is vacuous\n' >&2; return 1; }
  # The scratch file must NOT appear in the staged index. Protection here comes
  # solely from the committed .gitignore; no per-clone exclude is in effect.
  ! printf '%s\n' "$staged" | grep -E "^\.qrspi-commit-msg\.txt$"
}

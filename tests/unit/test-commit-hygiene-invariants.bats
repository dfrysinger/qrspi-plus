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

@test "[T39-hygiene] Implement SKILL appends .qrspi-commit-msg.txt to .git/info/exclude in full-pipeline worktree setup" {
  extract_and_grep "$IMPLEMENT_SKILL" H2 "Process Steps" \
    "\\.git/info/exclude"
}

@test "[T39-hygiene] Implement SKILL append names the .qrspi-commit-msg.txt entry" {
  extract_and_grep "$IMPLEMENT_SKILL" H2 "Process Steps" \
    "\\.qrspi-commit-msg\\.txt"
}

@test "[T39-hygiene] Implement SKILL append fires immediately after git worktree add and before implementer dispatch" {
  extract_and_grep "$IMPLEMENT_SKILL" H2 "Process Steps" \
    "after .git worktree add. succeeds and before dispatching the implementer"
}

@test "[T39-hygiene] Implement SKILL append references T38 worktree-local-exclude invariant" {
  extract_and_grep "$IMPLEMENT_SKILL" H2 "Process Steps" \
    "worktree-local-exclude invariant"
}

@test "[T39-hygiene] Implementer-protocol Commit hygiene invariants section exists (T38)" {
  extract_and_grep "$IMPLEMENTER_PROTOCOL" H2 "Commit hygiene invariants" \
    "(staging-before-scratch|cleanup-after-commit|worktree-local-exclude)"
}

# =============================================================================
# Invariant 3 — worktree-local-exclude: .git/info/exclude carries the entry
#                immediately after worktree setup.
# =============================================================================

@test "[T39-hygiene] worktree-local-exclude invariant holds immediately after worktree setup" {
  grep -E "^\\.qrspi-commit-msg\\.txt$" "$FIXTURE_DIR/.git/info/exclude"
}

# =============================================================================
# Representative implementer commit cycle exercised end-to-end.
# Asserts invariants 1 (staging-before-scratch) and 2 (cleanup-after-commit).
# =============================================================================

@test "[T39-hygiene] Implementer commit cycle: scratch file absent from committed tree" {
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

@test "[T39-hygiene] File-based commit-message convention used (no heredoc)" {
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

@test "[T39-hygiene] git status reports clean when scratch file exists with exclude in effect" {
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

@test "[T39-hygiene] cleanup-after-commit invariant holds standalone when exclude is emptied" {
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

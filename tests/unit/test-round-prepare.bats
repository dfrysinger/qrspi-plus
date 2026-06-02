#!/usr/bin/env bats
# ============================================================================
# Unit tests for scripts/round-prepare.sh — G4.
#
# Pins behaviors enumerated in task-12.md "Test expectations":
#   - File existence + JSON validity for the section-anchor manifest and the
#     three per-skill anchor JSON files.
#   - Happy-path artifact-level + per-task invocations write the expected
#     diff, sidecar, and (per-task) commit-anchor; reruns are byte-identical.
#   - Per-task SHA-correctness exits: 10 (missing-flag), 11 (HEAD mismatch),
#     12 (unadvanced commit), each with a recovery-path diagnostic.
#   - Prior-round bookkeeping validation: missing/malformed commit anchor and
#     missing/empty scope-set fail loud and block reviewer dispatch.
#   - Convergence narrow/broaden table: missing/empty/superset/partial/disjoint
#     scope-sets broaden; equal scope-sets narrow; HEAD~1 mismatch falls back
#     to broaden with reason recorded.
#   - Backward-loop flag handling: present flag forces broaden, flag is
#     consumed once, deletion failure is diagnosed.
#   - Non-git workspace: documented no-diff status (exit 2), no fabricated
#     diff path or scope hint.
# ============================================================================

setup() {
  TEST_ROOT=$(mktemp -d)
  export TEST_ROOT
  cd "$TEST_ROOT"

  REPO_ROOT=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)
  export REPO_ROOT
  PREP="$REPO_ROOT/scripts/round-prepare.sh"
  export PREP

  # Initialise a git repo with two commits (so HEAD~1 is valid).
  git init -q -b main "$TEST_ROOT/repo"
  cd "$TEST_ROOT/repo"
  git config user.email "t@example.test"
  git config user.name "Tester"
  echo "v1" > file.txt
  git add file.txt
  git commit -q -m "initial"
  BASE_SHA=$(git rev-parse HEAD)
  echo "v2" > file.txt
  git commit -q -am "second"
  HEAD_SHA=$(git rev-parse HEAD)
  export BASE_SHA HEAD_SHA

  # Round directory layout: <task-dir>/round-NN/ with bookkeeping artifacts in
  # <task-dir>/.
  TASK_DIR="$TEST_ROOT/task"
  mkdir -p "$TASK_DIR/round-01"
  mkdir -p "$TASK_DIR/round-02"
  mkdir -p "$TASK_DIR/round-03"
  export TASK_DIR
}

teardown() {
  rm -rf "$TEST_ROOT"
}

# ── File / JSON existence checks ────────────────────────────────────────────

@test "round-prepare.sh exists and is executable" {
  [ -f "$PREP" ]
  [ -x "$PREP" ]
}

@test "await-round.sh exists and is executable" {
  [ -f "$REPO_ROOT/scripts/await-round.sh" ]
  [ -x "$REPO_ROOT/scripts/await-round.sh" ]
}

@test "g4-section-anchor-manifest.json is valid JSON with entries[]" {
  python3 -c "
import json,sys
d=json.load(open('$REPO_ROOT/scripts/g4-section-anchor-manifest.json'))
assert isinstance(d.get('entries'), list) and len(d['entries']) >= 1
for e in d['entries']:
    assert isinstance(e['source'], str) and isinstance(e['index'], str)
"
}

@test "skills/using-qrspi/SKILL.anchors.json is valid JSON" {
  python3 -m json.tool "$REPO_ROOT/skills/using-qrspi/SKILL.anchors.json" >/dev/null
}

@test "skills/reviewer-protocol/SKILL.anchors.json is valid JSON" {
  python3 -m json.tool "$REPO_ROOT/skills/reviewer-protocol/SKILL.anchors.json" >/dev/null
}

@test "skills/plan/SKILL.anchors.json is valid JSON" {
  python3 -m json.tool "$REPO_ROOT/skills/plan/SKILL.anchors.json" >/dev/null
}

@test "anchor refresh is idempotent: rerun produces no diff against tracked indexes" {
  # Round-trip the refresh script in a clean copy of the repo's relevant files.
  cd "$REPO_ROOT"
  bash scripts/g4-section-anchor-refresh.sh
  # If indexes drift, git would detect it inside the worktree.
  run git -C "$REPO_ROOT" diff --exit-code -- \
      skills/using-qrspi/SKILL.anchors.json \
      skills/reviewer-protocol/SKILL.anchors.json \
      skills/plan/SKILL.anchors.json
  [ "$status" -eq 0 ]
}

# ── Artifact-level happy path (no --task-branch) ────────────────────────────

@test "artifact-level: writes round-NN.diff and .round-prepare.json sidecar" {
  cd "$TEST_ROOT/repo"
  run "$PREP" 1 "$TASK_DIR/round-01" --base-ref "$BASE_SHA"
  [ "$status" -eq 0 ]
  [ -f "$TASK_DIR/round-01/round-01.diff" ]
  [ -f "$TASK_DIR/round-01/.round-prepare.json" ]
  python3 -c "
import json
d=json.load(open('$TASK_DIR/round-01/.round-prepare.json'))
assert 'ref' in d and 'narrowed' in d and 'diff_file' in d
assert d['narrowed'] is False  # round-1 broadens by default
"
}

@test "artifact-level: rerun produces byte-identical sidecar (deterministic)" {
  cd "$TEST_ROOT/repo"
  "$PREP" 1 "$TASK_DIR/round-01" --base-ref "$BASE_SHA"
  cp "$TASK_DIR/round-01/.round-prepare.json" "$TEST_ROOT/first.json"
  cp "$TASK_DIR/round-01/round-01.diff" "$TEST_ROOT/first.diff"
  "$PREP" 1 "$TASK_DIR/round-01" --base-ref "$BASE_SHA"
  cmp "$TEST_ROOT/first.json" "$TASK_DIR/round-01/.round-prepare.json"
  cmp "$TEST_ROOT/first.diff" "$TASK_DIR/round-01/round-01.diff"
}

# ── Per-task SHA-correctness exit codes ─────────────────────────────────────

@test "per-task: --task-branch without --implementer-commit exits 10 (orchestrator bug)" {
  cd "$TEST_ROOT/repo"
  run "$PREP" 1 "$TASK_DIR/round-01" --task-branch foo --base-ref "$BASE_SHA"
  [ "$status" -eq 10 ]
  [[ "$output" == *"orchestrator bug"* ]]
  [[ "$output" == *"--implementer-commit"* ]]
}

@test "per-task: --implementer-commit without --task-branch exits 10 (orchestrator bug)" {
  cd "$TEST_ROOT/repo"
  run "$PREP" 1 "$TASK_DIR/round-01" --implementer-commit "$HEAD_SHA" --base-ref "$BASE_SHA"
  [ "$status" -eq 10 ]
  [[ "$output" == *"orchestrator bug"* ]]
}

@test "per-task: SHA != HEAD exits 11 (worktree integrity break)" {
  cd "$TEST_ROOT/repo"
  bogus="0000000000000000000000000000000000000001"
  run "$PREP" 1 "$TASK_DIR/round-01" \
      --task-branch main \
      --implementer-commit "$bogus" \
      --worktree "$TEST_ROOT/repo" \
      --base-ref "$BASE_SHA"
  [ "$status" -eq 11 ]
  [[ "$output" == *"HALT"* ]]
  [[ "$output" == *"$bogus"* ]]
}

@test "per-task: round 1 SHA == task base exits 12 (unadvanced — re-dispatch implementer)" {
  cd "$TEST_ROOT/repo"
  # Set worktree HEAD to BASE_SHA so within-round equality passes; then the
  # across-rounds check fires (passed SHA == task base on round 1).
  git reset --hard "$BASE_SHA" >/dev/null 2>&1
  run "$PREP" 1 "$TASK_DIR/round-01" \
      --task-branch main \
      --implementer-commit "$BASE_SHA" \
      --worktree "$TEST_ROOT/repo" \
      --base-ref "$BASE_SHA"
  [ "$status" -eq 12 ]
  [[ "$output" == *"re-dispatch the implementer"* ]]
  [[ "$output" == *"task base commit"* ]]
}

@test "per-task: round 2 SHA == round-1 anchor exits 12 with prior-round diagnostic" {
  cd "$TEST_ROOT/repo"
  printf '%s\n' "$HEAD_SHA" > "$TASK_DIR/round-01-commit.txt"
  printf '' > "$TASK_DIR/round-01-scope-set.txt"
  run "$PREP" 2 "$TASK_DIR/round-02" \
      --task-branch main \
      --implementer-commit "$HEAD_SHA" \
      --worktree "$TEST_ROOT/repo" \
      --base-ref "$BASE_SHA"
  [ "$status" -eq 12 ]
  [[ "$output" == *"prior round anchor"* ]]
}

@test "per-task: happy path writes round-NN-commit.txt with passed SHA + newline" {
  cd "$TEST_ROOT/repo"
  run "$PREP" 1 "$TASK_DIR/round-01" \
      --task-branch main \
      --implementer-commit "$HEAD_SHA" \
      --worktree "$TEST_ROOT/repo" \
      --base-ref "$BASE_SHA"
  [ "$status" -eq 0 ]
  [ -f "$TASK_DIR/round-01-commit.txt" ]
  # Anchor content must be 40 hex chars + single newline.
  python3 -c "
import re
data=open('$TASK_DIR/round-01-commit.txt').read()
assert re.match(r'^[0-9a-f]{40}\n\$', data), repr(data)
assert data.strip() == '$HEAD_SHA'
"
}

# ── Prior-round bookkeeping validation ──────────────────────────────────────

@test "prior-round: missing round-(NN-1)-commit.txt blocks dispatch with named diagnostic" {
  cd "$TEST_ROOT/repo"
  # Round 2 with no round-01-commit.txt present.
  run "$PREP" 2 "$TASK_DIR/round-02" \
      --task-branch main \
      --implementer-commit "$HEAD_SHA" \
      --worktree "$TEST_ROOT/repo" \
      --base-ref "$BASE_SHA"
  [ "$status" -ne 0 ]
  [ "$status" -ne 12 ]
  [[ "$output" == *"missing prior-round commit anchor"* ]]
}

@test "prior-round: malformed round-(NN-1)-commit.txt blocks dispatch with named diagnostic" {
  cd "$TEST_ROOT/repo"
  echo "not-a-sha" > "$TASK_DIR/round-01-commit.txt"
  run "$PREP" 2 "$TASK_DIR/round-02" \
      --task-branch main \
      --implementer-commit "$HEAD_SHA" \
      --worktree "$TEST_ROOT/repo" \
      --base-ref "$BASE_SHA"
  [ "$status" -ne 0 ]
  [[ "$output" == *"malformed prior-round commit anchor"* ]]
}

@test "prior-round: missing scope-set on round 3 blocks dispatch (when narrowing-eligible)" {
  cd "$TEST_ROOT/repo"
  printf '%s\n' "$HEAD_SHA" > "$TASK_DIR/round-01-commit.txt"
  PREV_SHA=$(git rev-parse HEAD~1)
  printf '%s\n' "$PREV_SHA" > "$TASK_DIR/round-02-commit.txt"
  # round-02-scope-set.txt deliberately absent.
  # `env VAR=val "$PREP"` (rather than `VAR=val run "$PREP"`) makes the
  # scope-tagger gate explicit in the subprocess environment regardless of
  # how the bats `run` function propagates assignment-prefix variables.
  run env QRSPI_SCOPE_TAGGER_ENABLED=true "$PREP" 3 "$TASK_DIR/round-03" \
      --task-branch main \
      --implementer-commit "$HEAD_SHA" \
      --worktree "$TEST_ROOT/repo" \
      --base-ref "$BASE_SHA"
  [ "$status" -ne 0 ]
  [[ "$output" == *"missing prior-round scope-set"* ]]
}

@test "prior-round: empty scope-set on round 3 blocks dispatch (when narrowing-eligible)" {
  cd "$TEST_ROOT/repo"
  printf '%s\n' "$HEAD_SHA" > "$TASK_DIR/round-01-commit.txt"
  PREV_SHA=$(git rev-parse HEAD~1)
  printf '%s\n' "$PREV_SHA" > "$TASK_DIR/round-02-commit.txt"
  : > "$TASK_DIR/round-02-scope-set.txt"  # empty
  run env QRSPI_SCOPE_TAGGER_ENABLED=true "$PREP" 3 "$TASK_DIR/round-03" \
      --task-branch main \
      --implementer-commit "$HEAD_SHA" \
      --worktree "$TEST_ROOT/repo" \
      --base-ref "$BASE_SHA"
  [ "$status" -ne 0 ]
  [[ "$output" == *"empty prior-round scope-set"* ]]
}

# ── Convergence narrow/broaden table ────────────────────────────────────────

@test "convergence: equal scope-sets narrow (proper-subset rule satisfied via equality)" {
  cd "$TEST_ROOT/repo"
  # Add a third commit so HEAD~1 matches the round-02 anchor (SHA safety
  # check requires HEAD~1 == round-(NN-1)-commit.txt content).
  echo "v3" > file.txt
  git commit -q -am "third"
  # After the third commit: HEAD points to R3; HEAD~1 == HEAD_SHA.
  # round-(NN-1) for NN=3 is round-02 → anchor must equal HEAD_SHA.
  printf '%s\n' "$HEAD_SHA" > "$TASK_DIR/round-02-commit.txt"
  printf '%s\n' "$BASE_SHA" > "$TASK_DIR/round-01-commit.txt"
  printf 'a\nb\nc\n' > "$TASK_DIR/round-01-scope-set.txt"
  printf 'a\nb\nc\n' > "$TASK_DIR/round-02-scope-set.txt"
  run "$PREP" 3 "$TASK_DIR/round-03" --base-ref "$BASE_SHA"
  [ "$status" -eq 0 ]
  python3 -c "
import json
d=json.load(open('$TASK_DIR/round-03/.round-prepare.json'))
assert d['narrowed'] is True, d
"
}

@test "convergence: superset (round NN-1 ⊃ NN-2) broadens" {
  cd "$TEST_ROOT/repo"
  PREV=$(git rev-parse HEAD~1)
  printf '%s\n' "$HEAD_SHA" > "$TASK_DIR/round-02-commit.txt"
  printf '%s\n' "$PREV"     > "$TASK_DIR/round-01-commit.txt"
  printf 'a\nb\n'       > "$TASK_DIR/round-01-scope-set.txt"
  printf 'a\nb\nc\nd\n' > "$TASK_DIR/round-02-scope-set.txt"
  run "$PREP" 3 "$TASK_DIR/round-03" --base-ref "$BASE_SHA"
  [ "$status" -eq 0 ]
  python3 -c "
import json
d=json.load(open('$TASK_DIR/round-03/.round-prepare.json'))
assert d['narrowed'] is False, d
"
}

@test "convergence: disjoint scope-sets broaden" {
  cd "$TEST_ROOT/repo"
  PREV=$(git rev-parse HEAD~1)
  printf '%s\n' "$HEAD_SHA" > "$TASK_DIR/round-02-commit.txt"
  printf '%s\n' "$PREV"     > "$TASK_DIR/round-01-commit.txt"
  printf 'a\nb\n' > "$TASK_DIR/round-01-scope-set.txt"
  printf 'x\ny\n' > "$TASK_DIR/round-02-scope-set.txt"
  run "$PREP" 3 "$TASK_DIR/round-03" --base-ref "$BASE_SHA"
  [ "$status" -eq 0 ]
  python3 -c "
import json
d=json.load(open('$TASK_DIR/round-03/.round-prepare.json'))
assert d['narrowed'] is False
"
}

@test "convergence: HEAD~1 mismatch falls back to broaden + reason recorded" {
  cd "$TEST_ROOT/repo"
  printf '%s\n' "$HEAD_SHA" > "$TASK_DIR/round-02-commit.txt"
  # Anchor for round-1 deliberately set to a SHA that does NOT match HEAD~1.
  printf '%s\n' "0000000000000000000000000000000000000002" > "$TASK_DIR/round-01-commit.txt"
  printf 'a\n' > "$TASK_DIR/round-01-scope-set.txt"
  printf 'a\n' > "$TASK_DIR/round-02-scope-set.txt"
  run "$PREP" 3 "$TASK_DIR/round-03" --base-ref "$BASE_SHA"
  [ "$status" -eq 0 ]
  python3 -c "
import json
d=json.load(open('$TASK_DIR/round-03/.round-prepare.json'))
assert d['narrowed'] is False
assert d.get('reason') and 'HEAD~1' in d['reason']
"
}

# Convergence-table coverage gap fixtures: missing, empty, full-artifact,
# overlap (partial), proper-subset-with-safety-margin. These exercise the
# table rows enumerated in task-12.md "Test expectations" bullet 6.

@test "convergence: missing scope-set (tagger disabled) broadens via decide_narrow path" {
  # When the scope-tagger is disabled, missing scope-set files are NOT a
  # blocking error (that branch is gated by SCOPE_TAGGER_ENABLED). Instead,
  # decide_narrow's `[ ! -s "$prev1" ]` check fires and the round broadens.
  cd "$TEST_ROOT/repo"
  PREV=$(git rev-parse HEAD~1)
  printf '%s\n' "$HEAD_SHA" > "$TASK_DIR/round-02-commit.txt"
  printf '%s\n' "$PREV"     > "$TASK_DIR/round-01-commit.txt"
  # Both scope-set files deliberately absent; tagger disabled (default).
  run "$PREP" 3 "$TASK_DIR/round-03" --base-ref "$BASE_SHA"
  [ "$status" -eq 0 ]
  python3 -c "
import json
d=json.load(open('$TASK_DIR/round-03/.round-prepare.json'))
assert d['narrowed'] is False, d
assert d.get('reason') and 'scope-set missing or empty' in d['reason'], d
"
}

@test "convergence: empty scope-set (tagger disabled) broadens via decide_narrow path" {
  cd "$TEST_ROOT/repo"
  PREV=$(git rev-parse HEAD~1)
  printf '%s\n' "$HEAD_SHA" > "$TASK_DIR/round-02-commit.txt"
  printf '%s\n' "$PREV"     > "$TASK_DIR/round-01-commit.txt"
  : > "$TASK_DIR/round-01-scope-set.txt"
  : > "$TASK_DIR/round-02-scope-set.txt"
  run "$PREP" 3 "$TASK_DIR/round-03" --base-ref "$BASE_SHA"
  [ "$status" -eq 0 ]
  python3 -c "
import json
d=json.load(open('$TASK_DIR/round-03/.round-prepare.json'))
assert d['narrowed'] is False, d
assert d.get('reason') and 'scope-set missing or empty' in d['reason'], d
"
}

@test "convergence: full-artifact scope-set (sentinel vs concrete prior) broadens" {
  # 'Full-artifact' is modeled here as a scope-set that uses an artifact-wide
  # sentinel ('*') rather than a concrete file list. Compared against a
  # concrete prior scope-set, the sets are non-equal and not a proper subset
  # (s1\s2 = {*} non-empty), so decide_narrow's diverge-broaden path fires.
  cd "$TEST_ROOT/repo"
  PREV=$(git rev-parse HEAD~1)
  printf '%s\n' "$HEAD_SHA" > "$TASK_DIR/round-02-commit.txt"
  printf '%s\n' "$PREV"     > "$TASK_DIR/round-01-commit.txt"
  printf '*\n'          > "$TASK_DIR/round-01-scope-set.txt"
  printf 'a\nb\nc\n'    > "$TASK_DIR/round-02-scope-set.txt"
  run "$PREP" 3 "$TASK_DIR/round-03" --base-ref "$BASE_SHA"
  [ "$status" -eq 0 ]
  python3 -c "
import json
d=json.load(open('$TASK_DIR/round-03/.round-prepare.json'))
assert d['narrowed'] is False, d
"
}

@test "convergence: partial-overlap scope-sets broaden" {
  cd "$TEST_ROOT/repo"
  PREV=$(git rev-parse HEAD~1)
  printf '%s\n' "$HEAD_SHA" > "$TASK_DIR/round-02-commit.txt"
  printf '%s\n' "$PREV"     > "$TASK_DIR/round-01-commit.txt"
  # NN-1 = {a,b,c}; NN-2 = {b,c,d}. Sets share {b,c} but neither is a subset
  # of the other (s1\s2 = {a} non-empty), so decide_narrow broadens.
  printf 'a\nb\nc\n' > "$TASK_DIR/round-01-scope-set.txt"
  printf 'b\nc\nd\n' > "$TASK_DIR/round-02-scope-set.txt"
  run "$PREP" 3 "$TASK_DIR/round-03" --base-ref "$BASE_SHA"
  [ "$status" -eq 0 ]
  python3 -c "
import json
d=json.load(open('$TASK_DIR/round-03/.round-prepare.json'))
assert d['narrowed'] is False, d
"
}

@test "convergence: proper-subset (NN-1 ⊂ NN-2) with HEAD~1 safety match narrows" {
  cd "$TEST_ROOT/repo"
  # Add a third commit so HEAD~1 == HEAD_SHA matches the round-02 anchor
  # (SHA safety margin satisfied for narrow eligibility).
  echo "v3" > file.txt
  git commit -q -am "third"
  printf '%s\n' "$HEAD_SHA" > "$TASK_DIR/round-02-commit.txt"
  printf '%s\n' "$BASE_SHA" > "$TASK_DIR/round-01-commit.txt"
  # NN-1 (round-02) = {a,b}; NN-2 (round-01) = {a,b,c}. Every element of NN-1
  # is in NN-2 (s1\s2 = {} ); decide_narrow returns the proper-subset narrow
  # path with the SCOPE_HINT carrying the round-NN-1 set.
  printf 'a\nb\nc\n' > "$TASK_DIR/round-01-scope-set.txt"
  printf 'a\nb\n'   > "$TASK_DIR/round-02-scope-set.txt"
  run "$PREP" 3 "$TASK_DIR/round-03" --base-ref "$BASE_SHA"
  [ "$status" -eq 0 ]
  python3 -c "
import json
d=json.load(open('$TASK_DIR/round-03/.round-prepare.json'))
assert d['narrowed'] is True, d
hint=d.get('scope_hint') or ''
# Hint sourced from round-(NN-1) scope-set = {a,b}; not the NN-2 superset.
assert 'a' in hint and 'b' in hint and 'c' not in hint, hint
"
}

# ── Backward-loop flag ──────────────────────────────────────────────────────

@test "backward-loop: present flag forces broaden + flag is consumed (deleted)" {
  cd "$TEST_ROOT/repo"
  PREV=$(git rev-parse HEAD~1)
  printf '%s\n' "$HEAD_SHA" > "$TASK_DIR/round-02-commit.txt"
  printf '%s\n' "$PREV"     > "$TASK_DIR/round-01-commit.txt"
  # Equal scope-sets would otherwise narrow.
  printf 'a\n' > "$TASK_DIR/round-01-scope-set.txt"
  printf 'a\n' > "$TASK_DIR/round-02-scope-set.txt"
  : > "$TASK_DIR/round-03-backward-loop.flag"
  run "$PREP" 3 "$TASK_DIR/round-03" --base-ref "$BASE_SHA"
  [ "$status" -eq 0 ]
  [ ! -f "$TASK_DIR/round-03-backward-loop.flag" ]
  python3 -c "
import json
d=json.load(open('$TASK_DIR/round-03/.round-prepare.json'))
assert d['narrowed'] is False
"
}

@test "backward-loop: deletion failure surfaces a diagnostic on stderr" {
  # Make the flag path a non-empty directory rather than a regular file.
  # `[ -e PATH ]` is true for both, so round-prepare enters the consume-once
  # branch; but `rm -f PATH` on a non-empty directory fails (rm: is a
  # directory), exercising the deletion-failure diagnostic branch in
  # round-prepare.sh (lines 203-205).
  cd "$TEST_ROOT/repo"
  PREV=$(git rev-parse HEAD~1)
  printf '%s\n' "$HEAD_SHA" > "$TASK_DIR/round-02-commit.txt"
  printf '%s\n' "$PREV"     > "$TASK_DIR/round-01-commit.txt"
  printf 'a\n' > "$TASK_DIR/round-01-scope-set.txt"
  printf 'a\n' > "$TASK_DIR/round-02-scope-set.txt"
  mkdir -p "$TASK_DIR/round-03-backward-loop.flag"
  # Put a child inside so the dir is non-empty and `rm -f` fails on it.
  : > "$TASK_DIR/round-03-backward-loop.flag/sentinel"
  run "$PREP" 3 "$TASK_DIR/round-03" --base-ref "$BASE_SHA"
  [ "$status" -eq 0 ]  # round still proceeds; only diagnostic on stderr
  [[ "$output" == *"failed to delete backward-loop flag"* ]]
  # Flag path remains because deletion failed (consume attempt, not consume).
  [ -e "$TASK_DIR/round-03-backward-loop.flag" ]
}

# ── Non-git workspace ───────────────────────────────────────────────────────

@test "non-git workspace: exits 2 with no fabricated diff_file or scope_hint" {
  NONGIT="$TEST_ROOT/nongit"
  mkdir -p "$NONGIT"
  cd "$NONGIT"
  mkdir -p "$NONGIT/round-01"
  run "$PREP" 1 "$NONGIT/round-01" --base-ref HEAD
  [ "$status" -eq 2 ]
  # No diff or sidecar with diff_file/scope_hint should be fabricated.
  [ ! -f "$NONGIT/round-01/round-01.diff" ]
  if [ -f "$NONGIT/round-01/.round-prepare.json" ]; then
    python3 -c "
import json
d=json.load(open('$NONGIT/round-01/.round-prepare.json'))
assert not d.get('diff_file')
assert not d.get('scope_hint')
"
  fi
}

# ── Anchor JSON content coverage (per task-12.md test-expectation bullet 10) ─
# Pin the specific section keys the v0.7.2 release touches so a future
# refactor of the SKILL.md section structure does not silently drop a key
# the dispatch / round-preparation / reviewer-protocol / plan-classification
# narrow-read consumers depend on.

@test "using-qrspi anchors cover Standard Review Loop + Backward Loops sections" {
  python3 -c "
import json
d=json.load(open('$REPO_ROOT/skills/using-qrspi/SKILL.anchors.json'))
for key in ('Standard Review Loop','Backward Loops (New Learnings)'):
    assert key in d, 'missing anchor: '+key
    e=d[key]
    assert e['line_start']>0 and e['line_end']>=e['line_start'], (key,e)
"
}

@test "reviewer-protocol anchors cover Reviewer Dispatch Contract + Phase Routing" {
  python3 -c "
import json
d=json.load(open('$REPO_ROOT/skills/reviewer-protocol/SKILL.anchors.json'))
for key in ('Reviewer Dispatch Contract','Phase Routing'):
    assert key in d, 'missing anchor: '+key
    e=d[key]
    assert e['line_start']>0 and e['line_end']>=e['line_start'], (key,e)
"
}

@test "plan anchors cover Per-Task Classification section" {
  python3 -c "
import json
d=json.load(open('$REPO_ROOT/skills/plan/SKILL.anchors.json'))
hits=[k for k in d if 'Per-Task Classification' in k]
assert hits, 'missing Per-Task Classification anchor; got keys='+repr(list(d.keys())[:5])
e=d[hits[0]]
assert e['line_start']>0 and e['line_end']>=e['line_start'], (hits[0],e)
"
}

@test "g4-section-anchor-manifest references all three per-skill SKILL sources" {
  python3 -c "
import json
d=json.load(open('$REPO_ROOT/scripts/g4-section-anchor-manifest.json'))
sources={e['source'] for e in d['entries']}
for s in ('skills/using-qrspi/SKILL.md','skills/reviewer-protocol/SKILL.md','skills/plan/SKILL.md'):
    assert s in sources, 'missing manifest source: '+s
"
}
